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
