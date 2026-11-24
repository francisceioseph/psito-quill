# Fase 2B: resultados

A interface nova (seção 10 do `PLANO.md`), em 23/11/2026. O detalhe de cada etapa está em `docs/fase2b/`, e as decisões vão do D-041 ao D-067.

**Resumo:** o Quill ganhou a cara que os desenhos pediam, e a memória ficou onde estava.
- Material 3 com densidade de desktop, ícones Material Symbols e a fonte do sistema;
- a faixa que se adapta à largura, como a do Office, e o Início redistribuído;
- as prévias das fontes e dos estilos;
- a régua, com as marcas do Word;
- várias páginas e o modo Livro, e a Estrutura dos títulos;
- o modo zen (tela cheia, máquina de escrever, foco, papel sépia);
- as abas de documentos, a busca única e o menu de contexto próprio;
- os trilhos dos dois lados, a barra de status clicável, os bastidores do Arquivo, a tela inicial e a aba Exibir;
- o progresso no rodapé, sem janelas;
- a acessibilidade: alto contraste, a interface até 200 %, o cursor, reduzir movimento e o documento no leitor de tela.

**A memória cresceu pouco:** +11,3 MB de memória anônima com o capítulo, em dez etapas (o orçamento era ~5 MB por etapa). A rolagem (59,5 fps) e a tecla → ladrilho (p95 9,4 ms) ficaram iguais.

**Abrir o capítulo ficou mais lento na medida, e menos de verdade:** o bench deu 369 ms na Fase 2 e 854 ms agora (meta de 400 ms). A investigação (D-068) mostrou que a maior parte é o dicionário da ortografia caindo antes do "aberto", em vez de depois. A perda real, no primeiro ladrilho, era de ~200 ms e caiu para ~120 ms (abaixo).

## O que entrou, por etapa

| Etapa | O que ficou | Decisões |
|---|---|---|
| 0. Privacidade e linha de base | O perfil do LibreOffice trava os relatórios de falha, as macros, os links de fora e a lista de recentes do motor; os avisos do LibreOffice não saem no terminal; "Guardar os arquivos recentes" desligável; um teste confere que nada em `lib/` usa rede | D-041 |
| 1. A fundação Material 3 | Os tokens da semente #415F91, a densidade, os ícones (com tree-shaking) e os átomos novos (`WSegmented`, `WSwitch`, `WSlider`, `WChip`) | D-042 |
| 2. A casca do editor | A fileira de abas com o Arquivo e a pesquisa, a faixa num cartão, o trilho e o painel Formatar com só a seção visível, a barra de status, a aba Imagem | D-043 |
| 3. As prévias | A lista de fontes desenhada nelas mesmas, com os filtros do fontconfig; os cartões de estilo com as propriedades lidas de uma cópia do documento; "Revelar formatação" com a origem | D-044, D-045 |
| 4. A régua | As margens, os recuos e as tabulações do callback do motor; arrastar e o teclado; a régua vertical. Criar tabulações ficou de fora | D-046, D-058b, D-060 |
| 5. Várias páginas e a Estrutura | Uma, Várias e Livro pelo `.uno:ViewLayout`; a Estrutura lida da cópia, com o salto ao título pela busca | D-047, D-059 |
| 6. O modo zen | A tela cheia do GTK, a máquina de escrever só com a rolagem do Flutter, o foco por faixa de linhas, o papel sépia | D-048 |
| 7. A interface que respira | A escala maior, a faixa adaptável, a busca única, as abas de documentos (todas carregadas, com limite), o menu de contexto, os trilhos, a barra de status clicável, os bastidores, a tela inicial, a aba Exibir | D-049 a D-065 |
| 8. Ocupado sem janelas | O callback do escritório com o progresso; abrir e salvar travam a tela com o véu; o progresso no rodapé | D-066 |
| 9. Acessibilidade | Alto contraste (7:1), o tamanho da interface, os botões maiores, o cursor, reduzir movimento, a cor da ortografia, o zoom ao abrir, o documento no leitor de tela, as Preferências por seções | D-067 |

## Os números

`tool/ab.py ac8a2d6` (A, a Fase 2) contra o `cd31c5f` (B, o fim da Fase 2B), mediana de 3, no mesmo dia (D-038). A memória em MB.

| Etapa do bench | Anônima Fase 2 | Anônima Fase 2B | Δ | RSS Fase 2 | RSS Fase 2B | Δ |
|---|---|---|---|---|---|---|
| O motor ligado | 108,1 | 111,8 | +3,7 | 257,7 | 265,0 | +7,3 |
| O documento vazio | 173,9 | 180,2 | +6,3 | 367,7 | 376,4 | +8,7 |
| O capítulo de 30 páginas | 232,7 | 243,9 | +11,3 | 433,4 | 451,8 | +18,4 |
| Depois de rolar | 234,2 | 247,7 | +13,5 | 431,5 | 455,2 | +23,7 |
| Depois de digitar | 243,3 | 250,4 | +7,1 | 443,5 | 460,6 | +17,1 |

| | Fase 2 | Fase 2B | Meta (D-025) |
|---|---|---|---|
| Tecla → ladrilho, p95 | 9,2 ms | 9,4 ms | ≤ 16 ms ✅ |
| Rolar as 30 páginas | 59,7 fps | 59,5 fps | 60 fps ✅ |
| Abrir as 30 páginas | 369 ms | **854 ms** | ≤ 400 ms ❌ |

**Para onde foi a memória** (o `tool/mapas.py`, com o capítulo): a memória anônima +9,8 MB (o mapa não separa o Dart do motor nela), as fontes +2,5 MB de arquivo, o heap +1,6 MB e a `libmergedlo` +3,4 MB de arquivo (páginas do LibreOffice que o kernel devolve). O RSS sobe mais que a anônima por causa das páginas de arquivo.

### A lentidão ao abrir (investigada depois do fecho, D-068)

- **O "854 ms" era quase todo o dicionário da ortografia.** O pico estava no `initializeForRendering`: a thread do kit esperava a trava global do LibreOffice, que a thread principal dele segurava enquanto carregava o dicionário pt-BR do Hunspell (~800 ms, uma vez por processo). Às vezes isso cai antes do "aberto", às vezes depois, e o bench mede só até o "aberto". Na Fase 2, caía depois (o primeiro ladrilho vinha em 709 ms).
- **A perda real era no primeiro ladrilho,** medido lado a lado no mesmo dia: ~1320 ms na Fase 2 e ~1520 ms na 2B. A cópia do documento (a Estrutura e os estilos) e as listas de fontes, estilos e idiomas, pedidas ao abrir, passavam na frente dos ladrilhos na thread do motor. Agora esperam o primeiro ladrilho: ~1430 ms, com a Fase 2 a ~1315 na mesma rodada.
- **Fica:** ~120 ms acima da Fase 2 no primeiro ladrilho, e a meta de 400 ms no "aberto" sem cumprir enquanto o dicionário carregar junto com o primeiro capítulo.

## Testes por nível

| Nível | Ferramenta | Testes | O quê |
|---|---|---|---|
| Unidade | `flutter test test/unit` | 213 (Fase 2: 135) | Os de antes, mais: os tokens e o contraste dos cinco temas modernos (7:1 nos de alto contraste); o perfil do LibreOffice (a privacidade, os esquemas, a cor da ortografia, o esquema atual); nenhum uso de rede; a régua (a geometria, as fileiras de páginas, o cache dos números); a cópia lida (os estilos, os títulos, as páginas, a busca no texto); a origem da formatação; as abas |
| Nativo | GoogleTest | 23 (Fase 2: 21) | Os de antes, mais o fontconfig |
| Widget | `flutter test test/widget` | 200 (Fase 2: 71) | Os de antes, mais: os átomos M3 nos temas; a faixa adaptável nos quatro tamanhos de tela e em 800 px; as prévias; a régua; as páginas e a Estrutura; o zen; as abas; a busca única e o painel Localizar; os trilhos e os painéis; o menu de contexto (com o Esc); a barra de status (o idioma, as estatísticas, o zoom, o teclado); os bastidores e a tela inicial; a aba Exibir; o ocupado; a acessibilidade (alto contraste, a interface a 150 e 200 %, o cursor, reduzir movimento, o zoom ao abrir, o leitor de tela, as Preferências) |
| Integração | `integration_test` com o LOK real | 1 (21 passos; Fase 2: 20) | Os de antes, mais: o progresso ao abrir, o ocupado ao salvar, o Esc no menu de contexto, o leitor de tela |
| Ponta a ponta | `tool/bench.sh`, `tool/fechar-test.sh`, `tool/ab.py` | 3 roteiros | O `ab.py` é novo: as duas builds lado a lado |

Tudo passa com `./test.sh --integracao`.

## As sondas no motor (24.2)

Toda chamada nova ao LOK passou antes pelo `lok_script`. As que não fizeram o que o plano esperava, e o que ficou no lugar:

| Sonda | O que o motor fez | O que ficou |
|---|---|---|
| `.uno:ParaWidows` e `.uno:PageBreak` com valor (o menu de contexto) | nada | "Manter com o próximo" e "Manter as linhas juntas" pelo `ParaKeepTogether` e o `ParaSplit`, em pares, sem o estado (D-061) |
| `.uno:GotoPage` com valor (a barra de status) | abre uma janela e trava | Clicar na página abre a Estrutura (D-063) |
| `.uno:LanguageStatus` com a etiqueta (`Current_en-US`) | nada | O nome que o motor dá na lista dos idiomas (D-063) |
| O progresso ao salvar | nada (só abrir manda) | "Salvando…" com a barra sem número (D-066) |
| A cor da ortografia com o motor ligado | o ondulado não muda | A cor vale ao abrir o Quill (D-067) |
| A prévia ao vivo do estilo (aplicar e desfazer) | funciona, mas liga o Refazer: quem escreve perderia o que tinha para refazer | A prévia fica nos cartões e na lista, desenhada pelo Flutter (D-044) |
| O retângulo do parágrafo para o foco do zen | não usado: custa a cada tecla | O foco por faixa de linhas (D-048) |

As que deram certo e viraram código: o `.uno:ViewLayout` (as páginas), o callback da régua (35), os dois documentos no mesmo processo (as abas), o callback do escritório com o progresso (9 a 11), a acessibilidade (62 e 63) e a entrada `Spell` do esquema de cores.

## Defeitos achados pelos testes

- **O Esc no menu de contexto ia ao motor** e o menu ficava aberto: o foco continuava no documento. A integração pegou. Agora o foco fica com o menu enquanto ele está aberto.
- **O texto a 200 % vazava da faixa e do painel** (cinco estouros em 1366 px). Virou o tamanho da interface inteira (D-067).
- **O nome da régua vertical e o do zoom subiam para o nó da janela** no leitor de tela. O teste do rodapé mostrou; ganharam nó próprio.
- **A caixa da Régua na aba Exibir ficava velha:** a chave da memoização da faixa não tinha a preferência (D-065).
- **A régua sumia no modo Livro** e as marcas ficavam fora do lugar: a posição da página vem do `pageOffset` do motor, sem descontar o vão (D-059).
- **Os rótulos curtos dos recuos perdiam o nome para o leitor de tela** (D-062).
- **A lista do Localizar refazia a cópia ao rolar** (D-062).

## O que não foi verificado

- **O Orca no app de verdade:** os testes conferem o nó do documento (o valor e o cursor), não o que o Orca fala.
- **O IME com o teclado ABNT2** nas telas novas (o painel Localizar, os bastidores).
- **A aparência de cada tema,** sobretudo os de alto contraste, o Clássico 97 nas telas novas e a interface a 200 %. Nenhuma captura de tela (CLAUDE.md): os testes de widget conferem a estrutura, os nomes e os estouros, não os pixels.
- **A cor azul ou laranja da ortografia no app** (a sonda contou os pixels no `lok_script`).
- **Abrir um documento de centenas de páginas no app,** com a barra do rodapé andando (a sonda viu os números no `lok_script`; a integração usa um capítulo de 30 páginas, que só manda o fim).
- **"Abrir a pasta do arquivo"** no gerenciador de arquivos.

Cada `docs/fase2b/etapa-*.md` tem a sua lista "Para olhar à mão".

## Pendências da documentação

- **Os números D-057 e D-058 apareciam duas vezes** no `DECISOES.md` (decisões diferentes, escritas em sessões diferentes). As segundas viraram D-057b (o respiro dos painéis) e D-058b (a régua segue a página do cursor); as referências foram corrigidas.

## Perguntas para o Francisco

Respondidas no D-070:

1. **A tela inicial ao abrir sem arquivo:** continua o padrão.
2. **O tamanho da interface e a página:** o zoom da página compensa; a página não cresce com a interface.
3. **A mensagem "Plugin: olá do Lua":** o plugin fica só para os testes, e o app não o roda ao abrir.
