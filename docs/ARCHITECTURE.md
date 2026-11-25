# Arquitetura

O plano completo está no `PLANO.md`. Este documento descreve o que existe no código e os padrões usados.

## As camadas

```
Flutter (Dart)
  pages       EditorPage
  templates   EditorTemplate (abas de documentos, faixa ou menus 97, aviso, trilhos, painéis, régua,
              corpo, status, o véu de ocupado), UiZoom (o tamanho da interface)
  organisms   DocumentView (a página e o DocumentSemantics), Ribbon, ClassicMenuBar, ClassicToolbars,
              Inspector (Formatar), NavRail, OutlinePanel, StylesPanel, FindPanel, CommandPalette
              (a busca única), FontPicker, Ruler, DocTabStrip, ZenView, BusyScope, menu de contexto,
              diálogos (estilos, tabela, "salvar?"), FilePanel (os bastidores), StartScreen,
              RecentList, PreferencesView, StatusBar
  molecules   CommandButton, CommandMenu, CommandCheck, AdaptiveRibbon, RibbonGroup, StyleCard,
              SidePanel, PanelAction, InspectorSection, MeasureField, ColorMenuButton, InfoBanner
  atoms       WButton, WToggle, WTextButton, WBigButton, WDropdown, WTextField, WSegmented, WSwitch,
              WSlider, WChip, WColorSwatch, WLabel, WSeparator
              ← só leem QuillTokens
  ─────────────────────────────────────────────
  fluxos      Workspace (novo, abrir, salvar, recentes, abas, sair)
  estado      DocumentController (com as abas, a Estrutura, a busca, o ocupado e a acessibilidade),
              CommandRegistry, Settings, RecentFiles, PluginHost
  portas      QuillKit ← LokQuillKit (FFI) | FakeQuillKit (testes)
              FileDialogs, TextClipboard, AppWindow, e o LockInspector (a trava)
                      │
          dart:ffi + NativeCallable.listener
                      │
packages/psito_quill_kit (C++)
  quill_kit_api.h      a API C (pqk_*), assíncrona
  plugin.cc            texturas (FlPixelBufferTexture) e o registro
  core/                sem GTK nem Flutter:
    task_queue         a thread do kit ("pqk-kit") e a de plugins ("pqk-lua")
    lok_engine         o LibreOfficeKit atrás da fila
    tile_cache         vagas de ladrilho, LRU, memória fixa
    lua_sandbox        um lua_State com teto e limite de instruções
```

## As threads

| Thread | Quem | Faz |
|---|---|---|
| UI / plataforma | Flutter | Widgets e entrada. Só chama `pqk_*`, que põem uma tarefa na fila e voltam na hora |
| `pqk-kit` | `TaskQueue` | É a única que chama o LOK: abrir, teclas, `paintTile`, salvar |
| LibreOffice | o LOK | Roda o laço principal dele e chama os nossos callbacks (o de cada documento e o do escritório, com o progresso, D-066). O callback só repassa o evento e põe trabalho na fila |
| `pqk-lua` | `TaskQueue` | Roda os plugins na caixa de areia |
| raster | Flutter | Chama o `copy_pixels` das texturas e copia a vaga sob o mutex dela |

## O caminho de uma tecla

1. O `DocumentView` recebe a tecla. Se for atalho do `CommandRegistry` (como `Ctrl+N`), roda o comando. Se não, o `routeKey` decide:
   - setas, Enter, Backspace: o `vclKeyFor` traduz para o VCL, e o `DocumentController.postKey` manda ao kit;
   - texto: a tecla segue para o IME do sistema, que devolve o texto (já composto, como o `á`) pelo `TextInputClient`. O `DocumentController.insertText` manda como `LOK_EXT_TEXTINPUT` + `END`;
   - Ctrl+letra que não é atalho: engolida.
2. O `pqk_post_key` (ou o `pqk_ext_text_input`) põe a tecla na fila do kit, e a thread do kit a entrega ao LOK.
3. O LibreOffice manda o `LOK_CALLBACK_INVALIDATE_TILES` com o retângulo que mudou.
4. A fila marca sujas só as vagas tocadas e redesenha as visíveis, 4 por passada.
5. Para cada vaga redesenhada, o kit chama `mark_texture_frame_available`, e o Flutter mostra os pixels novos no próximo quadro. Nada passa pelo Dart.

Enquanto o ladrilho novo não chega, o velho continua na tela, sem quadro em branco.

## Os padrões

| Padrão | Onde | Por quê |
|---|---|---|
| Ports & Adapters | `QuillKit` com o `LokQuillKit` e o `FakeQuillKit`; `FileDialogs` (também `pickImage`), `TextClipboard`, `AppWindow` | A UI e quase todos os testes rodam sem o LibreOffice nem o GTK, e o motor pode ir para outro processo sem mudar a UI |
| Facade | `Workspace` | Os fluxos de arquivo (trava, recentes, "salvar?", salvar como) num lugar só; os comandos e a UI só chamam ele |
| Active Object | `TaskQueue` + `LokEngine` | O LOK não é thread-safe, e a UI nunca espera o motor |
| Command | `CommandRegistry` (`Command`: id, rótulo, ícone, atalhos por jogo, `isActive`, `canRun`) | Uma fonte só para a faixa, os atalhos, os menus 97 (`editorMenus`), a paleta (Ctrl+K), o painel Formatar e, depois, os plugins |
| Command com receptor | `EditorViewActions` (`commands_view.dart`), implementado pela `EditorPage` | Os comandos que abrem uma tela (localizar, paleta, estilos, inserir imagem) só pedem; quem mostra é a página, e os testes trocam o receptor |
| Observer | Callbacks do LOK → `Stream<KitEvent>` tipado → `DocumentController` (`ChangeNotifier`) | O estado dos botões (negrito ligado) vem do motor, não é adivinhado |
| Flyweight + LRU | `TileCache`: vagas fixas, cada uma uma textura | A memória dos ladrilhos é fixa, seja qual for o documento |
| Strategy | `ComponentStyle` (moderno ou bisel) nos átomos | O mesmo átomo vira moderno ou Clássico 97 |
| Memoização | A `EditorPage` guarda a faixa, os painéis e a barra de status pela `stateRevision` e pela `statusRevision` (D-037) | A cada tecla, só a vista e o rodapé se refazem |
| Flyweight de arquivo | As cópias temporárias (D-044): a Estrutura, os estilos e a busca leem uma cópia FODT num isolate | O texto do livro não fica na memória do app |
| Atomic design + tokens | `lib/src/ui/` (atoms → molecules → organisms → templates → pages) e `QuillTokens` | Nenhuma cor literal fora de `tokens/themes/` (o `tokens_test` confere) |
| Facade do livro | `BookController` (no `Workspace.book`) | O fichário, a cortiça, as metas e os comandos mexem no livro por um lugar só, e cada mudança grava o `livro.json` de forma atômica |
| Memento | Os instantâneos (`snapshots.dart`, D-081): uma cópia do capítulo em `versoes/`, restaurável | Voltar a uma versão sem mudar o documento aberto |
| Pipeline | O compilar (`compile.dart`, D-086): cada capítulo em FODT pelo motor → um isolate junta (`fodt_join.dart`) → o motor grava o formato | Um passo de cada vez, cancelável entre eles; só o último põe o livro inteiro no motor |
| Repository de arquivos | As notas (`notes.dart`), os instantâneos (`versoes.json`) e as metas (`metas.json`), cada um lido e gravado pelo seu módulo, de forma atômica | Nada do livro fica na memória por via das dúvidas: lê-se ao abrir o painel ou a janela e solta-se ao fechar |

## Pastas

```
lib/
  main.dart                  liga o perfil, o kit e o app (ou o --bench)
  l10n/                      app_pt.arb (modelo), app_en.arb → gen/
  src/app.dart               MaterialApp, tema das preferências, "salvar?" ao sair
  src/kit/                   quill_kit.dart (a porta), lok/ (adaptador; lo_styles.dart, gerado), fake/
  src/book/                  book.dart (o livro.json), book_io.dart, book_controller.dart, fodt_split.dart e
                             docx_import.dart (o importador), odt_zip.dart (lê o content.xml; D-071),
                             chapter_cut.dart (dividir, D-079), book_search.dart (D-080), snapshots.dart
                             (D-081), notes.dart (D-082), goals.dart (as metas, D-083), compile.dart e
                             fodt_join.dart (o compilar, D-086), compile_models.dart e
                             compile_style.dart (os modelos, D-087)
  src/document/              document_controller.dart, doc_tab.dart (as abas), workspace.dart, fodt.dart
                             (a cópia lida), outline.dart, search.dart, format_origin.dart,
                             text_clipboard.dart, doc_colors.dart, comments.dart (as conversas, D-088)
  src/files/                 lo_lock.dart (a trava), recent_files.dart, file_dialogs.dart, app_window.dart,
                             open_folder.dart (xdg-open)
  src/settings/              settings.dart (tema, atalhos, painéis, acessibilidade), config_dir.dart
  src/commands/              command_registry.dart, commands_document.dart (os do documento),
                             commands_view.dart (os que abrem tela), menus.dart, palette_search.dart
  src/plugins/               plugin_host.dart
  src/bench/                 bench_runner.dart (medições da Fase 0)
  src/ui/tokens/             tokens.dart, themes/ (claro, escuro, sépia, alto contraste, clássico 97)
  src/ui/style_labels.dart, theme_labels.dart   os nomes dos estilos e dos temas
  src/ui/{atoms,molecules,organisms,templates,pages}/
packages/psito_quill_kit/
  ffigen.yaml                bindings → lib/src/quill_kit_bindings.g.dart
  linux/include/             psito_quill_kit_plugin.h, quill_kit_api.h
  linux/core/                o núcleo C++
  linux/test/                GoogleTest
  linux/tools/lok_probe.cc   o motor medido sem UI
  linux/tools/lok_script.cc  o motor perguntado por roteiro (D-029)
  linux/native/              CMake dos testes, do probe e do script
plugins/ola/                 o primeiro plugin Lua
integration_test/            com o LibreOffice real
test/{unit,widget}/          com o kit falso
test/support/harness.dart    o kit falso montado com o Workspace, janelas e área de transferência falsas
test/fixtures/               capitulo-30p.docx
tool/                        native-test.sh, bench.sh, make_fixture.py
```

## A pirâmide de testes

| Nível | Ferramenta | Comando | O quê |
|---|---|---|---|
| Unidade | `flutter test` | `./test.sh` | Leitura dos callbacks e dos estados (busca, menu de contexto, imagem, tabela, estilos, medidas), teclas → VCL e a rota delas, comandos (sem atalho repetido), perfil do LO, a trava, recentes, preferências, controlador e `Workspace` com o kit falso, tokens, contraste e cores literais |
| Nativo | GoogleTest | `tool/native-test.sh` (também no `./test.sh`) | Fila do kit, cache LRU, caixa de areia do Lua |
| Widget | `flutter test` | `./test.sh` | Átomos em cada tema e estilo, a página (IME, rotas das teclas, só leitura, zoom, alças da imagem), a faixa adaptável nos quatro tamanhos de tela, os menus 97, a busca única e o painel Localizar, o painel Formatar e os trilhos, a régua, a Estrutura, as abas, o zen, a barra de status, os bastidores e a tela inicial, a aba Exibir, o ocupado, a acessibilidade (alto contraste, a interface a 200 %, o leitor de tela) |
| Integração | `integration_test` | `./test.sh --integracao` | O LibreOffice real: abrir (com o progresso), status, digitar (também pelo IME), desfazer, negrito, copiar e colar, salvar DOCX e ODT (com o ocupado) e conferir o XML, a trava, Lua; ortografia, o menu de contexto, localizar e substituir, estilo novo, recuo, tabela, imagem, página; a acessibilidade |
| Ponta a ponta | `tool/bench.sh`, `tool/fechar-test.sh` | `tool/bench.sh`; o `fechar-test` roda no `./test.sh --integracao` | Memória, latência, rolagem, papel escuro: as metas da seção 8 do plano. Fechar a janela: código 0 e a trava apagada |

**Os limites dos testes.** O `./test.sh` roda 6 processos de teste (`TEST_JOBS`), num escopo do systemd com 6 GB de limite (`TEST_MEM`) e sem swap, como no Psito OS. Se passar do limite, só os testes morrem.
