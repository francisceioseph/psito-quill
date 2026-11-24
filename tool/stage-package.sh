#!/bin/bash
# Monta em <raiz> os arquivos que todo pacote instala, a partir do bundle de release.
# Quem chama é o build-deb.sh e o build-rpm.sh.
# Uso: tool/stage-package.sh <raiz>
set -e

cd "$(dirname "$0")/.."

ROOT="${1:?uso: tool/stage-package.sh <raiz>}"
ID=org.psito.quill
NAME=psito-quill
BUNDLE=build/linux/x64/release/bundle

mkdir -p "$ROOT/usr/bin" "$ROOT/usr/lib/$NAME" \
    "$ROOT/usr/share/applications" \
    "$ROOT/usr/share/icons/hicolor/scalable/apps" \
    "$ROOT/usr/share/doc/$NAME"

cp -r "$BUNDLE/." "$ROOT/usr/lib/$NAME/"
ln -s "../lib/$NAME/$NAME" "$ROOT/usr/bin/$NAME"
cp "$ID.desktop" "$ROOT/usr/share/applications/"
cp icon.svg "$ROOT/usr/share/icons/hicolor/scalable/apps/$ID.svg"
for size in 48 64 128 256 512; do
    png="assets/icon/$ID-$size.png"
    [ -f "$png" ] || continue
    mkdir -p "$ROOT/usr/share/icons/hicolor/${size}x${size}/apps"
    cp "$png" "$ROOT/usr/share/icons/hicolor/${size}x${size}/apps/$ID.png"
done
cp LICENSE README.md "$ROOT/usr/share/doc/$NAME/"
# O Lua que vai no bundle (MIT)
tool/lua-license.sh > "$ROOT/usr/share/doc/$NAME/LUA-LICENSE"
# Os textos das licenças do que foi compilado, que o Flutter junta no bundle
gunzip -c "$BUNDLE/data/flutter_assets/NOTICES.Z" > "$ROOT/usr/share/doc/$NAME/NOTICES"
