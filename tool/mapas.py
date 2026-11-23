#!/usr/bin/env python3
"""Para onde vai a memória: roda o `psito-quill --bench` e amostra o
/proc/<pid>/smaps a cada 0,5 s, somando por tipo de mapeamento.

O RSS sozinho engana: as páginas de código de uma biblioteca (o
libmergedlo.so tem uns 100 MB) entram no RSS, mas são do arquivo, e o
kernel as devolve quando falta memória. O que pesa de verdade é a
memória anônima (heap, malloc, buffers do Flutter), que só sai com swap.

Uso: tool/mapas.py <pasta-do-bundle> <documento> <saída.json>
Imprime, para cada etapa do bench, o RSS e o anônimo de cada grupo.
Abre uma janela por uns 40 s, como o bench.sh. Não mexe em mouse nem teclado.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time

GROUPS = [
    ('heap', lambda n: n == '[heap]'),
    ('anon', lambda n: n == '' or n.startswith('[anon')),
    ('pilhas', lambda n: n.startswith('[stack')),
    ('lo:libmergedlo', lambda n: n.endswith('libmergedlo.so')),
    ('lo:outras', lambda n: '/libreoffice/' in n),
    ('flutter:engine', lambda n: 'libflutter_linux_gtk' in n),
    ('flutter:app', lambda n: n.endswith('libapp.so')),
    ('gpu', lambda n: '/dev/dri' in n or 'nvidia' in n or 'libGL' in n or 'mesa' in n or 'dri/' in n or 'libgallium' in n or 'vulkan' in n.lower()),
    ('fontes', lambda n: n.endswith(('.ttf', '.otf', '.ttc', '.pfb')) or 'fontconfig' in n),
    ('memfd/shm', lambda n: n.startswith(('/memfd:', '/dev/shm', '/SYSV'))),
    ('outras .so', lambda n: '.so' in n),
    ('outros arquivos', lambda n: True),
]


def group_of(name):
    for g, test in GROUPS:
        if test(name):
            return g
    return 'outros arquivos'


def sample(pid):
    out = {}
    name = ''
    try:
        with open(f'/proc/{pid}/smaps') as f:
            for line in f:
                first = line.split(None, 1)[0]
                if '-' in first and not first.endswith(':'):
                    parts = line.split(None, 5)
                    name = parts[5].strip() if len(parts) > 5 else ''
                    g = out.setdefault(group_of(name), [0, 0])
                elif first == 'Rss:':
                    g[0] += int(line.split()[1])
                elif first == 'Anonymous:':
                    g[1] += int(line.split()[1])
    except (FileNotFoundError, ProcessLookupError, PermissionError):
        return None
    return out


def main():
    bundle, doc, dest = sys.argv[1:4]
    work = tempfile.mkdtemp(prefix='mapas-')
    copy = os.path.join(work, 'trabalho.docx')
    shutil.copy(doc, copy)
    bench = os.path.join(work, 'bench.json')
    app = subprocess.Popen([os.path.join(bundle, 'psito-quill'), '--bench', copy, bench],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    samples = []
    t0 = time.monotonic()
    while app.poll() is None:
        s = sample(app.pid)
        if s:
            samples.append({'t': round(time.monotonic() - t0, 2), 'g': s})
        time.sleep(0.5)
    result = json.load(open(bench)) if os.path.exists(bench) else {}
    json.dump({'bench': result, 'amostras': samples}, open(dest, 'w'))

    def total(s):
        return sum(v[0] for v in s['g'].values()) / 1024

    # Cada etapa: a primeira amostra, depois da anterior, com o RSS mais
    # perto do que o bench mediu.
    stages = [(k, result[k]) for k in ('rss_motor_ligado_mb', 'rss_vazio_mb', 'rss_30p_mb', 'rss_depois_de_digitar_mb') if k in result]
    start = 0
    for key, mb in stages:
        best = min(range(start, len(samples)), key=lambda i: abs(total(samples[i]) - mb))
        start = best
        s = samples[best]
        print(f'== {key}: bench {mb} MB, amostra {total(s):.1f} MB (t={s["t"]} s)')
        for g, (rss, anon) in sorted(s['g'].items(), key=lambda kv: -kv[1][0]):
            if rss >= 1024:
                print(f'   {g:18s} RSS {rss / 1024:7.1f}  anônima {anon / 1024:7.1f}')
    shutil.rmtree(work, ignore_errors=True)


if __name__ == '__main__':
    main()
