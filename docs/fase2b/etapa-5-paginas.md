# Etapa 5: várias páginas e a Estrutura

**Objetivo:** ver várias páginas lado a lado (tirar o zoom e ver o capítulo) e navegar pelos títulos. A decisão é o D-047.

## O que entrou

| O quê | Onde |
|---|---|
| O `.uno:ViewLayout`, mandado só quando muda | `DocumentController.setViewLayout`, `viewColumns`, `bookMode` |
| A disposição na barra de status (e nas preferências) | `EditorPage` (o `WSegmented` da barra), `Settings.pageLayout` |
| As colunas pelo zoom em "Várias" | `EditorPage._applyLayout`, ouvindo o `DocViewport` |
| O zoom mínimo de 20 % | `minZoom` |
| A página de cada título e o título atual | `OutlineEntry.page`, `currentHeading` (`lib/src/document/outline.dart`), `parseFodt` |
| A Estrutura ao vivo só com o painel aberto | `DocumentController.liveOutline` (pausa de 2 s, `outlinePause`) |
| Ir para um título | `DocumentController.goToHeading` |
| O painel com os títulos | `OutlinePanel` (já da Etapa 2), alimentado pela `snapshot.outline` |

## Como funciona

**As colunas.** Em "Várias", cada mudança do `DocViewport` (zoom, tamanho da janela) recalcula quantas páginas cabem: `(largura da área − 48) ÷ ((largura da página + 284 twips) × escala)`, entre 1 e 12. O `setViewLayout` compara com o que já está e só então manda o comando, e o motor responde com o tamanho novo do documento.

**A Estrutura ao vivo.** As teclas e o texto confirmado chamam `_edited()`. Com `liveOutline` ligado (o painel aberto), um `Timer` de 2 s é reiniciado a cada edição; quando a digitação para, ele pede a cópia. Fechado o painel, só fica marcado que houve edição, e abrir o painel pede a cópia na hora.

## O que os testes conferem

- `test/widget/fase2b_pages_test.dart`: o Livro manda duas colunas no modo livro e não repete; Uma volta; em "Várias", mais colunas no zoom de 30 %; a Estrutura mostra os títulos recuados, marca o atual e o clique busca o título; a pausa de 2 s com o painel aberto refaz a cópia, e com ele fechado não.
- `test/unit/fodt_test.dart`: a página de cada título pelas quebras, e o título atual.
- `integration_test/engine_test.dart`, passo 2d: no LibreOffice de verdade, o salto ao último título chega à página dele, e três colunas deixam o documento com três páginas de largura (e voltam).

## Para o Francisco conferir

- "Várias páginas" em 30 % num capítulo inteiro, e mudar o tamanho da janela.
- "Livro (pares)": a primeira página sozinha à direita, depois os pares.
- A Estrutura num capítulo com Título 1 e 2: o atual acompanha a página.
