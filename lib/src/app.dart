import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/gen/app_localizations.dart';
import 'document/document_controller.dart';
import 'ui/pages/editor_page.dart';
import 'ui/tokens/themes/themes.dart';
import 'ui/tokens/tokens.dart';

class QuillApp extends StatefulWidget {
  const QuillApp({super.key, required this.doc, this.scrollController, this.initialTheme = claro, this.showMemory = true});

  final DocumentController doc;
  final ScrollController? scrollController;
  final QuillTokens initialTheme;
  final bool showMemory;

  @override
  State<QuillApp> createState() => QuillAppState();
}

class QuillAppState extends State<QuillApp> {
  late QuillTokens theme = widget.initialTheme;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    widget.doc.addListener(_syncPaper);
    // Fechar a janela: fecha o documento no motor antes (tira a trava .~lock).
    _lifecycle = AppLifecycleListener(onExitRequested: () async {
      await widget.doc.close();
      return AppExitResponse.exit;
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    widget.doc.removeListener(_syncPaper);
    super.dispose();
  }

  DocStatus? _paperFor;

  /// O papel segue o tema: a cada documento aberto, o esquema certo.
  void _syncPaper() {
    if (widget.doc.docStatus == DocStatus.open && _paperFor != DocStatus.open) {
      widget.doc.setPaperScheme(theme.paperScheme);
    }
    _paperFor = widget.doc.docStatus;
  }

  void setTheme(QuillTokens t) {
    setState(() => theme = t);
    if (widget.doc.docStatus == DocStatus.open) widget.doc.setPaperScheme(t.paperScheme);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: theme.toThemeData(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: EditorPage(
            doc: widget.doc,
            scrollController: widget.scrollController,
            showMemory: widget.showMemory,
            onToggleDark: () => setTheme(theme.brightness == Brightness.dark ? claro : escuro),
          ),
        ),
      );
}
