#!/usr/bin/env python3
"""A memória de uma etapa, lado a lado com a anterior, no mesmo dia (D-038).

Uso: tool/ab.py <commit-anterior> [documento.docx] [rodadas]

Monta o commit anterior numa git worktree (build/ab/base), faz a build de
release dele e a da árvore atual, e roda o bench as rodadas pedidas (3 por
padrão), alternando A e B para o ruído da máquina cair nos dois. Imprime a
mediana da memória anônima e do RSS em cada etapa do bench, e a diferença.
Grava tudo em build/medicoes/ab.json.

Abre uma janela por uns 40 s em cada rodada. Não mexe em mouse nem teclado.
"""
import json
import os
import statistics
import subprocess
import sys

sys.path.insert(0, os.path.dirname(__file__))
import mapas  # noqa: E402

ROOT = os.path.realpath(os.path.join(os.path.dirname(__file__), '..'))
LIMIT = ['systemd-run', '--user', '--scope', '--quiet', '--collect', '-p', 'MemoryMax=3G', '-p', 'MemorySwapMax=0']


def build(tree):
    subprocess.run(['flutter', 'pub', 'get'], cwd=tree, check=True, stdout=subprocess.DEVNULL)
    subprocess.run(LIMIT + ['flutter', 'build', 'linux', '--release'], cwd=tree, check=True, stdout=subprocess.DEVNULL)
    return os.path.join(tree, 'build/linux/x64/release/bundle')


def worktree(commit):
    base = os.path.join(ROOT, 'build/ab/base')
    if os.path.exists(base):
        subprocess.run(['git', 'worktree', 'remove', '--force', base], cwd=ROOT, check=False)
    subprocess.run(['git', 'worktree', 'prune'], cwd=ROOT, check=True)
    subprocess.run(['git', 'worktree', 'add', '--detach', base, commit], cwd=ROOT, check=True, stdout=subprocess.DEVNULL)
    return base


def stages(bundle, doc):
    result, samples = mapas.run(bundle, doc)
    picked = mapas.stage_samples(result, samples)
    totals = {k: (mapas.total(s, 0), mapas.total(s, 1)) for k, _, s in picked}
    # Por grupo de mapeamento (heap, fontes, .so...), em MB: [RSS, anônima].
    groups = {k: {g: [v[0] / 1024, v[1] / 1024] for g, v in s['g'].items()} for k, _, s in picked}
    return totals, result, groups


def main():
    commit = sys.argv[1]
    doc = os.path.realpath(sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, 'test/fixtures/capitulo-30p.docx'))
    rounds = int(sys.argv[3]) if len(sys.argv) > 3 else 3
    base = worktree(commit)
    print(f'== build de {commit}')
    a_bundle = build(base)
    print('== build da árvore atual')
    b_bundle = build(ROOT)
    runs = {'A': [], 'B': []}
    for i in range(rounds):
        for name, bundle in (('A', a_bundle), ('B', b_bundle)):
            print(f'== rodada {i + 1}, {name}')
            runs[name].append(stages(bundle, doc))
    print(f'\n{"etapa":28s} {"anônima A":>10s} {"anônima B":>10s} {"Δ":>7s}   {"RSS A":>7s} {"RSS B":>7s} {"Δ":>7s}')
    summary = {}
    for key in mapas.STAGES:
        def med(name, i):
            vals = [r[0][key][i] for r in runs[name] if key in r[0]]
            return statistics.median(vals) if vals else float('nan')
        a_anon, b_anon, a_rss, b_rss = med('A', 1), med('B', 1), med('A', 0), med('B', 0)
        summary[key] = {'anonima': [a_anon, b_anon], 'rss': [a_rss, b_rss]}
        print(f'{key:28s} {a_anon:10.1f} {b_anon:10.1f} {b_anon - a_anon:+7.1f}   {a_rss:7.1f} {b_rss:7.1f} {b_rss - a_rss:+7.1f}')
    def metric(r, path):
        for part in path.split('.'):
            r = r.get(part) if isinstance(r, dict) else None
        return r
    for path in ('abrir_ms', 'rolar.fps_medio', 'latencia_tecla_ladrilho.p95_ms'):
        vals = {n: [v for v in (metric(r[1], path) for r in runs[n]) if v is not None] for n in runs}
        if all(vals.values()):  # noqa
            print(f'{path:28s} {statistics.median(vals["A"]):10.1f} {statistics.median(vals["B"]):10.1f}')
    # Onde está a diferença: os grupos que mudaram em cada etapa com o capítulo.
    for key, label in (('rss_30p_mb', 'com o capítulo'), ('rss_depois_de_rolar_mb', 'depois de rolar'),
                       ('rss_depois_de_digitar_mb', 'depois de digitar')):
        names = sorted({g for n in runs for r in runs[n] if key in r[2] for g in r[2][key]})
        print(f'\n{label + ", por grupo":30s}{"RSS A":>7s} {"RSS B":>7s} {"Δ":>6s}   {"anôn A":>7s} {"anôn B":>7s} {"Δ":>6s}')
        for g in names:
            def gmed(n, i):
                vals = [r[2][key].get(g, [0, 0])[i] for r in runs[n] if key in r[2]]
                return statistics.median(vals) if vals else 0
            ra, rb, aa, ab_ = gmed('A', 0), gmed('B', 0), gmed('A', 1), gmed('B', 1)
            if abs(rb - ra) >= 0.5 or abs(ab_ - aa) >= 0.5:
                print(f'  {g:26s} {ra:7.1f} {rb:7.1f} {rb - ra:+6.1f}   {aa:7.1f} {ab_:7.1f} {ab_ - aa:+6.1f}')
    out = os.path.join(ROOT, 'build/medicoes')
    os.makedirs(out, exist_ok=True)
    json.dump({'base': commit, 'resumo': summary, 'rodadas': {n: [r[1] for r in v] for n, v in runs.items()}},
              open(os.path.join(out, 'ab.json'), 'w'), indent=2)
    subprocess.run(['git', 'worktree', 'remove', '--force', base], cwd=ROOT, check=False)


if __name__ == '__main__':
    main()
