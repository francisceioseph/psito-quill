# Plugin nativo do Psito Quill: o LibreOfficeKit do sistema numa thread
# própria, os ladrilhos como texturas do Flutter e o Lua 5.4 dos plugins.
# Os testes nativos ficam em native/ (tool/native-test.sh), fora deste build.
cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "psito_quill_kit")
project(${PROJECT_NAME} LANGUAGES CXX)

# Não mudar: o Flutter usa este nome.
set(PLUGIN_NAME "psito_quill_kit_plugin")

find_package(PkgConfig REQUIRED)
pkg_check_modules(LUA REQUIRED IMPORTED_TARGET lua5.4)
# O fontconfig classifica as fontes para os filtros da lista (o GTK já o traz).
pkg_check_modules(FONTCONFIG REQUIRED IMPORTED_TARGET fontconfig)
# O LibreOfficeKit.h vem do libreofficekit-dev. A biblioteca do LO é aberta em
# tempo de execução (lok_init faz dlopen), então não há link com ela.
find_path(LOK_INCLUDE_DIR LibreOfficeKit/LibreOfficeKit.h REQUIRED)

list(APPEND PLUGIN_SOURCES
  "psito_quill_kit_plugin.cc"
  "core/task_queue.cc"
  "core/tile_cache.cc"
  "core/lok_engine.cc"
  "core/lua_sandbox.cc"
  "core/font_info.cc"
)

add_library(${PLUGIN_NAME} SHARED ${PLUGIN_SOURCES})
apply_standard_settings(${PLUGIN_NAME})
target_compile_features(${PLUGIN_NAME} PRIVATE cxx_std_20)

# Só o que tem FLUTTER_PLUGIN_EXPORT / PQK_EXPORT sai da biblioteca.
set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${PLUGIN_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}" "${LOK_INCLUDE_DIR}")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter PkgConfig::GTK PkgConfig::LUA PkgConfig::FONTCONFIG ${CMAKE_DL_LIBS})

set(psito_quill_kit_bundled_libraries "" PARENT_SCOPE)
