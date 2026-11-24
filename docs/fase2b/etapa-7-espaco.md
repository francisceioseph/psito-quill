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

## As abas de documentos (passo 9, D-054, D-056)

- **O motor** guarda vários documentos e só um ativo (`LokEngine::Doc`); o que chega de um documento fora da tela é descartado na thread do kit. `pqk_open` abre mais um, `pqk_activate` troca, `pqk_close_document` fecha um só.
- **O Dart** continua com um `DocumentController` só, a fachada do documento da tela. O estado de cada aba fica num `DocTab`, copiado de e para o controlador na troca. Até o motor confirmar a troca, os eventos do documento anterior são descartados.
- **A fileira** (`DocTabStrip`, `lib/src/ui/organisms/doc_tabs.dart`) aparece só com duas abas ou mais: o nome, o ponto das alterações, o X, a dica com o caminho. Ctrl+Tab, Ctrl+Shift+Tab, Ctrl+W e o clique do meio.
- **O limite de 8** abas carregadas; uma aba com alterações nunca sai do motor.
- **A contagem de palavras (D-056):** o LibreOffice 24.2 às vezes não manda a `.uno:StateWordCount` depois de abrir (uma corrida dele, que a Fase 2 também tem). Até ela chegar, a barra de status usa a contagem da cópia temporária (`meta:document-statistic`).
- **Não conferido:** o `.uno:ChangeTheme` nas abas fora da tela; o Ctrl+Tab deixou de inserir tabulação numa tabela.
- **Os testes:** `tabs_test`, `workspace_test`, `fase2b_tabs_test` e o passo 13b da integração (três documentos, o desfazer de cada um, salvar o certo, fechar a do meio). `./test.sh --integracao` passou duas vezes seguidas.
- **A medida, com uma aba só** (`tool/ab.py ac8a2d6`, mediana de 3): anônima +8,0 MB com o capítulo e +7,0 depois de digitar, mas o `heap` ficou em +1,8 a +2,1; a diferença está no grupo `anon`, o ruído do coletor do Dart (D-052), que em outras rodadas deu de +3,3 a +8,5. O `abrir_ms` subiu (846 contra 333 ms, com uma rodada em 280): era o dicionário da ortografia carregando durante o abrir, investigado no D-068.

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


## A barra de status clicável (passo 6, D-063)

- `lib/src/ui/organisms/status_bar.dart`: o `_StatusButton` com o `FocusableActionDetector` (Tab, Enter, Espaço, o anel de foco) e o `StatusField(menu:)`, que abre um `MenuAnchor` construído só ao abrir; o `StatusInfoRow` para as linhas só de leitura; a porcentagem do `ZoomControl` virou um botão com menu.
- `editor_page.dart`: os menus `_wordsMenu`, `_languageMenu` e `_zoomMenu`, e o `zoomToFit` (o `EditorViewActions` ganhou o método).
- `document_controller.dart`: `languages` (pedidos ao abrir), `language` e `setLanguage`. O `parseLanguage` e o `parseLanguageList` ficam em `lok_payloads.dart`.
- `plainMenuItem` (`command_menu.dart`): um item de menu com o desenho dos comandos, para o que não é comando (um idioma, um zoom).
- **Testes:** `test/widget/fase2b_status_test.dart` (o idioma, as estatísticas, o zoom, o Enter no campo, "modificado" salva, o `fitZoom` e a leitura do idioma).
- **Para olhar à mão:** o anel de foco nos campos; o menu do idioma num documento com dois idiomas; Ajustar à página no modo Várias.

## Os bastidores e a tela inicial (passo 7, D-064)

- `lib/src/ui/organisms/file_panel.dart`: o `FilePanel` com a `FileSection` (recentes, informações, preferências), o `_BackstageItem` e as Informações (`_InfoView`, `formatFileSize`).
- `recent_list.dart` (a tabela dos recentes), `start_screen.dart` (a tela inicial) e `preferences_view.dart` (as preferências).
- `lib/src/files/open_folder.dart`: o `xdg-open`, trocável nos testes.
- `Settings.startScreen` e o `main.dart`, que só abre o documento em branco se a preferência pedir.
- **Testes:** `test/widget/fase2b_backstage_test.dart`; o `editor_page_test` passou a escolher a seção (Recentes, Preferências) antes de clicar.
- **Para olhar à mão:** a tela inicial ao abrir o Quill sem arquivo; os bastidores no Clássico 97; "Abrir a pasta do arquivo" no gerenciador de arquivos.

## A aba Exibir (passo 8, D-065)

- `ribbon.dart`: o `_ViewTab`, com os grupos Mostrar, Páginas, Zoom, Modos e Janela.
- `lib/src/ui/molecules/command_check.dart`: um comando de ligar e desligar como caixa de seleção.
- `commands_view.dart`: `statusBar`, `layoutSingle`, `layoutMulti`, `layoutBook`, `fitWidth` e `fitPage`. O `EditorViewActions` ganhou `toggleStatusBar`, `statusBarShown` e `pageLayout`.
- `EditorTemplate(statusBar:)` aceita null, e `Settings.statusBar` guarda a escolha.
- **Testes:** `test/widget/fase2b_view_test.dart` (em 1024, 1366 e 1920 px; as caixas com o estado para o leitor de tela; a disposição e os ajustes).
- **Para olhar à mão:** a aba Exibir em 1024 px (ela rola de lado, como as outras abas curtas); as caixas no Clássico 97.

## A medida dos passos 4 a 8 (23/11/2026)

`tool/ab.py dfb7498` (A) contra o `6370706` (B), mediana de 3, no mesmo dia, numa worktree à parte:

| etapa do bench | anônima A | anônima B | Δ | RSS A | RSS B | Δ |
|---|---|---|---|---|---|---|
| motor ligado | 111,2 | 111,9 | +0,6 | 263,4 | 264,9 | +1,5 |
| vazio | 180,8 | 181,4 | +0,6 | 375,9 | 377,4 | +1,5 |
| com o capítulo de 30 páginas | 239,9 | 235,2 | −4,6 | 447,0 | 440,3 | −6,7 |
| depois de rolar | 243,7 | 237,8 | −5,9 | 451,0 | 443,2 | −7,8 |
| depois de digitar | 255,1 | 251,2 | −3,9 | 463,0 | 460,0 | −3,0 |

- Rolar 59,5 fps nas duas; tecla → ladrilho p95 9,4 ms nas duas.
- Abrir: 737 ms (A) e 816 ms (B). A diferença é do tamanho do ruído entre rodadas neste host, mas fica anotada para o fecho conferir.
- A memória caiu, e a causa não foi investigada: o que importa aqui é que não cresceu.
