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

## A medida (23/11/2026)

`tool/ab.py 6370706` (A, a Etapa 7) contra o `595937f` (B, esta), mediana de 3, no mesmo dia:

| etapa do bench | anônima A | anônima B | Δ | RSS A | RSS B | Δ |
|---|---|---|---|---|---|---|
| motor ligado | 111,0 | 112,0 | +1,0 | 264,0 | 266,1 | +2,1 |
| vazio | 177,0 | 178,8 | +1,9 | 372,5 | 375,9 | +3,4 |
| com o capítulo | 244,7 | 240,5 | −4,1 | 446,7 | 449,1 | +2,5 |
| depois de rolar | 245,0 | 237,2 | −7,8 | 452,1 | 445,7 | −6,3 |
| depois de digitar | 252,0 | 255,6 | +3,5 | 460,0 | 465,2 | +5,2 |

- Rolar 59,5 fps nas duas; tecla → ladrilho p95 9,1 e 9,2 ms.
- **Abrir:** 693 ms (A) e 849 ms (B). Conferido à parte: o `lok_probe` (o motor sozinho) abre o capítulo em ~635 ms com e sem o callback do escritório (3 rodadas de cada). E o mesmo commit `6370706` deu 816 ms na medida da Etapa 7 e 693 ms nesta. O abrir do app varia uns 120 ms entre medidas neste host; a diferença não é do callback.
- A memória ficou dentro do ruído: nada novo fica guardado (o progresso é um número; o véu só existe enquanto está ocupado).
