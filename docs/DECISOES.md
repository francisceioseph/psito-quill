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

## D-057b · O respiro dos painéis

**O retorno.** O Francisco achou que o maior problema dos painéis (Formatar, Estilos) era a falta de respiro entre os elementos: 4 px entre um controle e o seguinte, 2 px entre os ícones e as cores, 8 px de margem. O rótulo de um grupo ("Cor da fonte") ficava tão perto do controle de cima quanto do seu.

**Como ficou** (só nos painéis; a faixa tem o layout medido dela, D-049):
- **A `InspectorSection`:** 12 px entre um controle e o seguinte, e 4 px entre o rótulo de um grupo e o controle dele. O rótulo fica colado no que nomeia e longe do grupo de cima. Há 12 px depois do título e 20 px no fim da seção.
- **O `SidePanel`:** 20 px de margem à esquerda e 12 px à direita.
- **Os ícones, os chips e as cores:** 4 px entre eles.
- **No painel Estilos:** a lista com 4 px entre os itens, e as ações com 12 px em cima e 20 px embaixo.

## D-058b · A régua segue a página do cursor; a vista da barra de status colada à direita

- **A régua no modo Livro e no Várias:** o callback 35 manda o `pageOffset`, onde começa a página do cursor, em centésimos de mm (sondado na 24.2: 501 com uma página por linha, que é o vão entre as páginas, e 21502 no Livro, com a primeira página na coluna da direita). A régua horizontal fica em "área da página + (`pageOffset` − vão)": com uma página por linha não muda nada, e no Livro e no Várias ela acompanha a página do cursor. Antes, ela ficava sempre na primeira coluna, longe da página.
- **A barra de status:** os campos do documento e a mensagem ficam numa fileira que ocupa toda a sobra, e a vista (memória, disposição, zoom) fica colada à direita. Com os campos flexíveis direto na fileira de fora, a parte que eles não usavam ficava vazia no fim da barra.
- **O trilho:** "Localizar", curto (cortava "Localizar e substituir"). O nome inteiro e o atalho ficam na dica.

## D-059 · A régua no modo Livro: a página inteira e a régua vertical por fileira

- **O `pageOffset` é a posição da página no documento, e o vão não se desconta.** Os dois valores sondados na 24.2 batem assim: 501 (o vão de 284 twips) com uma página por linha, e 21502 (o vão mais a largura de uma página) no Livro, em que as duas páginas de um par se encostam. O D-058b descontava o vão, e a régua ficava 284 twips à esquerda da página em todas as disposições (19 px a 100 %); a margem da régua não batia com a do papel.
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

## D-066 · Ocupado sem janelas: o véu, as teclas paradas e o progresso no rodapé

A Etapa 8 da Fase 2B.

- **A sonda (24.2, `lok_script`):** o progresso vem pelo callback do **escritório** (o `registerCallback` do `LibreOfficeKit`, sem documento), que o kit não registrava.
  - Abrir um documento grande (391 páginas) manda `STATUS_INDICATOR_START` ("Carregando: "), `SET_VALUE` 0, 25, 50, 75 e `FINISH`, antes do documento aberto.
  - Um capítulo de 30 páginas manda só o `FINISH`.
  - Salvar (ODT ou DOCX, pelo `saveAs` do LOK) não manda nada.
- **O kit registra o callback do escritório** (`LokEngine::officeCallback`) e passa só o 9, o 10 e o 11. Com o callback registrado, um documento com senha faria o motor esperar a senha para sempre: o kit responde "sem senha" na hora, e abrir falha como antes. Pedir a senha fica para depois.
- **Os eventos** `ProgressStarted`, `ProgressValue` e `ProgressFinished` (`quill_kit.dart`). O controlador guarda o `progress` e refaz só a barra de status (a `statusRevision`), não a faixa.
- **O que trava (`DocumentController.busy`):** abrir o documento da tela (do pedido até o motor responder) e salvar (do pedido até "salvo" ou "falhou"). Se o motor não responder ao salvar em 90 s, a tela destrava. As cópias de leitura (a Estrutura, a busca) não travam: o usuário não pediu, e elas não mudam o documento.
- **O `BusyScope`** (no `EditorTemplate`, por cima de tudo menos o rodapé): o `AbsorbPointer`, o cursor de espera e um véu leve na cor da moldura. A árvore é a mesma com e sem o véu, para a página não ser remontada.
- **As teclas param:** a página e o documento engolem as teclas, também os atalhos; o controlador ignora texto e teclas enquanto está ocupado (o IME poderia confirmar no meio).
- **O rodapé:** "Abrindo… 50 %" com a barra determinada quando o motor manda números; "Salvando…" com a barra que corre (sem animação pedida, ela fica parada pela metade). É uma região viva para o leitor de tela.
- **Um trabalho com progresso que não é abrir nem salvar** aparece no rodapé com o nome que o motor dá, sem travar nada.
- **Sem "Cancelar":** o LOK não cancela um carregamento.
- **Saem os avisos que piscavam:** o "Abrindo…" no meio da página (o lugar fica vazio, e o progresso vai no rodapé) e o "Abrindo…" como mensagem do rodapé.

## D-067 · Acessibilidade: alto contraste, o tamanho da interface, o cursor e o documento no leitor de tela

A Etapa 9 da Fase 2B.

- **Dois temas de alto contraste,** escuro (preto, branco e amarelo) e claro (branco, preto e azul-escuro), com bordas fortes e o papel no mesmo contraste. O `tokens_test` exige 7:1 no texto, nos pares do Material 3, nas bordas e no papel, e 4,5:1 no anel de foco. Cada um tem o seu esquema de papel no perfil do LibreOffice. O Sépia já existia (D-048).
- **O tamanho da interface faz tudo crescer junto,** e não só o texto. O plano pedia o `MediaQuery.textScaler`, mas, a 200 %, o texto vazava dos controles de altura fixa da faixa e do painel (o teste mostrou: cinco estouros em 1366 px). Agora o `UiZoom` (`lib/src/ui/templates/ui_zoom.dart`) monta a interface numa área menor (a janela dividida pelo zoom) e a desenha ampliada, com a densidade de pixels multiplicada: a faixa se adapta como numa tela menor, e os ladrilhos do motor continuam nítidos. O tamanho de texto do sistema entra no mesmo zoom. A página também crescia; desde o D-070, o zoom da página compensa. As opções são 100, 125, 150 e 200 %.
- **Botões maiores:** a densidade confortável (44 px) da Etapa 1.
- **O cursor do texto:** a espessura (1, 2 ou 3 px; o padrão passou de 1,5 para 2) e se pisca. Sem piscar, não há relógio nenhum.
- **Reduzir movimento:** as durações dos tokens vão a zero e o `disableAnimations` liga (também segue o pedido do sistema). A barra de progresso sem número fica parada pela metade.
- **O foco visível:** os átomos já desenham o anel de 2 px ao navegar pelo teclado; nos temas de alto contraste, ele tem pelo menos 4,5:1.
- **A cor da marca de ortografia,** sondada na 24.2 (o `lok_script` ganhou o `color`, que conta os pixels de uma cor nos ladrilhos):
  - a entrada `Spell` do esquema de cores muda o ondulado (com ela azul, 54 pixels azuis e nenhum vermelho);
  - o motor lê a cor ao ligar: trocar de esquema com ele ligado muda o papel e não muda o ondulado;
  - por isso a cor (vermelho, azul ou laranja) vai em todos os esquemas do Quill ao abrir, e o perfil passa a ter o esquema do tema como o atual (`CurrentColorScheme`). Sem isso, na primeira vez valeria o esquema do LibreOffice. A preferência avisa que vale na próxima vez que o Quill abrir.
- **O documento no leitor de tela,** sondado na 24.2:
  - com o `setAccessibilityState` ligado, o motor manda o parágrafo do cursor (callback 62: o texto e a posição) e o cursor dentro dele (63). Desligado, não manda nada;
  - a API nova `pqk_set_accessibility` liga e desliga, e o kit religa a cada documento aberto ou trocado;
  - o `DocumentSemantics` (`document_view.dart`) é um campo de texto de várias linhas cujo valor é o parágrafo e cuja seleção é o cursor nele;
  - liga com a preferência ou com um leitor de tela ativo (`accessibleNavigation`), porque custa trabalho ao motor a cada tecla. Os eventos só refazem a vista.
  - O Orca no app de verdade fica para o Francisco conferir à mão.
- **O zoom ao abrir:** 100 %, Ajustar à largura ou Ajustar à página, uma vez por aba.
- **As Preferências** ganharam as seções Geral (a abertura, o zoom ao abrir), Aparência (o tema), Acessibilidade, Privacidade e Atalhos. Só a seção aberta é construída.
- **Dois nós de leitor de tela consertados:** a régua vertical e o controle deslizante do zoom não tinham nó próprio, e o nome deles se juntava ao da janela.

## D-068 · Abrir: o "854 ms" era o dicionário da ortografia, e o trabalho de abrir espera o primeiro ladrilho

A investigação da lentidão ao abrir que o fecho da Fase 2B achou (369 ms na Fase 2, 854 ms no fim da 2B).

- **Onde estava o tempo:** marcando cada chamada do `LokEngine::open`, o pico ficou todo no `initializeForRendering`, que às vezes levava 800 ms (e 5 ms nas outras). Com o `gdb` parando o processo no meio do pico, a thread do kit esperava a trava global do LibreOffice (o SolarMutex). Quem a segurava era a thread principal do LibreOffice, rodando a ortografia automática do capítulo recém-aberto (`SwViewShell::LayoutIdle` → `SwTextFrame::AutoSpell_`), que carregava o dicionário pt-BR (`Hunspell::Hunspell`). Isso acontece uma vez por processo, na primeira verificação de texto. Sem a ortografia (`LOK_ALLOWLIST_LANGUAGES=xx_XX`), os picos de 800 ms sumiram.
- **Não era nenhuma mudança da 2B em si:** nem o callback do escritório (D-066), nem o `SAL_LOG`, nem os documentos que continuam carregados (D-054). Os três foram desligados um de cada vez, e os picos continuaram.
- **O que a medida mostrava:** o carregamento do dicionário às vezes cai antes do "aberto" e às vezes depois, e o bench mede só até o "aberto". Na Fase 2, ele caía depois (o primeiro ladrilho vinha em 709 ms, contra 356 do "aberto"). Medidas lado a lado no mesmo dia, as duas builds do app, alternadas, 4 vezes cada:
  - o "aberto": Fase 2 de 529 a 695 ms, Fase 2B de 574 a 748 ms (o host estava mais lento que na medida do fecho);
  - o **primeiro ladrilho**, que é o que quem escreve sente: Fase 2 ~1320 ms, Fase 2B ~1520 ms. Essa era a perda real, uns 200 ms.
- **A correção:** ao abrir, o Quill pedia ao motor, de uma vez, a cópia do documento (a Estrutura e os estilos, D-044), a lista de fontes, a de estilos e a de idiomas. Tudo isso roda na thread do motor e passava na frente dos ladrilhos. Agora espera o primeiro ladrilho chegar (ou 1 s, sem vista). Depois da correção, o primeiro ladrilho foi a ~1430 ms (Fase 2 a ~1315 na mesma rodada): uns 90 ms recuperados, e ~120 ms ainda acima da Fase 2.
- **Nos testes,** o adiamento é uma opção do `DocumentController` (`deferOpenWork`), ligada no app e na integração. Os testes de unidade e de widget continuam com o trabalho na hora; o `open_work_test` confere o adiamento.
- **O que sobra:** a meta de abrir em 400 ms não se cumpre com o dicionário carregando junto. Carregar o dicionário antes, com o Quill ainda na tela inicial, tiraria os 800 ms do primeiro capítulo aberto depois. Feito depois, com a decisão do Francisco: D-069.

## D-069 · O dicionário carrega na tela inicial

O que sobrou do D-068: o primeiro capítulo aberto esperava ~800 ms pelo dicionário pt-BR. O Francisco decidiu carregar o dicionário logo que o Quill abre, enquanto ele está na tela inicial.

- **Como:** o `DocumentController.preloadSpelling` escreve um documento pequeno (uma frase, com o idioma pt-BR) nas cópias (`$XDG_RUNTIME_DIR`, com o prefixo delas). Ele pede ao motor `pqk_preload_spelling`, e o `LokEngine` abre o documento sem vista nem callback e apaga o arquivo. A ortografia automática do LibreOffice faz o resto na thread principal dele.
- **O documento oculto fecha** quando outro abre (o `LokEngine::open` o destrói antes de carregar). O dicionário fica no serviço de ortografia do processo, e não com o documento. Não há relógio nem thread a mais.
- **Só na tela inicial:**
  - Com outro documento aberto, o motor ignora o pedido. Um segundo documento mudaria a vista atual do LOK.
  - O documento em branco (`startScreen` desligado) não pede: não tem texto para verificar.
  - O `--bench` também não pede, e continua medindo o pior caso.
- **Medido no `lok_script`** (o motor sozinho, o `capitulo-30p.docx`, 2 rodadas):
  - o primeiro ladrilho do capítulo foi de ~1630 ms para ~975 ms;
  - o "aberto" foi de ~840 ms para ~585 ms.
  - Parte do ganho é o Writer, que já fica iniciado; o resto é o dicionário.
- **Memória** (3 rodadas, iguais):
  - com o capítulo aberto, +1 MB anônima e +3 MB de RSS;
  - na tela inicial, +87 MB anônima (de 45 para 132): o Writer e o dicionário carregam antes. É o mesmo custo de abrir qualquer documento, só que adiantado. Abaixo do teto do D-038 e aceito pelo Francisco.
- **Testes:**
  - o `preload_spelling_test` confere o arquivo (o prefixo das cópias e o idioma) e que nada é pedido com documento aberto;
  - a integração pede o dicionário antes do primeiro capítulo, espera o arquivo sumir e abre por cima.

## D-070 · As respostas do fecho da Fase 2B: a tela inicial, a página que não cresce e o plugin "olá"

As três perguntas do `FASE2B-RESULTADOS.md`, respondidas pelo Francisco.

- **A tela inicial continua o padrão** ao abrir o Quill sem um arquivo (D-064). A preferência Geral › "Ao abrir o Quill sem um arquivo" continua para quem quer o documento em branco.
- **O zoom da página sempre compensa o tamanho da interface:**
  - Com a interface a 200 % (D-067), a página continua do tamanho que o zoom diz: 100 % é a folha no tamanho real, como antes de aumentar a interface.
  - O `UiZoom` passa o fator para baixo (`UiZoom.of`), e o `DocumentView` divide o zoom da página por ele. A escala pedida ao motor fica igual (a densidade subiu na mesma proporção), e os ladrilhos continuam nítidos.
  - As réguas leem a mesma geometria e acompanham.
  - Os ajustes à largura e à página medem nos pixels da vista e multiplicam o resultado pelo fator.
  - O `fase2b_a11y_test` confere a 100 e a 200 %: a mesma escala no motor e o mesmo tamanho do ladrilho na tela.
- **O plugin "olá" fica só para os testes:**
  - O app não roda mais o `plugins/ola` ao abrir, e a mensagem "Plugin: olá do Lua" sumiu da barra de status.
  - O plugin continua nos assets: a integração o roda pelo `PluginHost`, como o app rodava, e confere o texto. Os plugins de verdade vêm na Fase 5.


## D-071 · O livro: a pasta `.psitobook`, o importador de DOCX e o fichário

A Etapa 1 da Fase 3. O Francisco escolheu a pasta com um ODT por capítulo, e os livros dele estão em DOCX.

- **O formato:**
  - `livro.json`: o formato e a versão, o título, e a árvore de partes e capítulos, com o status, o rótulo de cor, a sinopse e as palavras de cada capítulo;
  - `capitulos/NNN-slug.odt`: a ordem é a do `livro.json`, e o número é só para quem olha a pasta;
  - `lixeira/`: apagar no fichário move o arquivo para lá, nunca apaga de vez.
  - O `livro.json` é gravado a cada mudança, de forma atômica (escreve ao lado e renomeia).
- **O motor converte sem tocar nas abas:** `pqk_convert(id, src, dst, formato)` abre o arquivo sem vista, salva e fecha. A resposta é o `PQK_EVENT_CONVERTED`, com o número de quem pediu. Sondado no `lok_script`: com um documento aberto e editado no meio, a edição de antes e a de depois ficam nele, e a conversão não muda o ativo. O livro novo usa a mesma chamada, com a origem vazia (um documento novo).
- **O importador:**
  - o motor salva o DOCX em ODT plano nas cópias temporárias;
  - o Dart lê o `office:text` como uma lista de blocos de primeiro nível e corta antes dos títulos do nível escolhido. Cada pedaço leva o cabeçalho inteiro do manuscrito (as fontes, os estilos, os automáticos e as páginas), e o motor o salva em ODT;
  - **o nível sugerido** é o mais alto que dá mais de um capítulo. O `capitulo-30p.docx` só tem títulos de nível 2, e um livro com "Parte I" no nível 1 corta no 2;
  - **os títulos acima do nível** viram partes no fichário. O título da parte e o que vem depois dele ficam no começo do primeiro capítulo da parte, para nada se perder;
  - **o que vem antes do primeiro título** (a dedicatória) vira um capítulo "Abertura", se tiver palavras;
  - a janela mostra os capítulos achados, com as palavras, e o nível para trocar, antes de gravar. Depois mostra o progresso.
- **A sonda do corte** (`livro-teste.docx`, feito pelo motor com listas, nota de rodapé, imagem embutida, tabela e um marcador que atravessa dois capítulos):
  - a nota, a imagem (que vai para `Pictures/` no ODT), a lista e a tabela sobrevivem;
  - **o marcador que atravessa** é jogado fora pelo motor: o começo fica num capítulo e o fim no outro. Agora o começo sozinho vira um marcador de ponto, e o fim sozinho sai. As outras marcas de intervalo (referências, índices) e os comentários que atravessam perdem o fim;
  - **uma lista que continua** depois de um título recomeça a numeração no capítulo novo. Fica assim: cada capítulo é um documento.
- **O leitor de zip é nosso** (`odt_zip.dart`): o diretório central, o cabeçalho local e o deflate cru do `dart:io`. Lê só o `content.xml`, sem pacote novo. O Dart nunca escreve ODT.
- **As palavras** dos capítulos fechados saem do `content.xml`, num isolate. Os fins de parágrafo, as tabulações e os espaços do ODF separam palavras; as outras marcas não. Ficam no `livro.json` com a data do arquivo, e só se reconta o que mudou. Salvar um capítulo reconta o dele. A contagem é a do Quill, não a do LibreOffice, e pode diferir um pouco dela.
- **O fichário:**
  - é o primeiro item do trilho da esquerda, com um livro aberto, e aparece sozinho ao abrir o livro. Ele fica também sem documento aberto, na tela inicial;
  - a lista monta só as linhas visíveis. O clique abre o capítulo numa aba (D-054);
  - arrastar reordena: um capítulo solto logo abaixo de uma parte entra nela, e uma parte vai sempre para o primeiro nível;
  - pelo teclado: as setas andam, Alt+setas movem (na ponta de uma parte, sai dela; ao passar por uma parte, entra), Enter abre, F2 renomeia, Delete manda para a lixeira (com confirmação), e o menu do item abre com a tecla Menu ou Shift+F10;
  - embaixo, o item escolhido: o status (Rascunho, Revisão, Pronto), o rótulo e a sinopse, gravada 600 ms depois de parar de digitar;
  - é memoizado pela `revision` do livro (D-037).
- **Os rótulos de cor** são um token novo, `labels` (vermelho, laranja, verde, azul e roxo), em cada tema.
- **Os fluxos:**
  - os livros entram nos recentes (com o ícone de livro e a data do `livro.json`), e os capítulos não;
  - o título da janela é "Livro — Capítulo";
  - a barra de status mostra as palavras do livro, com o capítulo da tela pela contagem do motor;
  - a tela inicial e os bastidores ganham Novo livro, Abrir livro e Importar um manuscrito, e o menu Livro do Clássico 97 tem todos os comandos;
  - fechar o livro fecha as abas dele, perguntando se há alterações.
- **O `--bench` aceita um livro:** com uma pasta `.psitobook`, abre o livro e mede o primeiro capítulo.
- **A medida** (a build de release, 3 rodadas alternadas, a mediana): o livro de 60 capítulos (o `capitulo-30p` em ODT, 60 vezes), com o primeiro aberto e o fichário na tela, contra o mesmo capítulo avulso.
  - RSS com o capítulo: 448,4 MB no livro e 445,1 MB avulso (+3,3 MB). Depois do `trimMemory`: 443,9 MB nos dois.
  - Abrir: 544 a 759 ms no livro e 552 a 695 ms avulso, dentro do ruído do host.
  - O livro não cresce com o número de capítulos: o que fica na memória é a árvore do `livro.json` e as linhas visíveis do fichário. A recontagem dos 60 capítulos ao abrir roda num isolate, que é solto depois.
  - A meta antiga da seção 8 (≤ 400 MB com o livro) foi escrita antes de medir: o capítulo avulso já está em 445 MB (452 MB no fecho da 2B). O que vale é o livro não somar ao capítulo.
  - O `tool/ab.py` contra a Fase 2B não foi rodado nesta etapa: a abertura de um documento avulso não passa pelo código do livro (ele só escuta o salvar).
- **Os testes:**
  - unidade, `book_test`: o zip, o corte, o `livro.json`, o controlador e o importador com o falso;
  - widget, `fase3_book_test`: o fichário, o teclado, os detalhes, a tela inicial, os recentes e o `binderDrop`;
  - integração, passo 22: importar o DOCX de teste pelo motor, a nota no capítulo, abrir pelo fichário, salvar e recontar.

## D-072 · A Estrutura leva ao título: a vista segue o cursor, e o salto conta as ocorrências

O Francisco viu que, num DOCX, clicar num título da Estrutura não levava até ele.

- **A causa principal: a vista não seguia o cursor.** O salto funcionava no motor: a busca selecionava o título, e a página da barra de status mudava. Mas o `DocumentView` só rolava sozinho na máquina de escrever. Fora dela, o cursor ia para longe e a tela ficava parada. O mesmo valia para o Localizar e para as setas na beira da página. O passo 2d da integração não pegou, porque conferia a página do motor, não a rolagem.
  - **Agora,** quando o cursor muda e sai da área, a vista rola até ele. Perto, só o bastante para caber, com uma margem de 16 px. Longe (mais de uma tela), com ele no meio.
  - Rolar com a roda não move o cursor, então não puxa a vista de volta. Trocar de aba guarda a rolagem da aba (D-054), sem saltar ao cursor.
- **A segunda causa: o salto parava no lugar errado.** A busca do texto do título, a partir do cursor, para no primeiro parágrafo com aquele texto. Isso pode ser um parágrafo que cita o título, outro título igual, ou "Cena 10" quando o título é "Cena 1" (o capítulo de teste tem os dois).
  - **Agora,** a cópia conta, para cada título, quantas vezes a chave de busca dele aparece no texto antes dele. O salto vai ao começo (`.uno:GoToStartOfDoc`, sondado na 24.2) e procura uma vez a mais que isso.
  - **A chave** é o texto do título como está no parágrafo, até a primeira tabulação ou quebra de linha, porque a busca do motor não acha pelo espaço que a Estrutura mostra. As notas de rodapé dentro do título ficam de fora.
  - As respostas dessas buscas não acendem o Localizar nem marcam as ocorrências.
- **Um travamento ao abrir, achado no meio:** o teste de ponta a ponta caiu uma vez com SIGSEGV em `getenv`, dentro do fontconfig, na thread do GTK. O motor definia o `LOK_ALLOWLIST_LANGUAGES` e o `SAL_LOG` com `setenv` na thread dele enquanto o GTK lia o ambiente, e o `setenv` com outra thread lendo derruba o processo. Os despejos de 22/11 eram parecidos.
  - **Agora,** o `main` do app chama o `pqk_prepare_environment()` antes de qualquer thread. No motor, o `setenv` sem sobrescrever não escreve nada quando a variável já existe, e continua lá para as ferramentas.
  - Depois disso, o fechamento passou 5 vezes em 5, mas uma falha às vezes não se prova com repetições.
- **Os testes:**
  - `fodt_test`: a chave, as ocorrências (com "Cena 10", um título repetido, a tabulação e a nota);
  - `fase2b_pages_test`: o salto manda o começo e a busca sem acender o Localizar, e a vista rola até o cursor longe, sem puxar de volta depois da roda;
  - integração, passo 2d: o título com mais ocorrências antes dele fica selecionado, exatamente ele.

## D-073 · O salvamento automático numa cópia de recuperação

Fase 3, Etapa 2. O motor roda dentro do processo: se o LibreOffice cai, o Quill cai junto, e perde-se o que não foi salvo.

- **A cópia é a do D-044:** o `exportCopy` em ODT, que não muda o documento, o caminho nem o "modificado". O motor grava, e o Dart só troca o nome do arquivo e escreve um JSON pequeno ao lado.
- **Onde:** `~/.config/psito-quill/recuperacao/`, uma pasta só do usuário (700), nunca ao lado do arquivo. Por aba: `<sessão>-<aba>.odt` e `<sessão>-<aba>.json`, com o arquivo de onde veio, o nome que a aba mostrava ("Dustland — A poeira", no livro) e a hora.
  - A sessão é um carimbo da hora de abrir o Quill, não o pid: o pid se repete depois de reiniciar o computador.
  - O motor grava ao lado (`.gravando.odt`), e só o `rename` troca a cópia. Uma queda no meio não estraga a cópia anterior, e uma gravação pela metade some ao listar.
- **Quando:** depois de uma alteração, conta 60 s. Se a pessoa digitou nos últimos 2 s, espera uma pausa de 2 s, porque a cópia ocupa a fila do motor e a tecla espera atrás dela. Sem alteração, não grava nada. O cronômetro é um `Timer` só, que não refaz a interface.
  - A sonda no `lok_script` (24/11): a cópia leva ~0,27 s no capítulo de 30 páginas e ~0,65 s num documento de 300 páginas (a primeira, ~1,6 s).
  - Sair de uma aba com alterações (trocar, ou abrir outra) grava a cópia dela na hora. Ela vai para a fila antes da troca, então é do documento certo.
  - "Alteração" é a digitação, um comando do motor pelo `uno` ou o "modificado" ligando. Se o "modificado" desligou (desfez tudo), a cópia sai: o arquivo já é o documento.
- **Quando sai:** salvar a aba, fechar a aba e sair do Quill apagam as cópias da sessão. Uma aba que fecha no meio de uma gravação não deixa cópia. Desligar a preferência também apaga as da sessão.
- **Recuperar:** o que sobra na pasta é de uma sessão que caiu. A tela inicial mostra "Recuperar arquivos" antes dos cartões, com o nome, a pasta e a hora de cada cópia. Mesmo com a preferência "documento em branco", o Quill abre na tela inicial quando há cópias.
  - **Recuperar** abre a cópia como um documento novo: sem arquivo, "(recuperado)" no nome e modificado até ser salvo, para fechar perguntar. Salvar sugere o nome e a pasta de onde veio, sem sobrescrever sozinho. A cópia abre no lugar e fica até a aba ser salva ou fechada, ou até a primeira cópia nova dela (que tem tudo).
  - **Descartar** pergunta antes e apaga. As cópias que a pessoa não escolheu ficam para a próxima vez: nenhuma sai sem ela decidir.
- **A preferência:** Preferências › Geral › Salvamento automático, ligada por padrão. O `--bench` não grava cópias.
- **A memória:** nada novo fica na memória além de um `Timer` e de um mapa das gravações na fila (uma por aba, no máximo). O texto vai do motor para o disco sem passar pelo Dart. O `tool/ab.py` não foi rodado: o `--bench` não liga a recuperação, e a cópia em si é o mesmo `saveAs` das cópias do D-044, que o motor solta ao terminar.
- **Os testes:**
  - unidade, `recovery_test`: a pasta (as sessões, a gravação pela metade), o intervalo e a pausa, salvar e fechar, trocar de aba, desfazer tudo, desligar, a aba que fecha no meio, recuperar (o documento novo, o nome sugerido, a cópia que sai), descartar e sair;
  - widget, `fase3_recovery_test`: a lista na tela inicial, o nome para o leitor de tela, Recuperar e o "(recuperado)" no título, e Descartar com a pergunta;
  - integração, passo 23: a cópia do motor é um ODT com o texto novo, o documento segue no mesmo arquivo e modificado, e a cópia recuperada abre editável, sem arquivo.

## D-074 · O papel escuro desenhado pelo Quill: a luminosidade invertida, o tom mantido

O Francisco viu, no modo escuro, o texto de um DOCX quase sumir no papel escuro, e os cartões de estilo da faixa também.

- **A causa:** o esquema escuro do LibreOffice (`PsitoQuillEscuro`) só troca a cor do texto **automático**. Esse DOCX pinta o corpo com uma cor fixa (um cinza-escuro), que fica escura no papel escuro. Os títulos vermelhos apareciam porque o vermelho é claro o bastante.
- **As opções, sondadas no `lok_script` (24/11):**
  - a opção do LibreOffice "cor automática para o texto na tela" (`Accessibility/IsAutomaticFontColor`) clareia o cinza, mas apaga todas as cores: o vermelho dos títulos foi a 0 pixels;
  - **a escolhida, pelo Francisco:** o motor pinta o papel claro, e o plugin nativo inverte a luminosidade de cada ladrilho mantendo o tom.
- **A conta** (`LokEngine::invertPixels`, ao copiar o ladrilho para a vaga, na thread do kit):
  - a luminosidade de cada pixel vai por uma reta: a do papel claro do motor vira a cor do papel do tema escuro, e o preto vira a tinta do tema;
  - a diferença de cada canal para a luminosidade é somada de volta, então o tom fica: o vermelho escuro vira um vermelho claro, e o cinza-escuro, um cinza-claro;
  - os pixels transparentes (fora das páginas) não mudam, e os meio transparentes são tirados do pré-multiplicado e postos de volta.
  - Com o documento de teste: o papel virou o do tema, o cinza #333 virou ~#ccc e o vermelho #c00000 virou ~#ff8080.
- **Os temas:** um tema escuro pede ao motor o esquema do tema claro irmão (o Escuro pede o Claro; o Alto contraste escuro, o Alto contraste claro) e liga a inversão com o papel e a tinta dele (`enginePaper`, `pqk_set_paper_invert`). Os temas claros não invertem. O modo zen com o papel escuro usa o tema Escuro e vem junto.
- **Os cartões de estilo da faixa** usam a mesma conta em Dart (`PaperInvert.apply`), para mostrar a cor como a página mostra.
- **O preço:**
  - as imagens do documento também ficam invertidas no modo escuro (como num "modo leitura escura" de navegador). O arquivo não muda;
  - o ondulado da ortografia vem invertido junto (um vermelho mais claro).
  - **A memória:** nenhuma; a tabela tem 768 bytes. A conta é um laço sobre os 65.536 pixels de cada ladrilho pintado, na thread do kit, depois do `paintTile` do motor (que custa muito mais).
- **Os testes:** `paper_invert_test.cc` (o papel, a tinta, o cinza, o vermelho, o transparente e o meio transparente), `paper_invert_test.dart` (a mesma conta em Dart e o mapa dos temas) e o `fase2b_a11y_test` (o tema escuro manda o esquema claro e a inversão).

## D-075 · A página do livro: o cabeçalho, os campos, a hifenização e a capitular, e os estilos mudados pela cópia

A Fase 3, Etapa 3. Os itens vieram do OnlyOffice (os prints do Francisco): o cabeçalho e o rodapé, o número da página e os campos, a primeira página e as pares diferentes, a hifenização, a capitular e as quebras.

- **O que a 24.2 faz pelo `.uno:`** (sondado no `lok_script`, 24/11):
  - `.uno:InsertPageHeader` e `.uno:InsertPageFooter` com `{"On":true}` e **sem** o nome do estilo ligam em todos os estilos de página, e o cursor vai para o cabeçalho. Com o nome do estilo (`PageStyle`), não fazem nada;
  - `.uno:JumpToHeader` e `.uno:JumpToFooter` levam o cursor até ele;
  - os campos: `.uno:InsertPageNumberField`, `.uno:InsertPageCountField`, `.uno:InsertDateField` e `.uno:InsertTimeField`;
  - a hifenização de um parágrafo: `.uno:SetHyphenZone` com o booleano (formatação direta);
  - `.uno:InsertColumnBreak` funciona.
- **O que não funciona pelo `.uno:`:**
  - com `On:false`, o motor abre a janela "apagar o cabeçalho?" e o LOK trava;
  - `.uno:Hyphenate` trava (a janela da hifenização);
  - `.uno:FormatDropcap` com argumentos que ele não conhece também trava, e sem eles abre a janela;
  - `InsertBlankPage`, `InsertSection`, `InsertBreak` e `InsertTitleField` não fazem nada na 24.2. A página em branco são duas quebras de página.
- **O caminho que sobra: mudar os estilos pela cópia** (`style_patch.dart`, `PageFormat.patchStyles`):
  1. o motor grava a cópia FODT do documento, a mesma do D-044;
  2. o Dart, num isolate, tira o texto dela (`stylesOnly`: o capítulo de 30 páginas vai de ~1 MB a ~30 KB) e muda só o XML que precisa;
  3. o motor converte o FODT para ODT (`KitConverter`, D-071), porque o `.uno:LoadStyles` não lê o FODT;
  4. o `.uno:LoadStyles` com os tipos (`Flags`: parágrafo 1, página 4) e a sobrescrita (16) carrega os estilos por cima. Como a cópia tem todos os estilos do próprio documento, os outros voltam iguais.
  - **A vista certa** (achado na integração): o `postUnoCommand` despacha pelo quadro "atual" do LibreOffice, que é global. Depois da conversão (o motor abre o FODT oculto, salva e fecha), esse quadro deixa de ser o do documento, e o `LoadStyles` não fazia nada, em silêncio. Agora o `LokEngine` guarda a vista de cada documento ao abrir (`getView`) e chama o `setView` ao ativar uma aba e antes de cada `postUnoCommand` e `getCommandValues` (`focusView`). Isso também protege as abas (D-054) e o documento oculto do dicionário (D-069).
  - Uma cópia a mais, depois do `LoadStyles` na fila, diz quando ele terminou, e refaz a Estrutura, os estilos e o estado da página (`FodtSnapshot.page`, `parsePageSetup`). As cópias temporárias são apagadas.
  - **O tempo:** a cópia ODT do capítulo de 30 páginas leva ~0,27 s, e a de 300 páginas ~0,65 s. Somado à cópia FODT, uma mudança leva perto de 1 s num livro grande. Não é para digitar, mas é aceitável para um botão.
  - **O preço:** essas mudanças não passam pelo desfazer do motor (o `LoadStyles` não entra no Ctrl+Z). O caminho certo é a API UNO, que o LOK não expõe sem um script Basic ou Python, e eles estão desligados no perfil por privacidade e segurança.
- **As mudanças:**
  - **desligar o cabeçalho (ou o rodapé):** tira o bloco de todos os estilos de página, com as versões da primeira página e das pares, e o espaço dele no leiaute;
  - **a primeira página diferente:** um `style:header-first` (e `footer-first`) vazio onde houver cabeçalho;
  - **as pares diferentes:** um `style:header-left` que começa igual ao das ímpares;
  - **a hifenização do documento:** liga no estilo padrão de parágrafo e nos estilos que a desligavam por conta própria, menos os títulos (os de nível de estrutura), que não se hifenizam;
  - **a capitular** é do parágrafo, e o Writer só a muda pelo estilo ou pela janela. Então o Quill cria um estilo filho do estilo do parágrafo, "Corpo de texto · capitular 2", com a capitular, e o aplica. Tirar a capitular volta ao estilo de base. O estilo fica no documento.
  - O nome do estilo pai sai da própria cópia (`paragraphStyleXmlName`), porque o LibreOffice guarda as letras com acento no nome do XML ("Citação") e codifica o resto ("Text_20_body").
- **A interface:** a aba Inserir ganhou os grupos Páginas, Cabeçalho e rodapé, Notas, Links e Tipografia; a aba Layout, a Hifenização. Tudo também no menu Clássico 97 (Inserir e Formatar).
- **Os testes:** `style_patch_test.dart` (o XML de cada mudança), `fase3_page_test.dart` e o passo 24 da integração (ligar, mudar e desligar no motor real, e o ODT salvo).

## D-076 · O PDF, a impressão, as notas, os links e os caracteres especiais

A Fase 3, Etapa 4.

- **O PDF:** a cópia do D-044 no formato `pdf` (`exportTo`), com a janela de onde gravar (`pickExportPdf`). Os títulos viram marcadores do PDF, como o motor faz.
- **Imprimir (Ctrl+P):**
  - o motor grava um PDF temporário, e o plugin nativo abre a janela de impressão do GTK (`GtkPrintUnixDialog`, sem bloquear) e manda o PDF pronto à impressora (`GtkPrintJob`, `pqk_print_pdf`). O resultado volta como `PQK_EVENT_PRINTED` ("ok", "cancelado" ou o erro), e o PDF é apagado em todos os caminhos;
  - **o preço:** a janela não tem prévia, porque o GTK só mostra a prévia quando ele mesmo desenha as páginas. Uma impressora que não aceita PDF recebe um aviso.
  - A impressão é local (a fila do CUPS), sem rede do Quill.
- **As notas:** `.uno:InsertFootnote` (Ctrl+Alt+F) e `.uno:InsertEndnote` (Ctrl+Alt+D), os atalhos do Word. `.uno:JumpToFootnoteOrAnchor` vai do número ao texto e de volta.
- **Os links:**
  - **inserir e trocar:** `.uno:SetHyperlink` com o texto e o endereço; tirar: `.uno:RemoveHyperlink`;
  - **saber se o cursor está num link:** o callback 7 (`LOK_CALLBACK_HYPERLINK_CLICKED`) não chegou nas sondas. O que funciona é ligar o `LOK_FEATURE_VIEWID_IN_VISCURSOR_INVALIDATION_CALLBACK` no `LokEngine::init`: o callback 1 passa a ser um JSON com o `hyperlink` do cursor (`parseCursorLink`, `DocumentController.link`);
  - **Ctrl+clique:** como no Word. Um clique simples leva o cursor; se ele parar num link, o Quill **pergunta antes de abrir** ("Abrir o link?", com o endereço) e só então chama o `xdg-open`. Senão, faz a seleção da frase de sempre (o clique triplo do motor). O Quill não abre nada sozinho;
  - **só a web e o e-mail** (`http`, `https`, `mailto`). Um link `file:` levaria o `xdg-open` a rodar um script ou um `.desktop` do disco, então ele não abre, com um aviso.
- **Os caracteres especiais:** uma janela com os 46 mais usados num livro (o travessão, as aspas curvas, as reticências, o espaço sem quebra, o hífen opcional, as setas, os símbolos), com a busca pelo nome sem acento. A lista é fixa e pequena, sem a tabela Unicode inteira (que pesaria na memória e não ajuda quem escreve).
- **As aspas curvas e o travessão automáticos:** o autocorrigir do LibreOffice só age nas teclas, e o texto do IME chegava como `LOK_EXT_TEXTINPUT`, que ele não vê. Agora um caractere confirmado sozinho, sem pré-edição, vai ao motor como tecla (`postKey`). A composição do IME (`´` + `a`) continua pelo `TextInput`. Com uma imagem selecionada, a letra continua como texto: o Writer ignora a tecla nesse caso, e o texto tira a seleção e digita (o passo 21 da integração pegou isso). O "completar palavras" do LibreOffice ficou desligado no perfil, porque com as teclas ele passaria a sugerir no meio do texto.
  - **A memória** (`tool/ab.py f546027`, mediana de 3, 24/11): abrir, rolar e a latência da tecla ficaram iguais, mas **depois de digitar a memória anônima subiu +8,9 MB**. É o autocorrigir do motor, que só acorda com as teclas e carrega as regras dele: no `lok_script`, 60 palavras digitadas como teclas custam +2,6 MB de memória anônima (+5,7 MB de RSS) a mais que como texto. O resto deve ser ruído (só rolar variou +3,4 MB). **Aceito:** a outra saída seria o Quill fazer as aspas e o travessão sozinho, sem o custo, mas ele não sabe a letra antes do cursor depois de um clique no meio do texto, e a aspa de abrir e a de fechar sairiam trocadas.
- **Os testes:** `fase3_page_test.dart` (a impressão, a nota, o caractere especial, a janela do link, a pergunta e o `file:` recusado), o `document_view_test` (a letra vai como tecla) e o passo 24 da integração (a nota, o link no cursor, o ODT e o PDF).
