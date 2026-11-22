#!/usr/bin/env python3
"""Gera o DOCX de teste: um capítulo de ~30 páginas A4 com títulos e cenas.

O texto é sintético (frases montadas de pedaços), para não ter direitos de
ninguém. A conversão é do próprio LibreOffice, com um perfil temporário para
não mexer no do usuário.

Uso: tool/make_fixture.py [páginas] [saída.docx]
"""
import os
import random
import shutil
import subprocess
import sys
import tempfile

SUJEITOS = ["A caravana", "Kaelen", "O vento do leste", "A velha mecânica",
            "Ninguém na vila", "O rádio quebrado", "A poeira", "Mara",
            "O deus de silício", "A última bomba d'água"]
VERBOS = ["atravessou", "esqueceu", "guardava", "ouviu", "desenhou",
          "prometeu", "carregava", "procurava", "deixou para trás", "temia"]
OBJETOS = ["a estrada sem nome", "o mapa rasgado", "as vozes do deserto",
           "uma lata de sementes", "o sinal fraco do norte",
           "a cidade enterrada", "um pedaço de céu limpo", "a febre das máquinas",
           "o caminho de volta", "as regras antigas"]
FINAIS = ["antes do amanhecer", "sem dizer nada", "como se fosse a primeira vez",
          "enquanto o sol queimava as pedras", "e ninguém perguntou por quê",
          "com as mãos ainda tremendo", "porque não havia outra escolha",
          "debaixo da lona remendada", "até a água acabar", "no meio da tempestade"]


def frase(rng):
    return f"{rng.choice(SUJEITOS)} {rng.choice(VERBOS)} {rng.choice(OBJETOS)} {rng.choice(FINAIS)}."


def paragrafo(rng):
    return " ".join(frase(rng) for _ in range(rng.randint(4, 8)))


def html(paragrafos, seed=12):
    rng = random.Random(seed)
    out = ["<html><head><meta charset='utf-8'><title>Dustland — Capítulo 1</title></head><body>",
           "<h1>Capítulo 1 — A poeira</h1>"]
    for i in range(paragrafos):
        if i and i % 18 == 0:
            out.append(f"<h2>Cena {i // 18 + 1}</h2>")
        elif i and i % 6 == 0:
            out.append("<p align='center'>* * *</p>")
        out.append(f"<p>{paragrafo(rng)}</p>")
    out.append("</body></html>")
    return "\n".join(out)


def converter(src, fmt, outdir, profile):
    subprocess.run(["soffice", f"-env:UserInstallation=file://{profile}", "--headless",
                    "--convert-to", fmt, "--outdir", outdir, src],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def paginas(pdf):
    info = subprocess.run(["pdfinfo", pdf], capture_output=True, text=True).stdout
    for linha in info.splitlines():
        if linha.startswith("Pages:"):
            return int(linha.split()[1])
    return 0


def main():
    alvo = int(sys.argv[1]) if len(sys.argv) > 1 else 30
    saida = sys.argv[2] if len(sys.argv) > 2 else "test/fixtures/capitulo-30p.docx"
    tmp = tempfile.mkdtemp(prefix="quill-fixture-")
    profile = os.path.join(tmp, "perfil")
    try:
        n = alvo * 6
        for _ in range(8):
            src = os.path.join(tmp, "capitulo.html")
            with open(src, "w", encoding="utf-8") as f:
                f.write(html(n))
            converter(src, "docx:MS Word 2007 XML", tmp, profile)
            docx = os.path.join(tmp, "capitulo.docx")
            converter(docx, "pdf", tmp, profile)
            p = paginas(os.path.join(tmp, "capitulo.pdf"))
            print(f"{n} parágrafos → {p} páginas")
            if p == alvo:
                os.makedirs(os.path.dirname(saida) or ".", exist_ok=True)
                shutil.copy(docx, saida)
                print(f"ok: {saida}")
                return
            n = max(1, round(n * alvo / max(p, 1)) + (1 if p < alvo else -1))
        sys.exit("não chegou ao número de páginas")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    main()
