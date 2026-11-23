# Decisões

Cada decisão nova entra aqui, com a data, o porquê e o que foi descartado. As grandes, anteriores ao código, estão no `PLANO.md` (seção 1).

## D-001 · Versões de partida (22/11/2026)

- **Flutter 3.47.4 estável e Dart 3.13.3**, as últimas estáveis no dia.
- **O LibreOffice 24.2.7 do Ubuntu 24.04**, pela `libmergedlo.so`. Não existe `libsofficeapp.so` no Ubuntu, e o `lok_init` cai na mesclada sozinho.
- **O Lua 5.4.6** e o **GoogleTest 1.14**, também do sistema.

Os pacotes de desenvolvimento são `libreofficekit-dev`, `liblua5.4-dev`, `libgtest-dev` e `libclang-18-dev` (este para o ffigen).

## D-002 · O plugin nativo é um pacote local, `packages/psito_quill_kit`

O plugin nativo é um plugin Flutter de Linux, com o C++ em `linux/` e uma casca Dart fina (`NativeQuillKit`). O app adapta essa casca à porta `QuillKit` em `lib/src/kit/lok/`.

**Por quê:**
- O plugin precisa do `FlTextureRegistrar` para as texturas, e por isso não pode ser um `plugin_ffi` puro.
- Separar o motor num pacote mantém o adaptador trocável. É o caminho para o `psito-quill-kit` em outro processo (PLANO 1.2).

**Descartado:** pôr o C++ direto no runner do app, porque misturaria o motor com a janela.

## D-003 · O ffigen gera só a nossa API C e os enums do LOK

O plano pede os bindings do `LibreOfficeKit.h` pelo ffigen. Gerar as funções do LOK para o Dart seria um convite a chamá-las da thread da UI, e o LOK não é thread-safe.

O ffigen gera:
- a API C do kit, `quill_kit_api.h` (`pqk_*`), que só põe tarefas na fila;
- os enums do `LibreOfficeKitEnums.h`: os tipos de callback, de tecla e de mouse.

O Dart nunca chama o LOK direto. A config está em YAML (`ffigen.yaml`), que o ffigen 23 já marca como obsoleto. Migrar para a API Dart do ffigen quando o YAML sair.

## D-004 · O núcleo C++ não conhece o GTK

`linux/core/` (fila, cache de ladrilhos, motor e Lua) é C++20 puro.

**Por quê:** compila também nos testes do GoogleTest e no `lok_probe`, sem o Flutter. A cola com o GTK fica num arquivo só, o `psito_quill_kit_plugin.cc`.

## D-005 · Os ladrilhos são vagas fixas, cada vaga uma textura

- A `TileCache` tem N vagas de 256×256 (Flyweight + LRU), 128 por padrão, ou 32 MB. Cada vaga é uma `FlPixelBufferTexture`.
- O Dart posiciona as texturas pela grade em twips. Rolar só move widgets.
- Um redesenho no lugar (digitação) não passa pelo Dart: o nativo marca a textura, e pronto.
- O Dart só recebe um evento quando uma vaga passa a mostrar outro ladrilho.

**Descartado:** uma textura do tamanho da tela, montada no nativo. Rolar exigiria remontar e copiar a cada quadro, e a posição da textura chegaria um quadro atrasada.

**Detalhe:** a textura copia a vaga sob o mutex para um buffer de apoio único. O raster popula uma textura por vez e sobe para a GPU logo em seguida. O LOK pinta em BGRA, e o kit converte para RGBA.

## D-006 · Desenho fatiado para as teclas passarem na frente

Cada passada de desenho pinta no máximo 4 ladrilhos e se repõe no fim da fila. Uma tecla que chega no meio de uma tela inteira para desenhar não espera a tela toda.

## D-007 · Um perfil do LibreOffice só do Quill, com os esquemas de cor dos temas

O perfil fica em `~/.config/psito-quill/lo-profile`.

**Por quê:**
- não brigar com a trava do perfil de um LibreOffice aberto pelo usuário, nem mudar as configurações dele;
- o papel escuro: a 24.2 aceita o `.uno:ChangeTheme`, mas não traz nenhum esquema escuro. O `LoProfile.ensureSchemes` registra `PsitoQuillClaro` e `PsitoQuillEscuro`, com o papel, a tinta e o fundo tirados dos tokens dos temas.

Medido: a luminância dos ladrilhos vai de 232 a 51 (FASE0-RESULTADOS).

**Esquisitices:** o comando responde `success: false` mesmo funcionando, e não invalida os ladrilhos. O app pede o `repaintAll` depois.

## D-008 · O kit limpa o buffer antes de cada `paintTile`

O LOK não pinta fora das páginas. A limpeza é para transparente, e o fundo do tema aparece atrás.

## D-009 · Fechar a janela fecha o documento antes de sair

É o `AppLifecycleListener.onExitRequested` → `DocumentController.close()`, que espera o `PQK_EVENT_CLOSED` por até 3 s.

**Por quê:** a trava `.~lock` que sobra de um processo morto faz o LibreOffice abrir o arquivo só para leitura, em silêncio, com outro perfil. Isso aconteceu nas medições.

A Fase 1 ainda precisa detectar o modo só leitura e limpar as travas velhas.

## D-010 · Na caixa de areia Lua, o limite de instruções não se engole com `pcall`

Depois do limite, o hook de contagem passa a rodar a cada instrução. Sem isso, um `pcall` em volta de um laço infinito pegava o erro, e o plugin ganhava mais 1000 instruções para sempre. Um teste pegou esse caso.

Também saem da caixa de areia:
- `collectgarbage`, que mexeria no teto;
- `string.dump`, que gera bytecode;
- o `load` de bytecode: ele é trocado por um `load` só de texto.

## D-011 · Os tokens do `quill_ui` são classes Dart por enquanto

Os temas são `const QuillTokens` em `lib/src/ui/tokens/themes/`. O tema em JSON (PLANO 5.3) fica para quando houver temas de fora (`~/.config/psito-quill/themes/`, plugins). O formato JSON vai espelhar estas classes.

O `ComponentStyle` (moderno ou bisel) já existe nos átomos. Os testes exercitam o bisel com um tema de teste, porque o Clássico 97 só entra na Fase 2.

## D-012 · O jogo de atalhos padrão é o do Word em português

`Ctrl+N` é negrito e `Ctrl+B` é salvar, como no Word em português (PLANO 5.4). O do Word em inglês já existe no `CommandRegistry` (`ShortcutScheme.wordEn`). A escolha nas configurações vem na Fase 1.

## D-013 · Textos da interface na l10n desde o início

`lib/l10n/app_pt.arb` (o modelo) e `app_en.arb`, gerados em `lib/l10n/gen/`. Nenhum texto que quem usa lê fica no código, como no Player.

## D-014 · A medição tem dois lados: o `lok_probe` e o `--bench`

- O **`lok_probe`** (C++) mede o motor sem a UI.
- O **`psito-quill --bench`** mede o app inteiro e sai sozinho.

Separar mostra o custo do Flutter (~90 MB) e o do motor. Os dois trabalham numa cópia do documento, por causa da trava (D-009). O `tool/bench.sh` roda os dois.

## D-015 · O texto entra pelo IME do sistema; as teclas de edição vão direto

O `DocumentView` é um `TextInputClient` do Flutter. Com o foco e um documento editável, a conexão com o IME (o do GTK) fica aberta.

- **O texto** vem pelo IME. É o único jeito de `´` + `a` virar `á` no ABNT2: a tecla morta não traz caractere, e quem compõe é o IME.
  - A pré-edição (o `´` sozinho) vai ao motor como `LOK_EXT_TEXTINPUT` e aparece no documento.
  - A confirmação vai como `LOK_EXT_TEXTINPUT` com o texto final, seguido de um `LOK_EXT_TEXTINPUT_END` vazio. Medido na 24.2: o `END` ignora o texto que vem com ele.
  - O valor de edição do Flutter fica sempre vazio: o que o IME manda é o texto novo.
- **Setas, Enter, Backspace, Delete, Tab e F-teclas** vão direto ao motor, como teclas do VCL, com os modificadores (Ctrl+Seta anda por palavra).
- **Ctrl+letra que não é atalho do Quill é engolida.** Sem isso, o Ctrl+U (sublinhado no LibreOffice) passaria no jogo em português, onde o Ctrl+U é Substituir. Os atalhos são só os do `CommandRegistry`.
- **O AltGr do ABNT2 conta como Alt**, mas traz caractere (AltGr+Q = `/`). Tecla com caractere vai como texto, com ou sem Alt.
- Durante uma composição, todas as teclas são do IME (o Backspace apaga a pré-edição, não o documento).

O `routeKey` (`vcl_keys.dart`) decide a rota, e é testado sem o motor.

**Descartado:** mandar cada `KeyEvent` como caractere (o que a Fase 0 fazia). Não compõe acentos.

## D-016 · Copiar e colar: o motor guarda a formatação, o sistema recebe o texto

- **Copiar** manda `.uno:Copy` (a área do motor, com a formatação) e pede a seleção como texto simples (`getTextSelection`), que vai para a área de transferência do sistema.
- **Colar:** se o sistema ainda tem o que o Quill copiou, cola o do motor (`.uno:Paste`, com a formatação). Se não, cola o texto que veio de fora (`paste` com `text/plain`).
- **Recortar** pede o texto antes do `.uno:Cut`. A fila do motor garante a ordem.

A área do sistema é uma porta (`TextClipboard`). Os testes usam uma na memória, e a integração também: não toca na área de transferência do usuário.

**Fica para depois:** colar HTML de outro app com a formatação. A API de clipboard do Flutter só dá texto simples.

## D-017 · A trava do LibreOffice: a velha do próprio Quill some, a dos outros vira só leitura

Antes de abrir, o `LockInspector` lê o `.~lock.<arquivo>#`, cujo formato é `nome,usuário,máquina,data,perfil;`.

- **Trava do nosso perfil, nesta máquina:** é velha, e é apagada. O perfil do LibreOffice só aceita um processo de cada vez (um segundo LOK com o mesmo perfil morre com "User installation could not be completed"), e esse processo somos nós. A conferência só roda com o motor já ligado.
- **Qualquer outra trava** (um LibreOffice aberto, outro computador numa pasta em rede): abre só para leitura, com um aviso que diz quem está com o arquivo. Medido: o LibreOffice também recusa as teclas nesse caso.
  - O app também não edita (o `DocumentController.canEdit`). Só deixa andar e copiar.
  - "Salvar uma cópia…" salva com outro nome e reabre a cópia, editável.

**Descartado:** "Abrir mesmo assim" (apagar a trava dos outros). Dois programas escrevendo o mesmo arquivo perdem trabalho. O Francisco confirmou: fica só leitura, mais simples e mais seguro.

## D-018 · O `Workspace` junta os fluxos de arquivo (Facade)

Novo, abrir, salvar, salvar como, os recentes, "salvar as alterações?" e sair moram num lugar só: `lib/src/document/workspace.dart`. Os comandos e a UI só chamam o `Workspace`.

Ele depende de portas, e por isso tudo roda nos testes sem GTK nem LibreOffice:
- `FileDialogs`: o app usa o `file_selector`, que abre o seletor do GTK;
- `TextClipboard`;
- `AppWindow`: o título da janela, que o Flutter no Linux não muda. O plugin nativo ganhou o `pqk_set_window_title`, que passa pelo laço do GTK.

A pergunta "salvar as alterações?" é um callback que a página põe no `Workspace`. Sem ninguém para perguntar, ele cancela: nunca descarta em silêncio.

## D-019 · Salvar com `TakeOwnership`

O `saveAs` do LOK, sem opções, exporta uma cópia, e o documento continua apontando para o arquivo antigo. Com `TakeOwnership`, o documento passa a ser o arquivo novo, mesmo em outro formato. Assim, "Salvar como ODT" e depois Ctrl+B salvam no ODT. A integração confere isso.

O "modificado" vem do motor (`.uno:ModifiedStatus`), não é adivinhado no Dart.

## D-020 · Ladrilhos: só a largura do documento, e vagas pelo tamanho da tela

- **A área pedida ao motor é só o documento.** Até a Fase 0, ela tinha a largura da janela, e o motor pintava ladrilhos vazios dos lados da página. O `PageGeometry.visibleTwips` agora corta nas bordas do documento.
- **O número de vagas sai do maior monitor:** as colunas da tela, mais uma, vezes as linhas, mais três (`tileSlotsFor`), entre 48 e 256. Numa tela de 1920×1080 são 72 vagas (18 MB) em vez de 128 (32 MB), e a tela ainda fica coberta com zoom de 300 %.

Medido: uns 20 MB a menos com o capítulo aberto (FASE1-RESULTADOS).

## D-021 · O `trimMemory` do LibreOffice não ajuda: fica fora do app

Medido com o alvo 2000 (acima de 1000 o LibreOffice limpa os caches da VCL e chama o `malloc_trim`): o RSS não mudou. O método fica na porta, e o bench continua medindo. Um "aparar quando ocioso" só entra se uma versão do LibreOffice mudar isso.

## D-022 · Estilos rápidos por uma lista fixa, com os nomes do LibreOffice

O `getCommandValues(".uno:StyleFamilies")` volta vazio na 24.2. A galeria usa uma lista fixa: Padrão, Corpo de texto, Título do livro, Subtítulo, Título 1 a 3 e Citação.
- Aplica pelo nome interno do LibreOffice (`Heading 1`), que vale em ODT e em DOCX.
- O rótulo vem da l10n do app.
- O campo mostra o nome que o motor manda no estado (`.uno:StyleApply`), já no idioma do LibreOffice.

**O idioma do LibreOffice é o pt-BR** (`Language=pt-BR` ao abrir), também para os documentos novos (a ortografia). Os textos de status do motor ("Página 3 de 30") só servem pelos números. A frase final é da l10n do app (`parsePageStatus`, `parseWordCount`).

As fontes vêm do motor (`.uno:CharFontName`), uma vez por sessão.

## D-023 · A faixa da Fase 1: Arquivo e Início, e o acesso rápido

- **As abas:** Arquivo e Início. As outras entram com o que elas fazem.
- **O acesso rápido**, ao lado das abas: Salvar, Desfazer e Refazer, como no Word.
- **A aba Início:**
  - área de transferência (Colar, Recortar, Copiar);
  - o estilo de parágrafo;
  - a fonte (nome, tamanho, negrito, itálico, sublinhado, tachado);
  - o parágrafo (os quatro alinhamentos, marcadores, numeração).
  - A cor da fonte fica para o inspetor Formatar (Fase 2).
- **O painel Arquivo** é como o "backstage" do Word: Novo, Abrir, Salvar, Salvar como, os recentes e as preferências (tema e jogo de atalhos). O Esc volta.
- **Clicar na faixa não tira o foco do documento.** Os botões só ganham foco pelo Tab. Depois de um comando ou de fechar uma lista, o foco volta à página.

As preferências ficam em `~/.config/psito-quill/preferencias.json`, e os recentes (10) em `recentes.json`.

## D-024 · Os atalhos do Word, nos dois jogos

| Comando | Word em português | Word em inglês |
|---|---|---|
| Negrito, itálico, sublinhado | Ctrl+N, Ctrl+I, Ctrl+S | Ctrl+B, Ctrl+I, Ctrl+U |
| Salvar, Salvar como | Ctrl+B, F12 | Ctrl+S, F12 |
| Novo, Abrir | Ctrl+O, Ctrl+A | Ctrl+N, Ctrl+O |
| Desfazer, Refazer | Ctrl+Z, Ctrl+R | Ctrl+Z, Ctrl+Y |
| Selecionar tudo | Ctrl+T | Ctrl+A |
| Esquerda, centro, direita, justificar | Ctrl+Q, Ctrl+E, Ctrl+G, Ctrl+J | Ctrl+L, Ctrl+E, Ctrl+R, Ctrl+J |
| Recortar, copiar, colar | Ctrl+X, Ctrl+C, Ctrl+V | os mesmos |
| Título 1 a 3, corpo de texto | Ctrl+Alt+1 a 3, Ctrl+Alt+0 | os mesmos |
| Zoom | Ctrl+=, Ctrl+−, Ctrl+0, Ctrl+roda | os mesmos |

Um teste confere que nenhum jogo tem atalho repetido. O Ctrl+L (Localizar) e o Ctrl+U (Substituir) do jogo em português ficam livres para a Fase 2.

## D-025 · Metas de memória revistas; as de rapidez ficam

O Francisco aprovou rever as metas de memória para algo razoável, "sem perder o ethos de um app rápido e responsivo".

- **Memória (RSS, mediana de 3 ou mais execuções):** ≤ 340 MB vazio, ≤ 380 MB com o capítulo, ≤ 400 MB com o livro. O piso medido é o Flutter com o Impeller (uns 126 MB) mais o Writer vazio (uns 210 MB).
- **Ficam como estavam:** tecla → ladrilho ≤ 16 ms no p95, rolar a 60 fps, abrir o capítulo em ≤ 400 ms, e não crescer mais de 30 MB em 4 horas. A rapidez é a razão do Quill existir, e a meta de abrir continua aberta (515 ms).

A tabela está no PLANO, seção 8. O Skia contra o Impeller e o perfil enxuto do LibreOffice continuam como ideias, se a memória voltar a apertar.

## D-026 · O Windows fica para depois da Fase 6

Resposta à pergunta 2 da seção 12 do PLANO. Até lá, o Quill pode usar o que for só do Linux (GTK, `/proc`, o LOK do sistema), sempre atrás das portas.

## D-027 · O app sai com `_exit`, sem os destrutores estáticos

Fechar a janela derrubava o app com `SIGSEGV` (e um núcleo de ~20 MB) depois que o `main` terminava. Os destrutores estáticos do LibreOfficeKit (`LocaleDataWrapper`) rodavam no `exit()` com o motor ainda carregado. Na Fase 0 já havia um `SIGABRT` igual.

Agora o `linux/runner/main.cc` chama `fflush` e `_exit(status)` depois do `g_application_run`. Nessa hora, o documento já foi fechado no motor pelo `Workspace.requestExit`: a trava foi apagada e não há nada a gravar.

**Descartado:** chamar o `destroy` do LOK antes de sair. Na Fase 0 ele às vezes demorava, e um LOK destruído não religa no mesmo processo.

O `tool/fechar-test.sh` (no `./test.sh --integracao`) abre o app de verdade, fecha a janela pelo `wmctrl` e confere o código 0 e a trava apagada. Com o runner antigo, ele falha (código 139).

## D-028 · Cliques como no Word, e um zoom que não pula

**Cliques.** Medido na 24.2: no Writer, 2 cliques selecionam a palavra, 3 a frase e 4 o parágrafo. No Word, o clique triplo é o parágrafo. O Quill segue o Word:
- o clique triplo vai ao motor como 4 (parágrafo);
- o Ctrl+clique vai como 3 (frase), como no Word.

A série de cliques aceita até 500 ms entre um e outro (o GTK usa 400 ms) e 6 px de folga. A lógica fica no `ClickCounter`, testada sem a tela.

**Zoom.** Três coisas faziam a página pular:
- **A rolagem não acompanhava a escala.** Agora o ponto do documento sob a âncora fica no lugar. A âncora é o ponteiro, no Ctrl+roda, ou o centro da tela, nos botões e atalhos (`PageGeometry.scrollFor`).
- **Os ladrilhos sumiam até os novos chegarem.** Os da escala anterior ficam por baixo, esticados (`DocumentController.staleTiles`), como o plano pedia na seção 4. Eles saem quando a vaga é reusada.
- **Não havia rolagem horizontal.** Com zoom alto, a página fica mais larga que a janela. Agora a vista rola nas duas direções, e a área pedida ao motor acompanha.

## D-029 · O `lok_script`, uma sonda do motor por roteiro

A Fase 2 dependia de dezenas de comandos `.uno:` cujos argumentos e estados a 24.2 não documenta direito. Cada um foi medido antes de virar código, com o `lok_script` (`packages/psito_quill_kit/linux/tools/`). Ele lê um roteiro de passos (`open`, `uno`, `values`, `type`, `key`, `click`, `gsel`, `sel`, `save`, `wait`) e imprime os callbacks e os estados, com um filtro opcional.

**Por quê:** subir o app inteiro para cada pergunta custa um minuto e não mostra os callbacks crus. O `lok_probe` (Fase 0) mede, e o `lok_script` pergunta.

**O que ele mostrou na 24.2:**
- Muitos comandos respondem `success: false` e funcionam: `StyleNewByExample`, `InsertTable`, os da página, `Color`. O Quill não confia no `success` e confere pelo estado.
- O `.uno:StyleDelete` não faz nada.
- Recuos: `.uno:LeftRightParaMargin` com `LRSpace.LeftMargin`, `RightMargin` e `FirstLineIndent` (1/100 mm). Entrelinha: `.uno:LineSpacing` com `LineSpacing.Mode=0` e `LineSpacing.Height` (%).
- O `.uno:ULSpacing` com valores não funciona. Só o `ParaspaceIncrease` e o `ParaspaceDecrease`, por isso o espaço entre parágrafos anda em degraus (D-032).
- Página: `.uno:AttributePageSize` (largura e altura em 1/100 mm), `.uno:AttributePage` com `Landscape`, `.uno:PageLRMargin` e `.uno:PageULMargin`.
- Imagem: o callback 6 dá o retângulo e as alças. Um `setGraphicSelection` que começa numa alça redimensiona (mantendo a proporção). Um que começa dentro da imagem a move.
- Tabela: o callback 44 dá `{ }` fora e um JSON dentro.

## D-030 · Estilos: o estado vem traduzido, a lista vem com os nomes de programa

O estado do `.uno:StyleApply` traz o nome da interface em português ("Título 1", "Estilo de parágrafo Padrão"). O `getCommandValues(.uno:StyleApply)` dá os nomes de programa (126 de parágrafo e 27 de caractere). O Quill guarda o nome de programa e mapeia o estado de volta pela tabela gerada `lo_styles.dart` (`styleIdFromState`). Um estilo criado pelo usuário tem o mesmo nome nos dois.

- **A galeria** (na faixa Início) mostra os estilos de livro (`bookStyles`) e os do usuário, não os 126.
- **Criar a partir da seleção** é o `StyleNewByExample`; **atualizar**, o `StyleUpdateByExample`.
- **Apagar estilo fica de fora:** o `StyleDelete` não funciona na 24.2. A prévia do estilo desenhada pelo motor também fica para depois.

## D-031 · Localizar e substituir: a contagem vem antes

O `.uno:ExecuteSearch` (0 próxima, 1 todas, 2 substituir, 3 substituir todas; `AlgorithmType2=2` é expressão regular, `TransliterateFlags=256` ignora maiúsculas) responde pelo callback 15 com os retângulos, ou pelo 12 quando não acha. O "substituir todas" não diz quantas trocou. O Quill pede "achar todas" antes, guarda a contagem e depois manda o "substituir todas". A barra diz "3 substituídas".

A barra fica em cima da página, sem janela por cima do texto. Os atalhos são os do Word: Ctrl+L e Ctrl+U em português, Ctrl+F e Ctrl+H em inglês.

## D-032 · O espaço entre parágrafos anda em degraus

Como o `.uno:ULSpacing` com valores não funciona na 24.2 (D-029), o painel Formatar oferece "mais espaço" e "menos espaço" (os degraus do LibreOffice), e mostra os valores lidos do estado. Recuos e entrelinha aceitam números. Os estados do `ULSpacing` e do `LeftRightParaMargin` vêm em JSON, em polegadas com vírgula decimal. O `parseMeasures` converte para cm.

## D-033 · Ortografia: a lista de idiomas e um mistério no teste de integração

- **Sem a variável `LOK_ALLOWLIST_LANGUAGES`, o LOK desliga os idiomas** ("No language allowlisted"). O `LokEngine::init` a define (sem sobrescrever) com pt-BR, pt-PT, en-US, en-GB, es, fr, de e it.
- **As sugestões vêm pelo menu de contexto do motor.** O clique direito vai como mouse com o botão 4. O callback 23 traz o menu em JSON, com `.uno:SpellCheckApplySuggestion`, `SpellCheckIgnore` e `SpellCheckIgnoreAll`. O Quill desenha esse menu com os próprios widgets (`engine_context_menu.dart`), e cada item roda o comando do motor.
- **Depois de um "substituir todas", as marcas de ortografia somem** até a próxima tecla. É do motor.
- **O mistério:** no `lok_script`, o clique direito numa palavra errada traz as sugestões. Dentro do `integration_test` (o processo do Flutter), com a mesma sequência de chamadas, o mesmo perfil, a mesma variável, o mesmo `setlocale`, o pt-BR na lista do `LanguageStatus` e o `SpellOnline` ligado, o menu vem sem sugestões. Foram descartados: o plugin `svp`, ligar e desligar o `SpellOnline`, esperar sem bombear eventos e o tamanho da vista. O teste de integração prova o resto do caminho (o idioma ligado, o menu chega à tela e o Esc fecha). **Falta conferir à mão no app de verdade.**

## D-034 · O tema Clássico 97

O terceiro tema embutido, com a barra de menus completa e as barras Padrão e Formatação no lugar da faixa. A fonte é a Liberation Sans (vem com o LibreOffice e tem as métricas da Arial), e os controles têm bisel (o `WControlSurface` escolhe o desenho pela estratégia do tema). Os menus saem de `editorMenus` (`lib/src/commands/menus.dart`), só com ids do `CommandRegistry`, e a paleta (Ctrl+K) usa os mesmos menus para mostrar de onde vem cada comando. O papel do motor tem o esquema próprio `PsitoQuillClassico`, registrado no perfil como os outros (D-007).

## D-035 · O painel Formatar, o menu de contexto e as alças da imagem

- **O painel Formatar** fica à direita e muda com a seleção: imagem, tabela, caractere, parágrafo e página. F10 mostra e esconde, e a escolha fica nas preferências (`painelFormatar`, ligado por padrão). "Revelar formatação" (Shift+F1, como no Word) põe em cima o que vale no cursor, lido dos estados do motor, como no WordPerfect.
- **As abas de contexto** (Tabela, Imagem) aparecem na faixa só quando o cursor está numa tabela ou há uma imagem selecionada, como no Word.
- **As alças da imagem são do Flutter**, como o cursor e a seleção. Arrastar mostra uma prévia e, ao soltar, manda o `setGraphicSelection` de início e fim. O motor redesenha uma vez só.
- **Menu de contexto:** o do motor (D-033), desenhado pelo Quill.
- **Não conferido:** o Ctrl+Shift+8 (marcas de formatação) no teclado ABNT2, e se o Ctrl+Espaço (limpar formatação) briga com a troca de idioma do sistema.

## D-036 · Deitar a página troca a largura e a altura

Na 24.2, o `.uno:AttributePage` com `Landscape` só muda a marca (`print-orientation`), e a página continua em pé. Trocar só o tamanho também não basta, porque a marca fica "retrato". O Quill faz como o painel lateral do LibreOffice: manda o tamanho trocado e depois a marca. O teste de integração pegou isso, conferindo o XML salvo.

O motor não diz o tamanho da página: o `getCommandValues` do `AttributePageSize` vem vazio. O `DocumentController.pageSizeMm100` tira do tamanho do documento. No LOK, o Writer põe 284 twips em volta e entre as páginas (medido com o `lok_script`), e o número de páginas vem do `StatePageNumber`. Vale para documentos com um tamanho de página só. Os twips arredondam: 14800 (1/100 mm) volta como 14801 e fica nisso, e o ODT grava "14.801cm".

## D-037 · A faixa e o painel só se refazem quando os estados mudam

A primeira medição da Fase 2 rolou a 54 fps, com 5 quadros acima de 16 ms. Sem o painel Formatar, voltava a 58,7. Cada evento do motor (até um ladrilho novo ao rolar) chamava o `notifyListeners`, e a página refazia a faixa e o painel inteiros.

Agora o `DocumentController.stateRevision` sobe a cada mudança, menos as que são só da vista: ladrilho, cursor e seleção. A `EditorPage` memoiza a faixa (ou os menus 97) e o painel pela chave: a revisão, o jogo de atalhos, o tema aplicado (o dos tokens, não o das preferências, que muda um quadro antes), a aba, o painel Arquivo, o "Revelar" e a barra de localizar. Com a chave igual, devolve o mesmo widget, e o Flutter não o refaz. A barra de status e a página continuam se refazendo a cada evento (são leves).

**O ganho** (mediana de 3): rolar a 59,7 fps com 0 quadros lentos; tecla → ladrilho p95 de 13,6 para 9,3 ms; abrir de 479 para 356 ms. Um teste de unidade confere que o cursor não sobe a revisão.

## D-038 · Para onde foram os 46 MB da Fase 2

Medido com o `tool/mapas.py` (o `smaps` do app amostrado a cada 0,5 s e somado por tipo de mapeamento), comparando com a build da Fase 1 no mesmo dia e na mesma máquina, numa cópia do commit `1413dbb` (`git worktree`). Os números absolutos mudam de um dia para outro: a Fase 1 deu 383 MB de RSS com o capítulo nesse dia, não os 364 da medição antiga. **Só vale comparar duas builds medidas lado a lado.**

O RSS engana. As páginas de código das bibliotecas (o `libmergedlo.so`, por exemplo) contam no RSS, mas são do arquivo, e o kernel as devolve quando falta memória. Quase nada mudou nelas. O que cresceu foi a **memória anônima** (heap, malloc), com o capítulo aberto: de 186 MB para 232 MB (+46 MB, ±1 MB entre execuções). A divisão:

| Causa | MB | Como foi medido |
|---|---|---|
| O dicionário pt-BR do Hunspell | ~35 | Sem ortografia: 197 MB. O Hunspell sozinho, carregando o `pt_BR.dic` (4,4 MB em disco), pega 36 MB; o en-US, 7 MB |
| O serviço de idiomas, sem dicionário | ~3 | Com a lista de idiomas vazia em vez de um idioma falso |
| O painel Formatar | ~3,5 | Com o painel escondido |
| O resto (código novo, o heap do Dart) | ~4 | |

**Descartados, medidos:**
- `MALLOC_ARENA_MAX=2`: dentro do ruído.
- Só o pt-BR na lista (sem o en-US): dentro do ruído. O LibreOffice só carrega o dicionário do idioma que aparece no texto.
- O tcmalloc (`LD_PRELOAD`): economiza 7,6 MB no Hunspell sozinho, mas o app inteiro fica com 5 MB a mais.

**O que sobra para decidir:** a ortografia em português custa uns 35 MB, e é o preço do Hunspell. Não há ajuste que o reduza. O painel Formatar entra no redesenho mostrando uma seção de cada vez.

## D-039 · A ortografia começa ligada

Resposta do Francisco (23/11/2026) ao D-038: a ortografia fica ligada por padrão, e os ~35 MB do dicionário pt-BR do Hunspell são o preço aceito. As metas de memória do PLANO (seção 8) não mudam. A economia tem de vir de outro lugar: o painel Formatar com uma seção de cada vez no redesenho, e cada coisa nova medida antes e depois (CLAUDE.md).

## D-040 · A Fase 2B: a interface nova em Material 3, em etapas

O Francisco aprovou (23/11/2026) os desenhos do canvas "Psito Quill — nova interface" e o plano em 9 etapas (PLANO, seção 10). Escolhas dele:
- **Material 3 com densidade de desktop** (como o Google Docs) e os ícones Material Symbols Rounded. O Yaru e o fluent_ui foram descartados: um parece o app de configurações do GNOME, o outro é estranho no Linux e pesado.
- **A barra de título continua a do GTK.** A pesquisa Ctrl+K vai para a ponta da fileira de abas. Uma barra desenhada pelo Quill traria risco no X11 (sombra, redimensionar, arrastar) por pouco ganho.
- **A fonte da interface é a do sistema**, sem a Roboto embutida: nada a mais no pacote nem na memória.
- **A IA local fica para a Fase 5**, como plugin com permissões.

Cada etapa tem um orçamento de ~5 MB de memória anônima, medido lado a lado com a build anterior (D-038).

## D-041 · Privacidade: o perfil do motor trava o que fala para fora

Pedido do Francisco: nada de rede, de telemetria ou de log, tudo no computador. O app em Dart já não abre a rede; o risco estava no LibreOffice. O `LoProfile.ensureSettings` (antes `ensureSchemes`) grava, junto dos esquemas de cor, estas travas no `registrymodifications.xcu` (nomes conferidos no `main.xcd` da 24.2):

| Chave | Valor | Por quê |
|---|---|---|
| `Office.Common/Misc/CrashReport` | false | Sem relatório de falha enviado à TDF |
| `Office.Common/Security/Scripting/BlockUntrustedRefererLinks` | true | Um documento não busca imagens e links de fora sozinho |
| `Office.Common/Security/Scripting/DisableMacrosExecution` | true | Macro de documento não roda (poderia abrir a rede ou gravar arquivos) |
| `Office.Common/History/PickListSize` | 0 | O motor não guarda a lista de recentes dele |
| `Office.Common/History/RecentDocsThumbnail` | false | Nem as miniaturas |
| `Office.Common/Save/Document/GenerateThumbnail` | false | O arquivo salvo não leva a miniatura da primeira página |

- **Os logs da UNO** já vêm desligados (o `LogLevel` padrão é o máximo, ou seja, nada). A 24.2 do Ubuntu não tem verificação de atualizações, nem a coleta de uso.
- **Os avisos do LibreOffice** iam para o terminal. O `LokEngine::init` define `SAL_LOG=-WARN-INFO` sem sobrescrever: quem depura define a variável antes.
- **Os recentes do Quill:** a preferência "Guardar a lista de arquivos recentes" (ligada por padrão). Desligada, a lista vale só enquanto o Quill está aberto e o `recentes.json` é apagado.
- **Um teste** (`test/unit/privacy_test.dart`) confere as travas no perfil, que nada em `lib/` usa `HttpClient`, `Socket` ou parecido, e que o núcleo nativo (fora das ferramentas de medição) não abre a rede nem grava arquivo.

Ficam de fora, de propósito: a cópia de segurança do LibreOffice (`CreateBackup`), que fica no perfil, no próprio computador, e é útil num livro longo.

## D-042 · Os tokens do Material 3 e os átomos novos (Etapa 1 da Fase 2B)

- **Os tons ficam prontos nos arquivos de tema**, copiados do desenho (o Material Theme Builder com a semente #415F91). O `toThemeData` monta o `ColorScheme` com eles, sem o `ColorScheme.fromSeed`: o mesmo resultado, sem calcular paleta ao trocar de tema, e o Clássico 97 continua com os cinzas dele.
- **Os nomes antigos do `QuillColors` ficam** (`frame`, `accent`, `accentSoft`...), agora com o papel do M3 escrito ao lado (`frame` é o `surface`, `accentSoft` é o `secondaryContainer`). Entram os que faltavam: `onAccentSoft`, `accentContainer`, `tertiary` e o container (as abas de contexto), os cinco tons de superfície, `outline` e o container de erro. Trocar todos os nomes num commit só mexeria em 44 lugares sem mudar nada na tela; os organismos novos da Etapa 2 já usam os papéis certos.
- **O ligado é tonal:** o fundo `secondaryContainer`, o texto `onSecondaryContainer` e o ícone preenchido (o eixo FILL do Material Symbols). O realce do mouse é o `surfaceContainerHigh`; apertado, o `Highest`.
- **Densidade:** `QuillDensity.compact` (32 px, o padrão) e `.comfortable` (44 px, ícone de 24). A preferência entra na Etapa 8.
- **Ícones:** o pacote `material_symbols_icons`, estilo Rounded. Os 78 ícones do app passaram de `Icons.x_outlined` para `Symbols.x_rounded`.
- **Átomos novos:** `WSegmented`, `WSwitch`, `WSlider` (o `Slider` do Flutter, que já traz teclado e leitor de tela) e `WChip`. Cada um tem o desenho bisel do Clássico 97 pelo `ComponentStyle`.
- **O `tokens_test`** confere 4,5:1 nos pares novos e 3:1 no contorno e na cor da marca sobre a superfície (WCAG 1.4.11) nos temas modernos.

## D-043 · A casca do editor da Fase 2B (Etapa 2)

- **A fileira de abas** fica sobre o `surfaceContainer`: o Arquivo preenchido (a cor da marca), as abas Início, Inserir, Layout, **Estilos** (nova), Revisão e Exibir em pílula, as de contexto (Tabela, Imagem) no terciário. Na ponta direita: salvar, desfazer, refazer, o tema escuro, a pesquisa (abre a paleta Ctrl+K) e o **Recolher** (Ctrl+F1, guardado nas preferências). Numa janela com menos de 1100 px a pesquisa vira só o ícone, e as abas rolam em vez de estourar.
- **A faixa** é um cartão de cantos de 16 px. Os grupos têm uma ou duas linhas, o nome embaixo e a divisória à direita (`RibbonGroup.firstRow`, `secondRow`, `leading`). Início: Colar grande; Fonte com − e + (andam pela lista de tamanhos, sem comando novo), a cor da fonte e o realce em menus de amostras; Parágrafo com o menu de entrelinhas; os cartões de estilo; Localizar e Substituir em chips.
- **Os cartões de estilo** (`StyleCard`) mostram uma amostra genérica pelo tipo (título maior e em negrito, citação em itálico). As propriedades de verdade entram na Etapa 3.
- **O trilho** (`NavRail`), à esquerda: Estrutura, Localizar (abre a barra de localizar) e Estilos. Clicar no aberto fecha. A Estrutura recebe os títulos na Etapa 5; até lá, diz onde eles vão aparecer. O painel Estilos lista os de parágrafo (lista preguiçosa) e aplica ao clicar.
- **O painel Formatar** tem as seções Texto, Parágrafo e Página num `WSegmented`, mais Imagem e Tabela com a seleção. **Só a seção escolhida é construída** (o D-038 mediu ~3,5 MB para o painel inteiro).
- **A barra de status:** a mensagem, a página, as palavras, o idioma com o ícone da ortografia, o estilo atual e o zoom (−, o controle deslizante, + e a porcentagem). **Arrastar o zoom só muda o número**; o motor recebe o zoom ao soltar. O RSS virou um widget próprio (`MemoryLabel`): antes, o relógio de 2 s refazia a página inteira quando o número mudava.
- **A barra de status e o trilho também são memoizados** pela chave da faixa (D-037), que ganhou o painel da esquerda, a seção do Formatar e o Recolher.
- **O tamanho da imagem em cm** (aba Imagem, grupo Tamanho). Sondado no `lok_script`: o `.uno:Size` com valores e o `.uno:TransformWidth` não fazem nada na 24.2. O que funciona são as alças, pelo `setGraphicSelection`:
  - a do canto **sempre mantém a proporção** (pedir 3000 × 2500 twips num 6000 × 3000 deu 5001 × 2500);
  - a da direita muda só a largura, e a de baixo só a altura, com precisão de uns 5 twips.
  Por isso: com o cadeado, vai a alça do canto pela largura; sem, a da direita e, quando o retângulo novo chega, a de baixo (`DocumentController.setGraphicSizeCm`).
- **Ficam de fora, sondados:** "Original" (o `.uno:OriginalSize` não volta ao tamanho original depois de redimensionar) e "Legenda" (o `.uno:InsertCaptionDialog` só abre um diálogo, que o LOK não entrega). Voltam com a Fase 3, se houver outro caminho.

## D-044 · As prévias de estilo: a cópia temporária, e nada de prévia no texto

**A cópia temporária (sondada no `lok_script`).** O motor não diz as propriedades de um estilo nos estados. Um `saveAs` sem `TakeOwnership`, em ODT plano (`fodt`, um XML só, sem zip), grava uma cópia sem mudar o documento: o caminho continua o mesmo e o "modificado" continua ligado. No capítulo de 30 páginas a cópia tem 173 KB, com os 23 estilos (`style:style`, com `style:text-properties` e `style:paragraph-properties`) e os títulos com o nível (`text:h text:outline-level`), que a Etapa 5 usa para a Estrutura. A cópia vai para o `$XDG_RUNTIME_DIR` (memória, só do usuário), é lida num isolate e apagada na hora. O ODT plano dispensa uma biblioteca de zip.

**Sem prévia ao vivo no texto.** Aplicar e desfazer devolve o "modificado" a falso, mas **liga o Refazer**: passar o mouse num estilo trocaria o que o autor tinha para refazer (uma edição dele que ele desfez) pela prévia. A LOK não tem como limpar o Refazer. Por isso a prévia fica nos cartões e na lista de fontes, desenhada pelo Flutter, e o texto só muda ao clicar.

## D-045 · A lista de fontes na própria fonte, com filtros do fontconfig

- **A lista é do Quill** (`FontPicker`), não um menu simples: cada nome desenhado na própria fonte, a busca, os filtros Com serifa, Sem serifa e Mono, e as seções "Neste documento" (as fontes declaradas na cópia temporária, D-044), "Recentes" (as 5 últimas escolhidas, nas preferências) e "Todas". Enter na busca aplica a primeira que sobrou.
- **Preguiçosa:** um `ListView.builder` de altura fixa. Só as fontes visíveis (umas 12) são construídas e só elas carregam o arquivo da fonte. O sistema de teste tem 299 famílias.
- **Os filtros vêm do fontconfig**, numa função nativa pequena (`pqk_font_classes`, `core/font_info.cc`), uma chamada para a lista inteira quando ela chega do motor. Não passa pela thread do kit: não é o LibreOffice. A classe é a primeira família genérica que as regras do sistema acrescentam (`45-latin.conf`), e o mono vem do espaçamento da fonte de verdade. **Limite conhecido:** uma fonte que as regras não conhecem ganha "sem serifa" (o `49-sansserif.conf` faz isso). É só um filtro: ela continua em "Todas".
- **A galeria aberta** ("Gerenciar estilos…") virou cartões com as prévias, a busca, Parágrafo ou Caractere, "Do livro" e "Do LibreOffice", e o atalho de cada estilo (os títulos têm Ctrl+Alt+1 a 3).
- **"Revelar formatação" diz de onde vem cada coisa:** compara os estados do motor no cursor com as propriedades do estilo do parágrafo (a cópia): "estilo" ou "direto" ao lado de cada valor, também para o leitor de tela. "Tirar o que é direto" é o `.uno:ResetAttributes` que já existia (Limpar a formatação).

## D-046 · A régua: o callback 35, a cópia para a vertical, e nada se reconstrói ao rolar

**Sondado no `lok_script`:** o `LOK_CALLBACK_RULER_UPDATE` (35) chega sozinho ao abrir, sem pedir nada: `margin1` (o recuo esquerdo), `margin2` (a largura do texto), `leftOffset` (a margem esquerda), `pageWidth` e as tabulações, em centésimos de mm. As tabulações vêm com a chave repetida (`""`), que o `jsonDecode` juntaria numa só: o `parseRuler` lê por expressões regulares. Não vêm o recuo da primeira linha nem o direito: esses saem do estado `.uno:LeftRightParaMargin`, que o Quill já lia. Não há estado das margens de cima e de baixo (nem `.uno:PageULMargin`, nem `getCommandValues`): a régua vertical as lê do estilo de página da cópia temporária (D-044), que se refaz depois de mudar o tamanho, a orientação ou as margens da página.

**Também aprendido:** o `.uno:LeftRightParaMargin` com um argumento de nome errado abre o diálogo Parágrafo (o callback 46). Os nomes certos são os `LRSpace.*` que o `setIndents` já usa.

**Desenho e memória:**
- O `DocumentView` publica onde a página está (a borda, o topo, a escala) num `ValueNotifier<DocViewport>`, a cada rolagem e zoom. Cada régua é um `CustomPaint` com esse notifier como `repaint`: a rolagem repinta a régua, sem reconstruir widget nenhum.
- As marcas que recebem o foco (o teclado e o leitor de tela) são caixas transparentes sobre o desenho. Elas só se refazem quando a parte horizontal muda (zoom, rolagem para os lados, outro parágrafo), nunca com a rolagem vertical.
- Arrastar mexe só em notifiers locais (a marca e a linha tracejada sobre a página); o motor recebe o recuo ao soltar, já arredondado para o milímetro. Arrastar o recuo esquerdo leva a primeira linha junto, como no Word.
- Pelo teclado: Tab até a marca, as setas andam 1 mm, Shift + setas 1 cm. O leitor de tela tem o nome, o valor em cm e as ações de aumentar e diminuir.
- O duplo clique abre o painel Formatar na seção Parágrafo. Exibir › Régua liga e desliga (guardado), e a unidade (cm, mm, pol, pt) fica nas preferências (`unidadeRegua`; a tela de preferências entra na Etapa 8).

**Ficam para depois:** criar e mover tabulações pela régua (e o seletor do tipo no canto) e arrastar as margens da página pela régua. A régua mostra as tabulações, mas o comando para criá-las não foi sondado ainda.

## D-047 · Várias páginas pelo ViewLayout, e a Estrutura pela cópia

- **A disposição das páginas** fica na barra de status: Uma página, Várias páginas e Livro (pares), guardada nas preferências (`paginas`). É o `.uno:ViewLayout` (`ViewLayout.Columns`, `ViewLayout.BookMode`), sondado na Fase 2: com 3 colunas, o documento fica com 3 páginas de largura, e o `DocumentView` não precisa mudar (a área pedida ao motor continua sendo a visível).
- **Em "Várias", as colunas saem do zoom e da largura da área**: o quanto cabe de páginas (a largura da régua do motor mais o espaço de 284 twips). O cálculo roda quando o `DocViewport` muda, e o motor só recebe o comando quando o número muda.
- **O zoom mínimo caiu de 50 % para 20 %**, para caber o capítulo.
- **A régua vertical some** com mais de uma coluna (não há uma pilha só); a horizontal segue a primeira coluna.
- **A Estrutura** são os títulos da cópia temporária (D-044), com o nível. A página de cada título vem das quebras que o LibreOffice escreve no ODT (`text:soft-page-break`): o título atual é o último que começa na página do cursor ou antes. É uma aproximação: a página é a da última cópia.
- **A cópia só se refaz ao vivo com a Estrutura aberta**: uma pausa de 2 s na digitação refaz a cópia; com o painel fechado, nenhuma (ninguém paga pelo que não vê). Abrir o painel depois de editar refaz na hora.
- **Ir para um título** é a busca do texto dele, com maiúsculas: a 24.2 não tem um comando de ir para um título pela LOK. O título fica selecionado. Dois títulos com o mesmo texto levam ao próximo depois do cursor.

## D-048 · O modo zen: tela cheia do GTK, Sépia, e o foco por faixa de linhas

- **A tela cheia é a do GTK** (`gtk_window_fullscreen`, pela porta `AppWindow`). Ela é de verdade: cobre o painel do sistema, e o gerenciador de janelas devolve o tamanho de antes ao sair.
- **O Esc sai do zen** por um tratador do `HardwareKeyboard` que só existe enquanto o zen está aberto. Assim, os usos que o Esc já tinha no editor continuam iguais fora do zen.
- **O papel padrão do zen é o Sépia**, um tema novo e completo (também escolhível para a interface). O papel do zen fica nas preferências, separado do tema da interface. O modo zen em si não é guardado: o Quill sempre abre fora dele.
- **O foco escurece por faixa de linhas** (2 acima e 2 abaixo do cursor), e não pelo parágrafo. O retângulo do parágrafo viria dos callbacks de acessibilidade do motor, que custam memória e trabalho a cada tecla. Eles ficam para a Etapa 9, ligados só para quem usa leitor de tela.
- **Nada se refaz sem precisar:**
  - a barrinha de opções usa um `Timer` e um `ValueNotifier`;
  - o relógio da sessão muda uma vez por minuto e só refaz o rótulo;
  - a máquina de escrever só rola o Flutter.

## D-049 · A interface que respira: uma etapa nova antes de "ocupado"

**O retorno.** O Francisco testou a casca das Etapas 2 a 5 e achou os comandos densos, mal distribuídos no Início e difíceis de ver e de clicar. A interface não aproveitava as telas grandes (nem maximizada), e os menus eram pobres. Ele mandou capturas do OnlyOffice como referência.

**A decisão.** Uma Etapa 7 nova, "a interface que respira" (`docs/fase2b/etapa-7-espaco.md`). "Ocupado sem janelas" vira a 8 e "acessibilidade" a 9. Ela vem antes porque é o que ele sente a cada minuto de uso. Seguimos os padrões de layout do OnlyOffice e do Office, sem copiar a cara.

**O que muda:**
- **Na densidade padrão:** de 32 para 36 px, com texto de 14 px. O desenho do Claude Design pedia 32 px "como o Google Docs", mas o Docs tem poucos comandos por linha, e a nossa faixa tem muitos.
- **Na faixa:** os grupos passam a ter quatro tamanhos, do grande com nome ao recolhido num menu, escolhidos pela largura. É o que o Office faz desde 2007, e resolve ao mesmo tempo a densidade, a distribuição e as telas grandes e pequenas.
- **No menu de contexto:** passa a ser do Quill, com as sugestões do motor dentro dele. Antes era só o que o motor mandava (D-033).
- **No Arquivo:** vira bastidores na janela inteira, e as Preferências nascem ali.

**O que não muda:** os comandos continuam saindo do `CommandRegistry` (o Clássico 97 continua com os mesmos), e só a seção visível é construída.

## D-050 · Uma busca só: o texto e os comandos no mesmo campo

**O retorno.** O Francisco achou confuso ter "Pesquisar comandos" e "Localizar" lado a lado, com a mesma lupa. Escolheu uma busca só.

**Como ficou:**
- **Um campo,** na ponta direita da fileira de abas: "Pesquisar no texto e nos comandos". O Ctrl+L, o Ctrl+F, o Ctrl+K e o botão Localizar da faixa abrem esse campo.
- **Duas seções nos resultados:**
  - "No documento": as ocorrências, com o trecho em volta (o achado em negrito) e a página, e a contagem;
  - "Comandos": como a antiga paleta.
- **O último item** é "Localizar e substituir, com opções…". Ele abre o painel com a palavra digitada. O painel continua no Ctrl+H/Ctrl+U e no trilho, que agora se chama "Localizar e substituir".

**De onde vêm as ocorrências:**
- **A cópia temporária** (D-044) é feita na primeira busca no texto e apagada quando a busca fecha. A busca é modal, e o documento não muda enquanto ela está aberta, então uma cópia basta.
- **A cada pausa de 250 ms** na digitação, a cópia é lida num isolate: o texto do livro nunca fica na memória do app, e só as primeiras 50 ocorrências voltam.
- **A página** sai das quebras que o LibreOffice escreve na cópia (`text:soft-page-break`). Ela foi conferida no capítulo de 30 páginas: 29 quebras.

**Ir a uma ocorrência** é uma busca por expressão regular com o contexto: `(?<=antes)achado(?=depois)`. O lookbehind e o lookahead do ICU foram sondados no `lok_script` (24.2). A busca seleciona só a ocorrência pedida, mesmo com outras iguais antes dela, e dá a volta do fim para o começo sozinha. A integração confere o salto a uma ocorrência da página 5 ou mais.

## D-051 · Abas de documentos, leves: só o ativo (e os não salvos) no motor

**O pedido.** O Francisco quer abrir documentos em abas.

**As opções que ele viu:**
- **Abas completas:** todos os documentos carregados no motor. Seria ~50 MB por capítulo de 30 páginas (o bench: 180 MB vazio, 230 MB com o capítulo), e 10 capítulos passariam de 500 MB.
- **Abas leves:** só o documento ativo carregado.
- **Esperar o Fichário** da Fase 3.

**A escolha: abas leves.**
- **O que fica guardado:** uma aba inativa é só o caminho e a posição (o cursor, a rolagem e o zoom). Trocar de aba reabre o documento, o que leva ~0,3 s num capítulo (o `abrir_ms` do bench).
- **Documento não salvo:** fica carregado até ser salvo ou fechado, porque descartar alterações ao trocar de aba seria inaceitável. Para isso, o kit passa a aceitar mais de um documento. A sonda vem antes: dois documentos no mesmo processo LOK na 24.2, e quanto custa o segundo.
- **Na Fase 3,** os capítulos abertos do Fichário usam as mesmas abas.

## D-052 · A página e as palavras não refazem a faixa; o "+9,4 MB depois de digitar" era ruído

**A investigação.** A medida dos passos 1 a 3 da Etapa 7 deu +9,4 MB de memória anônima depois de digitar. O `tool/mapas.py` e o `tool/ab.py` passaram a separar também a etapa "depois de rolar" e a mostrar os grupos de mapeamento em cada etapa com o capítulo. Com o mesmo código, três A/B de 3 rodadas deram, depois de digitar, +9,4, −1,2 e +5,6 MB. A diferença está toda no grupo `anon`, onde o Dart guarda o heap dele: o número depende de quando o coletor rodou perto da amostra. O `heap` (malloc) fica estável em +2 MB, e o RSS a mais é quase todo de arquivo (fontes +2,6 MB, libmergedlo +3 MB), que o kernel devolve.

**O desperdício que apareceu no caminho.** A página atual e a contagem de palavras chegam como estados do motor. Elas mudam a cada página na rolagem e a cada tecla, e cada uma subia a `stateRevision`, refazendo a faixa, o painel Formatar e o trilho. Só a barra de status e a Estrutura as leem.

**A decisão:**
- **`.uno:StatePageNumber` e `.uno:StateWordCount`** (os `statusOnlyStates` do `DocumentController`) sobem só a nova `statusRevision`. Qualquer outra mudança sobe as duas.
- **A barra de status e o painel da esquerda** são memoizados pela chave com a `statusRevision`. A faixa, o trilho e o painel Formatar continuam na `stateRevision`.
- **Na hora de medir** uma etapa, o que conta é o grupo `heap` e a tendência de mais de uma rodada do A/B. Uma variação do `anon` de ±5 MB entre rodadas, sozinha, é o coletor do Dart.

**O resultado** (A/B de 3 rodadas contra a Fase 2, com a correção): anônima +3,3 MB com o capítulo, +1,0 depois de rolar e +5,6 depois de digitar; rolar a 59,5 fps, tecla → ladrilho p95 9,4 ms, abrir 277 ms. O teste: `fase2_controller_test` ("a página e as palavras sobem só a revisão da barra de status").

## D-053 · A sonda das abas: dois documentos no mesmo motor funcionam, e o segundo custa ~4 MB

O `lok_two_docs` (D-051, passo 9 da Etapa 7) abriu dois capítulos de 30 páginas no mesmo processo do LibreOffice 24.2. A entrada, os callbacks, os ladrilhos e o salvar de cada um ficaram separados, sem `setView`. O segundo capítulo custou +3,9 MB de memória anônima; fechar e reabrir levou ~90 ms e não deixou memória para trás depois da terceira vez. Os números estão no `docs/fase2b/etapa-7-espaco.md`.

**Consequência:** o kit pode guardar vários documentos (um `LibreOfficeKitDocument` por aba, todos na thread `pqk-kit`). A suposição do D-051 (~50 MB por capítulo) estava errada; ela era o custo do Writer subir. A escolha entre manter as abas carregadas ou reabrir ao trocar volta para o Francisco.

## D-054 · Abas de documentos: todas carregadas no motor, com um limite

**A escolha.** Com a sonda (D-053), o Francisco trocou as abas leves do D-051 por abas todas carregadas: a troca é na hora, e cada documento guarda o próprio desfazer.

**Como fica no kit:**
- O motor guarda vários `LibreOfficeKitDocument`, cada um com um número, e só um ativo. Todas as chamadas (teclas, comandos, salvar, ladrilhos) vão ao ativo.
- O callback de cada documento sabe o número dele. O que chega de um documento que não é o ativo é descartado na thread do kit: ele não recebe entrada, então não tem nada a dizer.
- `pqk_open` abre mais um documento e o ativa, sem fechar os outros. `pqk_activate(id)` troca o ativo: limpa as vagas de ladrilho e repinta. `pqk_close_document(id)` fecha um só.
- O `PQK_EVENT_OPENED` e o novo `PQK_EVENT_ACTIVATED` levam o número e o tamanho, e o `PQK_EVENT_CLOSED` leva o número.

**Como fica no Dart:**
- O `DocumentController` continua um só, a fachada do documento ativo, para a interface não precisar trocar de ouvinte. O estado de cada documento (os estados do motor, o cursor, a estrutura, o zoom, a posição da rolagem) fica num `DocTab`.
- Os eventos do motor vão para o `DocTab` que o motor tem ativo. A interface mostra o da aba escolhida, que passa a ser o do motor quando chega o `DocumentActivated`. Assim, um evento atrasado do documento anterior não cai no novo.

**Os fluxos:**
- Novo, Abrir e os recentes abrem numa aba nova. Um documento novo, vazio e sem alterações dá lugar ao que se abre. Um arquivo que já está aberto só ganha o foco.
- Fechar a aba pergunta se há alterações, como fechar o documento. Sair pergunta por aba, cada uma com o foco.

**O limite:** 8 abas carregadas. Passou disso, a aba salva usada há mais tempo é fechada no motor e guarda só o caminho, o zoom e a rolagem. Ao voltar, ela reabre (~0,3 s). Uma aba com alterações nunca é fechada assim. 8 capítulos de texto custam uns 30 MB no motor.

**A fileira de abas** fica acima da faixa e aparece só com 2 abas ou mais, para não gastar altura com um documento só. Os atalhos: Ctrl+Tab e Ctrl+Shift+Tab trocam, Ctrl+W fecha, e o clique do meio também fecha.

**O que ficou de fora ou não foi conferido:**
- **O Ctrl+Tab é das abas.** Numa tabela, ele não insere mais uma tabulação (o Writer usa o Ctrl+Tab para isso). Se fizer falta, a tabulação na tabela pode ir para outro atalho.
- **O papel nas abas fora da tela:** o `.uno:ChangeTheme` vai ao documento da tela. Ao voltar a outra aba, o motor repinta tudo, e na 24.2 o esquema de cores parece ser do programa inteiro, mas isso não foi conferido com duas abas e uma troca de tema no meio.
- **O motor, ao abrir,** entrega o `OPENED` antes de qualquer callback do documento novo: os que chegam antes ficam guardados e saem logo depois dele (`LokEngine::Doc::early`). Sem isso, o Dart, que descarta os eventos de documento até o `OPENED`, perdia o cursor.
- **Os testes:** `test/unit/tabs_test.dart` (o controlador), `test/unit/workspace_test.dart` (os fluxos), `test/widget/fase2b_tabs_test.dart` (a fileira e os atalhos) e o passo 13b da integração (três documentos no motor, o desfazer de cada um, salvar o certo, fechar a do meio).

## D-055 · A galeria de estilos do Início desce com o ▾, com as prévias

**O retorno.** O Francisco notou que os estilos do Início não abriam como lista: eram só os cartões que cabiam e, ao lado, um ícone que abria "Gerenciar estilos" numa janela. Ele escolheu a galeria com as prévias, que desce.

**Como ficou:**
- **Ao lado dos cartões,** o ▾ ("Mais estilos") desce a galeria inteira por cima da galeria da faixa, a partir do canto dela, como o "Mais" do Word. Ela tem os mesmos cartões com as prévias da cópia temporária, a busca, Parágrafo ou Caractere, "Do livro" e "Do LibreOffice", e Novo e Atualizar.
- **Escolher um estilo aplica e fecha.** Esc ou o clique fora também fecham.
- **O corpo é o mesmo da janela "Gerenciar estilos…"** (`StylesDialog`, com `dropdown: true`): um widget só, sem lista duplicada na memória. Ele só existe enquanto a lista está aberta.
- **"Gerenciar estilos…"** saiu do lado da galeria e ganhou um botão com nome na aba Estilos, ao lado de "Novo estilo". Continua nos menus do Clássico 97, no painel Estilos e na busca.

**O teste:** `fase2b_previews_test` ("o ▾ da galeria do Início desce todos os estilos; escolher aplica e fecha").

## D-056 · A contagem de palavras às vezes não vem ao abrir: vale a da cópia

**O que se viu.** A integração passou a falhar no passo 2 ("página, palavras, fontes") durante as abas. O LibreOffice 24.2 nem gera a `.uno:StateWordCount` depois de abrir o capítulo, em 60 s; o resto (a página, as fontes, os estados) chega. Abrir o capítulo direto no app, sem o bench, deu o mesmo: a barra de status ficava sem as palavras.

**A causa não é do Quill.** Uma bisseção com a Fase 2 (ac8a2d6) numa `git worktree` pareceu apontar arquivos (o motor de várias abas, depois só o `quill_kit_api.h`, que só declara funções). Repetida em A-B-A, a mesma configuração passou e falhou. É uma corrida dentro do LibreOffice: a contagem sai de uma tarefa de fundo (o Idle de estatísticas do Writer), que às vezes não avisa. A Fase 2 também está sujeita a ela, só que passou mais vezes.

**A decisão:** enquanto o motor não manda a contagem, a barra de status usa a da cópia temporária que o Quill já faz ao abrir e ao salvar (D-044): o LibreOffice grava `meta:document-statistic` com as palavras e os caracteres (no capítulo, os mesmos 21.069 da barra). O `FodtSnapshot` lê o `words` e o `characters`; o `DocumentController.wordCount` usa o do motor quando ele vem e o da cópia até lá. Não custa memória nem trabalho a mais: a cópia já era lida num isolate.

**O limite:** se o motor não mandar nada, a contagem da cópia fica parada até a próxima cópia (salvar, mudar um estilo, ou uma pausa de 2 s com a Estrutura aberta). O teste: `fodt_test` ("as palavras e os caracteres vêm do meta:document-statistic") e `fase2_controller_test` ("sem a contagem do motor, as palavras vêm da cópia").


## D-057 · Os painéis na largura que têm: ações na largura toda e cores numa linha

**O retorno.** No Formatar e no painel Estilos, as ações eram chips de larguras diferentes, que cortavam os nomes longos ("Novo estilo a partir da se…"). As amostras de cor (36 px cada) não cabiam na largura do painel: a última cor caía sozinha na linha de baixo, e "Limpar formatação" ficava solta embaixo do realce.

**Como ficou:**
- **`PanelAction`** (molécula): um botão com contorno na largura toda do painel, com o ícone e o nome do comando, e a dica com o nome inteiro e o atalho. No Formatar: "Atualizar estilo pela seleção", "Novo estilo a partir da seleção…" e "Limpar formatação"; no painel Estilos: "Novo estilo" e "Gerenciar estilos…".
- **`SwatchRow`** (molécula): a fileira de cores divide a largura que tem, e cada botão encolhe até 28 px para tudo caber numa linha. Abaixo disso, quebra a linha como antes.
- **A barra de status:** os campos do documento ficam à esquerda; a mensagem ("Salvo"), no meio, só quando existe; a vista (memória, disposição das páginas e zoom), à direita. O seletor da disposição usa o `WSegmented` compacto, na altura da barra.

**O teste:** `fase2b_panels_test` (em 1366 e 1920 px: cada fileira de cores numa linha, e as três ações com a mesma largura).

## D-058 · Rodapé office profissional e equilíbrio dos painéis

**O retorno.** As melhorias de espaçamento no rodapé precisavam fechar tanto em tela pequena (sem estourar ou truncar campos) quanto em tela maximizada (com o controle deslizante de zoom ativo nos tamanhos padrão de laptop e desktop). Os painéis laterais precisavam de respiro simétrico e larguras proporcionais para não cortar ações e títulos.

**Como ficou:**
- **No rodapé (`StatusBar`):**
  - O limiar do controle deslizante de zoom (`WSlider`) baixou de 1500 para 1050 px: agora telas como 1366×768 (o laptop maximizado) e 1080p exibem o slider completo, enquanto janelas estreitas (< 1050 px) usam o modo compacto (`[-] 100% [+]`) sem poluição.
  - Priorização responsiva dos campos em telas estreitas: página e contagem de palavras têm prioridade 1 (sempre visíveis sem reticências desnecessárias); idioma e status (somente leitura, modificado) entram a partir de 750 px; estilo entra a partir de 980 px.
  - Campos clicáveis (`_StatusButton`) com destaque suave ao passar o mouse: clicar na página abre o painel Estrutura; clicar no estilo abre o painel Estilos.
  - Borda superior de 1 px separando o rodapé da folha e dos painéis.
- **Nos painéis laterais (`SidePanel`):**
  - `SidePanel` com margens horizontais balanceadas (16 px de cada lado) e divisória sutil na borda interna, definindo o limite contra a área da página.
  - Os painéis Estrutura e Estilos passaram de 240 para 280 px de largura, dando espaço natural para títulos longos de capítulos e para as ações ("Novo estilo a partir da seleção…").
  - O `WSegmented` ganhou o modo `expanded: true` no topo do painel Formatar, distribuindo as seções proporcionalmente na largura total.
  - O `WDropdown` de estilos no Formatar acompanha a largura total via `LayoutBuilder`, alinhando-se perfeitamente com os botões `PanelAction`.

**Os testes:** `fase2b_space_test` (testes de rodapé em 800×600, 1024×768, 1366×768, 1920×1080 e 2560×1440, mais cliques nos campos) e `fase2b_panels_test` (largura de 280 px dos painéis e alinhamento de ações e dropdown).

## D-057 · O respiro dos painéis

**O retorno.** O Francisco achou que o maior problema dos painéis (Formatar, Estilos) era a falta de respiro entre os elementos: 4 px entre um controle e o seguinte, 2 px entre os ícones e as cores, 8 px de margem. O rótulo de um grupo ("Cor da fonte") ficava tão perto do controle de cima quanto do seu.

**Como ficou** (só nos painéis; a faixa tem o layout medido dela, D-049):
- **A `InspectorSection`:** 12 px entre um controle e o seguinte, e 4 px entre o rótulo de um grupo e o controle dele. O rótulo fica colado no que nomeia e longe do grupo de cima. Há 12 px depois do título e 20 px no fim da seção.
- **O `SidePanel`:** 20 px de margem à esquerda e 12 px à direita.
- **Os ícones, os chips e as cores:** 4 px entre eles.
- **No painel Estilos:** a lista com 4 px entre os itens, e as ações com 12 px em cima e 20 px embaixo.

## D-058 · A régua segue a página do cursor; a vista da barra de status colada à direita

- **A régua no modo Livro e no Várias:** o callback 35 manda o `pageOffset`, onde começa a página do cursor, em centésimos de mm (sondado na 24.2: 501 com uma página por linha, que é o vão entre as páginas, e 21502 no Livro, com a primeira página na coluna da direita). A régua horizontal fica em "área da página + (`pageOffset` − vão)": com uma página por linha não muda nada, e no Livro e no Várias ela acompanha a página do cursor. Antes, ela ficava sempre na primeira coluna, longe da página.
- **A barra de status:** os campos do documento e a mensagem ficam numa fileira que ocupa toda a sobra, e a vista (memória, disposição, zoom) fica colada à direita. Com os campos flexíveis direto na fileira de fora, a parte que eles não usavam ficava vazia no fim da barra.
- **O trilho:** "Localizar", curto (cortava "Localizar e substituir"). O nome inteiro e o atalho ficam na dica.

## D-059 · A régua no modo Livro: a página inteira e a régua vertical por fileira

- **O `pageOffset` é a posição da página no documento, e o vão não se desconta.** Os dois valores sondados na 24.2 batem assim: 501 (o vão de 284 twips) com uma página por linha, e 21502 (o vão mais a largura de uma página) no Livro, em que as duas páginas de um par se encostam. O D-058 descontava o vão, e a régua ficava 284 twips à esquerda da página em todas as disposições (19 px a 100 %); a margem da régua não batia com a do papel.
- **A borda direita da régua sai da esquerda** (`pageLeft + largura`). Antes, ela ficava na primeira coluna: com o cursor numa página da direita, a faixa se fechava, e a régua sumia.
- **A régua vertical mede fileiras, não páginas** (`pageRows`): uma coluna, uma página por fileira; várias, `colunas` por fileira; no Livro, a primeira sozinha e depois os pares. Antes, ela se desligava com mais de uma coluna. A altura sai de `(altura − vão) / fileiras − vão`, a mesma pilha do D-036.
- **O `pageSizeMm100` (o paisagem) segue as fileiras,** e, com mais de uma coluna, tira a largura da régua do motor. Sem isso, virar a página no Livro mandaria a largura de duas páginas.
- **Não conferido:** a pilha das fileiras no Livro e no Várias (o vão entre elas) ficou por conta da mesma regra do D-036; o `lok_script` não mostrou a mudança de tamanho depois do `.uno:ViewLayout`. A conferência é a olho, no app.

## D-060 · As marcas da régua no desenho do Office, refinado

- **Escolhido pelo Francisco entre três** (Office refinado, Docs e alças Material): a ampulheta do Word, que quem escreve livro já conhece. Em cima, a primeira linha; embaixo, o recuo esquerdo com a caixinha (que leva a primeira linha junto); à direita, o triângulo do recuo direito.
- **O desenho:** 14 px de largura (antes 10), preenchidas na cor do papel com contorno de 1 px, cantos arredondados no estilo moderno e retos no bisel do Clássico 97. Cabem inteiras na régua (antes saíam da borda e pareciam cortadas). Com o foco do teclado ou arrastando, o fundo vai para o `accentContainer` e o contorno para o `accent`.
- **A área de clique** acompanha: 10 px para cada lado da marca (antes 9).

## D-061 · O menu de contexto do Quill, com os submenus Estilo e Parágrafo

- **O menu é um `MenuAnchor`** numa camada do `Overlay` que só existe enquanto ele está aberto (antes, o `showMenu`, sem submenus). Os itens são os mesmos dos menus de comandos da faixa (`commandMenuItems`): ícone, nome, atalho à direita. Teclado e leitor de tela vêm do `MenuAnchor`.
- **A ordem:** as sugestões de ortografia do motor (com o "Ignorar"); Recortar, Copiar, Colar; os de tabela ou de imagem, quando é o caso; **Estilo ›** (Novo a partir da seleção, Atualizar, Gerenciar); **Parágrafo ›** (o fluxo entre as páginas); Limpar formatação; Selecionar tudo.
- **O fluxo do parágrafo, sondado na 24.2 com o `lok_script`** e conferido no XML salvo:
  - `.uno:ParaKeepTogether` com `true`/`false` liga e desliga o `fo:keep-with-next` ("Manter com o próximo");
  - `.uno:ParaSplit` com `false`/`true` liga e desliga o `fo:keep-together` ("Manter as linhas juntas");
  - sem o argumento, os dois não fazem nada (não alternam);
  - o motor não diz o estado (o `values` volta vazio, e não há callback de estado);
  - o `.uno:ParaWidows` com valor não mudou nada; o `.uno:PageBreak` (a quebra antes, como atributo) também não.
- **Por isso, pares, sem a marca de ligado** (escolhido pelo Francisco): "Manter com o próximo" e "Permitir separar do próximo", "Manter as linhas juntas" e "Permitir dividir as linhas". Cada item faz uma coisa só. A "quebra de página antes" fica como "Quebra de página" (inserir, o que já existia).
- **Os quatro são comandos do registro:** entram no menu Formatar do Clássico 97 e na paleta Ctrl+K.

## D-062 · Os trilhos dos dois lados, os rótulos em cima e o Localizar com a lista

O passo 5 da Etapa 7, a partir das capturas do OnlyOffice (D-049).

- **O trilho da direita** tem as seções do Formatar: Texto, Parágrafo, Página e, com a seleção, Imagem e Tabela. Escolher uma abre o painel nela, e escolher a aberta fecha, como no trilho da esquerda. O seletor de seções sai do painel, que fica com mais altura para os controles. No Clássico 97, que não tem trilhos, o seletor continua. O trilho é memoizado pela mesma chave da faixa, que agora inclui se o Formatar está aberto.
- **Os rótulos em cima:** o `LabeledRow` põe o nome em cima do controle (antes, o nome à esquerda e o controle espremido à direita). Os três recuos ficam lado a lado sob "Recuos", cada um com um rótulo curto (Esquerda, 1ª linha, Direita). O nome inteiro ("Recuo à esquerda") continua sendo o do campo para o leitor de tela; o teste pegou isso, porque o rótulo curto não lê e o campo não tinha nome próprio. Na faixa, o `MeasureField` continua numa linha.
- **O Localizar é um painel à esquerda** (`FindPanel`), no lugar da barra em cima da página. Os campos e as opções ficam em cima, e a lista de ocorrências embaixo, com a página e o trecho. O clique leva à ocorrência e o painel continua aberto. A lista sai da cópia da busca única (D-050), com até 50 linhas, e só as visíveis são construídas (`ListView.builder`). O painel abre por cima do painel da esquerda que estiver aberto, e esse volta quando ele fecha.
- **A cópia se renova quando o texto muda:** a busca única é modal e uma cópia bastava, mas o painel fica aberto enquanto se escreve. O `searchText(fresh: true)` refaz a cópia se a contagem de palavras e caracteres mudou desde ela. Usar a `statusRevision` refazia a cópia também ao rolar e ao saltar a uma ocorrência, o que o teste mostrou. Quem esperava uma cópia descartada recebe "sem resultado", em vez de esperar para sempre.
- **Limite conhecido:** a lista é a busca simples do texto. Diferenciar maiúsculas, palavra inteira e expressão regular valem para as setas, "Todas" e substituir, que vão pelo motor, mas não para a lista.

## D-063 · A barra de status clicável: o idioma, as estatísticas e o zoom

O passo 6 da Etapa 7 (D-049).

- **Cada campo é um botão de verdade:** recebe o foco pelo Tab, abre com Enter ou Espaço, tem o anel de foco, e o leitor de tela lê o texto do campo com a dica (antes, lia só a dica, e não havia caminho pelo teclado). Os campos com menu abrem um `MenuAnchor` no lugar, e os itens só são construídos enquanto o menu está aberto. O Esc fecha, também nos menus só de leitura.
- **As palavras** abrem as estatísticas: páginas, palavras (ou as selecionadas) e caracteres.
- **O idioma** abre a lista dos idiomas com ortografia instalada, "Sem verificação de ortografia", "Voltar ao idioma do estilo" e a ortografia ao digitar. A troca vale para a seleção ou, sem seleção, para o parágrafo.
- **Sondado na 24.2 com o `lok_script`:**
  - o `.uno:LanguageStatus` aceita `Current_<nome>` (a seleção), `Paragraph_<nome>`, `Paragraph_LANGUAGE_NONE` e `Paragraph_RESET_LANGUAGES`;
  - o nome é o da interface do LibreOffice ("Inglês (EUA)"), e não a etiqueta: `Current_en-US` e `Paragraph_es-ES` não fizeram nada;
  - o `getCommandValues(".uno:LanguageStatus")` dá a lista dos idiomas com ortografia instalada, no mesmo formato do estado ("Inglês (EUA);en-US"). O Quill pede a lista uma vez, ao abrir, e usa os nomes que o motor deu. Assim, o nome muda com a língua do sistema sem quebrar nada;
  - o `.uno:GotoPage` com valor abre uma janela e trava o roteiro. A página continua abrindo a Estrutura.
- **O zoom** (a porcentagem) abre as medidas comuns (50 a 200 %), Ajustar à largura e Ajustar à página. Os dois ajustes são comandos do registro (`exibir.ajustarLargura`, `exibir.ajustarPagina`), na paleta e na aba Exibir. O cálculo é o `fitZoom` (`document_view.dart`): a largura da fileira de páginas, ou a altura de uma página, na área do documento, arredondado para baixo em passos de 5 %.
- **"Modificado"** salva no clique.

## D-064 · Os bastidores do Arquivo e a tela inicial

O passo 7 da Etapa 7, a partir das capturas do OnlyOffice (D-049).

- **Os bastidores:** uma lista à esquerda, com itens altos (44 px), e o conteúdo à direita. Na lista: Voltar ao documento; Novo e Abrir; Recentes; Informações; Salvar, Salvar como e Fechar; Preferências e Sobre. Os comandos rodam e voltam ao documento; as seções (Recentes, Informações, Preferências) mudam o lado direito, e só a aberta é construída, como no painel Formatar (D-038).
- **A seção ao entrar:** Informações quando o documento tem arquivo, e Recentes quando não tem. "Mais informações…", no menu das palavras da barra de status, entra direto nas Informações.
- **Informações:** o nome, a pasta, o tamanho e quando o arquivo mudou (lidos do disco ao abrir a seção), as páginas, as palavras e os caracteres (do motor), e "Abrir a pasta do arquivo". A pasta abre pelo `xdg-open` (o padrão do freedesktop), sem o Quill saber qual gerenciador de arquivos existe. Nada sai do computador.
- **Recentes numa tabela:** o nome, a pasta e quando mudou. Um arquivo que sumiu fica apagado, com "Não encontrado". A data é lida do disco só quando a tabela é construída (no máximo 10 arquivos).
- **A tela inicial:** sem documento aberto, o lugar da página mostra dois cartões grandes (Documento em branco, com o foco, e Abrir um arquivo…) e os recentes na mesma tabela. Ela aparece ao fechar a última aba e, sem um arquivo na linha de comando, ao abrir o Quill.
- **A preferência "Ao abrir o Quill sem um arquivo":** Tela inicial (o padrão) ou Documento em branco (o de antes). Fica nas preferências (`telaInicial`).
- **As Preferências** saíram do painel para um widget próprio (`PreferencesView`), que a Etapa 9 divide em seções.

## D-065 · A aba Exibir com as caixas, a disposição e os ajustes do zoom

O passo 8 da Etapa 7, a partir da aba Ver do OnlyOffice e do Word (D-049).

- **Mostrar, em caixas de seleção:** Régua, Barra de status, Marcas de formatação, Estrutura, Painel Formatar e Revelar formatação. Cada caixa é um comando de ligar e desligar do registro (`CommandCheck`), com o estado "marcado" para o leitor de tela. Antes, eram seis ícones soltos, sem nome.
- **A barra de status pode sumir** (`exibir.barraStatus`, guardado nas preferências como `barraStatus`). Escondida, ela não é construída.
- **Páginas:** Uma página, Várias páginas e Livro (pares), botões grandes. São os mesmos três da barra de status (D-047), agora também comandos (`exibir.umaPagina`, `exibir.variasPaginas`, `exibir.livro`), na paleta e no Clássico 97.
- **Zoom:** 100 %, Ajustar à página e Ajustar à largura, grandes; + e − pequenos ao lado. Os ajustes são os do D-063.
- **Modos:** o zen. **Janela:** a paleta e Recolher a faixa.
- **A chave da memoização da faixa** (D-037) ganhou a régua e a barra de status: as caixas leem preferências que não vêm do motor. Sem isso, a caixa da Régua já ficava velha antes desta etapa.
