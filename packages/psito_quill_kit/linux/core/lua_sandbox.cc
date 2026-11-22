#include "lua_sandbox.h"

#include <lua.hpp>

#include <cstdlib>

namespace pqk {

namespace {

constexpr int kHookEvery = 1000;  // o hook roda a cada 1000 instruções
const char* const kSelfKey = "pqk.sandbox";

LuaSandbox* self(lua_State* L) {
  lua_getfield(L, LUA_REGISTRYINDEX, kSelfKey);
  auto* s = static_cast<LuaSandbox*>(lua_touserdata(L, -1));
  lua_pop(L, 1);
  return s;
}

}  // namespace

LuaSandbox::LuaSandbox(size_t memoryLimit, uint64_t instructionLimit, LogFn log)
    : limit_(memoryLimit), instructionLimit_(instructionLimit), log_(std::move(log)) {
  L_ = lua_newstate(&LuaSandbox::alloc, this);
  if (!L_) return;
  lua_pushlightuserdata(L_, this);
  lua_setfield(L_, LUA_REGISTRYINDEX, kSelfKey);
  openSafeLibs();
}

LuaSandbox::~LuaSandbox() {
  if (L_) lua_close(L_);
}

// Alocador com teto. Devolver NULL faz o Lua lançar "not enough memory".
void* LuaSandbox::alloc(void* ud, void* ptr, size_t osize, size_t nsize) {
  auto* s = static_cast<LuaSandbox*>(ud);
  // Quando ptr é NULL, osize é o tipo do objeto, não um tamanho.
  const size_t old = ptr ? osize : 0;
  if (nsize == 0) {
    s->used_ -= old;
    free(ptr);
    return nullptr;
  }
  if (nsize > old && s->used_ + (nsize - old) > s->limit_) return nullptr;
  void* p = realloc(ptr, nsize);
  if (p) s->used_ = s->used_ - old + nsize;
  return p;
}

void LuaSandbox::countHook(lua_State* L, lua_Debug*) {
  LuaSandbox* s = self(L);
  s->instructions_ += kHookEvery;
  if (s->instructions_ > s->instructionLimit_) {
    // Depois do limite, o hook passa a rodar a cada instrução. Assim um
    // pcall que engole o erro não ganha mais 1000 instruções: a primeira
    // instrução fora dele já falha de novo, até o erro sair do plugin.
    lua_sethook(L, &LuaSandbox::countHook, LUA_MASKCOUNT, 1);
    luaL_error(L, "plugin interrompido: passou de %I instruções",
               static_cast<lua_Integer>(s->instructionLimit_));
  }
}

int LuaSandbox::luaLog(lua_State* L) {
  LuaSandbox* s = self(L);
  int n = lua_gettop(L);
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  for (int i = 1; i <= n; ++i) {
    if (i > 1) luaL_addchar(&b, '\t');
    luaL_tolstring(L, i, nullptr);
    luaL_addvalue(&b);
  }
  luaL_pushresult(&b);
  if (s->log_) s->log_(lua_tostring(L, -1));
  return 0;
}

// load(chunk, name) só de texto: o modo "t" recusa bytecode, que pode quebrar
// a VM. O ambiente é sempre o global da sandbox.
int LuaSandbox::luaLoadText(lua_State* L) {
  size_t len;
  const char* src = luaL_checklstring(L, 1, &len);
  const char* name = luaL_optstring(L, 2, "=(load)");
  if (luaL_loadbufferx(L, src, len, name, "t") != LUA_OK) {
    lua_pushnil(L);
    lua_insert(L, -2);
    return 2;
  }
  return 1;
}

void LuaSandbox::openSafeLibs() {
  static const luaL_Reg libs[] = {
      {LUA_GNAME, luaopen_base},          {LUA_STRLIBNAME, luaopen_string},
      {LUA_TABLIBNAME, luaopen_table},    {LUA_MATHLIBNAME, luaopen_math},
      {LUA_UTF8LIBNAME, luaopen_utf8},    {LUA_COLIBNAME, luaopen_coroutine},
      {nullptr, nullptr}};
  for (const luaL_Reg* lib = libs; lib->func; ++lib) {
    luaL_requiref(L_, lib->name, lib->func, 1);
    lua_pop(L_, 1);
  }
  // Tira da base o que lê arquivos ou carrega bytecode.
  for (const char* name : {"dofile", "loadfile", "load", "collectgarbage"}) {
    lua_pushnil(L_);
    lua_setglobal(L_, name);
  }
  lua_pushcfunction(L_, &LuaSandbox::luaLoadText);
  lua_setglobal(L_, "load");
  // string.dump gera bytecode: fora.
  lua_getglobal(L_, LUA_STRLIBNAME);
  lua_pushnil(L_);
  lua_setfield(L_, -2, "dump");
  lua_pop(L_, 1);

  // psito = { log = ... }
  lua_newtable(L_);
  lua_pushcfunction(L_, &LuaSandbox::luaLog);
  lua_setfield(L_, -2, "log");
  lua_setglobal(L_, "psito");
}

LuaResult LuaSandbox::run(const std::string& source, const std::string& chunkName) {
  LuaResult r;
  if (!L_) {
    r.error = "sem memória para criar o estado Lua";
    return r;
  }
  instructions_ = 0;
  lua_sethook(L_, &LuaSandbox::countHook, LUA_MASKCOUNT, kHookEvery);
  int status = luaL_loadbufferx(L_, source.data(), source.size(),
                                ("=" + chunkName).c_str(), "t");
  if (status == LUA_OK) status = lua_pcall(L_, 0, 0, 0);
  lua_sethook(L_, nullptr, 0, 0);
  if (status == LUA_OK) {
    r.ok = true;
  } else {
    r.error = status == LUA_ERRMEM ? "plugin passou do teto de memória"
                                   : (lua_tostring(L_, -1) ? lua_tostring(L_, -1) : "erro");
    lua_pop(L_, 1);
  }
  // Devolve ao teto o que o código largou.
  lua_gc(L_, LUA_GCCOLLECT);
  return r;
}

}  // namespace pqk
