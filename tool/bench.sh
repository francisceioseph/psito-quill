#!/bin/bash
# Ponta a ponta da Fase 0: mede o motor sozinho (lok_probe) e o app inteiro
# (psito-quill --bench), e amostra o USS, PSS e RSS do app (smaps_rollup) enquanto roda.
# Saída em build/medicoes/: probe.json, bench.json, memoria.txt e os ladrilhos PPM.
# Uso: tool/bench.sh [documento.docx]
# Abre uma janela por ~40 s (precisa de sessão gráfica). Não mexe no mouse nem
# no teclado.
set -e
cd "$(dirname "$0")/.."

DOC="$(realpath "${1:-test/fixtures/capitulo-30p.docx}")"
OUT="$PWD/build/medicoes"
mkdir -p "$OUT"
# Trabalha numa cópia: o LibreOffice deixa uma trava (.~lock) ao lado do
# arquivo, e um arquivo travado por outro perfil abre só para leitura.
cp "$DOC" "$OUT/trabalho.docx"
DOC="$OUT/trabalho.docx"
rm -f "$OUT"/.~lock.*
LIMIT=(systemd-run --user --scope --quiet --collect -p MemoryMax=3G -p MemorySwapMax=0)

echo "== motor sozinho (lok_probe)"
cmake -S packages/psito_quill_kit/linux/native -B build/native -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo >/dev/null
cmake --build build/native -j 2 >/dev/null
"${LIMIT[@]}" build/native/lok_probe "$DOC" "$OUT" >"$OUT/probe.json" 2>"$OUT/probe.log"
python3 -c "
from PIL import Image
for n in ['ladrilho-1000','ladrilho-1250','ladrilho-2000']:
    Image.open('$OUT/'+n+'.ppm').save('$OUT/'+n+'.png')
" 2>/dev/null || true

echo "== app inteiro (--bench)"
"${LIMIT[@]}" flutter build linux --release >/dev/null
build/linux/x64/release/bundle/psito-quill --bench "$DOC" "$OUT/bench.json" >"$OUT/bench.log" 2>&1 &
APP=$!
: >"$OUT/memoria.txt"
while kill -0 $APP 2>/dev/null; do
    # Do próprio processo (não dos filhos): USS = privado; PSS = com a parte
    # justa das bibliotecas compartilhadas; RSS = tudo que está na RAM.
    awk '/^Rss:/{r=$2} /^Pss:/{p=$2} /^Private_(Clean|Dirty):/{u+=$2} END{if(r) print u, p, r}' \
        /proc/$APP/smaps_rollup >>"$OUT/memoria.txt" 2>/dev/null || true
    ps -o pid=,rss=,args= --ppid $APP 2>/dev/null | sed 's/^/filho: /' >>"$OUT/filhos.txt" || true
    sleep 1
done
wait $APP || { echo "o app falhou:"; tail -20 "$OUT/bench.log"; exit 1; }

python3 - "$OUT" <<'EOF'
import json, sys
out = sys.argv[1]
def mb(s):
    return float(s) / 1024  # kB
rows = [l.split() for l in open(f'{out}/memoria.txt') if len(l.split()) == 3]
peak = {k: round(max(mb(r[i]) for r in rows), 1) for i, k in enumerate(['uss', 'pss', 'rss'])} if rows else {}
probe, bench = json.load(open(f'{out}/probe.json')), json.load(open(f'{out}/bench.json'))
print(json.dumps({'memoria_pico_mb': peak,
                  'app_rss_30p_mb': bench['rss_30p_mb'],
                  'app_latencia': bench['latencia_tecla_ladrilho'],
                  'app_rolar': bench['rolar'],
                  'papel_escuro': {k: v for k, v in bench['papel_escuro'].items() if k != 'respostas'},
                  'motor_rss_30p_mb': round(probe['rss_30p_mb'], 1)}, ensure_ascii=False, indent=1))
EOF
