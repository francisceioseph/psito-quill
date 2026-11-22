# Psito Quill

Editor de texto para livros longos (*Dustland*, *Silicon Gods*), em Flutter, para Linux. Leia o `docs/PLANO.md` antes de qualquer coisa. Ele tem as decisões, as fases e as perguntas em aberto.

- **O motor** é o LibreOfficeKit do sistema (`/usr/lib/libreoffice/program`), num plugin nativo próprio: `packages/psito_quill_kit`.
  - Só a thread do kit (`pqk-kit`, a `TaskQueue` em `linux/core/`) chama o LOK. O Dart nunca chama o LOK direto: chama a API C `pqk_*` (`quill_kit_api.h`), que só põe uma tarefa na fila.
  - As respostas voltam por um `NativeCallable.listener` como `RawKitEvent`. O `LokQuillKit` (`lib/src/kit/lok/`) traduz para os `KitEvent` da porta `QuillKit`.
- **Os ladrilhos** são vagas fixas da `TileCache` (256×256, 128 por padrão), e cada vaga é uma `FlPixelBufferTexture`.
  - O `DocumentView` posiciona as texturas pela grade em twips, com as bordas arredondadas como no nativo (`tileRectTwips`).
  - Redesenhar no lugar não passa pelo Dart. O evento `PQK_EVENT_TILE` só chega quando uma vaga muda de ladrilho.
- **O cursor, a seleção e a entrada são do Flutter.** O cursor pisca sem tocar no motor. As teclas passam primeiro pelo `CommandRegistry` (atalhos), e o resto vai pelo `vclKeyFor` (os códigos do VCL estão em `vcl_keys.dart`).
- **O perfil do LibreOffice é só do Quill** (`LoProfile`, em `~/.config/psito-quill/lo-profile`). Ele registra os esquemas `PsitoQuillClaro` e `PsitoQuillEscuro`, com as cores dos tokens, e o papel troca pelo `.uno:ChangeTheme`.
  - Na 24.2, o `.uno:ChangeTheme` responde `success: false` mesmo funcionando, e não invalida os ladrilhos. Depois dele vem o `repaintAll`.
- **A trava `.~lock`:** o LibreOffice deixa uma ao lado do arquivo aberto. Um arquivo travado por outro perfil abre só para leitura, em silêncio. Feche o documento antes de sair (`DocumentController.close`, que o `onExitRequested` já chama). Testes e medições trabalham numa cópia do documento.
- **O Lua 5.4** roda em `LuaSandbox` (`linux/core/lua_sandbox.cc`), na thread `pqk-lua`.
  - Tem teto de memória pelo alocador e limite de instruções pelo hook. Depois do limite, o hook roda a cada instrução, para um `pcall` não engolir a interrupção.
  - Sem `io`, `os`, `package`, `debug`, `dofile`, `loadfile`, `collectgarbage` e `string.dump`. O `load` aceita só texto.
- **Os bindings do ffigen** ficam em `packages/psito_quill_kit/lib/src/quill_kit_bindings.g.dart`. Depois de mudar o `quill_kit_api.h`, rode `dart run ffigen --config ffigen.yaml` em `packages/psito_quill_kit`.
- **As medições** são o `tool/bench.sh`, que roda o `lok_probe` (motor sozinho) e o `psito-quill --bench` (app inteiro). Os resultados estão em `docs/FASE0-RESULTADOS.md`.

## Regras

- **Padrões conhecidos**, dizendo qual e por quê (a tabela está no `docs/ARCHITECTURE.md`). Toda decisão nova vai no `docs/DECISOES.md`.
- **Atomic design com tokens** (`lib/src/ui/`). Os widgets leem só o `QuillTokens.of(context)`. Nenhuma cor literal fora de `lib/src/ui/tokens/themes/`, e o `tokens_test` confere.
- **Nenhum texto que quem usa lê fica no código:** vai para `lib/l10n/app_pt.arb` (o modelo) e `app_en.arb`.
- **Todo clique tem nome para o leitor de tela e caminho pelo teclado.** Os átomos já fazem isso: `Semantics`, `Tooltip` e `FocusableActionDetector`.
- **Testes:** `./test.sh` roda a unidade, o widget e o nativo. `./test.sh --integracao` inclui o LibreOffice real, e abre uma janela.
  - O host tem pouca RAM: o script já limita a 2 processos e 2 GB.
  - Rode `flutter analyze` depois de editar Dart.
- **Nunca mexa no mouse ou no teclado da sessão do usuário** (xdotool) para testar. A janela ativa pode ser outra. Use o `--bench`, o `integration_test` ou o `wmctrl -i -c` com o id da janela do próprio processo.
- **O Quill não conhece o Psito OS.** Não mexa no `psito-os` sem autorização.
- **Commit e push só quando o Francisco pedir.** Os commits terminam com o `Co-Authored-By` do Claude.
- **Na dúvida sobre o produto, pergunte.** As perguntas abertas estão na seção 12 do plano.
