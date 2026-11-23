# Testes nativos (GoogleTest) e o lok_probe, fora do build do Flutter.
# Uso: tool/native-test.sh (na raiz do app)
cmake_minimum_required(VERSION 3.16)
project(psito_quill_kit_native LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_compile_options(-Wall -Wextra -Werror -Wno-unused-parameter)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LUA REQUIRED IMPORTED_TARGET lua5.4)
find_package(GTest REQUIRED)
find_package(Threads REQUIRED)

set(KIT ${CMAKE_CURRENT_SOURCE_DIR}/..)

add_library(pqk_core STATIC
  ${KIT}/core/task_queue.cc
  ${KIT}/core/tile_cache.cc
  ${KIT}/core/lok_engine.cc
  ${KIT}/core/lua_sandbox.cc
)
target_include_directories(pqk_core PUBLIC ${KIT})
target_link_libraries(pqk_core PUBLIC PkgConfig::LUA Threads::Threads ${CMAKE_DL_LIBS})

add_executable(pqk_tests
  ${KIT}/test/task_queue_test.cc
  ${KIT}/test/tile_cache_test.cc
  ${KIT}/test/lua_sandbox_test.cc
)
target_link_libraries(pqk_tests PRIVATE pqk_core GTest::gtest_main)

add_executable(lok_probe ${KIT}/tools/lok_probe.cc)
target_link_libraries(lok_probe PRIVATE pqk_core)

enable_testing()
include(GoogleTest)
gtest_discover_tests(pqk_tests)

# Conversa com o motor por um roteiro (para descobrir o que a versão
# instalada responde). Veja o cabeçalho de tools/lok_script.cc.
add_executable(lok_script ${KIT}/tools/lok_script.cc)
target_link_libraries(lok_script PRIVATE pqk_core)
