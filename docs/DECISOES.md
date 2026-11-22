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
