# Psito Quill: o plano

Um editor de texto para escrever livros longos, como *Dustland* e *Silicon Gods*. Ele precisa ser bonito, nítido e leve, e não pode travar.

O motor é o LibreOffice, pelo LibreOfficeKit. A interface é em Flutter, com plugins em Lua. Funciona em Linux primeiro, porque é onde o Francisco escreve. O Windows vem depois.

Só uma pessoa vai usar. Isso muda as prioridades: o que importa é o básico do Word muito bem feito, e as ferramentas de livro que o Word não tem. Compatibilidade perfeita com tudo vem depois.

---

## 1. As decisões grandes

### 1.1 Motor: LibreOfficeKit do sistema

O `libreoffice-core` instalado já traz o LibreOfficeKit (LOK): a `libsofficeapp.so` e o cabeçalho `LibreOfficeKit.h`. O host tem a 24.2, e o Debian 13 tem a 25.2.

**Usar o do sistema, sem compilar o LibreOffice.**
- Compilar leva horas, ocupa uns 30 GB e precisaria de manutenção eterna.
- O LOK é a mesma API que o Collabora Online usa em produção. É estável e é C puro.

**O que o LOK dá:**
- abrir e salvar ODT, DOCX, RTF e outros (`documentLoad`, `saveAs`);
- desenhar a página em ladrilhos (`paintTile`);
- receber teclado, mouse e IME (`postKeyEvent`, `postMouseEvent`, `postExtTextInputEvent`);
- rodar comandos (`postUnoCommand(".uno:Bold")`);
- avisar o que mudou (`registerCallback`): ladrilhos a redesenhar, cursor, seleção, estado dos botões (`.uno:Bold=true`), número de páginas;
- consultar dados (`getCommandValues`): estilos, fontes, sumário, comentários, alterações.

**Licença:** o LibreOffice é MPL-2.0. Usar a biblioteca pela API não contamina o código do Quill.

Abandonar o OnlyOffice (AGPL, motor em JS dentro de um navegador) já foi decidido na conversa sobre memória. O LOK é o caminho realista.

### 1.2 Processo: o motor numa thread própria, dentro do app

O LOK não é thread-safe. Toda chamada vai para uma única thread, a "thread do kit", que tem uma fila de tarefas.

A UI nunca espera o motor. Um comando vai para a fila, e a resposta volta por callback.

Na fase 0 o motor fica no mesmo processo, porque é mais simples e gasta menos memória.

A interface do kit (`QuillKit`, seção 3) é desenhada para poder ir a um processo à parte sem mudar a UI. Se a fase 0 mostrar que o LibreOffice derruba o app com frequência, separamos. O motor vira o `psito-quill-kit`, com os ladrilhos por memória compartilhada, como no Collabora.

### 1.3 Interface: Flutter, com design system próprio

**Por que Flutter, e não outra coisa:**
- Todo o ecossistema Psito é Flutter: o Player, o OS, os jogos. Os átomos, o empacotamento `.deb`, o CI e o semantic-release são reaproveitados.
- O Flutter desenha tudo, então dá para fazer um tema Office 97 de verdade, com relevos, cinza 3D e menus clássicos.
  - GTK ou Qt desenhariam com o tema do sistema.
  - O Slint ou o egui do Rust exigiriam refazer todo o conhecimento acumulado.
- A página é só uma textura vinda do LOK. O Flutter não precisa entender o documento: ele desenha a moldura, o cursor e os painéis.

**Por que não o Material 3 Expressive puro:** o tema clássico do 97 precisa trocar a forma dos componentes, e não só a cor. No Material, um botão é sempre um botão Material.

A decisão é um design system próprio, o `quill_ui`:
- **Tokens:** cor, tipografia, raio, elevação, densidade, relevo e movimento.
- **Átomos que leem os tokens.**
- **Um "estilo de componente" por tema:** o tema moderno desenha um botão com raio e realce suave, e o tema 97 desenha o mesmo átomo com bisel e fundo cinza.

O M3 Expressive entra como **inspiração** do tema moderno: formas generosas, movimento com mola e cor tonal. Não entra como dependência. Assim também não ficamos presos à migração do `material` do Flutter para um pacote separado.

Use a última versão estável do Flutter e do Dart na hora de começar, e anote qual foi no DECISOES.md.

### 1.4 Plugins em Lua: sim, é possível

Lua 5.4, embutido em C, carregado pelo plugin nativo.
- A `liblua5.4` já está no host, e o Debian tem o pacote.
- O LuaJIT seria mais rápido, mas para na sintaxe do 5.1. Os plugins não fazem conta pesada.

Cada plugin roda num `lua_State` próprio, numa thread de plugins separada da UI e do kit.

**Caixa de areia:**
- Sem `os`, `io`, `require` de C nem `load` de bytecode.
- Um alocador com teto de memória (por exemplo, 16 MB por plugin).
- Um `lua_sethook` que interrompe o plugin depois de N instruções, para um laço infinito não travar o editor.

Tudo que o plugin faz passa pela API `psito.*` (seção 7), que vira tarefas na fila do kit ou mensagens para a UI.

### 1.5 Formato do livro: uma pasta com um ODT por capítulo

Um livro grande num ODT só é o que faz os editores travarem. O LibreOffice repagina tudo a cada edição, e a memória cresce com o livro.

**Livro `Dustland.psitobook/`, uma pasta:**
```
Dustland.psitobook/
  livro.json          ordem, partes, metadados, metas, estilos do livro
  capitulos/
    001-a-poeira.odt
    002-....odt
  notas/              personagens, lugares, linha do tempo (Markdown ou ODT)
  pesquisa/           imagens, PDFs, links
  estilos.ott         o modelo de estilos que todo capítulo usa
  versoes/            instantâneos (ver seção 6)
```

**Por que assim:**
- **Só o capítulo aberto fica carregado no motor.** A memória depende do capítulo, não do livro, e a repaginação também.
- **Diferenças legíveis no git**, se o Francisco quiser versionar o livro. Um `.fodt` (ODT em XML plano) por capítulo é uma opção a medir.
- **Compilar** (seção 6) junta os capítulos num documento só, na hora de exportar PDF, EPUB ou DOCX.

**Documentos avulsos** (uma carta, um contrato) abrem direto, como em qualquer editor: ODT, DOCX ou RTF.

---

## 2. As melhores ideias de cada editor

| De onde | Ideia | No Psito Quill |
|---|---|---|
| OnlyOffice | Abas limpas, ícones grandes, sem poluição | A faixa de ferramentas do tema moderno |
| Pages (macOS) | Inspetor à direita que muda com a seleção | O painel Formatar contextual |
| Word | Painel de navegação por títulos, galeria de estilos, Modo de Foco | Navegador, estilos rápidos, Foco |
| Word 97 | Menus em categorias, barras de ferramentas encaixáveis | O tema Clássico 97, completo |
| WordPerfect | Revelar códigos | "Revelar formatação": mostra por que o texto está assim (estilo + formatação direta) |
| LibreOffice | Estilos de verdade (parágrafo, caractere, página, lista), Navegador | Os estilos são o centro, com a formatação direta como exceção visível |
| Scrivener | Fichário, cortiça, compilar, instantâneos, metas | O modo Livro (seção 6) |
| Ulysses / iA Writer | Máquina de escrever, foco na frase, metas de sessão | O modo Escrita |
| Google Docs | Comentários limpos, contorno lateral | Os comentários na margem |
| VS Code | Paleta de comandos | `Ctrl+K`: todo comando, estilo e capítulo por nome |
| Obsidian | Links entre notas | `[[Personagem]]` nas notas do livro |

---

## 3. Arquitetura

```
┌───────────────────────────── Flutter (Dart) ──────────────────────────────┐
│ pages      EditorPage, BookPage, CorkboardPage, SettingsPage              │
│ templates  QuillShell (barra de título, faixa/menus, laterais, status)   │
│ organisms  Ribbon, MenuBar97, Binder, Navigator, Inspector, PageView      │
│ molecules  StyleGallery, FontPicker, ColorSplitButton, ChapterCard        │
│ atoms      WButton, WToggle, WIcon, WField, WMenuItem, WBevel, WTooltip   │
│ ─────────────────────────────────────────────────────────────────────────  │
│ estado     DocumentController, BookController, CommandRegistry, Themes    │
│ kit        QuillKit (interface)  ←  LokQuillKit (FFI)  |  FakeQuillKit │
└────────────────────────────────────┬──────────────────────────────────────┘
                     dart:ffi + NativeCallable.listener
┌────────────────────────────────────┴──────────────────────────────────────┐
│ plugin nativo (C++)  psito_quill_kit                                     │
│   thread do kit: fila → LibreOfficeKit (lok_init, documentLoad, ...)      │
│   cache de ladrilhos (LRU com teto em MB) → FlPixelBufferTexture          │
│   thread de plugins: lua_State por plugin, API psito.* → fila do kit      │
└───────────────────────────────────────────────────────────────────────────┘
```

### 3.1 Padrões

| Padrão | Onde | Por quê |
|---|---|---|
| Ports & Adapters | `QuillKit` com `LokQuillKit` e `FakeQuillKit` | A UI e quase todos os testes rodam sem o LibreOffice |
| Command | `CommandRegistry`: id, rótulo, atalho, ícone, `canRun`, `run` | Uma fonte só para a faixa, os menus 97, a paleta, os atalhos e os plugins |
| Observer / streams | Callbacks do LOK → `Stream`s tipados | O estado dos botões (negrito ativo) vem do motor, não é adivinhado |
| Active Object | Thread do kit com fila | O LOK não é thread-safe, e a UI nunca bloqueia |
| Flyweight + LRU | Cache de ladrilhos | Memória fixa, seja qual for o tamanho do documento |
| Strategy | `ComponentStyle` por tema | O mesmo átomo vira moderno ou 97 |
| Memento | Instantâneos de capítulo | Versões do livro sem depender do desfazer do motor |
| Repository | `BookRepository` lê e grava o `.psitobook` | O formato fica num lugar só |

### 3.2 Pastas (repositório próprio, `~/projects/psito-quill`)

```
lib/
  main.dart
  src/kit/          quill_kit.dart, lok/ (bindings do ffigen), fake/
  src/document/     document_controller.dart, selection, cursor, state
  src/book/         book.dart, book_repository.dart, compile.dart
  src/commands/     command_registry.dart, commands_*.dart (por categoria)
  src/plugins/      plugin_host.dart (lado Dart: menus e painéis dos plugins)
  src/ui/
    tokens/         tokens.dart, themes/ (claro, escuro, sepia, classic97, alto_contraste)
    atoms/ molecules/ organisms/ templates/ pages/
  l10n/             en e pt (.arb)
linux/              runner + plugin nativo (kit, ladrilhos, Lua)
plugins/            plugins de exemplo em Lua
test/ integration_test/ docs/
```

**O Quill não conhece o Psito OS**, igual ao Player. Entrar no OS depois (`examples/quill_psito`, manifesto, sandbox) é uma decisão à parte, que precisa de autorização.

---

## 4. Desenho da página: nítido e sem travar

- **Ladrilhos de 256×256 px físicos**, pedidos já na escala do monitor (`devicePixelRatio`). Assim o texto sai nítido a 1,25x e 2x, sem esticar bitmap.
- **Só os visíveis e uma margem** são pedidos. Rolar para longe libera os de trás, e a cache tem um teto em MB (por exemplo, 64 MB).
- **Invalidação fina:** o `LOK_CALLBACK_INVALIDATE_TILES` diz o retângulo, e só os ladrilhos tocados são redesenhados.
- **Cursor, seleção, alças e realce de busca são desenhados pelo Flutter**, a partir dos retângulos que o LOK manda.
  - O cursor pisca sem tocar no motor.
  - A seleção tem a cor do tema.
- **Digitação:** a tecla vai para a fila do kit na hora. Enquanto o ladrilho novo não chega (alguns ms), o ladrilho velho continua na tela, sem nenhum quadro em branco.
- **Zoom** com ladrilhos da escala anterior esticados por um instante, até chegarem os novos, como faz o Collabora.
- **Papel escuro:** o LOK das versões recentes aceita esquema de cores do documento (`.uno:ChangeTheme`). A fase 0 confere na versão do sistema.
  - Se não funcionar, o modo escuro tem a moldura escura e a página clara. Isso é o que o Word faz, e é aceitável.
  - Inverter a cor dos ladrilhos fica proibido, porque estraga imagens.
- **Fontes:** o LibreOffice usa o fontconfig do sistema, e a UI usa a mesma lista, que vem por `getCommandValues(".uno:CharFontName")`.

---

## 5. A interface

### 5.1 Layout (tema moderno)

```
┌ título: Dustland — Cap. 12 · salvo ✓        [desfazer][refazer]  ⌘K  ─ □ ✕ ┐
├ Início  Inserir  Layout  Referências  Revisão  Livro  Exibir  Plugins      ┤
│ [estilos rápidos ▾][fonte][tam][N I S][cor] [≡ ≡ ≡][listas] [buscar]      │
├────────────┬───────────────────────────────────────────┬──────────────────┤
│ Fichário   │                                           │ Formatar         │
│ ▸ Parte I  │            ┌──────────────┐               │ (muda com a      │
│   ▸ Cap 1  │            │   página     │               │  seleção:        │
│   ▾ Cap 12 │            │              │               │  texto, imagem,  │
│     cena 1 │            └──────────────┘               │  tabela, página) │
│ Navegador  │                                           │ Comentários      │
├────────────┴───────────────────────────────────────────┴──────────────────┤
│ pág. 3/14 · cap. 2.140 palavras · livro 87.320 · meta hoje 640/1000 · pt-BR · 110% │
└───────────────────────────────────────────────────────────────────────────┘
```

**Revisto na Fase 2B** (os desenhos estão no canvas "Psito Quill — nova interface", no Claude Design):
- **Material 3 com densidade de desktop:** controles de 36 px (eram 32; subiu na Etapa 7, D-049) e 44 px na densidade confortável, cores tonais a partir da semente #415F91, ícones Material Symbols Rounded.
- **A barra de título é a do GTK.** A busca única, no texto e nos comandos (Ctrl+F e Ctrl+K, D-050), fica na ponta direita da fileira de abas.
- **A fonte da interface é a do sistema** (Ubuntu/Cantarell): nada embutido, nada a mais na memória.
- **À esquerda,** um trilho com Estrutura, Localizar e Estilos; o Fichário entra nele na Fase 3. **À direita,** o painel Formatar, uma seção de cada vez.

- **As laterais recolhem** (`F9`, `F10`), e a faixa também (`Ctrl+F1`) vira só as abas.
- **A faixa se adapta à largura** (Etapa 7, D-049): os grupos têm quatro tamanhos, do grande com nome ao recolhido num menu, como no Office. O resto fica no painel Formatar, no menu de contexto e na paleta.
- **Estilos rápidos** com prévia real: cada cartão é desenhado com as propriedades do estilo do livro, e passar o mouse mostra no texto, se o motor deixar (Fase 2B, Etapa 3).
- **Como ficou no fim da Fase 2B** (`docs/FASE2B-RESULTADOS.md`):
  - em cima, as abas dos documentos abertos (com dois ou mais), o acesso rápido (salvar, desfazer, refazer), o Arquivo, as abas da faixa e a busca única;
  - os trilhos dos dois lados: Estrutura, Localizar e Estilos à esquerda; as seções do Formatar à direita (D-062);
  - o Arquivo abre os bastidores (a lista à esquerda, a seção à direita) e, sem documento, a tela inicial mostra os cartões e os recentes (D-064);
  - a barra de status é clicável: as estatísticas, o idioma, a disposição das páginas e o zoom com os ajustes (D-063). Abrir e salvar mostram o progresso nela, sem janela (D-066);
  - a aba Exibir tem as caixas do que se mostra, as páginas e o zoom (D-065);
  - o tamanho da interface vai até 200 %, e tudo cresce junto (D-067).

### 5.2 Menus (os mesmos comandos nos dois temas)

A faixa e o menu 97 saem do mesmo `CommandRegistry`. Nenhum comando existe num lugar só.

- **Arquivo:**
  - Novo, Novo livro, Abrir, Recentes, Salvar, Salvar como, Exportar (PDF, EPUB, DOCX, ODT), Compilar livro…
  - Instantâneo, Propriedades, Imprimir, Sair.
- **Editar:**
  - Desfazer, Refazer, Recortar, Copiar, Colar, Colar sem formatação, Selecionar tudo.
  - Localizar, Substituir (com expressões regulares e por estilo), Ir para…
- **Exibir:**
  - Página, Rascunho (sem página, largura de leitura), Cortiça, Foco, Máquina de escrever, Tela cheia.
  - Painéis, Réguas, Marcas de formatação, Zoom, Tema.
- **Inserir:**
  - Quebra (página, seção, coluna), Imagem, Tabela, Nota de rodapé, Nota de fim, Comentário.
  - Referência cruzada, Marcador, Link, Caractere especial, Campo (data, página, contagem), Sumário, Índice.
- **Formatar:**
  - Caractere, Parágrafo, Listas, Colunas, Página, Limpar formatação direta, Revelar formatação.
- **Estilos:**
  - Gerenciar estilos, Novo estilo a partir da seleção, Atualizar estilo pela seleção, Importar estilos de outro documento.
- **Livro:**
  - Novo capítulo, Nova cena, Dividir capítulo aqui, Juntar com o próximo.
  - Metas, Personagens e lugares, Linha do tempo, Estatísticas, Compilar.
- **Ferramentas:**
  - Ortografia e gramática, Idioma, Contagem de palavras, Controlar alterações, Comparar documentos, Macros de plugins.
- **Tabela:** inserir, excluir, mesclar, dividir, propriedades. Só aparece no 97; no moderno é uma aba contextual.
- **Plugins:** gerenciar e os itens que cada plugin registra.
- **Janela** (só no 97) e **Ajuda:** atalhos, sobre.

### 5.3 Temas

**Os temas que vêm com o app:**
- **Claro:** neutro quente, papel branco, destaque na cor escolhida.
- **Escuro:** moldura grafite e papel escuro, se o motor deixar (seção 4).
- **Sépia:** para sessões longas à noite, e o papel do modo zen (Fase 2B).
- **Clássico 97:**
  - cinza `#C0C0C0`, bisel 3D, barra de título em degradê azul, fonte de UI bitmap-like (a fase 2 escolhe uma fonte livre parecida);
  - barra de menus no topo, barras de ferramentas Padrão e Formatação, sem faixa;
  - régua clássica e barra de status com os campos afundados.
- **Alto contraste,** escuro e claro, com contraste de 7:1 (Fase 2B).

**Um tema é um arquivo JSON** com tokens + um `ComponentStyle` (moderno ou bisel).
- Dá para criar temas sem recompilar: em `~/.config/psito-quill/themes/`.
- Plugins podem trazer temas.

### 5.4 Atalhos

São os do Word, para não reaprender nada, e o jogo de atalhos é uma escolha nas configurações:
- o do Word em português: `Ctrl+N/I/S` para negrito, itálico e sublinhado, e `Ctrl+B` para salvar;
- o do Word em inglês: `Ctrl+B/I/U`, e `Ctrl+S` para salvar;
- `Ctrl+Alt+1..3` para os títulos;
- `Ctrl+K` para a paleta, que nunca conflita com outro atalho.

A tabela é editável.

---

## 6. Para escrever livros

- **Fichário:**
  - árvore Livro → Partes → Capítulos → Cenas;
  - arrastar reordena, e o duplo clique abre;
  - cada item tem status (rascunho, revisão, pronto), rótulo de cor e sinopse.
- **Cortiça:** os capítulos como cartões com a sinopse, para reorganizar a história. Mexer nos cartões mexe no fichário.
- **Cenas:** separadores dentro do capítulo (um estilo de parágrafo "Cena" ou `* * *`). O navegador mostra as cenas, e "Dividir capítulo aqui" corta no cursor.
- **Notas do livro:**
  - personagens, lugares, facções, termos (para o mundo de *Silicon Gods*, por exemplo) e a linha do tempo;
  - abrem num painel ao lado, sem trocar o capítulo;
  - `[[Nome]]` liga as notas.
- **Metas:**
  - palavras por dia, por sessão e do livro, com prazo;
  - um gráfico pequeno na tela Livro, como no Scrivener.
- **Instantâneos:**
  - a versão de um capítulo com nome e data, guardada em `versoes/`;
  - comparar com o atual usa o "Comparar documento" do LibreOffice.
- **Compilar:**
  - escolhe capítulos, a folha de rosto, o sumário, os estilos de saída e o formato;
  - junta pelo motor num documento novo, e exporta PDF (com marcadores), EPUB (o LibreOffice exporta EPUB 3), DOCX ou ODT;
  - os modelos de compilação ficam salvos (Manuscrito, Livro 6×9, E-book).
- **Revisão:** controle de alterações e comentários na margem, e um modo "Leitura" sem ferramentas.
- **Escrita sem distração:**
  - Foco escurece o que não é o parágrafo atual;
  - Máquina de escrever mantém a linha no meio da tela;
  - Tela cheia esconde tudo, menos o texto e a contagem.
- **Busca no livro inteiro:** pesquisa nos capítulos fechados sem abri-los no motor. O ODT é um zip com XML, lido em Dart, num isolate.

---

## 7. Plugins em Lua

**`plugins/contagem-por-cena/plugin.lua`:**
```lua
local psito = require "psito"

psito.command {
  id = "contagem.cenas",
  label = "Palavras por cena",
  menu = "Ferramentas",
  run = function()
    local linhas = {}
    for i, cena in ipairs(psito.doc.paragraphs { style = "Cena" }) do
      linhas[#linhas + 1] = ("Cena %d: %d palavras"):format(i, cena:words())
    end
    psito.ui.message(table.concat(linhas, "\n"))
  end,
}

psito.on("save", function(doc)
  psito.book.log("salvou " .. doc.title)
end)
```

**A API (v1, pequena e estável):**
- **`psito.command{}`:** registra no `CommandRegistry`, e por isso aparece nos menus, na faixa, na paleta e nos atalhos.
- **`psito.doc`:**
  - `selection()`, `insert(text)`, `replace(range, text)`, `paragraphs{}`, `style(name)`;
  - `uno(".uno:Comando", args)`, a porta para todo o LibreOffice.
- **`psito.book`:** os capítulos, as notas, as metas, e `log`.
- **`psito.ui`:**
  - `message`, `ask`;
  - `panel{}`, um painel declarativo (texto, lista, botão, campo) que o Flutter desenha com os átomos do tema. O plugin não desenha pixels.
- **`psito.on(evento)`:** `open`, `save`, `selection`, `typing` (com debounce) e `compile`.

**O manifesto do plugin** (`plugin.json`) traz id, versão, autor e as permissões (`doc:read`, `doc:write`, `book`, `ui`). O app mostra as permissões ao instalar.

**Plugins de exemplo:**
- palavras por cena;
- verificador de nomes de personagens (avisa "Kaelen" escrito "Kaelan");
- realce de diálogos;
- exportar para o Wattpad.

---

## 8. Memória e desempenho

**Revistas depois da Fase 1** (D-025). As metas iniciais (250 MB vazio, 320 MB com o capítulo, 350 MB com o livro) foram escritas antes de medir. Só o Flutter e o Writer vazio já somam uns 335 MB. As de memória subiram para o que é razoável; as de rapidez ficaram como estavam.

| Situação | Meta | Fase 1 |
|---|---|---|
| App aberto, documento vazio | ≤ 340 MB | 335 MB ✅ |
| Capítulo de 30 páginas aberto | ≤ 380 MB | 364 MB ✅ |
| Livro de 60 capítulos, um aberto | O livro soma ≤ ~10 MB ao capítulo aberto e não cresce com o número de capítulos (D-085; era ≤ 400 MB) | +3,8 MB com o capítulo (Fase 3) |
| Sessão de 4 horas digitando | crescimento ≤ 30 MB | (teste de resistência) |
| Tecla → ladrilho pronto | ≤ 16 ms no p95 | 11,4 ms ✅ |
| Rolar | 60 fps sem quadros perdidos no capítulo de 30 páginas | 59,5 fps, 0 perdidos ✅ |
| Abrir capítulo | ≤ 400 ms | 515 ms ❌ |

**Depois da Fase 2B** (`FASE2B-RESULTADOS.md`), lado a lado com a Fase 2 no mesmo dia: 376 MB vazio e 452 MB com o capítulo (RSS), +11,3 MB de memória anônima com o capítulo em dez etapas; tecla → ladrilho p95 9,4 ms; rolar 59,5 fps; **abrir 854 ms ❌** (a Fase 2 abria em 369 ms). A maior parte é o dicionário da ortografia carregando antes do "aberto" (D-068); no primeiro ladrilho, a 2B fica ~120 ms acima da Fase 2.

A memória é o RSS do app inteiro, na mediana de pelo menos 3 execuções do `tool/bench.sh` (varia uns 20 MB de uma para outra).

**Depois da Fase 2** (D-038, D-039): o RSS muda uns 20 MB de um dia para outro, então cada fase e cada etapa se comparam **lado a lado** com a build anterior, pelo `tool/mapas.py`, olhando a memória anônima. **O orçamento é de ~5 MB de memória anônima por etapa;** passar disso pede um motivo e uma decisão. A ortografia em português custa uns 35 MB (o Hunspell) e foi aceita.

O LibreOffice sozinho já ocupa umas centenas de MB. A meta é ficar **bem abaixo do OnlyOffice** e, principalmente, **não crescer** em sessões longas. A lentidão do OnlyOffice em sessões longas é a queixa original.

**Táticas:**
- um motor só;
- um capítulo por vez;
- cache de ladrilhos com teto;
- imagens dos capítulos em resolução de tela;
- o Flutter sem imagens grandes nos assets;
- ícones em fonte ou SVG simples;
- um teste de resistência na fase de testes (seção 9), que digita por 30 minutos e falha se a memória crescer.

---

## 9. Testes (pirâmide)

| Nível | Ferramenta | O quê |
|---|---|---|
| Unidade | `flutter test` | `CommandRegistry`, `BookRepository`, compilação (com o kit falso), tokens e temas, a API Lua (lado Dart) |
| Nativo | GoogleTest (C++) + `busted` (Lua) | Fila do kit, cache LRU, caixa de areia do Lua (teto de memória, interrupção, sem `io`) |
| Widget | `flutter test` + goldens | Cada átomo nos 5 temas, faixa, menu 97, fichário, inspetor; rótulos de acessibilidade |
| Integração | `integration_test` com o LOK real | Abrir, digitar, negrito, salvar, reabrir; compilar 3 capítulos em PDF e EPUB |
| Ponta a ponta | Script que abre o app, injeta teclas, mede RSS e latência | A tabela da seção 8, rodada antes de cada versão |

O kit falso desenha linhas de texto simples, e por isso quase todo teste de UI roda sem o LibreOffice e rápido.

Siga a regra do Player: `./test.sh` com limite de memória, porque o host tem 8 GB (16 GB a partir de quarta).

---

## 10. Fases

Cada fase termina com `FASEn-RESULTADOS.md`, os números de testes por nível e as decisões no `DECISOES.md`.

**Fase 0: prova do motor (go/no-go)**
- O LOK do sistema carregado por FFI numa thread própria, um DOCX de 30 páginas na tela em ladrilhos, digitar e salvar.
- Medir a memória, a latência por tecla, a nitidez a 1x e 1,25x, e se o papel escuro funciona.
- Lua 5.4 embutido rodando um "olá" com a caixa de areia.
- **Critério de parada:** se a latência por tecla passar de 50 ms ou a memória passar de 500 MB com o capítulo, o plano volta para a mesa antes de escrever UI.

**Fase 1: editor básico**
- O `QuillKit` completo para texto: cursor, seleção, teclado, IME, desfazer, copiar e colar.
- A faixa Início, a barra de status, os temas Claro e Escuro, abrir e salvar ODT e DOCX, e os recentes.
- Atomic design desde o primeiro widget.

**Fase 2: formatação de verdade** (feita: `docs/FASE2-RESULTADOS.md`)
- Estilos (galeria, gerenciar, criar a partir da seleção), o inspetor Formatar, listas, página, imagens e tabelas simples.
- Localizar e substituir, ortografia (o LibreOffice já tem, pelo hunspell), "Revelar formatação", a paleta de comandos e o tema Clássico 97 com o menu completo.

**Fase 2B: a nova interface** (o plano aprovado em 23/11/2026; os desenhos estão no Claude Design)

Etapas que fecham sozinhas, nesta ordem. Cada uma termina com:
- `./test.sh --integracao` verde e `flutter analyze` limpo;
- a memória lado a lado com a build anterior (`tool/mapas.py`, ≤ ~5 MB de memória anônima);
- a decisão no `DECISOES.md`;
- uma lista do que o Francisco deve olhar à mão.

Antes de cada comando `.uno:` ou callback novo, uma sonda com o `lok_script` (D-029). Se a sonda falhar, vale a alternativa escrita aqui.

- **Etapa 0, privacidade e linha de base:**
  - o perfil do LO desliga os relatórios de falha, a coleta de uso, a verificação de atualizações e os logs (`LoProfile.ensureSettings`);
  - `SAL_LOG=-WARN-INFO` no `LokEngine::init`;
  - a preferência "Guardar os arquivos recentes";
  - um teste confere o perfil e que nada em `lib/` abre rede;
  - a linha de base da Fase 2 fica gravada.
- **Etapa 1, a fundação Material 3:**
  - os tokens a partir da semente, com os papéis do M3 (surface e os 5 surfaceContainer, secondaryContainer, outline, outlineVariant) e o `ColorScheme` do M3;
  - a densidade compacta ou confortável;
  - os ícones `material_symbols_icons` (Rounded, com tree-shaking; medir o `libapp.so`);
  - os átomos no visual novo, e os novos `WSegmented`, `WSwitch`, `WSlider` e `WChip`;
  - o bisel do Clássico 97 continua pelo `ComponentStyle`.
- **Etapa 2, a casca:**
  - a fileira de abas (Arquivo, Início, Inserir, Layout, Estilos, Revisão, Exibir, as abas de contexto na cor terciária, Recolher, e a pesquisa Ctrl+K na ponta);
  - a faixa num cartão, com a galeria embutida;
  - o trilho e o painel Estrutura;
  - o painel Formatar por seções (Texto, Parágrafo, Página, e Imagem ou Tabela), **só a visível construída**;
  - a barra de status nova, com o controle deslizante de zoom;
  - a aba Imagem com o tamanho em cm, o cadeado da proporção, Legenda e Original.
- **Etapa 3, as prévias de fontes e estilos:**
  - **A lista de fontes desenhadas com a própria fonte:** `ListView.builder`, com busca, "Neste documento", Recentes e Todas, e os filtros serifa, sem serifa e mono. Os filtros vêm de uma função nativa, `pqk_font_info`, que pergunta ao fontconfig.
  - **As propriedades dos estilos:** uma cópia temporária do documento, lida num isolate (`StyleCatalog`). Sonda: a cópia não pode mexer no documento. Se a sonda falhar, os cartões ficam com um desenho genérico.
  - **A galeria aberta,** com busca e as ações.
  - **A prévia ao vivo no texto:** aplicar e desfazer, se a sonda provar que é rápido e que não suja o desfazer. Se não provar, a prévia fica só nos cartões e na lista.
  - **"Revelar formatação"** marca o que vem do estilo e o que é direto, e "Tirar o que é direto" (`.uno:ResetAttributes`).
- **Etapa 4, a régua:**
  - **Os dados:** o `LOK_CALLBACK_RULER_UPDATE` (35). Se não vier, os estados de recuo e de margem.
  - **O desenho:** um `CustomPainter` só, que se repinta só quando muda. Mostra os milímetros, o zero na margem, as margens em cinza, os quatro recuos e as tabulações, mais o seletor do tipo de tabulação.
  - **A régua vertical,** com as margens de cima e de baixo.
  - **Ao arrastar,** a linha tracejada aparece na página.
  - **Teclado:** Tab chega a cada marca; as setas movem 1 mm e Shift+setas 1 cm.
  - **Exibir › Régua** liga e desliga, e a unidade fica nas preferências.
- **Etapa 5, várias páginas e a Estrutura:**
  - **Várias páginas:** `.uno:ViewLayout`, já testado (3 colunas dão 3 páginas de largura).
    - Uma, Várias ou Livro (pares) na barra de status; no modo Várias, as colunas saem do zoom.
    - O zoom mínimo cai para 20 %, e clicar numa página leva até ela.
    - O `PageGeometry` e o `DocumentView` são conferidos para mais de uma página por linha.
  - **A Estrutura:**
    - os títulos saem da mesma cópia temporária, refeita depois de salvar ou numa pausa de 2 s;
    - o salto a um título é escolhido pela sonda;
    - o item atual acompanha o cursor.
- **Etapa 6, o modo zen:**
  - tela cheia de verdade (`pqk_set_fullscreen` na porta `AppWindow`), que sai com Esc ou F11;
  - só o texto, com o papel Sépia (o esquema `PsitoQuillSepia`);
  - máquina de escrever: a linha no meio, só com a rolagem do Flutter;
  - foco no parágrafo, pelo retângulo dos callbacks de acessibilidade (sonda; a alternativa é uma faixa de linhas ao redor do cursor);
  - a barrinha de opções que some depois de 2 s;
  - as palavras e o tempo da sessão, atualizados uma vez por minuto.
- **Etapa 7, a interface que respira** (o retorno do Francisco em 23/11, testando o app; D-049). Os comandos estavam densos, mal distribuídos no Início, difíceis de ver e de clicar, sem aproveitar telas grandes, e os menus pobres. A referência é o OnlyOffice: os padrões de layout, não a cara. O detalhe está em `docs/fase2b/etapa-7-espaco.md`.
  - **Escala:** o texto da interface sobe de 13 para 14 px (as abas, 15), e a densidade padrão vai de 32 para 36 px, com ícones de 22. A confortável (44 px) continua, para a Etapa 9.
  - **A faixa adaptável, como a do Office:**
    - cada grupo tem quatro tamanhos: grande (ícone em cima do nome), médio (ícone e nome ao lado), só ícones, e recolhido num botão com o nome do grupo que abre o grupo num menu;
    - um `LayoutBuilder` escolhe o maior tamanho que cabe, encolhendo da direita para a esquerda pela prioridade de cada grupo;
    - de 1280 px para cima, nada rola de lado;
    - em telas largas, a galeria de estilos cresce e mostra mais cartões, no lugar de deixar um vazio à direita.
  - **O Início redistribuído:**
    - Área de transferência (Colar grande);
    - Fonte (fonte, tamanho, N I S, cor);
    - Parágrafo (alinhamentos, listas, recuos);
    - Estilos (a galeria que cresce);
    - Edição (Localizar e Substituir, grandes).
    - Sobrescrito, subscrito, tachado, limpar, realce e o espaçamento de linha ficam nos tamanhos maiores e, quando falta espaço, no menu do grupo.
  - **Acesso rápido:** salvar, desfazer e refazer à esquerda das abas. Na ponta direita, a pesquisa e o Recolher.
  - **Uma busca só** (D-050): "Pesquisar no texto e nos comandos". As ocorrências no documento (com a página e o trecho) e os comandos ficam no mesmo campo, aberto por Ctrl+F/L/K. Substituir fica no painel.
  - **Abas de documentos, todas carregadas** (D-054, no lugar das leves do D-051): as abas ficam acima da faixa, só com dois documentos ou mais, e todos ficam carregados no motor, com um ativo.
    - Trocar de aba é na hora e guarda a posição (o cursor, a rolagem e o zoom); cada documento guarda o próprio desfazer. A aba com alterações não salvas ganha um ponto.
    - **O limite:** 8 carregadas. Além disso, a aba salva usada há mais tempo sai do motor e reabre ao voltar (~0,3 s). Um capítulo de texto a mais custa ~4 MB no motor (a sonda, D-053).
    - **Os fluxos** de Novo, Abrir, Recentes, Fechar e Sair passam pelas abas: sair pergunta por cada documento não salvo. Um documento novo e vazio dá lugar ao que se abre.
    - **Teclado:** Ctrl+Tab, Ctrl+Shift+Tab e Ctrl+W; o clique do meio fecha a aba.
    - No modo Livro (Fase 3), os capítulos abertos do Fichário viram abas.
  - **A barra de status clicável** (D-063), **os bastidores do Arquivo e a tela inicial** (D-064) e **a aba Exibir** (D-065): os passos 6 a 8, no `etapa-7-espaco.md`.
- **Etapa 8, ocupado sem janelas:**
  - os callbacks `STATUS_INDICATOR` (9, 10, 11) viram o evento `Progress`;
  - abrir e salvar travam a tela com um `BusyScope`: os cliques e as teclas param, o cursor vira relógio e um véu leve fica por cima;
  - o progresso aparece no rodapé, como região viva para o leitor de tela;
  - sem "Cancelar", porque o LOK não cancela;
  - o trabalho de fundo não trava nada;
  - saem os avisos que piscam.
- **Etapa 9, acessibilidade:**
  - **Temas e tamanhos:**
    - Alto contraste, escuro e claro (7:1), e Sépia;
    - o tamanho do texto da interface (segue o sistema; um teste a 200 %). Feito como o tamanho da interface inteira: só o texto vazava a 200 % (D-067);
    - a densidade confortável.
  - **O cursor e o foco:**
    - a espessura do cursor e o piscar;
    - o foco sempre visível;
    - reduzir movimento.
  - **A cor da marca de ortografia** vem pelo esquema de cores, se a sonda achar a entrada.
  - **O documento no leitor de tela:**
    - `setAccessibilityState` e os callbacks `A11Y` (62, 63) viram um nó `Semantics` com o parágrafo e o cursor;
    - liga só com a preferência ou com o leitor de tela ativo;
    - o Orca, à mão.
  - **O zoom ao abrir.**
  - **A tela de Preferências:** Geral, Aparência, Acessibilidade, Privacidade, Atalhos.
- **Fecho:** o `FASE2B-RESULTADOS.md`, com os números lado a lado com a Fase 2. Atualizar `ARCHITECTURE.md`, `README.md` e `CLAUDE.md`.
- **Estado em 23/11/2026:** as Etapas 0 a 9 e o fecho estão feitos. Os resultados, as sondas e o que ficou para conferir à mão estão no `docs/FASE2B-RESULTADOS.md`.

**Fica para a Fase 5:** a IA local (llama.cpp em outro processo, desligada por padrão, como plugin com permissões). Na Fase 2B, só o lugar dela no trilho.

**Fase 3: o modo Livro** (o plano aprovado em 23/11/2026)
- O `.psitobook`, o fichário, as cenas, as notas, as metas, a cortiça, a busca no livro e os instantâneos.
- **Decidido com o Francisco:** a pasta `.psitobook` com um ODT por capítulo; os livros de hoje estão em DOCX, e a fase começa pelo importador; o núcleo primeiro, uma etapa usável de cada vez.
- **Em todas as etapas:**
  - só o capítulo da tela (e os das abas, até o limite do D-054) fica no motor;
  - o que se lê dos capítulos fechados (as palavras, a busca, as cenas) sai do `content.xml`, num isolate, por um leitor de zip nosso (`ZLibDecoder(raw: true)`), sem pacote novo. O Dart nunca escreve ODT: quem escreve é o motor;
  - um livro de 60 capítulos com um aberto soma ≤ ~10 MB ao capítulo e não cresce com o livro (seção 8, D-085).
- **Etapa 1: o livro, o importador e o fichário.**
  - O `livro.json` (a árvore de partes e capítulos, o status, o rótulo e a sinopse), gravado de forma atômica, e os capítulos em `capitulos/`. Apagar vai para a `lixeira/` do livro.
  - O importador de DOCX: o motor salva uma cópia FODT, o Dart a corta nos títulos do nível escolhido (com a prévia dos capítulos achados), e o motor salva cada pedaço em ODT. Uma sonda confere listas, notas, imagens e marcadores antes.
  - O fichário no trilho: abre o capítulo numa aba, arrasta e move pelo teclado (Alt+setas), F2 renomeia. As palavras de cada capítulo ficam no `livro.json`.
  - Novo livro e Importar na tela inicial, os livros nos recentes, "Livro — Capítulo" no título e as palavras do livro na barra de status.
- **O que falta para escrever, visto no OnlyOffice (23/11/2026):** o Francisco comparou o Quill com o OnlyOffice abrindo o *Dustland* (20 capturas). As três etapas abaixo entram antes das cenas, nesta ordem, porque o livro precisa delas para ser escrito no Quill de verdade.
- **Etapa 2: o salvamento automático e a recuperação.**
  - Hoje, se o LibreOffice cai, perde-se o que não foi salvo. O plano já citava isso nos riscos (seção 11), sem uma etapa.
  - A cada 60 s com alterações (e numa pausa da digitação), uma cópia de recuperação em ODT, pela cópia temporária do D-044: sem mudar o documento, o caminho nem o "modificado". Fica no perfil do Quill, nunca ao lado do arquivo.
  - Ao abrir depois de uma queda, a tela inicial mostra "Recuperar arquivos", com a data de cada cópia: Recuperar (abre a cópia como um documento novo) ou Descartar. Fechar normalmente apaga as cópias.
  - Uma preferência liga e desliga (ligada por padrão). A sonda mede o tempo da cópia no capítulo de 30 páginas e num livro grande, para a cópia não travar a digitação.
- **Etapa 3: a página do livro: o cabeçalho, o rodapé, o número de página, a hifenização e a capitular.**
  - O motor já desenha o cabeçalho e o rodapé do DOCX ("DUSTLAND · FRANCISCO SOUZA · 2025" e o número), mas o Quill não deixa criar nem editar.
  - Inserir › Cabeçalho e Rodapé (ligar e desligar por estilo de página), e editar com o clique duplo, como no Writer. Sonda: `.uno:InsertPageHeader`, `.uno:InsertPageFooter` e o clique no lugar do cabeçalho.
  - Os campos: número de página, total de páginas, título e data (`.uno:InsertPageNumberField` e os outros, sondados).
  - Primeira página diferente e páginas pares e ímpares diferentes, no painel Página.
  - No livro, o cabeçalho e o rodapé vêm do estilo de página de cada capítulo (os do importador continuam).
  - **A hifenização automática** (Layout › Hifenização, e no painel Parágrafo): o *Dustland* é justificado e hifenizado ("co-memorava", "verde-esme-ralda"). O dicionário `hyphen-pt-br` já está instalado; a sonda confere se o motor hifeniza com o `LOK_ALLOWLIST_LANGUAGES` e o perfil do Quill, e se o DOCX importado mantém a hifenização ligada.
  - **A letra capitular** (Inserir › Letra capitular: o número de linhas e o afastamento), para a abertura dos capítulos.
  - **As quebras de seção e de coluna** e a página em branco (Inserir › Quebras), além da quebra de página que já existe.
- **Etapa 4: exportar, imprimir, notas de rodapé, links e caracteres especiais.**
  - Exportar o capítulo para PDF (com marcadores dos títulos) e imprimir pela janela do sistema (GTK), com a prévia que o GTK mostra. O PDF do livro inteiro é o compilar, na Fase 4.
  - Notas de rodapé e de fim: inserir, e o clique no número leva à nota e volta. Vêm da Fase 4 para cá, porque um romance usa.
  - Links: inserir e editar (no menu de contexto também) e abrir com Ctrl+clique. Abrir um link pede confirmação: o Quill não abre nada na rede sozinho.
  - Caracteres especiais: uma grade pequena com os do português e da tipografia (travessão, aspas curvas, reticências, espaço sem quebra), com busca pelo nome. As aspas curvas e o travessão automáticos são o autocorrigir do motor (sonda).
- **Etapa 5: as cenas.** O estilo de parágrafo "Cena" (e `* * *` no importador), as cenas no fichário, e Nova cena, Dividir capítulo aqui e Juntar com o próximo (o caminho sai de uma sonda). **Decidido com o Francisco (24/11):** os separadores do manuscrito são convertidos para o estilo "Cena", não só reconhecidos.
- **Etapa 6: a busca no livro** (feita, D-080). "No livro" no painel Localizar: os fechados pelo `content.xml`, os abertos pelo motor; o clique abre e salta. Substituir no livro todo fica para depois.
- **Etapa 7: os instantâneos** (feita, D-081). Em `versoes/`, pelo motor, sem mudar o documento. Comparar abre o instantâneo ao lado, só para leitura (o `.uno:CompareDocuments` derruba o motor na 24.2); restaurar guarda um instantâneo antes; e um automático por dia.
- **Etapa 8: as notas** (feita, D-082). Markdown em `notas/`, editadas no Flutter, sem o motor: Personagens, Lugares, Facções, Termos e a Linha do tempo, com `[[Nome]]`.
- **Etapa 9: as metas** (feita, D-083). Do livro com prazo, do dia e da sessão, o histórico em `metas.json`, a meta na barra de status e no zen, e um gráfico dos últimos 30 dias num `CustomPainter`.
- **Etapa 10: a cortiça** (feita, D-084). Os capítulos como cartões no lugar da página, a mesma árvore do fichário, com a sinopse editável no cartão.
- **Fecho:** o `docs/FASE3-RESULTADOS.md` e a documentação.
- **Estado em 24/11/2026:** as Etapas 1 a 10 (D-071 a D-084) e o fecho estão feitos, e o papel escuro passou a ser desenhado pelo Quill (D-074). Os resultados, as sondas e o que ficou para conferir à mão estão no `docs/FASE3-RESULTADOS.md`.
  - **O que saiu diferente do plano nas Etapas 3 e 4** (as sondas na 24.2):
    - desligar o cabeçalho, a primeira página e as pares diferentes, a hifenização do documento e a capitular passam pela cópia dos estilos e o `.uno:LoadStyles` (D-075), porque os comandos do motor abrem janelas que travam o LOK. Essas mudanças não entram no Ctrl+Z;
    - editar o cabeçalho é pelo botão (o cursor vai até ele), não pelo clique duplo;
    - a quebra de seção e o campo do título ficaram de fora: o `InsertSection` e o `InsertTitleField` não fazem nada na 24.2. A página em branco são duas quebras de página;
    - a primeira página e as pares diferentes estão na faixa e no menu, não no painel Página;
    - a impressão não tem prévia: o GTK só a mostra quando ele mesmo desenha as páginas (D-076).
  - **O que saiu diferente do plano na Etapa 5** (D-079):
    - juntar é pelo motor (o `.uno:InsertDoc`, com o Ctrl+Z); dividir é pelo motor e pela cópia (um marcador no cursor, o Dart corta o resto, e o motor apaga até o fim);
    - veio também "Converter os separadores em cenas", para os capítulos já importados;
    - dividir no separador de uma cena tira o separador do capítulo novo.
  - **O que saiu diferente do plano na Etapa 6** (D-080):
    - uma aba de fundo com alterações vale a última cópia de recuperação dela (o motor só copia o documento da tela);
    - as opções do Localizar (maiúsculas, palavra inteira, expressão regular) passaram a valer também na lista "Neste capítulo";
    - cada capítulo mostra até 30 ocorrências; as outras só contam.
  - **O que saiu diferente do plano na Etapa 7** (D-081):
    - comparar abre o instantâneo numa aba ao lado, só para leitura: o `.uno:CompareDocuments` funciona, mas fechar o documento depois dele derruba o LibreOffice 24.2;
    - a lista fica numa janela (o menu Livro e o menu do item no fichário), não no painel do fichário;
    - o automático sai antes do primeiro salvamento do dia, não ao fechar o livro.
  - **O que saiu diferente do plano na Etapa 8** (D-082):
    - o clique numa ligação é nos botões de "Ligações", embaixo do texto: o campo de texto do Flutter não tem trecho clicável;
    - não há "Abrir ao lado" dividindo a página: o painel já fica ao lado dela;
    - a linha do tempo fica na ordem em que foi escrita, não na das datas;
    - com o foco num campo de texto, as teclas de editar texto ficam com o campo (Ctrl+Z desfazia o capítulo).
  - **O que saiu diferente do plano na Etapa 9** (D-083):
    - o progresso, o ritmo e o gráfico ficam na janela das metas (menu Livro e o clique na barra), não no alto do fichário;
    - cortar texto num capítulo conta zero no dia, não negativo; a base do dia sai na primeira contagem depois de abrir o livro.
  - **O que saiu diferente do plano na Etapa 10** (D-084):
    - os cartões são os capítulos (do livro ou de uma parte), não as cenas: as cenas não têm título nem sinopse no `livro.json`;
    - a cortiça abre pelo fichário, pelo menu Livro e pela faixa Exibir, além do Exibir do Clássico 97.

**Fase 4: compilar e revisar** (o plano aprovado em 24/11/2026)
- **Decidido com o Francisco (24/11/2026):** compilar primeiro, depois a revisão, e os ajustes do OnlyOffice no fim; os modelos de compilação ficam no livro (`compilar.json`); comparar com outro documento e combinar passa antes por uma sonda, e fica para depois se fechar o documento ainda derrubar o motor (D-081).
- **Em todas as etapas:**
  - compilar é a única hora em que o livro inteiro entra no motor, num documento oculto que fecha logo depois. O pico é medido e vai na decisão; a meta do D-085 vale fora da compilação;
  - o Dart nunca escreve ODT: escreve FODT, e o motor converte;
  - o que trava o LOK passa pela cópia FODT (D-075).
- **Etapa 1: compilar o livro** (feita, D-086). A janela Compilar (os capítulos, com o filtro por status; a folha de rosto; o sumário; as quebras, as partes e o separador de cena; o formato). Cada capítulo sai em FODT pelo motor, um isolate junta tudo num FODT só (o inverso do importador), e o motor grava em PDF (com marcadores), EPUB, DOCX ou ODT.
- **Etapa 2: os modelos de compilação.** Manuscrito, Livro 6×9 e E-book, com os estilos de saída, e "Salvar como modelo", no `compilar.json` do livro.
- **Etapa 3: os comentários.** O painel (adicionar, responder, resolver, excluir), o trecho marcado na página e a contagem por capítulo no fichário.
- **Etapa 4: o controle de alterações e o modo Leitura.** Editando, Revisão e Leitura; o painel Alterações (a anterior, a próxima, aceitar e rejeitar uma ou todas); a sonda de comparar e combinar.
- **Etapa 5: as referências.** O sumário no capítulo, as legendas, a tabela de figuras, os marcadores, a referência cruzada e o índice remissivo (também no compilar).
- **Etapa 6: os ajustes da Estrutura, do parágrafo e das Informações.**
- **Etapa 7: os ajustes da Página Inicial, do Layout e do Inserir.**
- **Etapa 8: as Preferências e os modelos.**
- **Fecho:** o `docs/FASE4-RESULTADOS.md` e a documentação.

O que a fase cobre (a lista de 23/11/2026):
- Compilar para PDF, EPUB e DOCX com modelos, referências cruzadas, marcadores, sumário e índice. (As notas de rodapé foram para a Fase 3, Etapa 4.)
- Comentários e alterações na margem, e o modo Leitura:
  - o painel Comentários: adicionar (também pelo menu de contexto), responder, resolver e excluir;
  - o controle de alterações: os modos Editando, Revisão (sugerir) e Leitura, a alteração anterior e a próxima, aceitar e rejeitar (uma ou todas);
  - comparar com outro documento e combinar.
- **Os ajustes vistos no OnlyOffice** (23/11/2026):
  - a Estrutura com "Início do documento" no topo e o nível até onde mostrar, com recolher e expandir;
  - no parágrafo: a cor de fundo, "Não adicionar intervalo entre parágrafos do mesmo estilo", e uma janela avançada com as bordas e as tabulações;
  - nas Informações: os parágrafos, os caracteres com espaços, e as propriedades editáveis (autor, título, assunto, etiquetas, comentário);
  - nas Preferências: as regras da ortografia (ignorar MAIÚSCULAS e palavras com números), personalizar o acesso rápido e escolher cada atalho;
  - os modelos: "Novo a partir do modelo", com o `estilos.ott` do livro como o primeiro;
  - na Página Inicial: copiar a formatação (o pincel), mudar maiúsculas e minúsculas (Aa), e as listas de vários níveis;
  - no Layout: as colunas de texto, os números de linha, a cor da página e a marca d'água, e organizar as imagens (trazer para a frente, alinhar, agrupar);
  - nas Referências: as legendas, a tabela de figuras, os marcadores (Favorito) e a referência cruzada, junto do sumário do compilar;
  - no Inserir: a caixa de texto, a data e a hora como campo.

**Fase 5: plugins**
- A API `psito.*` v1, o gerenciador de plugins com permissões, os 4 plugins de exemplo, e temas vindos de plugins.
- O assistente de IA local como plugin: desligado por padrão, num processo à parte, sem rede, e o texto só muda quando quem escreve aceita.
- **Vistos no OnlyOffice** (23/11/2026): os sinônimos pelo dicionário local do LibreOffice (sonda) e a gramática do LanguageTool só com um servidor local, ambos como plugins. Exportar para Markdown pode entrar no compilar.
- **Ficam de fora, de propósito:** a senha e a assinatura digital (a aba Proteção do OnlyOffice), as macros, as nuvens, a aba Desenhar, as formas, o SmartArt, os gráficos, as equações, a arte de texto, os controles de conteúdo, e os plugins que dependem da rede (DeepL, Send, Zotero).

**Fase 6: acabamento**
- As animações com mola no tema moderno. (Foco, Máquina de escrever, Tela cheia, Sépia e Alto contraste entraram na Fase 2B.)
- O pacote `.deb` e o APT, como no Player.
- A medição de memória final (seção 8) e um site.

**Depois:**
- Windows, mas **não** com o LibreOffice instalado: no Windows, ele não manda a invalidação dos ladrilhos (D-078). Vai pedir algo mais elaborado, a decidir quando chegar a hora:
  - um motor headless (svp) no Windows: o nosso, compilado com `--enable-headless`, como o Collabora faz; ou o do Collabora, que já fala o COKit (C++, MSVC) em vez do LOK;
  - ou redesenhar sem o aviso (pedir de novo os ladrilhos da tela depois de cada mudança);
  - nos dois casos, uma camada nativa para o Windows (as texturas, a impressão, as fontes, o perfil) e um instalador que leva o motor e o runtime do Visual C++. O ponto de partida é a sonda `tool/windows-probe/` e o D-078;
- a entrada no Psito OS, se autorizada;
- e talvez o Psito Calc, sobre o mesmo kit.

---

## 11. Riscos

| Risco | Mitigação |
|---|---|
| O LOK do Debian ou Ubuntu muda entre versões | Os bindings são gerados do cabeçalho instalado, e o app checa a versão ao abrir. A fase 0 testa a 24.2 (host) e a 25.2 (Debian 13) |
| Acessibilidade fraca no LOK (o leitor de tela não lê ladrilhos) | Feito na Fase 2B (D-067): o parágrafo do cursor e a posição dele vêm dos callbacks de acessibilidade do LOK e viram um campo de texto no `Semantics`. Não lê o documento inteiro, só o parágrafo; o README diz isso. Falta conferir com o Orca |
| IME (acentos compostos, `´` + `a`) | `postExtTextInputEvent`, testado com o teclado ABNT2 já na fase 1 |
| Papel escuro não suportado | Moldura escura com papel claro (seção 4) |
| Um crash do LibreOffice derruba o app | Salvamento automático a cada 60 s numa cópia de recuperação no perfil do Quill, e a recuperação ao abrir (Fase 3, Etapa 2, feita: D-073). Se for frequente, o kit vai para um processo à parte (1.2) |
| DOCX complexos (de editoras) | Fiel ao que o LibreOffice já faz. O formato do livro é ODT, e o DOCX é exportação |
| Escopo enorme | Fases com saída usável: a fase 1 já edita um capítulo. Só o necessário para escrever os livros |

---

## 12. Perguntas abertas para o Francisco

1. **O formato do livro:** a pasta `.psitobook` com um ODT por capítulo está boa, ou você prefere um arquivo único? **Respondido:** a pasta, com um ODT por capítulo.
2. **O Windows** entra junto com o Linux desde a fase 1, ou só depois da fase 6? **Respondido:** depois da fase 6. **Atualizado em 24/11/2026:** só Linux por enquanto. O Windows fica para depois, com um caminho próprio (D-078).
3. **O nome:** decidido, é Psito Quill (a pena de escrever, irmã do Plume). App `org.psito.quill`, repositório `psito-quill`.
4. **Os livros atuais:** em que formato estão hoje *Dustland* e *Silicon Gods* (DOCX, ODT, Google Docs)? A fase 3 precisa de um importador que divida pelos títulos de capítulo. **Respondido:** em DOCX.
5. **O repositório** no GitHub (`francisceioseph/psito-quill`), público como o Player?
