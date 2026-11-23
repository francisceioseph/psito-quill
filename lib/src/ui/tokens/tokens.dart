// Os tokens do design system `quill_ui`.
//
// Todo widget lê cor, espaço, raio, tipo e movimento daqui
// (`QuillTokens.of(context)`). Nenhum widget tem cor literal: só os arquivos
// de tema, em tokens/themes/, têm números de cor (o design_test confere).
import 'package:flutter/material.dart';

/// Strategy: o mesmo átomo desenhado de dois jeitos.
/// - modern: raio, realce suave (Claro, Escuro, Sépia, Alto contraste);
/// - bevel: bisel 3D e cinza (Clássico 97).
enum ComponentStyle { modern, bevel }

@immutable
class QuillColors {
  const QuillColors({
    required this.frame,
    required this.frameRaised,
    required this.onFrame,
    required this.onFrameMuted,
    required this.border,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.backdrop,
    required this.paper,
    required this.paperInk,
    required this.onAccentSoft,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.surfaceLowest,
    required this.surfaceContainer,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.outline,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.cursor,
    required this.selection,
    required this.focusRing,
    required this.bevelLight,
    required this.bevelDark,
    required this.danger,
  });

  // Os nomes do Material 3 estão entre parênteses (D-042). Os nomes antigos
  // ficaram para os widgets da Fase 2 continuarem certos até a Etapa 2.

  /// O fundo da janela (surface).
  final Color frame;

  /// Superfícies um tom acima: a faixa, os painéis (surfaceContainerLow).
  final Color frameRaised;

  /// Texto e ícones (onSurface, onSurfaceVariant).
  final Color onFrame, onFrameMuted;

  /// Divisórias e contornos de campo (outlineVariant).
  final Color border;

  /// A cor da marca (primary, onPrimary).
  final Color accent, onAccent;

  /// Ligado, aba atual, item escolhido (secondaryContainer e o texto sobre ele).
  final Color accentSoft, onAccentSoft;

  /// Destaque mais forte (primaryContainer): "direto" no Revelar formatação.
  final Color accentContainer, onAccentContainer;

  /// As abas de contexto, Tabela e Imagem (tertiary e o container).
  final Color tertiary, tertiaryContainer, onTertiaryContainer;

  /// Os cinco tons de superfície: campos (lowest), a área do documento
  /// (container), o realce do mouse (high), trilhos e fundos (highest).
  final Color surfaceLowest, surfaceContainer, surfaceHigh, surfaceHighest;

  /// O contorno forte: botões segmentados, chaves desligadas (outline).
  final Color outline;

  /// Atrás das páginas.
  final Color backdrop;

  /// O papel e a tinta. Também viram o esquema de cor do LibreOffice.
  final Color paper, paperInk;
  final Color cursor, selection, focusRing;
  final Color bevelLight, bevelDark;

  /// Erro (error, errorContainer e o texto sobre ele).
  final Color danger, dangerContainer, onDangerContainer;

  QuillColors lerp(QuillColors o, double t) => QuillColors(
        frame: Color.lerp(frame, o.frame, t)!,
        frameRaised: Color.lerp(frameRaised, o.frameRaised, t)!,
        onFrame: Color.lerp(onFrame, o.onFrame, t)!,
        onFrameMuted: Color.lerp(onFrameMuted, o.onFrameMuted, t)!,
        border: Color.lerp(border, o.border, t)!,
        accent: Color.lerp(accent, o.accent, t)!,
        onAccent: Color.lerp(onAccent, o.onAccent, t)!,
        accentSoft: Color.lerp(accentSoft, o.accentSoft, t)!,
        backdrop: Color.lerp(backdrop, o.backdrop, t)!,
        paper: Color.lerp(paper, o.paper, t)!,
        paperInk: Color.lerp(paperInk, o.paperInk, t)!,
        onAccentSoft: Color.lerp(onAccentSoft, o.onAccentSoft, t)!,
        accentContainer: Color.lerp(accentContainer, o.accentContainer, t)!,
        onAccentContainer: Color.lerp(onAccentContainer, o.onAccentContainer, t)!,
        tertiary: Color.lerp(tertiary, o.tertiary, t)!,
        tertiaryContainer: Color.lerp(tertiaryContainer, o.tertiaryContainer, t)!,
        onTertiaryContainer: Color.lerp(onTertiaryContainer, o.onTertiaryContainer, t)!,
        surfaceLowest: Color.lerp(surfaceLowest, o.surfaceLowest, t)!,
        surfaceContainer: Color.lerp(surfaceContainer, o.surfaceContainer, t)!,
        surfaceHigh: Color.lerp(surfaceHigh, o.surfaceHigh, t)!,
        surfaceHighest: Color.lerp(surfaceHighest, o.surfaceHighest, t)!,
        outline: Color.lerp(outline, o.outline, t)!,
        dangerContainer: Color.lerp(dangerContainer, o.dangerContainer, t)!,
        onDangerContainer: Color.lerp(onDangerContainer, o.onDangerContainer, t)!,
        cursor: Color.lerp(cursor, o.cursor, t)!,
        selection: Color.lerp(selection, o.selection, t)!,
        focusRing: Color.lerp(focusRing, o.focusRing, t)!,
        bevelLight: Color.lerp(bevelLight, o.bevelLight, t)!,
        bevelDark: Color.lerp(bevelDark, o.bevelDark, t)!,
        danger: Color.lerp(danger, o.danger, t)!,
      );
}

@immutable
class QuillSpace {
  const QuillSpace({this.xs = 2, this.sm = 4, this.md = 8, this.lg = 12, this.xl = 20});
  final double xs, sm, md, lg, xl;
}

@immutable
class QuillRadius {
  const QuillRadius({required this.control, required this.panel});
  final double control, panel;
}

@immutable
class QuillFont {
  const QuillFont({required this.family, this.ui = 14, this.small = 13, this.title = 16, this.tab = 15});
  // Subiram na Etapa 7 (D-049): eram 13, 12 e 15.
  final String? family;
  final double ui, small, title;

  /// O nome das abas da faixa.
  final double tab;
}

@immutable
class QuillMotion {
  const QuillMotion({this.fast = const Duration(milliseconds: 90), this.normal = const Duration(milliseconds: 180)});
  final Duration fast, normal;

  /// Reduzir movimento (D-067): as transições acontecem na hora.
  static const none = QuillMotion(fast: Duration.zero, normal: Duration.zero);

  /// O piscar do cursor (desenhado pelo Flutter, sem tocar no motor).
  Duration get caretBlink => const Duration(milliseconds: 530);
}

@immutable
class QuillDensity {
  const QuillDensity({this.control = 36, this.toolbar = 48, this.statusBar = 32, this.icon = 22});

  /// O padrão: botões de 36 px. O desenho pedia 32, como o Google Docs, mas
  /// a faixa tem muitos mais comandos e ficou difícil de acertar (D-049).
  static const compact = QuillDensity();

  /// Mais fácil de acertar (Acessibilidade › Botões maiores).
  static const comfortable = QuillDensity(control: 44, toolbar: 56, statusBar: 32, icon: 24);

  /// A altura de um botão, a da barra de ferramentas e a da barra de status.
  final double control, toolbar, statusBar;

  /// O tamanho dos ícones nos botões.
  final double icon;
}

class QuillTokens extends ThemeExtension<QuillTokens> {
  const QuillTokens({
    required this.id,
    required this.brightness,
    required this.colors,
    required this.radius,
    required this.font,
    required this.component,
    required this.paperScheme,
    this.space = const QuillSpace(),
    this.motion = const QuillMotion(),
    this.density = const QuillDensity(),
  });

  /// "claro", "escuro"...
  final String id;
  final Brightness brightness;
  final QuillColors colors;
  final QuillSpace space;
  final QuillRadius radius;
  final QuillFont font;
  final QuillMotion motion;
  final QuillDensity density;
  final ComponentStyle component;

  /// Nome do esquema de cor do LibreOffice para este tema.
  final String paperScheme;

  static QuillTokens of(BuildContext context) => Theme.of(context).extension<QuillTokens>()!;

  @override
  QuillTokens copyWith({QuillColors? colors, ComponentStyle? component, QuillDensity? density, QuillMotion? motion}) => QuillTokens(
        id: id,
        brightness: brightness,
        colors: colors ?? this.colors,
        radius: radius,
        font: font,
        component: component ?? this.component,
        paperScheme: paperScheme,
        space: space,
        motion: motion ?? this.motion,
        density: density ?? this.density,
      );

  @override
  QuillTokens lerp(QuillTokens? other, double t) {
    if (other == null) return this;
    return (t < 0.5 ? this : other).copyWith(colors: colors.lerp(other.colors, t));
  }

  /// O ThemeData do Flutter montado a partir dos tokens, para o que vem do
  /// framework (seleção de texto, barras de rolagem) seguir o tema.
  ThemeData toThemeData() {
    // O ColorScheme do M3 com os papéis dos tokens, sem `fromSeed`: os tons
    // já vêm prontos nos arquivos de tema (iguais aos do desenho).
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      primaryContainer: colors.accentContainer,
      onPrimaryContainer: colors.onAccentContainer,
      secondary: colors.onAccentSoft,
      onSecondary: colors.surfaceLowest,
      secondaryContainer: colors.accentSoft,
      onSecondaryContainer: colors.onAccentSoft,
      tertiary: colors.tertiary,
      onTertiary: colors.surfaceLowest,
      tertiaryContainer: colors.tertiaryContainer,
      onTertiaryContainer: colors.onTertiaryContainer,
      error: colors.danger,
      onError: colors.surfaceLowest,
      errorContainer: colors.dangerContainer,
      onErrorContainer: colors.onDangerContainer,
      surface: colors.frame,
      onSurface: colors.onFrame,
      onSurfaceVariant: colors.onFrameMuted,
      surfaceContainerLowest: colors.surfaceLowest,
      surfaceContainerLow: colors.frameRaised,
      surfaceContainer: colors.surfaceContainer,
      surfaceContainerHigh: colors.surfaceHigh,
      surfaceContainerHighest: colors.surfaceHighest,
      outline: colors.outline,
      outlineVariant: colors.border,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      visualDensity: VisualDensity.compact,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.frame,
      fontFamily: font.family,
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(colors.onFrameMuted.withValues(alpha: 0.5)),
      ),
      // Os menus (de contexto, do tema 97) e os diálogos seguem o tema.
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceContainer,
        surfaceTintColor: colors.surfaceContainer,
        textStyle: TextStyle(color: colors.onFrame, fontSize: font.ui, fontFamily: font.family),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.control),
          side: BorderSide(color: colors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.frame,
        surfaceTintColor: colors.frame,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.panel),
          side: component == ComponentStyle.bevel ? BorderSide(color: colors.bevelDark, width: 2) : BorderSide.none,
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colors.surfaceContainer),
          surfaceTintColor: WidgetStatePropertyAll(colors.surfaceContainer),
          side: WidgetStatePropertyAll(BorderSide(color: colors.border)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius.control))),
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: space.sm)),
        ),
      ),
      menuBarTheme: MenuBarThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colors.frame),
          surfaceTintColor: WidgetStatePropertyAll(colors.frame),
          elevation: const WidgetStatePropertyAll(0),
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          // Itens de menu com a altura de um controle, como os do Office (D-049).
          minimumSize: WidgetStatePropertyAll(Size(0, density.control)),
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: space.lg)),
          iconSize: WidgetStatePropertyAll(density.icon - 2),
          foregroundColor: WidgetStatePropertyAll(colors.onFrame),
          overlayColor: WidgetStatePropertyAll(colors.surfaceHigh),
          textStyle: WidgetStatePropertyAll(TextStyle(fontSize: font.ui, fontFamily: font.family)),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.onFrame,
        selectionColor: colors.selection,
      ),
      extensions: [this],
    );
  }
}
