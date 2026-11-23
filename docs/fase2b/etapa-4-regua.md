# Etapa 4: a régua

**Objetivo:** a régua detalhada do desenho: as margens, a medida com o zero na margem, os recuos que se arrastam e andam pelo teclado, as tabulações, e a régua vertical. A decisão é o D-046.

## O que entrou

| O quê | Onde |
|---|---|
| O callback 35 vira `RulerUpdated(RulerInfo)` | `lib/src/kit/quill_kit.dart`, `parseRuler` em `lib/src/kit/lok/lok_payloads.dart` |
| A régua do parágrafo no controlador | `DocumentController.ruler` |
| As margens da página na cópia (para a vertical) | `FodtSnapshot.pageMargins` (`lib/src/document/fodt.dart`) |
| Onde a página está na tela | `DocViewport`, publicado pelo `DocumentView` (`viewport:`) |
| As réguas, a moldura e a linha tracejada | `lib/src/ui/organisms/ruler.dart` (`HorizontalRuler`, `VerticalRuler`, `RulerFrame`) |
| Exibir › Régua e a unidade | `ViewCommandIds.ruler`; `Settings.ruler`, `Settings.rulerUnit` |

## Como funciona

A `EditorPage` embrulha o `DocumentView` num `RulerFrame` quando a régua está ligada. A horizontal fica em cima, depois de um canto do tamanho da vertical, e por isso o x da régua é o mesmo x da página. Os dados do parágrafo (`RulerData`: a régua do motor e os recuos em cm) vão para o desenho. A posição na tela vem do `DocViewport`, que só repinta.

**A geometria** (`HRulerGeometry`): `pxPerCm` = escala × twips por cm; a margem esquerda = borda da página + `leftOffset`; o texto vai até `margin2`. As marcas ficam em: esquerdo = margem + recuo; primeira linha = margem + recuo + primeira linha; direito = fim do texto − recuo direito.

**A vertical** pinta cada página visível da pilha do motor (as páginas têm 284 twips entre si, D-036), com as margens de cima e de baixo da cópia, e a medida a partir da margem de cima.

## O que os testes conferem

- `test/unit/ruler_test.dart`: o callback 35 de verdade (com a chave repetida), a geometria com o zero na margem, os recuos depois de arrastar (o esquerdo leva a primeira linha junto), o arredondamento para o milímetro.
- `test/widget/fase2b_ruler_test.dart`: as réguas aparecem com o documento e as marcas têm nome; arrastar o recuo esquerdo só manda ao soltar, com o esquerdo e a primeira linha; pelo teclado, a seta anda 1 mm; Exibir › Régua esconde e guarda.
- `test/unit/fodt_test.dart`: as margens do estilo de página.
- `integration_test/engine_test.dart`, passo 2c: no LibreOffice de verdade, o callback 35 chega ao abrir, com a largura da A4 e a margem esquerda do capítulo, e as margens vêm da cópia.

## O que não foi feito

- Criar, mover e apagar tabulações pela régua, e o seletor do tipo de tabulação no canto: a régua só mostra as tabulações (o comando para criá-las ainda não foi sondado).
- Arrastar as margens da página pela régua (elas mudam pela faixa Layout e pelo painel Formatar).
- A régua acompanha a primeira coluna de páginas; com várias páginas lado a lado (Etapa 5), ela segue a da esquerda.

## Para o Francisco conferir

- A régua em 100 %, 150 % e 50 %: os números e os tracinhos legíveis, sem amontoar.
- Arrastar os três recuos num parágrafo do livro; a linha tracejada e a medida aparecem.
- Tab até uma marca e as setas (e com Shift).
