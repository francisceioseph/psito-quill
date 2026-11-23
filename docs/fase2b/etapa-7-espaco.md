# Etapa 7: a interface que respira

**Estado:** planejada em 23/11/2026, a partir do retorno do Francisco depois de testar o app: "os comandos estão meio que abarrotados, muito densos, mal distribuídos na tela de início, não aproveitam os vários tamanhos de tela, difíceis de ver, clicar e usar"; "aproveita mal o espaço no modo maximizado"; "os menus parecem pobres". A referência que ele mandou é o OnlyOffice (20 capturas). Seguimos os padrões de layout dele, não a cara. A decisão é o D-049.

## O diagnóstico

| O que ele viu | A causa no código | O que o OnlyOffice faz |
|---|---|---|
| Comandos densos e pequenos | `QuillDensity.compact`: botões de 32 px, ícones de 20, texto de 13 px; grupos em duas fileiras de ícones sem nome | Botões grandes com o nome embaixo (ícone ~28 px); texto da interface ~15 px; abas ~17 px |
| Mal distribuídos no Início | A faixa é uma `Row` numa rolagem horizontal com `IntrinsicHeight`: os grupos ficam encostados à esquerda e o resto da largura fica vazio | Os grupos têm larguras diferentes e se espalham; a Área de transferência fica fixa à esquerda em 2×2 |
| Não aproveita as telas | Não há tamanhos por largura: a mesma faixa em 1024 e em 2560 px (em 1024 ela rola de lado) | A faixa troca botões grandes por pequenos quando falta espaço |
| Difíceis de clicar | Alvos de 32 px colados (espaço de 4 px) | Alvos de ~40 px, espaçados |
| Menus pobres | O menu de contexto é o do motor (D-033), só com o que o LOK manda | Menu próprio com ícones, atalhos, separadores e submenus (Formatar como estilo › Criar novo / Atualizar), e itens de parágrafo (Quebra de página antes, Manter as linhas juntas) |
| Espaço mal aproveitado maximizado | Painéis estreitos e a barra de status baixa (26 px) | Trilhos dos dois lados (esquerda: localizar, comentários, títulos; direita: parágrafo, tabela, imagem, forma), painéis com linhas de 44 px, barra de status com página, palavras, idioma, modos e zoom |

Outros padrões das capturas que entram:
- **O Arquivo como bastidores:** uma lista grande à esquerda (Criar novo, Abrir, Abrir recente, Salvar, Salvar como, Imprimir, Proteger, Informações, Abrir local do arquivo, Fechar, Configurações avançadas, Ajuda), e o conteúdo à direita. "Informações" tem as estatísticas e as propriedades; "Configurações avançadas" é um formulário por seções com Aplicar.
- **A tela inicial:** cartões grandes para criar, a recuperação de arquivos e os recentes numa tabela (nome, pasta, última abertura).
- **A aba Ver:** caixas para mostrar a barra de status, os painéis e as réguas; Ajustar à página, Ajustar à largura e Ampliar para 100 %.
- **O seletor Editando / Revisão / Visualizando:** um menu com título e descrição em cada item. O Quill usa o mesmo formato nos menus que escolhem um modo.

Ficam de fora (não são deste editor ou já têm lugar): plug-ins (Fase 5), colaboração, proteção com senha, assinatura, macros e modelos de terceiros.

## O que entra

O resumo está no `docs/PLANO.md` (Fase 2B, Etapa 7). A ordem de trabalho:

1. **Escala e densidade** (`tokens.dart`): o texto da interface vai a 14 px, as abas a 15 e o título a 16. Os controles ficam com 36 px e os ícones com 22; a barra de status, com 32. A confortável continua em 44.
2. **A faixa adaptável** (`ribbon.dart`, `ribbon_group.dart`): um `RibbonGroupSpec` com os quatro tamanhos e a prioridade, e o `AdaptiveRibbon`, que mede e escolhe sem rolar. A galeria de estilos ocupa a sobra.
3. **O Início redistribuído e o acesso rápido** à esquerda das abas.
4. **O menu de contexto próprio**, com sondas para os comandos de parágrafo (`.uno:ParaKeepTogether` ou parecido, pelo `lok_script`).
5. **Os trilhos e os painéis:** o trilho direito do Formatar, os campos com rótulo em cima e o Localizar com a lista.
6. **A barra de status** maior e clicável.
7. **Os bastidores do Arquivo e a tela inicial.**
8. **A aba Exibir** com as caixas e os ajustes de zoom.
9. **As abas de documentos, todas carregadas** (D-051, D-053, D-054): a sonda de dois documentos no motor (feita); o kit com vários documentos e um ativo; as abas acima da faixa; a troca com a posição guardada; os fluxos de arquivo pelas abas; o limite de abas carregadas.

Cada passo fecha com `flutter analyze`, os testes de widget nos quatro tamanhos (1024×768, 1366×768, 1920×1080 e 2560×1440) e, no fim da etapa, a medida A/B.

## A regra da memória aqui

- A faixa adaptável mede com um `LayoutBuilder` só, e calcula os tamanhos a partir de larguras fixas de cada tamanho, sem `IntrinsicWidth` nem layout duplo. Só refaz quando a largura cruza um limiar.
- O menu de contexto é construído ao abrir e descartado ao fechar.
- Os bastidores constroem só a seção aberta, como o painel Formatar (D-038).

## Feito até aqui (passos 1 a 3)

| O quê | Onde |
|---|---|
| Texto da interface 14 px, abas 15, controles 36 px, ícones 22, barra de status 32 | `QuillFont`, `QuillDensity` (`tokens.dart`); o Clássico 97 fica com os tamanhos dele |
| Itens de menu com a altura de um controle e margens | `menuButtonTheme` e `menuTheme` no `toThemeData` |
| A faixa adaptável: tamanhos por grupo, prioridade, grupo elástico | `AdaptiveRibbon`, `RibbonGroupSpec`, `RibbonLevel`, `chooseRibbonLevels` (`lib/src/ui/molecules/adaptive_ribbon.dart`) |
| O nome de cada grupo nunca é cortado: medido uma vez por nome | `ribbonTitleWidth` (um mapa pequeno, um `TextPainter` descartado na hora) |
| O Início em grupos com tamanhos: Área de transferência, Fonte, Parágrafo, Estilos (elástico), Edição | `_HomeTab` (`ribbon.dart`) |
| A galeria mostra quantos cartões couberem; sem espaço, os mais usados num livro e o atual | `StyleGallery(width:)` |
| Menus de comandos ricos: ícone, nome, atalho à direita, marca de ligado, separadores | `commandMenuItems`, `CommandMenuButton` (`lib/src/ui/molecules/command_menu.dart`) |
| Botão grande de largura fixa, com o nome em até duas linhas e a setinha de menu | `WBigButton(width:, dropdown:)` |
| Acesso rápido (salvar, desfazer, refazer) à esquerda do Arquivo | `Ribbon` |
| Abaixo de 1600 px, a pesquisa e o Recolher viram ícones; abaixo de 1500, o zoom perde o controle deslizante | `Ribbon`, `ZoomControl` (a largura vem da barra de status, por um `InheritedWidget`) |

Os tamanhos do Início, do maior ao menor:

| Grupo | Prioridade | Grande | Menor |
|---|---|---|---|
| Área de transferência | 1 (encolhe primeiro) | Colar grande, Recortar e Copiar | só o Colar |
| Edição | 2 | Localizar e Substituir grandes | os dois em ícones |
| Parágrafo | 3 | as duas linhas de ícones | um botão "Parágrafo" que abre tudo num menu |
| Fonte | 9 | a fonte larga e 9 efeitos | a fonte mais estreita, e sobrescrito, subscrito e limpar no "mais" |
| Estilos | elástico | o que sobrar | 3 cartões |

**Os testes:** `test/widget/fase2b_space_test.dart`, com a escolha dos tamanhos e o Início em 1024×768, 1366×768, 1920×1080 e 2560×1440 (nada vaza; a partir de 1280 nada rola de lado; mais estilos na tela larga). A suíte inteira passa (309 testes).

**A medida dos passos 1 a 3** (com o zen, contra a Fase 2): +1,5 MB de anônima com o capítulo, dentro do orçamento, mas **+9,4 MB depois de digitar** (nas Etapas 3 a 5 era +1,7 a +3,9). A integração passou. **A investigação (D-052):** era ruído do coletor do Dart. Três A/B com o mesmo código deram +9,4, −1,2 e +5,6 MB depois de digitar, tudo no grupo `anon`, e o `heap` ficou estável em +2 MB. No caminho apareceu um desperdício: a página e as palavras refaziam a faixa a cada página rolada e a cada tecla. Agora elas sobem só a `statusRevision`, que refaz a barra de status e a Estrutura.

| Com a correção, contra a Fase 2 | Anônima Δ | RSS Δ |
|---|---|---|
| Motor ligado | +2,8 | +6,2 |
| Vazio | −0,8 | +6,1 |
| Com o capítulo | +3,3 | +9,8 |
| Depois de rolar | +1,0 | +7,8 |
| Depois de digitar | +5,6 | +11,9 |

Rolar 59,5 fps; tecla → ladrilho p95 9,4 ms; abrir 277 ms. O `tool/ab.py` agora mostra os grupos também depois de rolar e de digitar.

## A busca única (D-050)

O Francisco achou confusas as duas buscas com a mesma lupa e escolheu uma só.

| O quê | Onde |
|---|---|
| A busca no texto da cópia: a página, o trecho e a expressão que seleciona só a ocorrência | `searchFodtText`, `TextHit`, `TextSearchResult` (`lib/src/document/fodt.dart`) |
| A cópia da busca: feita na primeira busca e apagada ao fechar; a leitura num isolate | `DocumentController.searchText`, `endTextSearch`, `goToHit` |
| O campo e as duas seções, com as setas, o Enter e "com opções" | `CommandPalette`, `showCommandPalette` (`lib/src/ui/organisms/command_palette.dart`) |
| Ctrl+F/L e o botão Localizar abrem a busca; o painel fica no Ctrl+H/U e no trilho "Localizar e substituir" | `commands_view.dart`, `EditorPage.openPalette` |

**Os testes:**
- `test/unit/text_search_test.dart`: a página, o contexto, o limite e a expressão escapada;
- `test/widget/fase2b_search_test.dart`: Ctrl+L, as duas seções, o clique numa ocorrência, a cópia apagada ao fechar, um comando pelo Enter e o "com opções";
- `integration_test`, passo 2e: o salto a uma ocorrência da página 5 ou mais, no LibreOffice de verdade.

## A sonda das abas (passo 9, D-053)

O `lok_two_docs` (`packages/psito_quill_kit/linux/tools/`, no `build/native`) abre duas cópias do capítulo de 30 páginas no mesmo processo do LibreOffice 24.2, pinta as duas inteiras, digita uma marca em cada uma e salva as duas como `.odt`. Depois fecha e reabre 6 vezes, como a troca de aba das abas leves, e por fim abre 6 capítulos ao mesmo tempo. Não abre janela. Duas rodadas, com os mesmos números:

| Passo | Anônima (MB) |
|---|---|
| Motor ligado | 28,5 |
| O primeiro capítulo aberto e pintado | 142,7 (+114: o Writer inteiro sobe com ele) |
| O segundo capítulo, com o primeiro aberto | 146,6 (**+3,9**) |
| Depois de salvar os dois como `.odt` (o filtro de exportação, uma vez) | 174,0 (+27) |
| 6 trocas (fechar e reabrir) | +3 nas três primeiras, depois parado |
| 6 capítulos abertos ao mesmo tempo, depois das trocas | +0,7 (o malloc reaproveita o que os fechados deixaram) |

**O que funcionou:**
- Os dois documentos vivem juntos sem `setView`. O texto digitado em cada um ficou só nele (conferido no `content.xml` salvo), e os callbacks de cada um chegaram só ao dele.
- O ladrilho do primeiro continuou certo depois de abrir o segundo.
- Fechar um não estragou o outro: deu para digitar e salvar de novo.
- Reabrir o capítulo leva ~90 ms no motor (o `abrir_ms` do app, com tudo, é ~300 ms).

**O que isso muda:** o D-051 supôs ~50 MB por capítulo aberto (a diferença entre o vazio e o capítulo no bench), mas quase tudo aquilo é o Writer subindo uma vez. Um capítulo só de texto custa ~4 MB a mais no motor. Capítulos com imagens custam mais (o LibreOffice guarda as imagens decodificadas), e isso não foi medido.

## A galeria que desce (D-055)

O ▾ ao lado dos cartões de estilo do Início desce a galeria inteira, com as prévias e a busca, por cima da galeria da faixa. Escolher aplica e fecha. "Gerenciar estilos…" ganhou um botão com nome na aba Estilos.

## O rodapé office e os painéis equilibrados (D-057, D-058)

- **O rodapé (`StatusBar`):**
  - **Telas pequenas (< 1050 px):** o controle deslizante de zoom recolhe para o modo compacto `[-] 100% [+]`, e campos secundários (estilo, modificado) são omitidos progressivamente abaixo de 980 e 750 px para garantir que os essenciais (página e contagem de palavras) não sejam espremidos nem causem overflow.
  - **Telas maximizadas (1366 px, 1920 px, 2560 px):** o controle deslizante de zoom fica sempre visível e funcional com transição suave.
  - **Campos clicáveis:** os itens do rodapé agora têm reação ao passar o mouse (`surfaceHigh`); clicar em "Página X de Y" abre o painel Estrutura para navegação, e clicar no nome do estilo abre o painel Estilos.
  - Borda sutil de 1 px superior emoldurando a divisão entre a folha e a barra de status.
- **Os painéis laterais (`SidePanel`):**
  - Margens horizontais equilibradas (16 px dos dois lados) e divisória na borda interna contra a área da página.
  - Painéis Estrutura e Estilos com 280 px de largura (espaço ideal para títulos e botões de ação longos sem corte).
  - `WSegmented` com modo `expanded: true` no topo do Formatar, preenchendo toda a largura de forma simétrica.
  - `WDropdown` de estilo no Formatar ajustado para preencher a largura total, alinhando com os botões `PanelAction`.
- **Os testes:** `test/widget/fase2b_space_test.dart` e `test/widget/fase2b_panels_test.dart` cobrem todas as resoluções de tela e o comportamento dos painéis.

## O menu de contexto (passo 4, D-061)

- `lib/src/ui/organisms/engine_context_menu.dart`: o `contextEntries` (puro, testado) monta a lista; o `contextMenuChildren` desenha com os menus de comandos; o `showEngineContextMenu` abre um `MenuAnchor` numa camada do `Overlay` e a tira depois que o menu fecha.
- Os comandos novos: `paragrafo.manterComProximo`, `paragrafo.separarDoProximo`, `paragrafo.manterLinhas` e `paragrafo.dividirLinhas` (`DocumentController.setKeepWithNext` e `setKeepLinesTogether`).
- As sondas: o `ParaKeepTogether` e o `ParaSplit` com valor funcionam (conferido no XML salvo); sem valor, nada; o estado não vem. O `ParaWidows` e o `PageBreak` não fizeram nada.
- Testes: `fase2_controller_test` (a ordem e os submenus) e `fase2_test` (clique direito › Parágrafo › os dois comandos, com os argumentos).
- **Para olhar à mão:** o menu abre no ponto do clique, os submenus abrem para o lado sem sair da tela, e Esc fecha e devolve o cursor ao texto.

## Os trilhos e os painéis (passo 5, D-062)

- **O trilho da direita:** um `NavRail<InspectorPart>` no novo lugar `rightRail` do `EditorTemplate` (`editor_page.dart`), com `inspectorPartIcon`, `inspectorPartLabel` e `shownInspectorPart` em `inspector.dart`. O `Inspector(sectionsInRail:)` esconde o seletor.
- **Os rótulos em cima:** o `LabeledRow` (`inspector_section.dart`) e o `MeasureField(caption:)` (`measure_field.dart`).
- **O Localizar com a lista:** o `lib/src/ui/organisms/find_panel.dart` substitui o `find_bar.dart`, e o `DocumentController.searchText(fresh:)` renova a cópia.
- **Testes:**
  - `fase2b_shell_test`: o trilho abre e fecha o painel, os rótulos curtos e os nomes para o leitor de tela;
  - `fase2b_search_test`: a lista, o clique e a cópia refeita só depois de mudar o texto;
  - `fase2_test`: o Ctrl+U e o substituir pelo painel novo.
- **Para olhar à mão:** os dois trilhos em 1366 px com os dois painéis abertos (a página fica com ~600 px); a lista num capítulo longo; o painel Localizar no Clássico 97.

