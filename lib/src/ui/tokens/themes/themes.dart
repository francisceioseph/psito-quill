import '../../../kit/lok/lo_profile.dart';
import '../tokens.dart';
import 'classico97.dart';
import 'claro.dart';
import 'escuro.dart';

export 'classico97.dart';
export 'claro.dart';
export 'escuro.dart';

/// Os temas que vêm com o app. Sépia e Alto contraste entram na Fase 6.
const List<QuillTokens> builtInThemes = [claro, escuro, classico97];

/// O esquema de cor do LibreOffice de cada tema, a partir dos tokens.
List<PaperScheme> paperSchemes(Iterable<QuillTokens> themes) => [
      for (final t in themes)
        PaperScheme(
          name: t.paperScheme,
          paper: t.colors.paper.toARGB32() & 0xFFFFFF,
          ink: t.colors.paperInk.toARGB32() & 0xFFFFFF,
          backdrop: t.colors.backdrop.toARGB32() & 0xFFFFFF,
        ),
    ];
