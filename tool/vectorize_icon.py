#!/usr/bin/env python3
# Precisa do potracer, do numpy e do Pillow (pip install potracer numpy pillow, num venv).
# Uso: tool/vectorize_icon.py assets/icon/icon-source.jpg icon.svg
"""Vetoriza o ícone do Quill (D-077). A fonte é um quadrado arredondado azul-marinho
com borda escura, sobre fundo branco, com um livro aberto creme e uma pena
azul-clara. O quadrado vira dois retângulos arredondados (a borda e o fundo),
medidos na imagem; o creme e o azul são classificados por cor e traçados com o
potrace. O branco de fora sai (o ícone fica transparente em volta).
Uso: vectorize_icon.py <fonte.jpg> <saida.svg>"""
import sys

import numpy as np
import potrace
from PIL import Image, ImageFilter

src, out = sys.argv[1], sys.argv[2]
full = np.asarray(Image.open(src).convert('RGB')).astype(int)

# O quadrado: tudo o que não é branco.
ys, xs = np.where(full.sum(-1) < 600)
x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
im = full[y0:y1, x0:x1]
H, W, _ = im.shape

palette = {
    'border': (28, 51, 82),
    'navy': (41, 69, 106),
    'cream': (242, 240, 228),
    'blue': (204, 222, 251),
    'white': (255, 255, 255),
}
names = list(palette)
cols = np.array([palette[n] for n in names])
label = ((im[:, :, None, :] - cols[None, None]) ** 2).sum(-1).argmin(-1)


def mask(*ns):
    m = np.isin(label, [names.index(n) for n in ns])
    # Suaviza o serrilhado do JPEG antes de traçar.
    img = Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.MedianFilter(5))
    return np.asarray(img) > 127


def trace(m):
    plist = potrace.Bitmap(~m).trace(turdsize=30, alphamax=1.0, opticurve=True, opttolerance=0.3)
    parts = []
    for curve in plist:
        s = curve.start_point
        parts.append(f'M{s.x:.1f} {s.y:.1f}')
        for seg in curve.segments:
            if seg.is_corner:
                parts.append(f'L{seg.c.x:.1f} {seg.c.y:.1f}L{seg.end_point.x:.1f} {seg.end_point.y:.1f}')
            else:
                parts.append(f'C{seg.c1.x:.1f} {seg.c1.y:.1f} {seg.c2.x:.1f} {seg.c2.y:.1f} '
                             f'{seg.end_point.x:.1f} {seg.end_point.y:.1f}')
        parts.append('Z')
    return ''.join(parts)


# A espessura da borda: do lado esquerdo, no meio da altura, até o azul-marinho.
# Os primeiros pixels são o serrilhado da beira (cinza, mais perto do azul).
row = label[H // 2]
border = 4 + int(np.argmax(row[4:] == names.index('navy')))
# O raio do canto: na linha do raio aproximado, onde o quadrado começa.
radius = round(0.205 * min(W, H))

# A camada clara inclui o azul (ele fica por cima), para não abrir frestas.
light = trace(mask('cream', 'blue'))
blue = trace(mask('blue'))
# Quadrado: o ícone não sai achatado nos PNGs.
S = max(W, H)
hexc = lambda c: '#%02X%02X%02X' % c  # noqa: E731
svg = f'''<!-- O ícone do Psito Quill, vetorizado de assets/icon/icon-source.jpg (tool/vectorize_icon.py) -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {S} {S}"><g transform="translate({(S - W) / 2:g} {(S - H) / 2:g})">
<rect width="{W}" height="{H}" rx="{radius}" fill="{hexc(palette['border'])}"/>
<rect x="{border}" y="{border}" width="{W - 2 * border}" height="{H - 2 * border}" rx="{radius - border}" fill="{hexc(palette['navy'])}"/>
<path fill="{hexc(palette['cream'])}" fill-rule="evenodd" d="{light}"/>
<path fill="{hexc(palette['blue'])}" fill-rule="evenodd" d="{blue}"/>
</g></svg>
'''
open(out, 'w').write(svg)
print(W, 'x', H, 'borda', border, 'raio', radius, '|', len(svg), 'bytes')
