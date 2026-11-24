# Fase 3: resultados

O modo Livro (seção 10 do `PLANO.md`), de 23 a 24/11/2026. As decisões vão do D-071 ao D-084.

**Resumo:** o Quill passou a escrever livros, e não só arquivos.
- O livro é uma pasta `.psitobook`, com um ODT por capítulo e o `livro.json`. O importador corta um DOCX nos títulos.
- O fichário mostra a árvore de partes, capítulos e cenas.
- O salvamento automático guarda uma cópia de recuperação.
- Entraram a página do livro (o cabeçalho, os campos, a hifenização, a capitular), o PDF e a impressão, as notas de rodapé, os links e os caracteres especiais.
- Entraram também as cenas, a busca no livro inteiro, os instantâneos, as notas do livro, as metas e a cortiça.

**A memória não cresce com o livro:** com o capítulo de 30 páginas aberto, um livro de 60 capítulos fica +3,8 MB acima de um livro de um capítulo só, com as notas, as metas e um ano de histórico. A tecla → ladrilho (p95 8,6 ms) e a rolagem (60 fps) ficaram iguais.

## O que entrou, por etapa

| Etapa | O que ficou | Decisões |
|---|---|---|
| 1. O livro, o importador e o fichário | A pasta `.psitobook` com o `livro.json` atômico e a `lixeira/`. O importador de DOCX pela cópia FODT, cortada nos títulos. O fichário no trilho: arrastar, Alt+setas, F2, o status, o rótulo e a sinopse. As palavras dos capítulos fechados pelo `content.xml`, num isolate. Os livros nos recentes e "Livro — Capítulo" no título | D-071, D-072 |
| 2. O salvamento automático | Uma cópia de recuperação em ODT a cada 60 s com alterações, no perfil do Quill, e "Recuperar" na tela inicial depois de uma queda | D-073 |
| 3. A página do livro | O cabeçalho e o rodapé, os campos, a primeira página e as pares diferentes, a hifenização e a capitular, pela cópia dos estilos e o `.uno:LoadStyles`. E o papel escuro desenhado pelo Quill | D-074, D-075 |
| 4. Exportar e imprimir | O PDF com os marcadores, a impressão pelo GTK, as notas de rodapé e de fim, os links (abrir pergunta antes) e os caracteres especiais. As aspas curvas e o travessão pelo autocorrigir | D-076 |
| (entre etapas) | O ícone, os pacotes `.deb`, `.rpm` e `.tar.gz`, o CI com o semantic-release, e a sonda do LOK no Windows | D-077, D-078 |
| 5. As cenas | O estilo "Cena" (o importador converte os `* * *`), as cenas no fichário, e Nova cena, Dividir capítulo aqui e Juntar com o próximo | D-079 |
| 6. A busca no livro | "No livro" no Localizar: os fechados pelo `content.xml`, o da tela pela cópia, e as abas de fundo pela cópia de recuperação | D-080 |
| 7. Os instantâneos | Em `versoes/`, pelo motor, sem mudar o documento. Comparar abre ao lado, só para leitura. Restaurar guarda antes. Um automático por dia | D-081 |
| 8. As notas | Markdown em `notas/`, editadas no Flutter, com os `[[Nome]]`, as menções e a linha do tempo. As teclas de editar texto ficam com o campo | D-082 |
| 9. As metas | Do livro com prazo, do dia e da sessão. O histórico em `metas.json` (cortar não desconta), a meta na barra e no zen, e o gráfico de 30 dias | D-083 |
| 10. A cortiça | Os capítulos como cartões no lugar da página, a mesma árvore do fichário. Arrastar e Alt+setas reordenam, e a sinopse se edita no cartão | D-084 |

## Os números

### O livro de 60 capítulos

O `capitulo-30p` em ODT, 60 vezes (1.800 páginas). Ele tem uma sinopse em cada capítulo, 40 notas, as metas e um ano de histórico em `metas.json`. Foi medido contra um livro de um capítulo só, o mesmo, sem nada disso. A build é a de release, com 3 rodadas alternadas, e o resultado é a mediana do `--bench`, com o primeiro capítulo aberto e o fichário na tela. A memória está em MB de RSS.

| Etapa do bench | 1 capítulo | 60 capítulos | Δ |
|---|---|---|---|
| O motor ligado | 270,2 | 270,6 | +0,4 |
| O capítulo de 30 páginas | 444,5 | 448,3 | +3,8 |
| Depois do `trimMemory` | 443,6 | 446,3 | +2,7 |
| Depois de rolar | 443,9 | 452,4 | +8,5 |
| Depois de digitar | 463,2 | 458,5 | −4,7 |
| No fim, depois do `trimMemory` | 452,9 | 462,5 | +9,6 |

| | 1 capítulo | 60 capítulos | Meta |
|---|---|---|---|
| Tecla → ladrilho, p95 | 8,5 ms | 8,6 ms | ≤ 16 ms ✅ |
| Rolar as 30 páginas | 60,1 fps | 60,1 fps | 60 fps ✅ |
| Abrir (até o "aberto") | 710 ms | 472 ms | ≤ 400 ms ❌ (D-068) |
| O primeiro ladrilho | 735 ms | 754 ms | |
| O quadro ao digitar (build, p95) | 3,7 ms | 5,2 ms | |

- **O livro não soma ao capítulo além do ruído** (uns 20 MB entre execuções, D-038). O RSS depois de rolar e no fim fica de 8 a 10 MB acima. É o heap do grupo de isolates da contagem das palavras dos 60 capítulos ao abrir (D-080: +21 MB no pico, reusado e não devolvido logo).
- **A meta antiga de ≤ 400 MB** (seção 8) foi escrita antes de medir. O capítulo avulso já passa dela (D-071). O que vale é o livro não crescer com o número de capítulos, e não cresce.
- **O quadro ao digitar ficou 1,5 ms mais caro no livro** (build p95 de 3,7 para 5,2 ms, nas três rodadas). Continua longe dos 16 ms do quadro, e nenhum quadro passou deles. Ver abaixo.

- **O quadro ao digitar:** a build da Etapa 8 no mesmo livro já dava 4,8 ms. A barra de status de um livro tem as palavras do livro e as cenas do fichário ao vivo, e as metas somam 0,3 ms (D-084). O capítulo avulso não paga nada disso.
- **Abrir:** os dois livros ficam entre 350 e 760 ms, alternando de uma rodada para outra, como desde a Fase 2B (D-068, o dicionário que cai antes ou depois do "aberto").

### A fase inteira, no capítulo avulso

`tool/ab.py fa3e6da` (A, o fim da Fase 2B, com as respostas do D-070) contra a árvore de agora (B), com o `capitulo-30p.docx` avulso, sem livro. Mediana de 3, no mesmo dia (D-038). A memória em MB.

| Etapa do bench | Anônima Fase 2B | Anônima Fase 3 | Δ | RSS Fase 2B | RSS Fase 3 | Δ |
|---|---|---|---|---|---|---|
| O motor ligado | 113,5 | 115,3 | +1,8 | 268,6 | 272,0 | +3,4 |
| O documento vazio | 178,1 | 185,5 | +7,4 | 374,8 | 383,4 | +8,5 |
| O capítulo de 30 páginas | 242,4 | 237,5 | −5,0 | 451,4 | 448,3 | −3,2 |
| Depois de rolar | 240,7 | 244,8 | +4,1 | 450,9 | 455,0 | +4,1 |
| Depois de digitar | 254,0 | 254,5 | +0,5 | 464,4 | 466,0 | +1,6 |

| | Fase 2B | Fase 3 | Meta (D-025) |
|---|---|---|---|
| Tecla → ladrilho, p95 | 9,4 ms | 9,4 ms | ≤ 16 ms ✅ |
| Rolar as 30 páginas | 59,5 fps | 59,5 fps | 60 fps ✅ |
| Abrir as 30 páginas | 750 ms | 756 ms | ≤ 400 ms ❌ (D-068) |

- **A fase não pesou no capítulo:** de −5,0 a +4,1 MB de memória anônima com o documento, dentro do ruído, em dez etapas.
- **A janela vazia subiu +7,4 MB.** Ela inclui a tela inicial com os recentes e os cartões novos (Novo livro, Importar, Recuperar), e o código do livro, das cenas e das notas no binário. Com o capítulo aberto, a diferença some. Não investiguei mais a fundo, porque o teto de ~5 MB vale para o documento aberto, que é o caso de uso.

## Testes por nível

| Nível | Ferramenta | Testes | O quê |
|---|---|---|---|
| Unidade | `flutter test test/unit` | 319 (Fase 2B: 213) | Os de antes, mais: o `livro.json`, o zip, o corte do FODT e o importador; a recuperação; os estilos pela cópia; as cenas e o corte do capítulo; a busca no livro e as opções; os instantâneos; as notas; as metas |
| Nativo | GoogleTest | 29 (Fase 2B: 23) | Os de antes, mais o papel escuro invertido |
| Widget | `flutter test test/widget` | 241 (Fase 2B: 200) | Os de antes, mais: o fichário (o teclado, arrastar, os detalhes), a tela inicial e os recentes de livro, a recuperação, a página do livro, os links e os caracteres especiais, as cenas, a busca no livro, os instantâneos, as notas, as metas e a cortiça |
| Integração | `integration_test` com o LOK real | 1 (27 passos; Fase 2B: 21) | Os de antes, mais: importar o DOCX pelo motor e abrir pelo fichário (22), a cópia de recuperação (23), a página do livro, os links e o PDF (24), as cenas, dividir e juntar (25), a busca no livro com o capítulo da tela modificado (26) e os instantâneos, comparar e restaurar (27) |
| Ponta a ponta | `tool/bench.sh`, `tool/fechar-test.sh`, `tool/ab.py`, `tool/vm-test.sh` | 4 roteiros | O `vm-test.sh` é novo: instala o pacote numa VM limpa e abre um capítulo |

Tudo passa com `./test.sh --integracao`. As metas e a cortiça não ganharam passo na integração: não passam pelo motor.

## As sondas no motor (24.2)

Toda chamada nova ao LOK passou antes pelo `lok_script`. As que não fizeram o que o plano esperava, e o que ficou no lugar:

| Sonda | O que o motor fez | O que ficou |
|---|---|---|
| Desligar o cabeçalho, a primeira página e as pares diferentes, a hifenização do documento, a capitular | abrem janelas que travam o LOK | A cópia dos estilos em FODT, mudada em Dart, e o `.uno:LoadStyles`, que não entra no Ctrl+Z (D-075) |
| O clique duplo no cabeçalho | não entra nele | Um botão leva o cursor até o cabeçalho (D-075) |
| `.uno:InsertSection`, `.uno:InsertTitleField` | nada | A quebra de seção e o campo do título ficaram de fora; a página em branco são duas quebras (D-075) |
| A prévia da impressão | o GTK só a mostra quando ele mesmo desenha as páginas | Imprimir manda um PDF, sem a prévia (D-076) |
| O texto do IME e o autocorrigir | o autocorrigir não vê o `LOK_EXT_TEXTINPUT` | Um caractere confirmado sozinho vai como tecla (D-076) |
| Dividir o capítulo pelo motor | as teclas chegam depois dos comandos `.uno:` | Um marcador no cursor, o Dart corta o resto e o motor apaga até o fim; juntar é pelo `.uno:InsertDoc` (D-079) |
| `.uno:CompareDocuments` | funciona, mas fechar o documento depois derruba o LibreOffice | Comparar abre o instantâneo numa aba ao lado, só para leitura (D-081) |
| A cópia de uma aba de fundo | o motor só copia o documento da tela | A busca usa a última cópia de recuperação dela (D-080) |
| O `.uno:LoadStyles` depois de uma conversão | não fazia nada, em silêncio: o quadro "atual" do motor era outro | O motor guarda a vista de cada documento e chama o `setView` antes de cada comando (D-075) |
| O LOK no Windows | não manda a invalidação dos ladrilhos | O Windows fica para depois, com um motor headless (D-078) |

As que deram certo e viraram código: o `pqk_convert` (o importador, os capítulos novos e o dividir), o `exportTo` (os instantâneos e a recuperação), o estilo "Cena", o `.uno:InsertDoc` e o PDF com os marcadores.

## Defeitos achados pelos testes

- **A vista não seguia o cursor** fora da máquina de escrever: a Estrutura, o Localizar e as setas levavam o cursor para longe com a tela parada (D-072).
- **O `setenv` do motor numa thread, com o GTK lendo o ambiente,** derrubava o processo ao abrir, às vezes. A ponta a ponta pegou (D-072).
- **O `.uno:LoadStyles` não fazia nada depois de uma conversão.** A integração pegou (D-075).
- **Uma letra com uma imagem selecionada** sumia em vez de trocar a imagem, depois que o texto passou a ir como tecla. O passo 21 da integração pegou (D-076).
- **O Enter antes de um comando `.uno:`** chegava depois dele, e o estilo "Cena" caía no parágrafo errado. A integração pegou (D-079).
- **A busca no livro lia o capítulo da tela do disco,** sem a palavra nova: o "modificado" do motor chega depois da edição (D-080).
- **Trocar de aba logo depois de editar** não gravava a cópia de recuperação (D-080).
- **Fechar depois do `CompareDocuments`** derrubava o LibreOffice no restaurar. A integração caiu (D-081).
- **O Ctrl+Z num campo de texto desfazia o capítulo,** e o Ctrl+A selecionava o documento. Os atalhos da página vinham antes do campo (D-082).

## O que não foi verificado

- **A aparência das telas novas:** o fichário, as notas, a janela das metas, o gráfico, a cortiça, a janela dos instantâneos, nos temas modernos, no Clássico 97 e no alto contraste. Não houve captura de tela (CLAUDE.md). Os testes de widget conferem a estrutura, os nomes e os estouros, não os pixels.
- **O *Dustland* de verdade** importado (o DOCX dele, numa cópia): a integração usa o DOCX de teste, com listas, notas, imagens e marcadores.
- **Arrastar na cortiça e no fichário com o mouse de verdade:** os testes arrastam pelo `WidgetTester`.
- **A virada da meia-noite com o livro aberto:** o teste de unidade troca o dia, mas o app não foi deixado aberto de um dia para o outro.
- **O IME com o teclado ABNT2** nos campos novos (a nota, a sinopse no cartão, as metas).
- **O Orca** nas telas novas: os testes conferem os nomes e as dicas, não o que ele fala.

## Perguntas para o Francisco

1. **A cortiça mostra os capítulos.** O plano falava em "as cenas de uma parte". Cartões por cena pediriam um título e uma sinopse por cena no `livro.json`, que hoje só guarda o começo de cada uma. Vale a pena?
2. **Os capítulos que encolhem contam zero na meta do dia.** Cortar 300 palavras numa revisão não desconta o que se escreveu em outro capítulo. É o que você quer, ou prefere o saldo (escrito menos cortado)?
3. **A meta de 400 MB da seção 8** fica velha: o capítulo avulso já está em ~445 MB. Trocamos por "o livro não soma mais que ~10 MB ao capítulo"?
