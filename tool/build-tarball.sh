#!/bin/bash
# O bundle num tar.gz, para quem não usa .deb nem .rpm: descompacta e roda o
# psito-quill de dentro da pasta. Precisa do LibreOffice Writer do sistema.
# Uso: tool/build-tarball.sh [pasta de saída, padrão build/tar] [--no-build]
set -e

cd "$(dirname "$0")/.."

OUT="$(realpath -m "${1:-build/tar}")"
VERSION="$(sed -n 's/^version: \([^+]*\).*/\1/p' pubspec.yaml)"
NAME=psito-quill

[ "$2" = "--no-build" ] || flutter build linux --release

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
DIR="$WORK/$NAME-$VERSION"
mkdir -p "$DIR"
cp -r build/linux/x64/release/bundle/. "$DIR/"
cp icon.svg "$DIR/org.psito.quill.svg"
cp org.psito.quill.desktop LICENSE README.md "$DIR/"
tool/lua-license.sh > "$DIR/LUA-LICENSE"
mkdir -p "$OUT"
tar -C "$WORK" --owner=0 --group=0 -czf "$OUT/$NAME-$VERSION-linux-x64.tar.gz" "$NAME-$VERSION"
echo "$OUT/$NAME-$VERSION-linux-x64.tar.gz"
