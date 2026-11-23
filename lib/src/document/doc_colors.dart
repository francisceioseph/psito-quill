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
