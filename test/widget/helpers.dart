import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:psito_quill/l10n/gen/app_localizations.dart';
import 'package:psito_quill/src/ui/tokens/tokens.dart';

/// Monta o widget com o tema e a l10n, como no app.
Widget themed(Widget child, QuillTokens tokens, {Locale locale = const Locale('pt')}) => MaterialApp(
      theme: tokens.toThemeData(),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
