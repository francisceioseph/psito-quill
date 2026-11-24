#!/bin/bash
# Compila a sonda do LibreOfficeKit para o Windows com o MinGW, num contêiner do
# Debian (nada é instalado no host). Os cabeçalhos do LOK vêm do libreofficekit-dev
# do sistema. Saída: build/windows-probe/lok_win_probe.exe
set -e
cd "$(dirname "$0")/../.."
mkdir -p build/windows-probe
cp -r /usr/include/LibreOfficeKit build/windows-probe/
podman run --rm -v "$PWD":/src:Z -w /src docker.io/library/debian:trixie bash -c '
  apt-get update -qq >/dev/null && apt-get install -y -qq g++-mingw-w64-x86-64-posix >/dev/null &&
  x86_64-w64-mingw32-g++-posix -std=c++17 -O2 -static -I build/windows-probe \
    tool/windows-probe/lok_win_probe.cc -o build/windows-probe/lok_win_probe.exe'
ls -la build/windows-probe/lok_win_probe.exe
