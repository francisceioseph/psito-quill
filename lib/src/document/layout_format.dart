// A Página Inicial, o Layout e o Inserir (Fase 4, Etapa 7, D-092): o pincel,
// maiúsculas e minúsculas, as listas de vários níveis, as colunas, os números
// de linha, a cor da página, a marca d'água, organizar as imagens e a caixa
// de texto. Parte do DocumentController. Sondados na 24.2: os nativos vão
// pelo `.uno:`; os números de linha, a cor da página e a caixa de texto, por
// macros do D-090.
part of 'document_controller.dart';

/// Maiúsculas e minúsculas (o Aa), pelos `.uno:ChangeCase*`.
enum TextCase {
  sentence('.uno:ChangeCaseToSentenceCase'),
  lower('.uno:ChangeCaseToLower'),
  upper('.uno:ChangeCaseToUpper'),
  title('.uno:ChangeCaseToTitleCase'),
  toggle('.uno:ChangeCaseToToggleCase');

  const TextCase(this.command);
  final String command;
}

/// As listas de vários níveis: os modelos do `.uno:SetOutline` que servem
/// (o número é o do motor; os três primeiros níveis, pela sonda).
enum MultilevelList {
  /// 1 · 1.1 · 1.1.1
  decimal(7),

  /// I. · A. · 1.
  roman(1),

  /// A. · 1. · a.
  letters(2),

  /// 1) · a) · 1)
  parenthesis(6),

  /// ➢ e os marcadores de baixo
  bullets(8);

  const MultilevelList(this.outline);
  final int outline;
}

/// Organizar a imagem selecionada (a ordem entre as que se sobrepõem).
enum Arrange {
  front('.uno:BringToFront'),
  forward('.uno:ObjectForwardOne'),
  backward('.uno:ObjectBackOne'),
  back('.uno:SendToBack');

  const Arrange(this.command);
  final String command;
}

/// A marca d'água (o `.uno:Watermark`, no cabeçalho de cada página).
@immutable
class WatermarkSpec {
  const WatermarkSpec({required this.text, this.color = 0xC0C0C0, this.diagonal = true});
  final String text;

  /// RGB.
  final int color;

  /// 45°; senão, na horizontal.
  final bool diagonal;
}

extension LayoutFormat on DocumentController {
  // ------------------------------------------------------- a Página Inicial --

  /// O pincel: a próxima seleção pelo mouse ganha a formatação da atual. O
  /// motor diz se está ligado.
  bool get paintbrushOn => isOn('.uno:FormatPaintbrush');
  void formatPaintbrush() => uno('.uno:FormatPaintbrush');

  void changeCase(TextCase c) => uno(c.command);

  void setMultilevelList(MultilevelList l) =>
      uno('.uno:SetOutline', '{"SetOutline":{"type":"unsigned short","value":${l.outline}}}');

  /// Um nível abaixo (o item vira um subitem) ou acima, na lista do cursor.
  void listLevelDown() => uno('.uno:DecrementLevel');
  void listLevelUp() => uno('.uno:IncrementLevel');

  // ----------------------------------------------------------------- o Layout --

  /// As colunas da página do cursor, pelo estado `.uno:PageColumnType`.
  int? get pageColumns => int.tryParse(commandStates['.uno:PageColumnType'] ?? '');
  void setPageColumns(int n) =>
      uno('.uno:PageColumnType', '{"PageColumnType":{"type":"short","value":${n.clamp(1, 3)}}}');

  void setLineNumbers(bool on) {
    uno(quillMacro('Linhas', [on]));
    refreshSnapshot();
  }

  /// [rgb] null tira a cor.
  void setPageColor(int? rgb) {
    uno(quillMacro('CorPagina', [rgb == null ? -1 : rgb & 0xFFFFFF]));
    refreshSnapshot();
  }

  /// [w] null tira a marca d'água.
  void setWatermark(WatermarkSpec? w) {
    final args = w == null || w.text.trim().isEmpty
        ? '{"Text":{"type":"string","value":""}}'
        : jsonEncode({
            'Text': {'type': 'string', 'value': w.text.trim()},
            'Angle': {'type': 'short', 'value': w.diagonal ? 45 : 0},
            'Transparency': {'type': 'short', 'value': 50},
            'Color': {'type': 'long', 'value': w.color & 0xFFFFFF},
          });
    uno('.uno:Watermark', args);
    refreshSnapshot();
  }

  void arrange(Arrange a) {
    if (graphic != null) uno(a.command);
  }

  // ---------------------------------------------------------------- o Inserir --

  /// Uma caixa de texto de 6 cm no parágrafo do cursor, com o cursor dentro.
  void insertTextBox() => uno(quillMacro('Caixa', [6000]));
}
