#!/bin/bash
# Ponta a ponta: abre o app de verdade (release) numa cópia do capítulo,
# fecha a janela pelo gerenciador de janelas (wmctrl, com o id da janela do
# próprio processo: não mexe no mouse nem no teclado) e confere:
# - o app sai com código 0 (sem SIGSEGV no fim; D-027);
# - a trava .~lock do documento foi apagada.
# Preferências e perfil numa pasta temporária. Uso: tool/fechar-test.sh
set -e
cd "$(dirname "$0")/.."

TMP=$(mktemp -d /tmp/quill-fechar-XXXXXX)
trap 'rm -rf "$TMP"' EXIT
cp test/fixtures/capitulo-30p.docx "$TMP/cap.docx"
flutter build linux --release >/dev/null

XDG_CONFIG_HOME="$TMP/config" build/linux/x64/release/bundle/psito-quill "$TMP/cap.docx" >"$TMP/log" 2>&1 &
APP=$!

# Espera a janela do próprio processo e a trava (o documento aberto).
WIN=""
for _ in $(seq 1 100); do
    WIN=$(wmctrl -lp | awk -v p="$APP" '$3==p{print $1}' | head -1)
    [ -n "$WIN" ] && [ -e "$TMP/.~lock.cap.docx#" ] && break
    sleep 0.2
done
[ -n "$WIN" ] || { echo "a janela não apareceu"; kill $APP; exit 1; }
[ -e "$TMP/.~lock.cap.docx#" ] || { echo "o documento não abriu"; kill $APP; exit 1; }
sleep 1

wmctrl -i -c "$WIN"
set +e
wait $APP
RC=$?
set -e
if [ $RC -ne 0 ]; then
    echo "o app saiu com $RC (esperado 0)"
    tail -5 "$TMP/log"
    exit 1
fi
if [ -e "$TMP/.~lock.cap.docx#" ]; then
    echo "a trava ficou"
    exit 1
fi
echo "fechou limpo: código 0, sem trava"
