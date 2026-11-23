# Etapa 3: as prévias de fontes e estilos

**Objetivo:** ver a fonte e o estilo antes de escolher, como no Office 2007. As decisões são o D-044 (a cópia temporária, e nada de prévia no texto) e o D-045 (a lista de fontes).

## O que entrou

| O quê | Onde |
|---|---|
| A cópia temporária: pedir, ler num isolate, apagar | `DocumentController.refreshSnapshot`, `snapshot`, `cleanStaleCopies` |
| A cópia na porta do kit (sem `TakeOwnership`) e o evento próprio | `QuillKit.exportCopy`, `CopyExported`; `LokQuillKit._saves` separa cópia de salvamento |
| O leitor do ODT plano (estilos, fontes, títulos) | `lib/src/document/fodt.dart` |
| Os cartões com as propriedades de verdade | `styleSample` (`ribbon.dart`), `StyleCard` |
| A lista de fontes | `lib/src/ui/organisms/font_picker.dart` |
| Os filtros pelo fontconfig | `packages/psito_quill_kit/linux/core/font_info.cc`, `pqk_font_classes`, `QuillKit.fontClasses` |
| As fontes recentes | `Settings.recentFonts`, `useFont` (`fontesRecentes`) |
| A galeria aberta | `lib/src/ui/organisms/styles_dialog.dart` (`StylesDialog`) |
| A origem no "Revelar formatação" | `lib/src/document/format_origin.dart`; `_RevealSection` e `_OriginTag` no `inspector.dart` |

## Como funciona

**A cópia.** Ao abrir, ao salvar e ao criar ou atualizar um estilo, o controlador pede ao motor uma cópia em ODT plano no `$XDG_RUNTIME_DIR` (memória, só do usuário). O núcleo responde com o mesmo evento de um salvamento; o `LokQuillKit` sabe, pela fila, que era uma cópia e manda `CopyExported`. O controlador lê o arquivo num isolate (`Isolate.run(parseFodt)`), apaga o arquivo e a trava do LibreOffice ao lado, e guarda só o resultado: um mapa de estilos (fonte, tamanho, peso, itálico, cor, alinhamento, recuos, com a herança resolvida), a lista de fontes declaradas e os títulos. Um pedido no meio de outro espera a vez (um só por vez). Ao iniciar, o Quill apaga cópias de uma sessão que caiu.

**Nunca a cada tecla.** A cópia grava o documento inteiro na fila do motor. No capítulo de 30 páginas é rápida, mas num livro inteiro pode levar mais; por isso ela só vem nos momentos acima.

**Sem prévia no texto** (D-044): aplicar e desfazer ligaria o Refazer, e o autor perderia o que tinha para refazer. A prévia fica nos cartões e na lista, desenhada pelo Flutter.

**A lista de fontes** monta uma lista achatada (títulos de seção e fontes, `fontListItems`) e a mostra num `ListView.builder` de altura fixa. A classe de cada fonte vem de uma chamada só ao fontconfig, guardada num mapa no controlador.

## O que os testes conferem

- `test/unit/fodt_test.dart`: com a cópia de verdade do capítulo (`test/fixtures/capitulo-30p.fodt`), os estilos, a herança, as fontes e os títulos; num XML montado à mão, a porcentagem relativa ao pai, a cor, o alinhamento, os recuos, os nomes codificados (`Cita_e7__e3_o`) e o texto do título sem as marcas.
- `test/unit/fase2_controller_test.dart` (grupo "a cópia temporária"): pedida ao abrir, o arquivo some, não vira salvamento; a fila de pedidos; salvar pede outra; fechar esquece; as cópias velhas somem.
- `test/unit/format_origin_test.dart`: estilo ou direto em cada aspecto.
- `test/widget/fase2b_previews_test.dart`: a lista achatada; a lista de fontes na própria fonte, com seções, busca e filtro; escolher aplica, guarda nas recentes e fecha; Enter aplica a primeira; os cartões com as propriedades; o "Revelar formatação" com "direto" e "estilo"; a galeria aberta com o atalho, "Do livro" e a busca.
- Nativo (`test/font_info_test.cc`): as classes das fontes Liberation e DejaVu, uma por linha, e 0 para a que não existe.
- `integration_test/engine_test.dart`, passo 2b: no LibreOffice de verdade, a cópia chega, o arquivo some, o documento continua o mesmo, e o fontconfig classifica as fontes.

## Para o Francisco conferir

- A lista de fontes: os nomes na própria fonte, e os filtros (alguma fonte no filtro errado?).
- Os cartões de estilo: parecem os estilos do livro?
- O "Revelar formatação" (Shift+F1) num trecho com itálico à mão: "direto".
