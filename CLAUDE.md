# Psito Quill

Editor de texto para livros longos (*Dustland*, *Silicon Gods*), em Flutter, para Linux. Leia o `docs/PLANO.md` antes de qualquer coisa. Ele tem as decisões, as fases e as perguntas em aberto.

- **O motor** é o LibreOfficeKit do sistema (`/usr/lib/libreoffice/program`), num plugin nativo próprio: `packages/psito_quill_kit`.
  - Só a thread do kit (`pqk-kit`, a `TaskQueue` em `linux/core/`) chama o LOK. O Dart nunca chama o LOK direto: chama a API C `pqk_*` (`quill_kit_api.h`), que só põe uma tarefa na fila.
  - As respostas voltam por um `NativeCallable.listener` como `RawKitEvent`. O `LokQuillKit` (`lib/src/kit/lok/`) traduz para os `KitEvent` da porta `QuillKit`.
- **Os ladrilhos** são vagas fixas da `TileCache` (256×256), e cada vaga é uma `FlPixelBufferTexture`. O número de vagas sai do tamanho do maior monitor (`tileSlotsFor`: 72 numa tela de 1920×1080), e a área pedida ao motor é só a do documento, sem os lados vazios.
  - O `DocumentView` posiciona as texturas pela grade em twips, com as bordas arredondadas como no nativo (`tileRectTwips`).
  - Redesenhar no lugar não passa pelo Dart. O evento `PQK_EVENT_TILE` só chega quando uma vaga muda de ladrilho.
- **O cursor, a seleção e a entrada são do Flutter.** O cursor pisca sem tocar no motor. As teclas passam primeiro pelo `CommandRegistry` (atalhos). Depois, o `routeKey` decide:
  - setas, Enter, Backspace e F-teclas vão ao motor pelo `vclKeyFor` (os códigos do VCL estão em `vcl_keys.dart`);
  - o texto vem pelo `TextInput` do sistema (o IME do GTK, que faz `´` + `a` virar `á`), e o `DocumentView` é o `TextInputClient`. A pré-edição vai como `LOK_EXT_TEXTINPUT`; a confirmação, como `LOK_EXT_TEXTINPUT` com o texto final e um `LOK_EXT_TEXTINPUT_END` vazio (o `END` ignora o texto);
  - Ctrl+letra que não é atalho do Quill é engolida: os atalhos são só os do jogo escolhido.
- **Os fluxos de arquivo** (novo, abrir, salvar, salvar como, recentes, sair) ficam no `Workspace` (`lib/src/document/workspace.dart`). As janelas de arquivo são a porta `FileDialogs`, e o título da janela é a porta `AppWindow` (`pqk_set_window_title`).
- **O perfil do LibreOffice é só do Quill** (`LoProfile`, em `~/.config/psito-quill/lo-profile`). Ele registra os esquemas `PsitoQuillClaro` e `PsitoQuillEscuro`, com as cores dos tokens, e o papel troca pelo `.uno:ChangeTheme`.
  - Na 24.2, o `.uno:ChangeTheme` responde `success: false` mesmo funcionando, e não invalida os ladrilhos. Depois dele vem o `repaintAll`.
- **A trava `.~lock`:** o LibreOffice deixa uma ao lado do arquivo aberto. Um arquivo travado por outro perfil abre só para leitura, em silêncio. O `LockInspector` (`lib/src/files/lo_lock.dart`) olha antes de abrir:
  - uma trava do nosso perfil, nesta máquina, é velha (o perfil só aceita um processo, e ele é o nosso): apaga;
  - qualquer outra abre só para leitura, com o aviso e o "Salvar uma cópia".
  - Feche o documento antes de sair (o `onExitRequested` chama o `Workspace.requestExit`). Testes e medições trabalham numa cópia do documento.
- **O Lua 5.4** roda em `LuaSandbox` (`linux/core/lua_sandbox.cc`), na thread `pqk-lua`.
  - Tem teto de memória pelo alocador e limite de instruções pelo hook. Depois do limite, o hook roda a cada instrução, para um `pcall` não engolir a interrupção.
  - Sem `io`, `os`, `package`, `debug`, `dofile`, `loadfile`, `collectgarbage` e `string.dump`. O `load` aceita só texto.
- **Os bindings do ffigen** ficam em `packages/psito_quill_kit/lib/src/quill_kit_bindings.g.dart`. Depois de mudar o `quill_kit_api.h`, rode `dart run ffigen --config ffigen.yaml` em `packages/psito_quill_kit`.
- **Antes de usar um comando `.uno:` novo, pergunte ao motor** com o `lok_script` (`linux/tools/lok_script.cc`, D-029): na 24.2, muitos respondem `success: false` e funcionam, e outros não fazem nada (`StyleDelete`, `ULSpacing` com valores). Confira pelo estado, não pelo `success`.
- **A ortografia precisa da `LOK_ALLOWLIST_LANGUAGES`** (o `LokEngine::init` define). As sugestões vêm no menu de contexto do motor (callback 23), que o Quill desenha (D-033).
- **As medições** são o `tool/bench.sh`, que roda o `lok_probe` (motor sozinho) e o `psito-quill --bench` (app inteiro), com saída em `build/medicoes/`. Os resultados estão em `docs/FASE0-RESULTADOS.md`, `docs/FASE1-RESULTADOS.md`, `docs/FASE2-RESULTADOS.md` e `docs/FASE2B-RESULTADOS.md`. A memória varia uns 20 MB entre execuções: rode mais de uma vez e use a mediana. Para comparar uma etapa, use o `tool/ab.py <commit-anterior>`, que mede as duas builds lado a lado no mesmo dia; rode-o numa `git worktree` do commit novo se for continuar editando enquanto ele mede.
- **A `EditorPage` memoiza a faixa e o painel Formatar** pela `stateRevision` do controlador (D-037). Algo novo que eles leiam e não venha do motor entra na chave, ou o widget fica velho.
- **Os dois callbacks do LOK:** o de cada documento e o do escritório (`LokEngine::officeCallback`), que traz o progresso de abrir (9 a 11). O do escritório responde "sem senha" na hora a um pedido de senha, senão o motor espera para sempre (D-066).
- **Ocupado:** abrir e salvar travam a tela pelo `DocumentController.busy` e pelo `BusyScope` (D-066). Entrada nova de teclado ou texto precisa respeitar o `busy`.
- **O livro** (`lib/src/book/`, D-071) é uma pasta `.psitobook`: o `livro.json` (a árvore, gravada de forma atômica a cada mudança) e um ODT por capítulo em `capitulos/`. O `BookController` fica no `Workspace` (`workspace.book`), e os capítulos abrem como abas.
  - O motor converte sem tocar nas abas (`pqk_convert`, `PQK_EVENT_CONVERTED`): o importador e o capítulo novo passam por ele. O Dart nunca escreve ODT.
  - Os capítulos fechados são lidos pelo `content.xml` (o leitor de zip `odt_zip.dart`, num isolate), sem abrir no motor.
- **O salvamento automático** (D-073): a cada 60 s com alterações, numa pausa de 2 s da digitação, o `exportCopy` grava um ODT em `~/.config/psito-quill/recuperacao/` (o `RecoveryStore`, `lib/src/document/recovery.dart`). Salvar, fechar a aba e sair apagam; o que sobra é de uma queda, e a tela inicial oferece. A cópia recuperada abre sem arquivo e modificada (`DocumentController.recovered`).
- **O dicionário carrega na tela inicial:** o motor abre um documento oculto de uma frase (`preloadSpelling`), que fecha quando outro abre (D-069). O `--bench` não faz isso, para medir o pior caso.
- **O leitor de tela** recebe o parágrafo do cursor pelos callbacks 62 e 63, só com a acessibilidade ligada (`pqk_set_accessibility`, D-067). O `DocumentSemantics` é o nó do documento.
- **O tamanho da interface** é o `UiZoom` (D-067): a interface inteira é montada menor e desenhada ampliada, com a densidade de pixels multiplicada. O `textScaler` fica em 1; não use o tamanho do texto para crescer controles. A página não cresce junto: o `DocumentView` divide o zoom pelo `UiZoom.of` (D-070).

## Regras

- **Memória como um programador chato dos anos 2000** (RAM está cara e escassa). Toda coisa nova:
  - não refaz a interface sem necessidade (nada de `notifyListeners` por ladrilho, cursor ou tique de relógio; memoize o que é pesado, como no D-037);
  - não guarda cache, widget ou lista "por via das dúvidas", e não traz dependência pesada;
  - é medida com o `tool/bench.sh` antes e depois (mediana de 3). Crescer mais de ~5 MB pede um motivo e uma decisão no `DECISOES.md`. Para achar a causa, use o `tool/mapas.py` (a memória anônima por tipo de mapeamento, não só o RSS) e compare com a build anterior no mesmo dia, numa cópia do commit anterior (`git worktree`): os números absolutos mudam uns 20 MB de um dia para outro (D-038).
- **Privacidade total:** sem rede, sem telemetria, sem arquivo de log. Tudo fica no computador. O perfil do LibreOffice desliga os relatórios de falha, a coleta de uso e os logs. Uma IA, se vier, roda local e começa desligada.
- **Padrões conhecidos**, dizendo qual e por quê (a tabela está no `docs/ARCHITECTURE.md`). Toda decisão nova vai no `docs/DECISOES.md`.
- **Atomic design com tokens** (`lib/src/ui/`). Os widgets leem só o `QuillTokens.of(context)`. Nenhuma cor literal fora de `lib/src/ui/tokens/themes/`, e o `tokens_test` confere.
- **Nenhum texto que quem usa lê fica no código:** vai para `lib/l10n/app_pt.arb` (o modelo) e `app_en.arb`.
- **Todo clique tem nome para o leitor de tela e caminho pelo teclado.** Os átomos já fazem isso: `Semantics`, `Tooltip` e `FocusableActionDetector`.
- **Testes:** `./test.sh` roda a unidade, o widget e o nativo. `./test.sh --integracao` inclui o LibreOffice real, e abre uma janela.
  - O host tem pouca RAM: o script já limita a 2 processos e 2 GB.
  - Rode `flutter analyze` depois de editar Dart.
- **Nunca mexa no mouse ou no teclado da sessão do usuário** (xdotool) para testar. A janela ativa pode ser outra. Use o `--bench`, o `integration_test` ou o `wmctrl -i -c` com o id da janela do próprio processo.
- **Nunca capture a tela** (`xwd`, `import`, `gnome-screenshot`), nem só "a janela do Quill". No X11, a captura copia o que está na tela naquele lugar, e a janela pode estar coberta por outra do usuário (aconteceu duas vezes). Para conferir pixels, use o `pqk_debug_tiles_luma` ou os PPMs do `lok_probe`.
- **O Quill não conhece o Psito OS.** Não mexa no `psito-os` sem autorização.
- **Commit e push só quando o Francisco pedir.** Os commits terminam com o `Co-Authored-By` do Claude.
- **Na dúvida sobre o produto, pergunte.** As perguntas abertas estão na seção 12 do plano.
