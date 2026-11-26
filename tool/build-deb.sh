#!/bin/bash
# Compila e monta o pacote .deb, sem sudo. O pacote leva o bundle inteiro e usa o
# LibreOffice do sistema (o motor, aberto por dlopen: o ldd não o mostra) e o GTK.
# O Lua 5.4 vai no bundle (D-077). O Flutter abre o EGL e o GLES na hora de desenhar,
# então eles também vão à mão. O binário usa um símbolo da GLib 2.80, que o Ubuntu
# 24.04 do CI tem e o Debian 12 não.
# Uso: tool/build-deb.sh [pasta de saída, padrão build/deb] [--no-build]
set -e

cd "$(dirname "$0")/.."

OUT="${1:-build/deb}"
VERSION="$(sed -n 's/^version: \([^+]*\).*/\1/p' pubspec.yaml)"
NAME=psito-quill

[ "$2" = "--no-build" ] || flutter build linux --release

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
mkdir -p "$ROOT/DEBIAN"
tool/stage-package.sh "$ROOT"
chmod 755 "$ROOT"
chmod -R go-w "$ROOT/usr"

cat > "$ROOT/DEBIAN/control" <<CONTROL
Package: $NAME
Version: $VERSION
Section: editors
Priority: optional
Architecture: amd64
Maintainer: Francisco Souza <francisceioseph@users.noreply.github.com>
Homepage: https://github.com/francisceioseph/psito-quill
Installed-Size: $(du -sk "$ROOT/usr" | cut -f1)
Depends: libreoffice-writer (>= 4:24.2), libfontconfig1, libgtk-3-0 | libgtk-3-0t64, libglib2.0-0t64 (>= 2.80) | libglib2.0-0 (>= 2.80), libegl1, libgles2
Recommends: libgl1-mesa-dri, hunspell-pt-br | hunspell-dictionary, libpulse0
Description: Editor for long books, on the LibreOffice engine
 Writes books as a folder of chapters (one ODT each), imports a DOCX split by
 its headings, and opens and saves ODT and DOCX. The engine is the system
 LibreOffice. Sends nothing anywhere: no account, no network, no telemetry.
CONTROL

mkdir -p "$OUT"
DEB="$OUT/${NAME}_${VERSION}_amd64.deb"
dpkg-deb --root-owner-group --build "$ROOT" "$DEB" >/dev/null
echo "$DEB"
