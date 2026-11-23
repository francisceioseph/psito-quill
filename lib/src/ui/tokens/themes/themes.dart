import '../../../kit/lok/lo_profile.dart';
import '../tokens.dart';
import 'alto_contraste.dart';
import 'classico97.dart';
import 'claro.dart';
import 'escuro.dart';
import 'sepia.dart';

export 'alto_contraste.dart';
export 'classico97.dart';
export 'claro.dart';
export 'escuro.dart';
export 'sepia.dart';

/// Os temas que vêm com o app. Os de alto contraste entraram na Etapa 9 da
/// Fase 2B (D-067).
const List<QuillTokens> builtInThemes = [claro, escuro, sepia, altoContrasteEscuro, altoContrasteClaro, classico97];

/// Os temas de alto contraste: o tokens_test exige 7:1 no texto.
bool isHighContrast(QuillTokens t) => t.id.startsWith('altoContraste');

/// As cores do ondulado da ortografia (Acessibilidade, D-067), em 0xRRGGBB.
/// O vermelho é o do LibreOffice (null: sem a entrada no esquema).
const spellMarkColors = <String, int?>{'vermelho': null, 'azul': 0x1A5FD6, 'laranja': 0xE66A00};

/// O tema de um id (o primeiro, se não existe).
QuillTokens themeById(String id) => builtInThemes.firstWhere((t) => t.id == id, orElse: () => builtInThemes.first);

/// O esquema de cor do LibreOffice de cada tema, a partir dos tokens.
List<PaperScheme> paperSchemes(Iterable<QuillTokens> themes, {int? spell}) => [
      for (final t in themes)
        PaperScheme(
          name: t.paperScheme,
          paper: t.colors.paper.toARGB32() & 0xFFFFFF,
          ink: t.colors.paperInk.toARGB32() & 0xFFFFFF,
          backdrop: t.colors.backdrop.toARGB32() & 0xFFFFFF,
          spell: spell,
        ),
    ];
