#!/bin/bash
# Roda a pirâmide de testes e imprime só as falhas.
#   unidade + widget: flutter test (test/)
#   nativo:           GoogleTest (tool/native-test.sh)
#   integração:       integration_test com o LibreOffice de verdade (--integracao)
# Como no Psito OS: TEST_JOBS processos de teste (padrão 6), num escopo do
# systemd com TEST_MEM de limite (padrão 6G) e sem swap. Se passar disso, só
# os testes morrem, e o resto do host fica.
# Uso: ./test.sh [--integracao]       Sem limite: TEST_MEM=0 ./test.sh
cd "$(dirname "$0")"

JOBS="${TEST_JOBS:-6}"
MEM="${TEST_MEM:-6G}"
LIMIT=()
if [ "$MEM" != "0" ] && command -v systemd-run >/dev/null; then
    LIMIT=(systemd-run --user --scope --quiet --collect -p MemoryMax="$MEM" -p MemorySwapMax=0)
fi

STATUS=0
run() {
    local name=$1; shift
    OUT=$("$@" 2>&1)
    CODE=$?
    if [ $CODE -ne 0 ]; then
        echo "❌ $name:"
        [ $CODE -eq 137 ] && echo "   morto pelo limite de memória ($MEM). Tente TEST_MEM=8G ou TEST_JOBS=2."
        echo "$OUT" | tail -n 40
        STATUS=$CODE
    else
        echo "✅ $name"
    fi
}

run "dart (unidade + widget)" "${LIMIT[@]}" flutter test --no-pub -j "$JOBS" -r failures-only test/
run "nativo (GoogleTest)" env TEST_MEM="$MEM" TEST_JOBS="$JOBS" tool/native-test.sh
if [ "$1" = "--integracao" ]; then
    # Uma janela abre e fecha: precisa de uma sessão gráfica.
    run "integração (LibreOffice real)" "${LIMIT[@]}" flutter test --no-pub -d linux integration_test/
    run "ponta a ponta (fechar a janela)" "${LIMIT[@]}" tool/fechar-test.sh
fi

exit $STATUS
