#!/usr/bin/env python3
# Precisa do potracer, do numpy e do Pillow (pip install potracer numpy pillow, num venv).
# Uso: tool/vectorize_icon.py assets/icon/icon-source.jpg icon.svg
"""Vetoriza o ícone do Quill: classifica cada pixel numa das quatro cores e traça
cada camada com o potrace. Uso: vectorize.py <fonte.jpg> <saida.svg>"""
import sys
import numpy as np
import potrace
from PIL import Image, ImageFilter

src, out = sys.argv[1], sys.argv[2]
im = np.asarray(Image.open(src).convert('RGB')).astype(int)
H, W, _ = im.shape
palette = {
    'navy': (41, 70, 111),
    'cream': (244, 242, 230),
    'blue': (204, 225, 253),
    'line': (222, 220, 206),
    'white': (255, 255, 255),
}
names = list(palette)
cols = np.array([palette[n] for n in names])
d = ((im[:, :, None, :] - cols[None, None]) ** 2).sum(-1)
label = d.argmin(-1)

def mask(*ns):
    m = np.isin(label, [names.index(n) for n in ns])
    # Suaviza o serrilhado do JPEG antes de traçar
    img = Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.MedianFilter(5))
    return np.asarray(img) > 127

def trace(m):
    bm = potrace.Bitmap(~m)
    plist = bm.trace(turdsize=30, alphamax=1.0, opticurve=True, opttolerance=0.3)
    parts = []
    for curve in plist:
        s = curve.start_point
        parts.append(f'M{s.x:.1f} {s.y:.1f}')
        for seg in curve.segments:
            if seg.is_corner:
                parts.append(f'L{seg.c.x:.1f} {seg.c.y:.1f}L{seg.end_point.x:.1f} {seg.end_point.y:.1f}')
            else:
                parts.append(f'C{seg.c1.x:.1f} {seg.c1.y:.1f} {seg.c2.x:.1f} {seg.c2.y:.1f} {seg.end_point.x:.1f} {seg.end_point.y:.1f}')
        parts.append('Z')
    return ''.join(parts)

# A camada clara inclui o azul e as linhas (eles ficam por cima), para não abrir frestas.
light = trace(mask('cream', 'blue', 'line'))
blue = trace(mask('blue'))
line = trace(mask('line'))
hexc = lambda c: '#%02X%02X%02X' % c
svg = f'''<!-- O ícone do Psito Quill, vetorizado de assets/icon/icon-source.jpg (gerado no Gemini) -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">
<rect x="4" y="4" width="{W-8}" height="{H-8}" rx="200" fill="{hexc(palette['navy'])}"/>
<path fill="{hexc(palette['cream'])}" fill-rule="evenodd" d="{light}"/>
<path fill="{hexc(palette['blue'])}" fill-rule="evenodd" d="{blue}"/>
<path fill="{hexc(palette['line'])}" fill-rule="evenodd" d="{line}"/>
</svg>
'''
open(out, 'w').write(svg)
print(len(svg), 'bytes')
