# Etapa 8: ocupado sem janelas

**Estado:** feita (D-066).

## O que entrou

- **O progresso do motor:** o kit registra o callback do escritório (`packages/psito_quill_kit/linux/core/lok_engine.cc`, `officeCallback`) e passa os callbacks 9, 10 e 11. O `LokQuillKit.translate` os traduz em `ProgressStarted`, `ProgressValue` e `ProgressFinished`.
- **O ocupado:** `DocumentController.busy` (`BusyKind.opening` e `BusyKind.saving`), o `progress` e o `backgroundTask`. A guarda de 90 s no salvar (`savingTimeout`).
- **A tela:** `lib/src/ui/organisms/busy_scope.dart` no `EditorTemplate(busy:)`; as teclas param no `_onPageKey` e no `DocumentView._onKey`; o `insertText` e o `postKey` não fazem nada enquanto está ocupado.
- **O rodapé:** o `StatusProgress` (`status_bar.dart`), no lugar da mensagem.

## A sonda

| Caso | O que o motor mandou |
|---|---|
| Abrir um capítulo de 30 páginas (DOCX) | só o `FINISH` (11) |
| Abrir um documento de 391 páginas (FODT, 1,8 MB) | `START` "Carregando: ", `SET_VALUE` 0, 25, 50, 75, `FINISH`, e depois o documento aberto |
| Salvar como ODT e como DOCX | nada |

## Testes

- `test/widget/fase2b_busy_test.dart`: a tradução dos callbacks; salvar trava e destrava, sem janela, e as teclas param; o progresso de abrir com o número; o trabalho de fundo que não trava; a guarda dos 90 s.
- `integration_test/engine_test.dart`: o `FINISH` chega do motor real ao abrir, e o salvar marca e desmarca o ocupado.

## Para olhar à mão

- Abrir um documento grande (centenas de páginas): a barra no rodapé anda, o cursor do mouse é o de espera, e a página não aceita cliques.
- O véu no tema escuro e no Clássico 97.
- O Orca lê "Salvando…" ao salvar.
