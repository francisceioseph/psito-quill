# Psito Quill

Um editor de texto para escrever livros longos. O motor é o LibreOffice (pelo LibreOfficeKit do sistema), a interface é em Flutter, e os plugins são em Lua 5.4.

Em construção. A Fase 1 (o editor básico: digitar com acentos, desfazer, copiar e colar, a faixa Início, abrir e salvar ODT e DOCX, os recentes) está em `docs/FASE1-RESULTADOS.md`; a prova do motor, em `docs/FASE0-RESULTADOS.md`; o plano completo, em `docs/PLANO.md`.

## Para compilar (Ubuntu 24.04)

```bash
sudo apt install libreoffice-writer libreofficekit-dev liblua5.4-dev libgtest-dev libclang-18-dev
flutter build linux --release
build/linux/x64/release/bundle/psito-quill capitulo.docx
```

## Testes

```bash
./test.sh               # unidade, widget e nativo
./test.sh --integracao  # e com o LibreOffice real (abre uma janela)
tool/bench.sh           # as medições de memória e latência
```
