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
# A janela de impressão do GTK (D-076).
pkg_check_modules(GTK_PRINT REQUIRED IMPORTED_TARGET gtk+-unix-print-3.0)
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
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter PkgConfig::GTK PkgConfig::LUA PkgConfig::FONTCONFIG PkgConfig::GTK_PRINT ${CMAKE_DL_LIBS})

# O Lua vai junto no bundle, ao lado do plugin (o rpath $ORIGIN o acha): o nome
# da biblioteca muda de uma distribuição para outra (liblua5.4.so.0 no Debian,
# liblua-5.4.so no Fedora), e o pacote não pode depender do nome de uma só (D-077).
# A cópia leva o nome do SONAME, que é o que o carregador procura.
find_library(LUA_SHARED_LIB NAMES ${LUA_LIBRARIES} HINTS ${LUA_LIBRARY_DIRS} REQUIRED)
execute_process(COMMAND objdump -p "${LUA_SHARED_LIB}" OUTPUT_VARIABLE LUA_OBJDUMP)
string(REGEX MATCH "SONAME +([^ \n]+)" _ "${LUA_OBJDUMP}")
set(LUA_SONAME "${CMAKE_MATCH_1}")
get_filename_component(LUA_LIB_DIR "${LUA_SHARED_LIB}" DIRECTORY)
set(LUA_SONAME_LIB "${LUA_LIB_DIR}/${LUA_SONAME}")
if(NOT LUA_SONAME OR NOT EXISTS "${LUA_SONAME_LIB}")
  message(FATAL_ERROR "não achei o SONAME do Lua em ${LUA_SHARED_LIB}")
endif()
# O SONAME é um link simbólico, e o install(FILES) do Flutter copiaria o link:
# a cópia aqui é o arquivo de verdade, já com o nome do SONAME.
file(REAL_PATH "${LUA_SONAME_LIB}" LUA_REAL_LIB)
set(LUA_BUNDLED_LIB "${CMAKE_CURRENT_BINARY_DIR}/${LUA_SONAME}")
configure_file("${LUA_REAL_LIB}" "${LUA_BUNDLED_LIB}" COPYONLY)
set_target_properties(${PLUGIN_NAME} PROPERTIES BUILD_RPATH "$ORIGIN")

set(psito_quill_kit_bundled_libraries "${LUA_BUNDLED_LIB}" PARENT_SCOPE)
