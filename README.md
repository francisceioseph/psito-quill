# Psito Quill

Um editor de texto para escrever livros longos. O motor é o LibreOffice (pelo LibreOfficeKit do sistema), a interface é em Flutter, e os plugins são em Lua 5.4.

Em construção: a Fase 0 (a prova do motor) está em `docs/FASE0-RESULTADOS.md`, e o plano completo em `docs/PLANO.md`.

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
