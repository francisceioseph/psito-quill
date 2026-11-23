import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/gen/app_localizations.dart';
import 'document/document_controller.dart';
import 'document/workspace.dart';
import 'files/app_window.dart';
import 'settings/settings.dart';
import 'ui/pages/editor_page.dart';
import 'ui/tokens/themes/themes.dart';
import 'ui/tokens/tokens.dart';

class QuillApp extends StatefulWidget {
  const QuillApp({
    super.key,
    required this.workspace,
    required this.settings,
    this.window,
    this.scrollController,
    this.showMemory = true,
    this.locale,
  });

  final Workspace workspace;
  final Settings settings;
  final AppWindow? window;
  final ScrollController? scrollController;
  final bool showMemory;

  /// null: o do sistema.
  final Locale? locale;

  @override
  State<QuillApp> createState() => QuillAppState();
}

class QuillAppState extends State<QuillApp> {
  late final AppLifecycleListener _lifecycle;

  DocumentController get doc => widget.workspace.doc;

  QuillTokens get theme =>
      builtInThemes.firstWhere((t) => t.id == widget.settings.theme, orElse: () => builtInThemes.first);

  @override
  void initState() {
    super.initState();
    doc.addListener(_syncPaper);
    widget.settings.addListener(_onSettings);
    // Fechar a janela: pergunta se há alterações e fecha o documento no motor
    // (tira a trava .~lock).
    _lifecycle = AppLifecycleListener(
      onExitRequested: () async =>
          await widget.workspace.requestExit() ? AppExitResponse.exit : AppExitResponse.cancel,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    widget.settings.removeListener(_onSettings);
    doc.removeListener(_syncPaper);
    super.dispose();
  }

  DocStatus? _paperFor;
  String? _paperScheme;

  /// O papel segue o tema: a cada documento aberto, o esquema certo.
  void _syncPaper() {
    if (doc.docStatus == DocStatus.open && _paperFor != DocStatus.open) {
      _paperScheme = theme.paperScheme;
      doc.setPaperScheme(theme.paperScheme);
    }
    _paperFor = doc.docStatus;
  }

  void _onSettings() {
    setState(() {});
    final scheme = theme.paperScheme;
    if (doc.isOpen && scheme != _paperScheme) {
      _paperScheme = scheme;
      doc.setPaperScheme(scheme);
    }
  }

  /// Troca o tema (e o papel). O bench usa.
  void setTheme(QuillTokens t) => widget.settings.theme = t.id;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: widget.locale,
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
            workspace: widget.workspace,
            settings: widget.settings,
            window: widget.window,
            scrollController: widget.scrollController,
            showMemory: widget.showMemory,
          ),
        ),
      );
}
