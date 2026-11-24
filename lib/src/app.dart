import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/gen/app_localizations.dart';
import 'document/document_controller.dart';
import 'document/workspace.dart';
import 'files/app_window.dart';
import 'settings/settings.dart';
import 'ui/pages/editor_page.dart';
import 'ui/templates/ui_zoom.dart';
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

  /// O tema da interface; no modo zen, o do papel escolhido para ele (a
  /// janela inteira fica da cor do papel).
  QuillTokens get theme {
    final s = widget.settings;
    final t = themeById(s.zen ? s.zenPaper : s.theme);
    // Acessibilidade (D-067): os botões maiores e sem animação.
    return t.copyWith(
      density: s.comfortable ? QuillDensity.comfortable : null,
      motion: s.reduceMotion ? QuillMotion.none : null,
    );
  }

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
  Object? _paper;

  /// O papel segue o tema: a cada documento aberto, o esquema certo (e, num
  /// tema escuro, a inversão, D-074).
  void _syncPaper() {
    if (doc.docStatus == DocStatus.open && _paperFor != DocStatus.open) _applyPaper();
    _paperFor = doc.docStatus;
  }

  void _applyPaper() {
    final p = enginePaper(theme);
    _paper = p;
    doc.setPaperScheme(p.scheme, invert: p.invert);
  }

  void _onSettings() {
    setState(() {});
    if (doc.isOpen && enginePaper(theme) != _paper) _applyPaper();
  }

  /// Troca o tema (e o papel). O bench usa.
  void setTheme(QuillTokens t) => widget.settings.theme = t.id;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: widget.locale,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: theme.toThemeData(),
        // O tamanho da interface (o do texto do sistema vezes a preferência)
        // vira um zoom da interface inteira, e reduzir movimento (D-067).
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          final s = widget.settings;
          final zoom = s.uiScale * mq.textScaler.scale(100) / 100;
          return MediaQuery(
            data: mq.copyWith(
              textScaler: TextScaler.noScaling,
              disableAnimations: mq.disableAnimations || s.reduceMotion,
            ),
            child: UiZoom(zoom: zoom, child: child!),
          );
        },
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
