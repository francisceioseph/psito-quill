# Etapa 9: acessibilidade

**Estado:** feita (D-067).

## O que entrou

| O quê | Onde |
|---|---|
| Alto contraste escuro e claro (7:1) | `lib/src/ui/tokens/themes/alto_contraste.dart`, `themes.dart` (`isHighContrast`, `themeById`), `theme_labels.dart` |
| O tamanho da interface (100 a 200 %) | `lib/src/ui/templates/ui_zoom.dart`, `app.dart` (o `builder`) |
| Botões maiores, reduzir movimento | `app.dart` (o `theme` com a densidade e o `QuillMotion.none`) |
| O cursor: espessura e piscar | `DocumentView(caretWidth:, caretBlink:)` |
| A cor da marca de ortografia | `PaperScheme.spell`, `LoProfile.ensureSettings(current:)`, `spellMarkColors`, `main.dart` |
| O documento no leitor de tela | `pqk_set_accessibility` (o kit), `A11yParagraph` e `A11yCaret`, `DocumentController.setAccessibility`, `DocumentSemantics` |
| O zoom ao abrir | `EditorPage._applyOpenZoom` |
| As Preferências por seções | `lib/src/ui/organisms/preferences_view.dart` |

As preferências novas ficam no `preferencias.json`: `escalaInterface`, `botoesMaiores`, `cursorLargura`, `cursorPisca`, `reduzirMovimento`, `corOrtografia`, `zoomAoAbrir` e `documentoLeitorTela`.

## As sondas

- **O leitor de tela:** o `lok_script` ganhou o `a11y on|off`. Com ela ligada, a cada tecla vem o callback 62 com `{"content", "position", "start", "end"}` ao mudar de parágrafo, e o 63 com `{"position"}` ao andar dentro dele. Desligada, nada.
- **A cor da ortografia:** o `lok_script` ganhou o `color <rrggbb>` e o `repaint`. A entrada `Spell` no esquema muda o ondulado, mas só ao ligar o motor.

## Testes

- `test/widget/fase2b_a11y_test.dart`: os dois temas de alto contraste; a interface a 150 % em 1366 px e a 200 % em 1920 e 2560 px, sem estouro na faixa nem no painel; os botões maiores; o cursor; reduzir movimento; o zoom ao abrir; o documento para o leitor de tela (o valor, o cursor, desligar); as Preferências › Acessibilidade.
- `test/unit/tokens_test.dart`: 7:1 nos temas de alto contraste.
- `test/unit/lo_profile_test.dart`: a entrada `Spell` e o esquema atual, sem duplicar quando o LibreOffice regrava.
- `integration_test/engine_test.dart`: com o motor real, ligar a acessibilidade traz o parágrafo, e desligar limpa.

## Para olhar à mão

- O Orca lendo o parágrafo e andando com o cursor (Preferências › Acessibilidade › Texto do documento para o leitor de tela, ou com o Orca já aberto).
- Os dois temas de alto contraste na faixa, nos menus e no papel.
- A interface a 200 % numa tela de 1920 px: a faixa encolhe os grupos, e a página continua nítida.
- A cor azul ou laranja da ortografia depois de fechar e abrir o Quill.
