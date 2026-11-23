import '../../../kit/lok/lo_profile.dart';
import '../tokens.dart';
import 'classico97.dart';
import 'claro.dart';
import 'escuro.dart';
import 'sepia.dart';

export 'classico97.dart';
export 'claro.dart';
export 'escuro.dart';
export 'sepia.dart';

/// Os temas que vêm com o app. O Alto contraste entra na Etapa 8 da Fase 2B.
const List<QuillTokens> builtInThemes = [claro, escuro, sepia, classico97];

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
