// A caixa de areia de um plugin Lua 5.4.
//
// - Um lua_State por plugin, com um alocador que tem teto de bytes.
// - Só as bibliotecas seguras: base (sem dofile, loadfile e load de bytecode),
//   string, table, math, utf8 e coroutine. Sem io, os, package, debug.
// - Um hook de contagem que interrompe o código depois de N instruções, para
//   um laço infinito não travar o editor.
// - A API psito.* entra por registerFunction; no Fase 0 só psito.log.
//
// Não é thread-safe: cada sandbox vive numa thread só (a de plugins).
#pragma once

#include <cstdint>
#include <functional>
#include <string>

struct lua_State;
struct lua_Debug;

namespace pqk {

struct LuaResult {
  bool ok = false;
  std::string error;  // vazio se ok
};

class LuaSandbox {
 public:
  using LogFn = std::function<void(const std::string&)>;

  // memoryLimit em bytes; instructionLimit por chamada de run().
  LuaSandbox(size_t memoryLimit, uint64_t instructionLimit, LogFn log);
  ~LuaSandbox();

  LuaSandbox(const LuaSandbox&) = delete;
  LuaSandbox& operator=(const LuaSandbox&) = delete;

  // Roda o código-fonte (só texto, nunca bytecode).
  LuaResult run(const std::string& source, const std::string& chunkName);

  size_t memoryUsed() const { return used_; }
  size_t memoryLimit() const { return limit_; }
  bool valid() const { return L_ != nullptr; }

 private:
  static void* alloc(void* ud, void* ptr, size_t osize, size_t nsize);
  static void countHook(lua_State* L, ::lua_Debug* ar);
  static int luaLog(lua_State* L);
  static int luaLoadText(lua_State* L);
  void openSafeLibs();

  lua_State* L_ = nullptr;
  size_t limit_;
  size_t used_ = 0;
  uint64_t instructionLimit_;
  uint64_t instructions_ = 0;
  LogFn log_;
};

}  // namespace pqk
