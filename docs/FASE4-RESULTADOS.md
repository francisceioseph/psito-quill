# Fase 4: resultados

Compilar e revisar (seção 10 do `PLANO.md`), de 24 a 25/11/2026. As decisões vão do D-086 ao D-093.

**Resumo:** o livro passou a sair do Quill, e a ser revisado nele.
- O compilar junta os capítulos num PDF (com o sumário e os marcadores), num EPUB, num DOCX ou num ODT, com a folha de rosto, as partes e os modelos Manuscrito, Livro 6×9 e E-book, que ficam no livro.
- Entraram os comentários, o controle de alterações e os modos Editando, Revisão e Leitura.
- Entraram as referências: o sumário no capítulo, as legendas, os índices, os marcadores, a referência cruzada e o índice remissivo.
- Entraram os ajustes vistos no OnlyOffice: a Estrutura, o parágrafo avançado, as Informações, o pincel, o Aa, as listas de vários níveis, as colunas, a marca d'água, as Preferências (a ortografia, o acesso rápido, os atalhos) e os modelos `.ott`.
- E o Quill passou a ter um repositório APT e DNF assinado, no GitHub Pages, como o Player.

**A memória:** compilar 60 capítulos leva o processo a uns 350 MB durante a gravação, e o documento oculto fecha no fim. Fora do compilar, as oito etapas somaram +5,1 MB de memória anônima com o capítulo avulso aberto (uns 0,6 MB por etapa). A tecla → ladrilho e a rolagem ficaram iguais; o abrir ficou 146 ms mais lento, e isso não foi investigado.

## O que entrou, por etapa

| Etapa | O que ficou | Decisões |
|---|---|---|
| 1. Compilar o livro | A janela Compilar (os capítulos com o filtro por status, a folha de rosto, o sumário, as quebras, as partes, o separador de cena, o formato). Cada capítulo sai em FODT pelo motor, um isolate junta tudo (`fodt_join.dart`), e o motor grava o formato num documento oculto, com o `UpdateAllIndexes` antes | D-086 |
| 2. Os modelos de compilação | Manuscrito, Livro 6×9 e E-book, e os de quem escreve, no `compilar.json` do livro. A página, o corpo, os cabeçalhos alternados, o capítulo na página ímpar (`QuillAbertura`) e a capa | D-087 |
| 3. Os comentários | O painel (adicionar, responder, resolver, excluir, os resolvidos), o trecho marcado na página pelo Quill (callback 32), o Ctrl+Alt+C, o autor nas Preferências e a contagem por capítulo no fichário | D-088 |
| 4. O controle de alterações e a Leitura | Editando, Revisão e Leitura, na barra de status e no menu Revisar. O painel Alterações (a anterior, a próxima, aceitar e rejeitar uma ou todas), com a lista só com o painel aberto. A Leitura folheia com as setas | D-089 |
| 5. As referências | O sumário no capítulo e atualizar, as legendas, os índices de figuras e de tabelas, os marcadores, a referência cruzada e o índice remissivo (também no compilar), por uma biblioteca Basic no perfil do Quill | D-090 |
| 6. A Estrutura, o parágrafo e as Informações | "Início do documento", o nível e recolher na Estrutura. A cor de fundo, o intervalo entre parágrafos do mesmo estilo, as bordas e as tabulações ("Parágrafo…"). As contagens e as propriedades editáveis | D-091 |
| 7. A Página Inicial, o Layout e o Inserir | O pincel, o Aa e as listas de vários níveis. As colunas, os números de linha, a cor da página, a marca d'água e a ordem das imagens. A caixa de texto, e a data e a hora no grupo Texto | D-092 |
| 8. As Preferências e os modelos | As regras da ortografia (no perfil, na próxima abertura), o acesso rápido escolhido, o atalho de cada comando com o aviso de conflito. "Salvar como modelo", o `estilos.ott` do livro (os capítulos novos nascem dele) e "Novo a partir do modelo" | D-093 |
| (entre etapas) | O repositório APT e DNF assinado no GitHub Pages, montado a cada versão com as três últimas (`tool/build-apt-repo.sh`, `build-dnf-repo.sh`, `create-apt-key.sh`), e o `pdftotext` na integração do CI | — |

## Os números

### Compilar 60 capítulos

Pelo `lok_script` (D-086): 60 cópias do `capitulo-30p`, 1.866 páginas, um FODT juntado de 8,3 MB. A memória é o pico do processo, em MB de RSS. O motor parado fica em 112 MB.

| Formato | Gravar | Pico |
|---|---|---|
| PDF (com o sumário e os marcadores) | 23 s | 341 MB |
| EPUB | 20 s | 365 MB |
| DOCX | 19 s | 351 MB |

- **Juntar leva 0,9 s,** no isolate, com o corpo gravado aos pedaços num arquivo ao lado. Só os estilos ficam na memória.
- **O pico é só durante o compilar.** O documento oculto fecha no fim, e o compilar não guarda nada fora da janela.
- **Não medido:** quanto do pico volta ao sistema depois do `trimMemory`, no app. O `--bench` não compila.

### A fase inteira, no capítulo avulso

`tool/ab.py 5f937e8` (A, o fim da Fase 3, com as respostas do D-085) contra a árvore de agora (B), com o `capitulo-30p.docx` avulso, sem livro. Mediana de 5, no mesmo dia (D-038). A memória em MB.

| Etapa do bench | Anônima Fase 3 | Anônima Fase 4 | Δ | RSS Fase 3 | RSS Fase 4 | Δ |
|---|---|---|---|---|---|---|
| O motor ligado | 114,9 | 117,3 | +2,4 | 271,3 | 274,5 | +3,2 |
| O documento vazio | 179,6 | 185,9 | +6,3 | 378,3 | 385,1 | +6,7 |
| O capítulo de 30 páginas | 238,6 | 243,7 | +5,1 | 449,4 | 454,8 | +5,4 |
| Depois de rolar | 239,3 | 243,5 | +4,3 | 449,8 | 457,4 | +7,6 |
| Depois de digitar | 253,2 | 256,2 | +3,0 | 465,1 | 468,7 | +3,6 |

| | Fase 3 | Fase 4 | Meta (D-025) |
|---|---|---|---|
| Tecla → ladrilho, p95 | 9,5 ms | 9,6 ms | ≤ 16 ms ✅ |
| Rolar as 30 páginas | 59,5 fps | 59,5 fps | 60 fps ✅ |
| Abrir as 30 páginas | 754 ms | 900 ms | ≤ 400 ms ❌ (D-068) |

- **As oito etapas somaram +5,1 MB de memória anônima com o capítulo.** Fica dentro do teto de ~5 MB de uma etapa só. Quase tudo está no grupo `anon` (+4,8 MB), com +0,6 MB do código do app (`flutter:app`) e +0,5 MB do heap.
- **A janela vazia subiu +6,3 MB,** como o +6,5 da Etapa 1 e o +7,4 do fecho da Fase 3: é a mesma medida que já oscilava, e o compilar não monta nada sem a janela.
- **O abrir subiu de 754 para 900 ms,** na mediana de 5. A Fase 4 pôs mais coisas no abrir: o pedido da lista dos comentários (`.uno:ViewAnnotations`) e mais campos lidos da cópia (os marcadores, as legendas, as propriedades, as contagens). Não investiguei qual pesa. O abrir já variava de 350 a 760 ms entre as rodadas desde a Fase 2B (D-068), e a meta continua estourada.

### Cada etapa

O `tool/ab.py` contra a etapa anterior, com o `capitulo-30p.docx` avulso, no mesmo dia (D-038). A memória anônima, a menor e a maior diferença entre as etapas do bench.

| Etapa | Contra | Rodadas | Memória anônima | Tecla p95 |
|---|---|---|---|---|
| 1. Compilar | `5f937e8` | 3 | −1,2 a +2,5 MB (a janela vazia, +6,5) | 9,6 ms |
| 2. Os modelos | `a4402d4` | 3 | −0,2 a +1,9 MB | 13,7 ms |
| 3. Os comentários | `b38da96` | 5 | −3,7 a +2,2 MB | 9,5 ms |
| 4. As alterações e a Leitura | `09b5994` | 5 | −3,6 a +3,9 MB | 9,6 ms |
| 5. As referências | `a02c1c2` | 5 | −2,4 a +0,8 MB | 9,4 ms |
| 6. A Estrutura e o parágrafo | `9098f86` | 5 | +1,5 a +4,4 MB | 9,6 ms |
| 7. O Layout e o Inserir | `6ffeb24` | 5 | −1,2 a +1,4 MB | 9,6 ms |
| 8. As Preferências e os modelos | `beb1c92` | 5 | −2,1 a 0,0 MB | 13,8 ms |

- **A tecla de 13,7 e 13,8 ms** nas Etapas 2 e 8 veio igual nas duas builds de cada medição: a máquina estava mais ocupada naqueles dias.
- **A Etapa 6 ficou acima das outras** (+4,4 MB depois de rolar), mas abaixo do teto de ~5 MB, e não foi investigada com o `mapas.py`. O `--bench` não abre nada do que ela trouxe; o que muda na tela dele é só a faixa.
- **O rolar ficou em 59,5 fps** em todas.

## Testes por nível

| Nível | Ferramenta | Testes | O quê |
|---|---|---|---|
| Unidade | `flutter test test/unit` | 393 (Fase 3: 319) | Os de antes, mais: juntar os FODTs (a ordem, os automáticos com prefixo, os ids, as quebras, os separadores), o compilar e o `compilar.json`, os estilos de cada modelo, o callback dos comentários e as conversas, as alterações, as macros (o módulo, os argumentos, o perfil), o parágrafo e as propriedades, o Layout, os atalhos escolhidos, as preferências novas, a ortografia no perfil e os modelos |
| Nativo | GoogleTest | 31 (Fase 3: 29) | Os de antes, mais o autor dos comentários no `initializeForRendering` (vazio, e com aspas e barra). O convert com as opções e os índices é conferido pela integração |
| Widget | `flutter test test/widget` | 263 (Fase 3: 241) | Os de antes, mais: a janela Compilar e os modelos, o painel Comentários, a Revisão e a Leitura, as referências, a Estrutura, a janela do parágrafo e as Informações, o pincel, o Aa, as listas, as colunas, a marca d'água, os atalhos, o acesso rápido e os modelos |
| Integração | `integration_test` com o LOK real | 1 (35 passos; Fase 3: 27) | Os de antes, mais: compilar em PDF, EPUB, DOCX e ODT (28), o Livro 6×9 (29), os comentários até reabrir (30), a Revisão, aceitar e rejeitar (31), as referências num perfil novo (32), o parágrafo e as propriedades (33), o Layout no ODT gravado (34) e os modelos (35) |
| Ponta a ponta | `tool/bench.sh`, `tool/fechar-test.sh`, `tool/ab.py`, `tool/vm-test.sh` | 4 roteiros | Iguais aos da Fase 3. O pacote da v0.15.0 foi instalado pelo repositório APT num Linux Mint 22 |

Tudo passa com `./test.sh --integracao`, e o CI ficou verde de novo na Etapa 8: a integração do CI não tinha o `pdftotext`, que o passo 28 usa.

## As sondas no motor (24.2)

Toda chamada nova ao LOK passou antes pelo `lok_script`, conferida pelo estado ou pelo arquivo gravado. As que não fizeram o que o plano esperava, e o que ficou no lugar:

| Sonda | O que o motor fez | O que ficou |
|---|---|---|
| O `.uno:UpdateAllIndexes` no documento oculto | roda depois do `postUnoCommand`, na thread do LOK: salvar logo em seguida grava o sumário vazio | O convert espera o `UNO_COMMAND_RESULT` pelo callback do documento oculto (D-086) |
| As opções do filtro do EPUB (`EPUBVersion`, `EPUBSplitMethod`, `RVNGCoverImage`, `RVNGTitle`) | ignoradas pelo LOK | O título e o autor vão no `office:meta`; a capa é a primeira imagem do livro, sem o `cover-image` no `content.opf` (D-086, D-087) |
| O autor de um documento aberto | não se troca | O `.uno:Author` do `initializeForRendering`, que vale para os abertos depois (D-088) |
| `.uno:CompareDocuments` e `.uno:MergeDocuments` | comparar funciona, mas fechar depois derruba o LibreOffice; combinar trava | Ficam de fora. Uma saída possível é comparar num processo à parte (D-089) |
| O sumário, a legenda e a entrada do índice | só por janelas, que travam o LOK | Uma biblioteca Basic no perfil do Quill, despachada por `macro:///` (D-090) |
| O `.uno:UpdateAllIndexes` numa aba aberta | trava a edição depois | Atualizar é a macro `Atualizar` (D-090) |
| O `.uno:JumpToMark` | não vai ao marcador | Ir a um marcador é macro (D-090) |
| A legenda pelo nome do arquivo ("Figure") | nasce uma segunda sequência, que o índice não vê | O campo vai com o nome da interface do motor, em pt-BR ("Figura", "Tabela") (D-090) |
| `.uno:ParaContextMargin`, as bordas com `ParaTopBorder` e o `BorderLine` antigo | nada | As macros `Intervalo` e `Bordas`, com o `TopBorder` e o `BorderLine2` (D-091) |
| A cor de fundo do parágrafo | o motor só diz a cor depois de mudá-la | O botão não mostra a cor atual (D-091) |
| `.uno:ChangeCaseRotateCase`, `.uno:DemoteList` | nada | O Aa tem os cinco que funcionam; descer o nível é o `DecrementLevel` (D-092) |
| `.uno:FillPageColor` | ignora a cor e põe o azul padrão | A macro `CorPagina` (D-092) |
| `.uno:DrawText`, `.uno:InsertFrame` | um pede o arrasto do mouse, o outro abre uma janela | A macro `Caixa` (D-092) |
| `.uno:FormatGroup` | desligado com imagens: a 24.2 só agrupa formas de desenho | Agrupar ficou de fora (D-092) |
| As regras da ortografia com o motor ligado | gravam no perfil, mas não refazem a verificação | A regra vai no perfil antes de ligar, e vale na próxima abertura (D-093) |
| Abrir um `.ott` | edita o próprio modelo, com a trava ao lado dele | O "Novo a partir do modelo" abre uma cópia convertida, sem arquivo (D-093) |

As que deram certo e viraram código: o `pqk_convert` com as opções do filtro e os índices, o callback 32 dos comentários e os comandos deles, os de alterações (`TrackChanges`, aceitar e rejeitar pelo índice), os marcadores e os campos de referência e de sequência, o `.uno:BackgroundColor`, o pincel, o Aa, o `SetOutline`, o `PageColumnType`, o `.uno:Watermark` e a ordem das imagens.

## Defeitos achados pelos testes e pelas sondas

- **O sumário do PDF saía vazio:** o `UpdateAllIndexes` terminava depois de o motor gravar. A sonda pegou (D-086).
- **A referência a um marcador não achava o marcador** no livro compilado: o prefixo dos ids ia também no `ref-name`. Achado na Etapa 5 (D-090).
- **A legenda levava a âncora da imagem** para o parágrafo novo, e o truque de um "x" provisório levava junto um marcador. A integração pegou (D-090).
- **Uma linha `Dim` com dois `As New`** fazia a Sub inteira não rodar, em silêncio. Achado ao sondar as bordas (D-091).
- **Os comandos que pedem uma seleção** (o Aa, o "Marcar a entrada") ficavam com o estado velho na faixa memoizada: a seleção não mudava a `stateRevision` (D-092).
- **O pincel e o "Centralizar" sumiam da faixa** em 1.500 px, quando os grupos encolhiam. Os testes de widget pegaram (D-091, D-092).

## O que não foi verificado

- **A aparência das telas novas:** a janela Compilar, os painéis Comentários e Alterações, a Leitura, as janelas das referências, do parágrafo, da marca d'água, dos atalhos e dos modelos, nos temas modernos, no Clássico 97 e no alto contraste. Não houve captura de tela (CLAUDE.md).
- **O *Dustland* de verdade** compilado, e o PDF e o EPUB abertos fora do Quill. O EPUB só foi conferido pelo `content.opf`, não num leitor.
- **A ordem das imagens:** os comandos ficam ligados, mas com uma imagem só a ordem não muda nada no arquivo (D-092).
- **As tabulações num parágrafo com recuo:** se a régua conta da margem ou do recuo (D-091).
- **O motor fazendo a marca d'água e as colunas,** e carregando o Basic na primeira macro: o `--bench` não roda nenhum deles.
- **O IME com o teclado ABNT2** nos campos novos (o comentário, as propriedades, o nome do modelo) e **o Orca** nas telas novas.

## Perguntas para o Francisco

1. **Comparar com outro documento:** fazer num LibreOffice à parte (abrir, comparar, gravar o ODT com as diferenças e sair sem fechar), que o Quill abriria com o painel Alterações? Custa um segundo motor durante a comparação (D-089).
2. **O abrir subiu 146 ms na fase** (de 754 para 900 ms). Investigo qual das coisas novas do abrir pesa (a lista dos comentários, os campos novos da cópia), ou fica para a medição final da Fase 6?
3. **A memória da Etapa 6** (+4,4 MB depois de rolar) ficou abaixo do teto, e a fase inteira deu +5,1 MB. Investigo com o `mapas.py`, ou fica?
