# Etapa 2: a casca do editor

**Objetivo:** a disposição da tela do desenho "Main": a fileira de abas, a faixa num cartão, o trilho e os painéis da esquerda, o painel Formatar com uma seção de cada vez e a barra de status com o zoom. A decisão é o D-043.

## O que entrou

| O quê | Onde |
|---|---|
| A fileira de abas, a faixa em cartão, a aba Estilos, o Recolher, a pesquisa | `lib/src/ui/organisms/ribbon.dart` |
| O grupo da faixa em duas linhas, com o nome e a divisória | `lib/src/ui/molecules/ribbon_group.dart` |
| O botão grande (Colar, Inserir) e os tons do botão (preenchido, de contexto) | `lib/src/ui/atoms/w_button.dart` (`WBigButton`, `WTone`) |
| A cor da fonte e o realce em menus de amostras | `lib/src/ui/molecules/color_menu_button.dart` |
| Os cartões de estilo | `lib/src/ui/molecules/style_card.dart` |
| O trilho | `lib/src/ui/organisms/nav_rail.dart` |
| O painel genérico (título, fechar, conteúdo) | `lib/src/ui/molecules/side_panel.dart` |
| Os painéis Estrutura e Estilos | `lib/src/ui/organisms/outline_panel.dart`, `styles_panel.dart`; o modelo em `lib/src/document/outline.dart` |
| O painel Formatar em seções | `lib/src/ui/organisms/inspector.dart` (`InspectorPart`) |
| A barra de status, o zoom e o RSS | `lib/src/ui/organisms/status_bar.dart` (`ZoomControl`, `MemoryLabel`) |
| Os lugares do trilho, do painel da esquerda e da régua | `lib/src/ui/templates/editor_template.dart` |
| Os comandos novos (Estrutura, Estilos, Recolher a faixa) | `lib/src/commands/commands_view.dart`, também no menu Exibir do Clássico 97 |
| O tamanho da imagem em cm pelas alças | `DocumentController.setGraphicSizeCm`; `ImageSizeGroup` na faixa |
| A preferência da faixa recolhida | `Settings.ribbonCollapsed` (`faixaRecolhida`) |

## Como funciona

**Memória e reconstruções.** A página do editor se refaz a cada evento do motor que muda estado. A faixa, o painel Formatar, o trilho, o painel da esquerda e a barra de status são memoizados por uma chave só: a `stateRevision` do controlador (que não sobe com ladrilho, cursor ou seleção) e o estado da página (aba, painéis, seção). Rolar e mover o cursor não refazem nenhum deles. O zoom, ao arrastar, muda só o número do `ZoomControl` (estado local); o motor recebe o zoom ao soltar. O RSS da barra de status lê o processo a cada 2 s, e só o rótulo se refaz.

**O painel Formatar** recebe a seção escolhida (`InspectorPart`) e constrói só ela. Imagem e Tabela aparecem no seletor com a seleção; se a seleção sai, a seção volta para Texto.

**O trilho** abre um painel de cada vez. Localizar não é um painel: abre e fecha a barra de localizar que já existia.

**O tamanho da imagem.** O motor não aceita o tamanho por comando (sondado, D-043). O controlador manda o arrasto de uma alça: a do canto, que sempre mantém a proporção, ou a da direita e depois a de baixo. O segundo arrasto espera o retângulo novo do motor (`_pendingGraphicHeight`).

## O que os testes conferem

- `test/widget/fase2b_shell_test.dart`: os cartões de estilo marcam o aplicado; Ctrl+F1 recolhe e guarda, e clicar numa aba mostra de novo; a pesquisa abre a paleta; numa janela de 900 px nada estoura e a pesquisa vira ícone; o trilho abre Estrutura e Estilos (e o estilo da lista aplica); Localizar pelo trilho; o painel Formatar constrói só a seção escolhida e fecha pelo botão com o atalho na dica; as seções de contexto; Aumentar e Diminuir a fonte; a cor da fonte pelo menu; o zoom só vai ao motor ao soltar; nenhum tema estoura.
- `test/unit/fase2_controller_test.dart` (grupo "tamanho da imagem"): as alças e os pontos de cada caso.
- `integration_test/engine_test.dart`, passo 18b: no LibreOffice de verdade, 2 cm com a proporção e 3 × 1 cm sem.
- Os testes antigos da faixa e do painel foram atualizados para os widgets novos.

## Para o Francisco conferir

- A fileira de abas nos três temas; o Arquivo preenchido; as abas Tabela e Imagem na cor de contexto, com a faixa com a borda de cima dessa cor.
- O trilho: abrir e fechar cada painel; o painel Estilos aplica.
- O zoom pelo controle deslizante (o número muda arrastando; a página, ao soltar).
- A aba Imagem: largura e altura com e sem o cadeado.

## Resultado

`tool/ab.py ac8a2d6` (contra a Fase 2; as Etapas 0 e 1 mediram ≈0), 23/11/2026, mediana de 3 (MB):

| Etapa do bench | Anônima Fase 2 | Anônima Etapa 2 | Δ | RSS Fase 2 | RSS Etapa 2 |
|---|---|---|---|---|---|
| Motor ligado | 108,3 | 109,3 | +1,1 | 258,9 | 262,9 |
| Vazio | 180,5 | 175,9 | −4,6 | 368,7 | 366,4 |
| Capítulo de 30 páginas | 227,0 | 230,9 | **+3,9** | 427,4 | 433,1 |
| Depois de digitar | 245,8 | 248,4 | +2,6 | 447,4 | 452,4 |

Abrir: 467 → 330 ms (a primeira rodada da Fase 2 foi lenta; a mediana das outras é parecida). Rolar: 59,7 → 59,6 fps. Tecla → ladrilho p95: 9,2 → 9,3 ms.

**Dentro do orçamento de 5 MB, mas não é zero.** A casca tem mais coisa na tela (o trilho, os cartões de estilo, o zoom), e o painel Formatar, que agora constrói uma seção só, economiza parte disso. `./test.sh --integracao` verde, com o passo novo do tamanho da imagem no LibreOffice de verdade.
