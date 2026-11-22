#include "core/lua_sandbox.h"

#include <gtest/gtest.h>

#include <chrono>
#include <vector>

using pqk::LuaSandbox;

namespace {
constexpr size_t kMB = 1024 * 1024;

struct Fixture {
  std::vector<std::string> logs;
  LuaSandbox sb{16 * kMB, 10'000'000, [this](const std::string& s) { logs.push_back(s); }};
};
}  // namespace

TEST(LuaSandbox, SaysHello) {
  Fixture f;
  auto r = f.sb.run(R"(psito.log("olá", 5.4, true))", "ola.lua");
  ASSERT_TRUE(r.ok) << r.error;
  ASSERT_EQ(f.logs.size(), 1u);
  EXPECT_EQ(f.logs[0], "olá\t5.4\ttrue");
}

TEST(LuaSandbox, IsLua54) {
  Fixture f;
  auto r = f.sb.run(R"(psito.log(_VERSION, math.type(1), 7 // 2))", "versao.lua");
  ASSERT_TRUE(r.ok) << r.error;
  EXPECT_EQ(f.logs[0], "Lua 5.4\tinteger\t3");
}

TEST(LuaSandbox, InfiniteLoopIsInterrupted) {
  Fixture f;
  auto start = std::chrono::steady_clock::now();
  auto r = f.sb.run("while true do end", "laco.lua");
  auto ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - start).count();
  EXPECT_FALSE(r.ok);
  EXPECT_NE(r.error.find("interrompido"), std::string::npos) << r.error;
  EXPECT_LT(ms, 2000.0);
  // E o estado continua usável depois.
  EXPECT_TRUE(f.sb.run(R"(psito.log("ainda vivo"))", "depois.lua").ok);
}

TEST(LuaSandbox, InterruptionCannotBeCaughtByPcallForever) {
  // pcall pega o erro do hook, mas o contador não zera: o próximo hook
  // dispara de novo, e o laço externo também morre.
  Fixture f;
  auto r = f.sb.run("while true do pcall(function() while true do end end) end", "esperto.lua");
  EXPECT_FALSE(r.ok);
}

TEST(LuaSandbox, MemoryCeilingStopsHugeAllocation) {
  Fixture f;
  auto r = f.sb.run(R"(
    local t = {}
    for i = 1, 1e9 do t[i] = string.rep("x", 1024) .. i end
  )", "memoria.lua");
  EXPECT_FALSE(r.ok);
  EXPECT_NE(r.error.find("memória"), std::string::npos) << r.error;
  EXPECT_LE(f.sb.memoryUsed(), f.sb.memoryLimit());
  // O lixo é recolhido: o plugin volta a funcionar.
  EXPECT_TRUE(f.sb.run(R"(psito.log("recuperou"))", "depois.lua").ok);
  EXPECT_LT(f.sb.memoryUsed(), 1 * kMB);
}

TEST(LuaSandbox, NoFilesystemOrProcessAccess) {
  Fixture f;
  auto r = f.sb.run(R"(
    psito.log(type(io), type(os), type(require), type(package), type(debug),
              type(dofile), type(loadfile), type(string.dump), type(collectgarbage))
  )", "fuga.lua");
  ASSERT_TRUE(r.ok) << r.error;
  EXPECT_EQ(f.logs[0], "nil\tnil\tnil\tnil\tnil\tnil\tnil\tnil\tnil");
}

TEST(LuaSandbox, LoadAcceptsTextButRefusesBytecode) {
  Fixture f;
  auto r = f.sb.run(R"(
    local fn = load("return 1 + 1")
    local bad, err = load("\27Lua\84\0garbage")
    psito.log(fn(), bad, err ~= nil)
  )", "load.lua");
  ASSERT_TRUE(r.ok) << r.error;
  EXPECT_EQ(f.logs[0], "2\tnil\ttrue");
}

TEST(LuaSandbox, SyntaxErrorIsReportedNotThrown) {
  Fixture f;
  auto r = f.sb.run("isto não é lua", "quebrado.lua");
  EXPECT_FALSE(r.ok);
  EXPECT_NE(r.error.find("quebrado.lua"), std::string::npos) << r.error;
}
