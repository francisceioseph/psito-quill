import '../../../kit/lok/lo_profile.dart';
import '../tokens.dart';
import 'claro.dart';
import 'escuro.dart';

export 'claro.dart';
export 'escuro.dart';

/// Os temas que vêm com o app. Sépia, Clássico 97 e Alto contraste entram nas
/// fases 2 e 6.
const List<QuillTokens> builtInThemes = [claro, escuro];

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
