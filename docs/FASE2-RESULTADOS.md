# Fase 2: resultados

A formatação de verdade (seção 10 do `PLANO.md`), em 23/11/2026.

**Resumo:** o Quill já formata um livro:
- estilos de parágrafo e de caractere, com a galeria, criar a partir da seleção, atualizar e gerenciar;
- o painel Formatar (F10) e o "Revelar formatação" (Shift+F1);
- listas, recuos, entrelinha, espaço entre parágrafos, cores e realce;
- a página (tamanho, orientação, margens);
- tabelas e imagens simples, com as abas de contexto e as alças da imagem;
- localizar e substituir, com expressão regular;
- a ortografia, com as sugestões no clique direito;
- a paleta de comandos (Ctrl+K);
- o tema Clássico 97, com o menu completo e as barras Padrão e Formatação.

**A rapidez melhorou:**
- abrir o capítulo cumpriu a meta pela primeira vez (356 ms, meta de 400 ms);
- tecla → ladrilho: p95 de 9,3 ms;
- a rolagem continua a 60 fps.

**A memória piorou e passou das metas:** 370 MB vazio (meta de 340 MB) e 433 MB com o capítulo (meta de 380 MB). Metade disso é a ortografia. **Precisa de uma decisão do Francisco** (abaixo).

## O que entrou

| Item do plano | Como ficou |
|---|---|
| Estilos | A galeria na faixa Início (os estilos de livro e os do usuário); novo a partir da seleção (nome repetido não passa); atualizar pelo parágrafo; o diálogo Gerenciar; estilos de caractere. O estado vem traduzido e é mapeado para o nome de programa (D-030). Apagar estilo fica de fora: o motor não apaga |
| O painel Formatar | À direita, F10. Muda com a seleção: imagem, tabela, caractere (efeitos, cor, realce, limpar), parágrafo (alinhamento, listas, recuos em cm, entrelinha, espaço) e página. A escolha fica nas preferências (D-035) |
| "Revelar formatação" | Shift+F1: estilo, fonte, efeitos, cor, alinhamento, recuos, espaços, entrelinha, idioma e estilo de página no cursor, lidos do motor |
| Listas e parágrafo | Marcadores, numeração, aumentar e diminuir o recuo; entrelinha 1, 1,5 e 2; espaço entre parágrafos em degraus (D-032); quebra de página |
| Página | A4, A5, Carta, 6×9" e 5,5×8,5"; retrato e paisagem (D-036); margens Normal, Estreita, ABNT e Larga |
| Tabelas | Inserir pela grade; linhas e colunas antes e depois; apagar; mesclar. A aba Tabela aparece só dentro de uma tabela |
| Imagens | Inserir (PNG, JPEG, GIF, SVG, WebP, BMP, TIFF); as alças são do Flutter e o arraste mostra uma prévia; quebra de texto e alinhamento; o tamanho em cm. A aba Imagem aparece só com uma imagem selecionada |
| Localizar e substituir | A barra em cima da página (Ctrl+L e Ctrl+U em português, Ctrl+F e Ctrl+H em inglês); próxima e anterior, todas (com a contagem), maiúsculas, palavra inteira, expressão regular; substituir uma e todas, dizendo quantas (D-031) |
| Ortografia | O hunspell do sistema, com a lista de idiomas (D-033); o sublinhado vermelho; o menu de contexto do motor desenhado pelo Quill, com as sugestões, "ignorar" e "ignorar sempre" |
| A paleta de comandos | Ctrl+K: acha sem acento e sem maiúsculas, mostra o atalho e o menu de onde vem cada comando |
| Clássico 97 | O terceiro tema: Liberation Sans, bisel, a barra de menus completa (Arquivo, Editar, Exibir, Inserir, Formatar, Estilos, Ferramentas, Tabela, Ajuda), as barras Padrão e Formatação, e o status com os campos afundados (D-034) |

**Ferramenta nova:** o `lok_script`, que pergunta ao motor por roteiro (D-029). Todo comando novo foi medido nele antes de virar código. Ele achou os comandos que dizem que falharam e funcionam, e os que dizem que funcionaram e não fazem nada.

## Os números

Mediana de 3 execuções do `tool/bench.sh` (mesma máquina e documento das fases anteriores).

| | Fase 1 | Fase 2 | Meta (D-025) |
|---|---|---|---|
| App sem documento (RSS) | 335 MB | **370 MB** | ≤ 340 MB ❌ |
| As 30 páginas abertas (RSS) | 364 MB | **433 MB** | ≤ 380 MB ❌ |
| Pico no roteiro (USS / PSS / RSS) | 314 / 330 / 383 MB | **358 / 378 / 456 MB** | |
| Tecla → ladrilho, p50 / p95 | 6,4 / 11,4 ms | **5,7 / 9,3 ms** | p95 ≤ 16 ms ✅ |
| Rolar as 30 páginas | 59,5 fps, 0 quadros > 16 ms | **59,7 fps, 0 quadros > 16 ms** | 60 fps ✅ |
| Abrir as 30 páginas | 515 ms | **356 ms** | ≤ 400 ms ✅ |
| Primeiro ladrilho | 720 ms | 709 ms | |
| Papel escuro (luminância) | 233 → 51 → 232 | 232 → 51 → 232 | |

**A primeira medição foi pior:** 54 fps com quadros lentos, p95 de 13,6 ms e o primeiro ladrilho em 1,3 s. O painel Formatar se refazia a cada ladrilho novo. Com a memoização da faixa e do painel (D-037), ficou como na tabela.

### Para onde foi a memória a mais

As etapas do `--bench`, contra as da Fase 1:

| Etapa | Fase 1 | Fase 2 | Diferença |
|---|---|---|---|
| Flutter, antes do motor | 127 MB | 133 MB | +6 MB (o código novo) |
| O motor ligado | 241 MB | 259 MB | +18 MB |
| O documento vazio | 335 MB | 370 MB | +35 MB |
| O capítulo | 364 MB | 433 MB | +69 MB |

**Uma execução sem a ortografia** (`LOK_ALLOWLIST_LANGUAGES=xx_XX`) deu 367 MB vazio e 402 MB com o capítulo. A ortografia custa uns **31 MB no capítulo** (o hunspell e a verificação do texto inteiro) e uns 600 ms no primeiro ladrilho dessa execução. Com só pt-BR e en-US na lista, deu o mesmo que com os 8 idiomas: o custo não é o número de idiomas.

**Medido depois, parte por parte (D-038):** comparando com a build da Fase 1 no mesmo dia, o que cresceu foi a memória anônima com o capítulo aberto (+46 MB). Uns 35 MB são o dicionário pt-BR do Hunspell, uns 3 MB o serviço de idiomas, uns 3,5 MB o painel Formatar, e uns 4 MB o resto. Sem o capítulo, as duas fases ficam a uns 10 MB uma da outra: a diferença de 35 MB no documento vazio, na tabela acima, era ruído entre dias.

## Testes por nível

| Nível | Ferramenta | Testes | O quê (novo na Fase 2 em negrito) |
|---|---|---|---|
| Unidade | `flutter test test/unit` | 135 (Fase 1: 97) | Os de antes, mais: **busca, menu de contexto, imagem, tabela, listas de estilos, medidas (polegadas com vírgula → cm), tamanho do objeto**; **o controlador: estilos, localizar e substituir com a contagem, o menu de contexto e a sugestão, imagem e arraste, tabela, recuos, entrelinha, página (e paisagem trocando o tamanho), margens, cores, a revisão dos estados**; **a busca da paleta (sem acento, pelo menu)**; **cm nos dois idiomas** |
| Nativo | GoogleTest | 21 | Sem mudanças |
| Widget | `flutter test test/widget` | 71 (Fase 1: 56) | Os de antes, mais: **os menus 97 (todos os comandos existem), Ctrl+L, Enter, "Todas" e Esc, Ctrl+U e "Substituir todas", a paleta, o painel (cor, recuo, Revelar, F10), o clique direito com as sugestões, inserir tabela e a aba de contexto, inserir imagem com as alças e o arraste, novo estilo, o Clássico 97, a galeria, a pré-edição cancelada** |
| Integração | `integration_test` com o LOK real | 1 (20 passos; Fase 1: 13) | Os de antes, mais: **a ortografia (o pt-BR ligado, o menu de contexto na tela, Esc fecha), localizar (contagem, maiúsculas, nada) e substituir com expressão regular, estilo novo e recuo pelo painel, tabela, imagem e arraste da alça, A5 em paisagem, e tudo conferido no XML do ODT** |
| Ponta a ponta | `tool/bench.sh`, `tool/fechar-test.sh` | 3 roteiros | Sem mudanças |

Tudo passa com `./test.sh --integracao`.

## Defeitos achados pelos testes

- **A paisagem não deitava a página.** O `.uno:AttributePage` só muda a marca da orientação. A integração pegou isso no XML salvo (14,8 × 21 cm "landscape"). Agora o tamanho é trocado antes (D-036).
- **Cancelar a pré-edição não limpava o texto em composição.** O `insertText('')` era ignorado. Agora é um `LOK_EXT_TEXTINPUT` vazio com confirmação.
- **O Enter num campo de medida soltava o foco**, e os atalhos paravam de funcionar. Agora o foco volta ao documento.
- **O painel Formatar travava a rolagem** (D-037).

## O que não foi verificado

- **As sugestões de ortografia no app de verdade.** No `lok_script`, o clique direito numa palavra errada traz as sugestões. No `integration_test`, com o mesmo caminho, o menu chega sem elas, e não achei a causa (D-033). **Peço ao Francisco:** abrir o app, digitar "erru", clicar com o botão direito na palavra e ver se aparecem sugestões.
- **Os atalhos no teclado ABNT2:** Ctrl+Shift+8 (marcas de formatação) e se o Ctrl+Espaço (limpar formatação) briga com a troca de idioma do sistema.
- **O seletor de imagens do GTK.** Os testes usam a porta falsa, como no abrir e salvar da Fase 1.
- **A aparência dos temas, sobretudo o Clássico 97.** Nenhuma captura de tela (CLAUDE.md). Os testes de widget conferem a estrutura e os nomes, não os pixels.
- **Documentos com mais de um tamanho de página.** O tamanho da página é deduzido do tamanho do documento (D-036).

## Perguntas para o Francisco

1. **A memória.** Respondida: a ortografia fica ligada por padrão, e os ~35 MB do Hunspell são aceitos (D-039).
2. **As sugestões de ortografia** aparecem no app quando você clica com o botão direito numa palavra errada?
