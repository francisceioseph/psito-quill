# Fase 1: resultados

O editor básico (seção 10 do `PLANO.md`), em 22/11/2026.

**Resumo:** o Quill já edita um capítulo de verdade:
- digitar com acentos compostos (pelo IME do sistema), desfazer e refazer, copiar e colar com a formatação;
- a faixa Início, a barra de status, os temas Claro e Escuro (lembrados entre as sessões);
- abrir e salvar ODT e DOCX, salvar como, os recentes;
- a trava do LibreOffice tratada (a velha some, a dos outros vira só leitura);
- a pergunta "salvar as alterações?";
- o título da janela.

A memória caiu uns 20 MB. Com as metas revistas (D-025), o app fica dentro: 335 MB vazio (meta de 340 MB) e 364 MB com o capítulo (meta de 380 MB). Abrir em 400 ms continua em aberto (515 ms).

## O que entrou

| Item do plano | Como ficou |
|---|---|
| O `QuillKit` completo para texto | Cursor e seleção (já da Fase 0); teclado com as rotas do D-015; IME pelo `TextInput` do Flutter e o `postWindowExtTextInputEvent` do LOK; desfazer e refazer com o estado do motor; copiar, recortar e colar (D-016); selecionar tudo; zoom (de 50 % a 300 %, Ctrl+roda) |
| A faixa Início | Área de transferência, estilo de parágrafo, fonte e tamanho, negrito, itálico, sublinhado, tachado, os quatro alinhamentos, marcadores e numeração. Salvar, Desfazer e Refazer no acesso rápido (D-023) |
| A barra de status | Mensagem, página (3 de 30), palavras (ou palavras selecionadas), só leitura, modificado, idioma, zoom com − e + |
| Os temas Claro e Escuro | Já existiam. Agora a escolha fica nas preferências, e o papel do motor segue o tema |
| Abrir e salvar ODT e DOCX | O seletor do GTK (`file_selector`); salvar no formato do arquivo; salvar como em ODT ou DOCX, e o documento passa a ser o arquivo novo (D-019) |
| Os recentes | Os 10 últimos, no painel Arquivo; um arquivo que sumiu sai da lista ao falhar |
| Atomic design desde o primeiro widget | Átomos novos (`WTextButton`, `WDropdown`, `WSeparator`), moléculas (`CommandButton`, `RibbonGroup`, `InfoBanner`), organismos (`Ribbon`, `FilePanel`, o diálogo "salvar?"). Nenhuma cor fora dos temas |

**Pendências da Fase 0 resolvidas:**
- a trava: detectar o modo só leitura e limpar as travas velhas (D-017);
- a escolha do jogo de atalhos nas preferências (D-012, D-024);
- a memória: o motor só pinta a largura do documento, e as vagas de ladrilho saem do tamanho da tela (D-020).

## Os números

Mediana de 4 execuções do `tool/bench.sh` (mesma máquina e documento da Fase 0). A memória varia uns 20 MB entre execuções.

| | Fase 0 | Fase 1 | Meta (seção 8) |
|---|---|---|---|
| App sem documento (RSS) | 349 MB | **335 MB** | ≤ 340 MB ✅ (era ≤ 250) |
| As 30 páginas abertas (RSS) | 384 MB | **364 MB** | ≤ 380 MB ✅ (era ≤ 320) |
| Pico no roteiro (USS / PSS / RSS) | 343 / 352 / 404 MB | **314 / 330 / 383 MB** | |
| Tecla → ladrilho, p50 / p95 | 6,9 / 12,3 ms | **6,4 / 11,4 ms** | p95 ≤ 16 ms ✅ |
| Rolar as 30 páginas | 59,8 fps, 0 quadros > 16 ms | **59,5 fps, 0 quadros > 16 ms** | 60 fps ✅ |
| Abrir as 30 páginas | 555 ms | **515 ms** | ≤ 400 ms ❌ |
| Primeiro ladrilho | 736 ms | 720 ms | |
| Vagas de ladrilho (1920×1080) | 128 (32 MB) | 72 (18 MB) | |
| Papel escuro (luminância) | 232 → 51 → 232 | 233 → 51 → 232 | |

**O `trimMemory` do LibreOffice não devolveu nada** (372,6 MB antes e depois). Fica fora do app (D-021).

### Para onde vai a memória

Com o capítulo aberto, uns 364 MB de RSS:
- uns 126 MB são do Flutter com o Impeller, antes de o motor ligar;
- uns 110 MB, do LibreOffice ligado sem documento;
- uns 100 MB, do documento vazio (o Writer inteiro carregado);
- uns 30 MB, do capítulo.

Os ladrilhos agora pesam 18 MB, e a página só pede os que estão sobre o documento.

## As metas de memória: revistas (D-025)

As metas de 250 MB (vazio) e 320 MB (capítulo) foram escritas antes de medir. O piso, só com o Flutter e o Writer vazio, já é uns 335 MB. As ideias que sobram, em ordem de custo:

1. **Medir o Skia contra o Impeller.** O Flutter sozinho custa 126 MB, e o Impeller tem caches próprios.
2. **Desligar no perfil o que o Quill não usa:** a autocorreção de tabelas, a galeria, o Basic.
3. **O motor em outro processo** (PLANO 1.2): a memória total não cai, mas a do app fica separada.

O Francisco aprovou rever as metas para ≤ 340 MB vazio e ≤ 380 MB com o capítulo, mantendo as de rapidez. As ideias acima ficam guardadas. A meta que mais importa, **não crescer em sessões longas**, ainda não foi medida a sério. O teste de resistência (30 min digitando) é o próximo passo de medição.

## Testes por nível

| Nível | Ferramenta | Testes | O quê (novo na Fase 1 em negrito) |
|---|---|---|---|
| Unidade | `flutter test test/unit` | 97 (Fase 0: 43) | Callbacks do LOK, **estados (página, palavras, fontes)**, teclas → VCL, **a rota das teclas (IME, motor, engolida; AltGr; tecla morta)**, `CommandRegistry` **(nenhum atalho repetido nos dois jogos, os do Word em português)**, perfil do LO, **a trava (velha, dos outros, outra máquina)**, **recentes**, **preferências**, controlador **(IME, desfazer, copiar e colar, só leitura, zoom, salvar como)**, **`Workspace` (abrir, trava, recentes, salvar sem arquivo, "salvar?", sair)**, **vagas de ladrilho**, tokens |
| Nativo | GoogleTest | 21 | Fila do kit, cache LRU, caixa de areia do Lua (sem mudanças) |
| Widget | `flutter test test/widget` | 56 (Fase 0: 30) | Átomos nos temas Claro, Escuro e bisel, **`WDropdown`, `WTextButton`**; a página **(IME e pré-edição, Enter e setas, Ctrl+letra engolida, Ctrl+setas, só leitura, Ctrl+roda)**; a tela **(a faixa, as dicas com o atalho, listas de estilo, fonte e tamanho, a barra de status, o aviso de só leitura e a cópia, o título da janela, "salvar?", o painel Arquivo e os recentes, trocar o jogo de atalhos, o tema nas preferências, arquivo que não abre)**, rótulos de acessibilidade |
| Integração | `integration_test` com o LOK real | 1 (13 passos) | Abrir as 30 páginas, **a faixa e o status lendo o motor**, rolar, digitar, **o IME (´ + é)**, **desfazer**, negrito, **copiar e colar com a formatação**, salvar e conferir no XML do DOCX, **salvar como ODT**, **a trava de outro (o motor também recusa as teclas) e a cópia editável**, **a trava velha apagada**, Lua |
| Ponta a ponta | `tool/bench.sh`, `tool/fechar-test.sh` | 3 roteiros | As tabelas acima, **com o efeito do `trimMemory`**; **fechar a janela sai com código 0 e apaga a trava (D-027)** |

Tudo passa com `./test.sh --integracao`.

## Um defeito achado depois: o app quebrava ao fechar

Na primeira vez que o Francisco abriu o app, fechar a janela deu "Falha de segmentação". Os destrutores estáticos do LibreOffice rodavam no `exit()`. O documento já estava fechado, e nada se perdia, mas o erro aparecia e um núcleo era gravado. Corrigido no runner (D-027), com um teste de ponta a ponta que fecha a janela de verdade.

## Mais três defeitos achados pelo Francisco

- **O zoom fazia a página pular.** A rolagem não compensava a escala, os ladrilhos antigos sumiam antes dos novos e faltava a rolagem horizontal. Corrigido (D-028).
- **O cursor não aparecia até a primeira tecla.** O LibreOffice manda a posição do cursor ao abrir, mas o "cursor visível" só depois de digitar, e o Quill esperava por ele. O kit falso mandava "visível" ao abrir, e por isso os testes não pegaram. Agora o falso faz como o motor, e o cursor começa visível.
- **O clique triplo selecionava só a frase** (é o padrão do LibreOffice). Agora seleciona o parágrafo, como no Word, e o Ctrl+clique seleciona a frase. A série de cliques ficou mais tolerante: 500 ms entre um e outro (D-028).

## O que não foi verificado

- **O IME do GTK com o teclado ABNT2 de verdade.** A integração prova o caminho do motor (pré-edição e confirmação), e o teste de widget prova o lado do Flutter. Mas ninguém digitou `´` + `a` numa janela do Quill, porque não mexo no teclado da sessão (CLAUDE.md). **Peço ao Francisco:** abrir o app, digitar `café`, `ação`, `à`, `ü` e `Ç`, e conferir.
- **O seletor de arquivos do GTK e a área de transferência do sistema.** Os testes usam portas falsas. Abrir, salvar como e colar de outro app precisam de uma passada à mão.
- **A escala fracionária (1,25x).** Continua sem teste, como na Fase 0.
- **Nenhuma captura de tela nesta fase.** Uma tentativa com o `xwd` pegou o conteúdo de outra janela do usuário, que cobria o Quill. A imagem foi apagada na hora, e o `CLAUDE.md` agora proíbe capturas de tela.
- **O título da janela** foi conferido pelo `wmctrl`: "tela.docx — Psito Quill".

## Respostas do Francisco

1. **As metas de memória:** revistas para algo razoável, sem perder a rapidez (D-025).
2. **Arquivo travado por outro:** continua só leitura, mais simples e mais seguro (D-017).
3. **O Windows:** depois da Fase 6 (D-026).
