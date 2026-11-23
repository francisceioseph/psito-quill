# Etapa 1: a fundação Material 3

**Objetivo:** os tokens, os ícones e os átomos no visual do desenho (canvas "Psito Quill — nova interface"), sem mudar ainda a disposição da tela (isso é a Etapa 2). A decisão é o D-042.

## O que entrou

| O quê | Onde |
|---|---|
| Os papéis do M3 no `QuillColors` (com os nomes antigos mapeados) | `lib/src/ui/tokens/tokens.dart` |
| Os tons do Claro e do Escuro (semente #415F91) | `lib/src/ui/tokens/themes/claro.dart`, `escuro.dart` |
| O Clássico 97 com os papéis novos em cinza | `lib/src/ui/tokens/themes/classico97.dart` |
| O `ColorScheme` do M3 montado dos tokens, `useMaterial3`, densidade compacta | `QuillTokens.toThemeData` |
| `QuillDensity.compact` e `.comfortable` (e o tamanho do ícone) | `tokens.dart` |
| Os ícones Material Symbols Rounded | o pacote `material_symbols_icons`; 8 arquivos migrados |
| O ligado tonal, o ícone preenchido, as abas em pílula, o campo em `surfaceLowest` | `lib/src/ui/atoms/w_button.dart`, `w_text_field.dart`, `w_dropdown.dart` |
| Átomos novos | `w_segmented.dart`, `w_switch.dart`, `w_slider.dart`, `w_chip.dart` |
| Testes | `test/widget/atoms_m3_test.dart`, `test/unit/tokens_test.dart` |

## A tabela dos papéis

| Token | Papel do M3 | Claro | Escuro | Onde aparece |
|---|---|---|---|---|
| `frame` | surface | #F9F9FF | #111318 | o fundo da janela |
| `frameRaised` | surfaceContainerLow | #F3F3FA | #191C20 | a faixa, os painéis |
| `surfaceContainer` | surfaceContainer | #EDEDF4 | #1D2024 | os menus |
| `surfaceHigh` | surfaceContainerHigh | #E7E8EE | #282A2F | o realce do mouse |
| `surfaceHighest` | surfaceContainerHighest | #E2E2E9 | #33353A | apertado, trilhos |
| `surfaceLowest` | surfaceContainerLowest | #FFFFFF | #0C0E13 | os campos |
| `onFrame` / `onFrameMuted` | onSurface / onSurfaceVariant | #191C20 / #44474E | #E2E2E9 / #C4C6D0 | texto, ícones |
| `border` / `outline` | outlineVariant / outline | #C4C6D0 / #74777F | #44474E / #8E9099 | divisórias / segmentados |
| `accent` | primary | #415F91 | #AAC7FF | a marca, o switch ligado |
| `accentSoft` / `onAccentSoft` | secondaryContainer | #DAE2F9 / #3E4759 | #3E4759 / #DAE2F9 | ligado, aba atual |
| `accentContainer` | primaryContainer | #D6E3FF | #284777 | "direto" no Revelar |
| `tertiaryContainer` | tertiaryContainer | #FAD8FD | #573E5C | abas Tabela e Imagem |
| `backdrop` | — | #EDEDF4 | #0C0E13 | atrás das páginas |

## Os átomos

- **`WControlSurface`** (base de `WButton`, `WToggle`, `WTextButton`, `WDropdown`, `WChip`): só ícone é um quadrado de 32 px sem margem; o ligado tem fundo `accentSoft`, texto `onAccentSoft` e ícone com `fill: 1` e peso 500; `pill` deixa os cantos inteiros (as abas); `height` próprio (o chip tem 28 px).
- **`WSegmented<T>`:** um contorno `outline` com divisórias; cada segmento é focável, fala "escolhido" e está num grupo exclusivo para o leitor de tela; `iconOnly` deixa o rótulo só na dica.
- **`WSwitch`:** 52×32, a bolinha cresce de 16 para 24 px; no 97, uma caixinha de marcar afundada.
- **`WSlider`:** o `Slider` do Flutter com as cores dos tokens. `onChangeEnd` existe para o que é caro (o zoom do motor) ir só ao soltar.
- **`WChip`:** filtro com estado de escolhido.

## Memória

O que podia pesar era a fonte de ícones (a Rounded inteira tem uns 4 MB por estilo). Na build de release, o Flutter recorta as fontes e deixa só os ícones usados: a `MaterialSymbolsRounded.ttf` do pacote final tem **165 KB**, com os eixos variáveis (FILL, peso) preservados; a Outlined e a Sharp, que não são usadas, ficam com 2 KB cada.

`tool/ab.py ac8a2d6` (a Etapa 0 mediu ≈0 contra esse commit, então a diferença é desta etapa), 23/11/2026, mediana de 3 (MB):

| Etapa do bench | Anônima antes | Anônima Etapa 1 | Δ | RSS antes | RSS Etapa 1 |
|---|---|---|---|---|---|
| Motor ligado | 108,4 | 108,7 | +0,3 | 258,2 | 260,1 |
| Vazio | 179,1 | 175,4 | −3,7 | 366,5 | 364,0 |
| Capítulo de 30 páginas | 232,8 | 227,9 | −4,9 | 432,7 | 429,5 |
| Depois de digitar | 241,8 | 243,4 | +1,6 | 443,1 | 446,4 |

Abrir: 300 → 294 ms. Rolar: 59,7 fps nos dois. Tecla → ladrilho p95: 9,5 → 9,3 ms. Nada cresceu além do ruído. `./test.sh --integracao` verde.

## Para o Francisco conferir

- Os três temas: o ligado (Negrito com o cursor num texto em negrito) aparece tonal e com o ícone cheio.
- Os ícones novos: nenhum quadrado vazio (ícone que faltou).
