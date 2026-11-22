#!/bin/bash
# Compila e roda os testes nativos (GoogleTest): fila do kit, cache de
# ladrilhos e caixa de areia do Lua. Também compila o lok_probe.
# Como o ./test.sh, roda num escopo do systemd com limite de memória.
# Uso: tool/native-test.sh [filtro-do-gtest]
set -e
cd "$(dirname "$0")/.."

SRC=packages/psito_quill_kit/linux/native
BUILD=build/native
MEM="${TEST_MEM:-2G}"
JOBS="${TEST_JOBS:-2}"

LIMIT=()
if [ "$MEM" != "0" ] && command -v systemd-run >/dev/null; then
    LIMIT=(systemd-run --user --scope --quiet --collect -p MemoryMax="$MEM" -p MemorySwapMax=0)
fi

cmake -S "$SRC" -B "$BUILD" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo >/dev/null
"${LIMIT[@]}" cmake --build "$BUILD" -j "$JOBS"
"${LIMIT[@]}" "$BUILD/pqk_tests" --gtest_brief=1 ${1:+--gtest_filter="$1"}
