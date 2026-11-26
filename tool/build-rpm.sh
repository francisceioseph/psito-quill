#!/bin/bash
# Compila e monta o pacote .rpm para o Fedora, sem sudo. Leva o mesmo bundle do .deb e
# usa o LibreOffice do sistema (em /usr/lib64). As dependências vão à mão, sem o
# AutoReq, porque o motor e o EGL são abertos na hora (dlopen) e porque o rpm
# procuraria dentro do bundle por bibliotecas que já vêm nele.
# Uso: tool/build-rpm.sh [pasta de saída, padrão build/rpm] [--no-build]
set -e

cd "$(dirname "$0")/.."

OUT="$(realpath -m "${1:-build/rpm}")"
VERSION="$(sed -n 's/^version: \([^+]*\).*/\1/p' pubspec.yaml)"
NAME=psito-quill

[ "$2" = "--no-build" ] || flutter build linux --release

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
tool/stage-package.sh "$WORK/stage"

cat > "$WORK/$NAME.spec" <<SPEC
%global debug_package %{nil}
%global __os_install_post %{nil}
%global _build_id_links none

Name: $NAME
Version: $VERSION
Release: 1
Summary: Editor for long books, on the LibreOffice engine
License: MPL-2.0
URL: https://github.com/francisceioseph/psito-quill
AutoReqProv: no
Requires: libreoffice-writer >= 1:24.2
Requires: fontconfig
Requires: gtk3
Requires: glib2 >= 2.80
Requires: mesa-libEGL
Requires: mesa-libGLES
Recommends: mesa-dri-drivers
Recommends: hunspell-pt
# Os sons da máquina de escrever (D-095), abertos por dlopen: sem eles, o som fica mudo.
Recommends: pulseaudio-libs

%description
Writes books as a folder of chapters (one ODT each), imports a DOCX split by
its headings, and opens and saves ODT and DOCX. The engine is the system
LibreOffice. Sends nothing anywhere: no account, no network, no telemetry.

%install
cp -a "$WORK/stage/." %{buildroot}/

%files
/usr/bin/$NAME
/usr/lib/$NAME
/usr/share/applications/org.psito.quill.desktop
/usr/share/icons/hicolor/*/apps/org.psito.quill.*
/usr/share/doc/$NAME
SPEC

mkdir -p "$OUT"
rpmbuild -bb "$WORK/$NAME.spec" --target x86_64 \
    --define "_topdir $WORK/rpmbuild" \
    --define "_rpmdir $OUT" \
    --define "_build_name_fmt %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm" >/dev/null 2>&1
echo "$OUT/$NAME-$VERSION-1.x86_64.rpm"
