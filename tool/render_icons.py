#!/usr/bin/env python3
# Os PNGs do ícone, a partir do icon.svg, para os tamanhos fixos do hicolor.
# Precisa do cairosvg (pip install cairosvg, num venv).
# Uso: tool/render_icons.py
import cairosvg

for size in (48, 64, 128, 256, 512):
    cairosvg.svg2png(url='icon.svg', write_to=f'assets/icon/org.psito.quill-{size}.png',
                     output_width=size, output_height=size)
