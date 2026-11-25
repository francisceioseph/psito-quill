// As cores do documento que o painel Formatar oferece (RGB, como o
// LibreOffice as guarda). São do texto do autor, não da interface: não
// mudam com o tema.

enum DocColorName { black, gray, red, orange, yellow, green, blue, purple }

/// Cor da fonte: as da paleta padrão do LibreOffice.
const fontColorChoices = <(DocColorName, int)>[
  (DocColorName.black, 0x000000),
  (DocColorName.gray, 0x666666),
  (DocColorName.red, 0xC9211E),
  (DocColorName.orange, 0xFF8000),
  (DocColorName.green, 0x00A933),
  (DocColorName.blue, 0x2A6099),
  (DocColorName.purple, 0x800080),
];

/// Realce: as claras, que deixam o texto legível.
const highlightChoices = <(DocColorName, int)>[
  (DocColorName.yellow, 0xFFFF00),
  (DocColorName.green, 0x81D41A),
  (DocColorName.blue, 0x729FCF),
  (DocColorName.orange, 0xFFBF00),
  (DocColorName.gray, 0xDDDDDD),
];

/// A cor da página (D-092): claras, para o texto continuar legível. Na ordem
/// dos nomes da faixa (creme, cinza, azul, verde, amarelo).
const pageColorValues = <int>[0xFFF5E0, 0xEEEEEE, 0xDEE6EF, 0xE8F2D0, 0xFFFFD7];

/// A marca d'água: os cinzas e as cores claras, que deixam o texto legível
/// por cima.
const watermarkColorValues = <int>[0xC0C0C0, 0x808080, 0xFFA6A6, 0xB4C7DC, 0xAFD095];
