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

- **As laterais recolhem** (`F9`, `F10`), e a faixa também (`Ctrl+F1`) vira só as abas.
- **A faixa tem poucos botões grandes**, como no OnlyOffice. O resto fica no inspetor e na paleta.
- **Estilos rápidos** com prévia real: o motor desenha "Título 1" com o estilo do livro.

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
- **Sépia:** para sessões longas à noite.
- **Clássico 97:**
  - cinza `#C0C0C0`, bisel 3D, barra de título em degradê azul, fonte de UI bitmap-like (a fase 2 escolhe uma fonte livre parecida);
  - barra de menus no topo, barras de ferramentas Padrão e Formatação, sem faixa;
  - régua clássica e barra de status com os campos afundados.
- **Alto contraste.**

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
| Livro de 60 capítulos, um aberto | ≤ 400 MB (não cresce com o livro) | (Fase 3) |
| Sessão de 4 horas digitando | crescimento ≤ 30 MB | (teste de resistência) |
| Tecla → ladrilho pronto | ≤ 16 ms no p95 | 11,4 ms ✅ |
| Rolar | 60 fps sem quadros perdidos no capítulo de 30 páginas | 59,5 fps, 0 perdidos ✅ |
| Abrir capítulo | ≤ 400 ms | 515 ms ❌ |

A memória é o RSS do app inteiro, na mediana de pelo menos 3 execuções do `tool/bench.sh` (varia uns 20 MB de uma para outra).

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

**Fase 3: o modo Livro**
- O `.psitobook`, o fichário, as cenas, as notas, as metas, a cortiça, a busca no livro e os instantâneos.

**Fase 4: compilar e revisar**
- Compilar para PDF, EPUB e DOCX com modelos, notas de rodapé, referências cruzadas, sumário e índice.
- Comentários e alterações na margem, e o modo Leitura.

**Fase 5: plugins**
- A API `psito.*` v1, o gerenciador de plugins com permissões, os 4 plugins de exemplo, e temas vindos de plugins.

**Fase 6: acabamento**
- Os modos Foco, Máquina de escrever e Tela cheia, o Sépia e o Alto contraste, e as animações com mola no tema moderno.
- O pacote `.deb` e o APT, como no Player.
- A medição de memória final (seção 8) e um site.

**Depois:**
- Windows, com o LOK do instalador do LibreOffice para Windows;
- a entrada no Psito OS, se autorizada;
- e talvez o Psito Calc, sobre o mesmo kit.

---

## 11. Riscos

| Risco | Mitigação |
|---|---|
| O LOK do Debian ou Ubuntu muda entre versões | Os bindings são gerados do cabeçalho instalado, e o app checa a versão ao abrir. A fase 0 testa a 24.2 (host) e a 25.2 (Debian 13) |
| Acessibilidade fraca no LOK (o leitor de tela não lê ladrilhos) | Expor o parágrafo atual e a seleção pelo `Semantics` do Flutter, a partir do texto que o LOK devolve. Não fica perfeito, e isso deve ser dito no README |
| IME (acentos compostos, `´` + `a`) | `postExtTextInputEvent`, testado com o teclado ABNT2 já na fase 1 |
| Papel escuro não suportado | Moldura escura com papel claro (seção 4) |
| Um crash do LibreOffice derruba o app | Salvamento automático a cada 60 s em `.~lock` próprio + recuperação. Se for frequente, o kit vai para um processo à parte (1.2) |
| DOCX complexos (de editoras) | Fiel ao que o LibreOffice já faz. O formato do livro é ODT, e o DOCX é exportação |
| Escopo enorme | Fases com saída usável: a fase 1 já edita um capítulo. Só o necessário para escrever os livros |

---

## 12. Perguntas abertas para o Francisco

1. **O formato do livro:** a pasta `.psitobook` com um ODT por capítulo está boa, ou você prefere um arquivo único?
2. **O Windows** entra junto com o Linux desde a fase 1, ou só depois da fase 6? **Respondido:** depois da fase 6.
3. **O nome:** decidido, é Psito Quill (a pena de escrever, irmã do Plume). App `org.psito.quill`, repositório `psito-quill`.
4. **Os livros atuais:** em que formato estão hoje *Dustland* e *Silicon Gods* (DOCX, ODT, Google Docs)? A fase 3 precisa de um importador que divida pelos títulos de capítulo.
5. **O repositório** no GitHub (`francisceioseph/psito-quill`), público como o Player?
