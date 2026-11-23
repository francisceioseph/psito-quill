# Etapa 6: o modo zen

**Objetivo:** escrever sem nada em volta: tela cheia, só a página, num papel calmo. A decisão é o D-048.

## O que entrou

| O quê | Onde |
|---|---|
| Tela cheia de verdade (`gtk_window_fullscreen`) | `pqk_set_fullscreen` (`quill_kit_api.h`, o plugin), `AppWindow.setFullscreen` |
| Entrar e sair: F11, e Esc enquanto o zen está aberto | `ViewCommandIds.zen`, `EditorPage.toggleZen` e `_zenEscape` (um tratador do `HardwareKeyboard` que só existe no zen) |
| Só a página: sem faixa, painéis, régua nem barra de status | `EditorPage._zenView`, `ZenView` (`lib/src/ui/organisms/zen_view.dart`) |
| O tema Sépia (papel creme, tinta marrom), também nos temas da interface | `themes/sepia.dart`, o esquema `PsitoQuillSepia` no perfil (gerado pelos tokens, como os outros) |
| O papel do zen: Sépia, Claro ou Escuro | `Settings.zenPaper`; o tema do app usa ele enquanto o zen está aberto |
| Máquina de escrever: a linha do cursor no meio | `DocumentView(typewriter:)`, `_centerCaret` (só a rolagem do Flutter) |
| Foco: escurece o que está a mais de 2 linhas do cursor | `DocumentView(focusLines:)`, dois retângulos por cima da página |
| A barrinha de opções, que some depois de 2 s parado | `ZenView`: um `Timer` e um `ValueNotifier`; só a barrinha se refaz |
| As palavras e o tempo da sessão | `ZenView`: um `Timer.periodic` de 1 minuto; só o rótulo se refaz |

## Como funciona

**O Esc.** O Esc já tem dono no editor (fechar a busca, tirar a seleção). Enquanto o zen está aberto, um tratador do `HardwareKeyboard` vem antes e só pega o Esc. Ele é tirado ao sair, então fora do zen o Esc continua como era.

**O foco por faixa de linhas.** O plano pedia o retângulo do parágrafo pelos callbacks de acessibilidade (62). Ligar a acessibilidade do motor custa memória e trabalho a cada tecla, por isso fica para a Etapa 9, que vai ligá-la só para quem usa leitor de tela. No lugar dela, entrou a alternativa do plano: uma faixa de 2 linhas acima e abaixo do cursor, calculada pela altura do cursor, sem tocar no motor.

## O que os testes conferem

- `test/widget/fase2b_zen_test.dart`: o F11 tira a faixa e a barra de status e pede a tela cheia; o Esc sai e devolve a faixa; a barrinha liga e desliga o foco e a máquina de escrever e troca o papel.
- `test/unit/` (tokens): o Sépia passa nas conferências de contraste como os outros temas.
- A tela cheia nativa não tem teste automático (o `integration_test` não confere o gerenciador de janelas).

## A medida

Medida junto com os passos 1 a 3 da Etapa 7 (a medida só do zen se perdeu na troca), contra a Fase 2 (`ac8a2d6`), em 23/11, com o `tool/ab.py` (mediana de 3, em MB):

| Etapa do bench | Anônima A | Anônima B | Δ | RSS Δ |
|---|---|---|---|---|
| Motor ligado | 108,1 | 111,3 | +3,3 | +6,3 |
| Vazio | 183,7 | 180,3 | −3,4 | +6,9 |
| Com o capítulo | 229,2 | 230,7 | +1,5 | +8,3 |
| Depois de digitar | 245,7 | 255,1 | **+9,4** | +19,2 |

Rolar a 59,5 fps; tecla → ladrilho p95 9,5 ms; abrir 287 ms. O zen não roda no bench (ele começa fora do zen), então o que ele custa fechado é só o código. O +9,4 depois de digitar passa do orçamento e está sendo investigado na Etapa 7 (ver o `etapa-7-espaco.md`).

## Para o Francisco conferir

- F11 com um capítulo aberto: a janela ocupa a tela toda, inclusive o painel do sistema, e o papel fica Sépia.
- A barrinha some depois de 2 s parado e volta ao mexer o mouse.
- Digitando no meio do capítulo, a linha fica no meio da tela (máquina de escrever), e o resto fica esmaecido (foco).
- Esc e F11 saem e devolvem a janela ao tamanho de antes.
