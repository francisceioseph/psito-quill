#!/usr/bin/env bash
# Instala o .deb ou o .rpm numa VM limpa (Ubuntu, Debian ou Fedora) e abre um capítulo com o pacote instalado.
# A VM é uma cópia descartável (qcow2 por cima) de uma imagem de nuvem; o
# cloud-init cria o usuário com uma chave só desta VM. Nada sai da máquina além do
# apt ou o dnf da própria VM, que baixam o LibreOffice e as dependências do pacote.
#
#   tool/vm-test.sh <imagem-de-nuvem> <pacote.deb|pacote.rpm>
#
# O teste: o apt ou o dnf instalam o pacote e resolvem as dependências; o atalho e o ícone
# ficam no lugar; e o `psito-quill --bench`, num Xvfb, abre o capitulo-30p.docx pelo
# motor do sistema e grava as medições (sem o motor, ele não grava nada).
#
# Variáveis: VM_DIR (~/vms/psito-quill-ubuntu), MEM (2560M), SMP (4), SSH_PORT (2225).
set -euo pipefail

IMAGE="$(realpath "${1:?uso: tool/vm-test.sh <imagem> <pacote.deb|pacote.rpm>}")"
DEB="$(realpath "${2:?uso: tool/vm-test.sh <imagem> <pacote.deb|pacote.rpm>}")"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
VM_DIR="${VM_DIR:-$HOME/vms/psito-quill-ubuntu}"
MEM="${MEM:-2560M}"
SMP="${SMP:-4}"
SSH_PORT="${SSH_PORT:-2225}"
KEY="$VM_DIR/ssh_key"
RUN="$(mktemp -d)"
QEMU_PID=""

cleanup() {
    [ -n "$QEMU_PID" ] && kill "$QEMU_PID" 2>/dev/null || true
    rm -rf "$RUN"
}
trap cleanup EXIT

mkdir -p "$VM_DIR"
[ -f "$KEY" ] || ssh-keygen -q -t ed25519 -N '' -C psito-quill-vm -f "$KEY"

cat > "$RUN/user-data" <<EOF
#cloud-config
users:
  - name: quill
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $(cat "$KEY.pub")
EOF
printf 'instance-id: psito-quill-%s\nlocal-hostname: quill-vm\n' "$$" > "$RUN/meta-data"
genisoimage -quiet -output "$RUN/seed.iso" -volid cidata -joliet -rock "$RUN/user-data" "$RUN/meta-data"
qemu-img create -q -f qcow2 -F qcow2 -b "$IMAGE" "$RUN/disk.qcow2" 12G

qemu-system-x86_64 -enable-kvm -cpu host -m "$MEM" -smp "$SMP" \
    -drive file="$RUN/disk.qcow2",if=virtio \
    -drive file="$RUN/seed.iso",if=virtio,media=cdrom \
    -netdev user,id=net0,hostfwd=tcp:127.0.0.1:"$SSH_PORT"-:22 -device virtio-net,netdev=net0 \
    -display none -serial file:"$RUN/serial.log" &
QEMU_PID=$!

SSH=(ssh -q -i "$KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 quill@127.0.0.1)
SCP=(scp -q -i "$KEY" -P "$SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

echo "== ligando a VM"
for _ in $(seq 1 90); do
    "${SSH[@]}" true 2>/dev/null && break
    sleep 2
done
"${SSH[@]}" 'cloud-init status --wait >/dev/null; cat /etc/os-release | sed -n "s/^PRETTY_NAME=//p"'

"${SCP[@]}" "$DEB" "$HERE/test/fixtures/capitulo-30p.docx" quill@127.0.0.1:

PKG="$(basename "$DEB")"
case "$PKG" in
    *.deb)
        INSTALL="sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ./$PKG xvfb xauth desktop-file-utils python3"
        REMOVE="sudo apt-get remove -y -qq psito-quill"
        QUERY='dpkg-query -W -f "  \${Package} \${Version}: \${Status}\n" psito-quill; dpkg-query -W -f "  LibreOffice \${Version}\n" libreoffice-writer' ;;
    *.rpm)
        INSTALL="sudo dnf install -y -q ./$PKG xorg-x11-server-Xvfb xauth desktop-file-utils python3"
        REMOVE="sudo dnf remove -y -q psito-quill"
        QUERY='rpm -q psito-quill | sed "s/^/  /"; rpm -q --qf "  LibreOffice %{EPOCH}:%{VERSION}\n" libreoffice-writer' ;;
    *) echo "nem .deb nem .rpm: $PKG" >&2; exit 2 ;;
esac

echo "== instalar ./$PKG"
"${SSH[@]}" "$INSTALL >/tmp/install.log 2>&1 || { tail -30 /tmp/install.log; exit 1; }"

echo "== os arquivos instalados"
"${SSH[@]}" "set -e; $QUERY"
"${SSH[@]}" 'set -e
    test -x /usr/bin/psito-quill && echo "  /usr/bin/psito-quill"
    desktop-file-validate /usr/share/applications/org.psito.quill.desktop 2>/dev/null && echo "  o atalho é válido"
    test -f /usr/share/icons/hicolor/scalable/apps/org.psito.quill.svg && echo "  o ícone"
    LD_LIBRARY_PATH=/usr/lib/psito-quill/lib ldd /usr/lib/psito-quill/psito-quill /usr/lib/psito-quill/lib/*.so | grep "not found" && exit 1 || echo "  nenhuma biblioteca faltando"'

echo "== abrir um capítulo com o motor do sistema (--bench num Xvfb)"
BENCH_OK=0
"${SSH[@]}" 'rm -f out.json; timeout 300 xvfb-run -a -s "-screen 0 1600x1000x24" psito-quill --bench capitulo-30p.docx out.json >bench.log 2>&1; code=$?
    if [ -s out.json ]; then
        python3 -c "import json,sys; d=json.load(open(\"out.json\")); print(\"  motor\", d.get(\"versao\"), \"| abrir_ms\", d.get(\"abrir_ms\"), \"| primeiro_ladrilho_ms\", d.get(\"primeiro_ladrilho_ms\"), \"| rss_30p_mb\", d.get(\"rss_30p_mb\")); d.get(\"ok\") or sys.exit(\"  erro: \" + str(d.get(\"erro\"))[:1500])" || { tail -20 bench.log; exit 1; }
    else
        echo "  falhou (saída $code):"; tail -20 bench.log; exit 1
    fi' && BENCH_OK=1

# O que o bench deixou, para ver depois em $VM_DIR/ultimo/
mkdir -p "$VM_DIR/ultimo"
"${SCP[@]}" quill@127.0.0.1:out.json quill@127.0.0.1:bench.log "$VM_DIR/ultimo/" 2>/dev/null || true
[ "$BENCH_OK" = 1 ] || exit 1

echo "== remover"
"${SSH[@]}" "$REMOVE >/dev/null 2>&1 && ! test -e /usr/bin/psito-quill && echo '  removido'"
echo "✅ a VM instalou, abriu e removeu o pacote"
