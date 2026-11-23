import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_document.dart';
import '../../commands/commands_view.dart';
import '../../document/document_controller.dart';
import '../../document/workspace.dart';
import '../../files/app_window.dart';
import '../../files/file_dialogs.dart';
import '../../settings/settings.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../molecules/command_button.dart';
import '../molecules/info_banner.dart';
import '../organisms/classic_bars.dart';
import '../organisms/command_palette.dart';
import '../organisms/document_view.dart';
import '../organisms/file_panel.dart';
import '../organisms/find_bar.dart';
import '../organisms/inspector.dart';
import '../organisms/ribbon.dart';
import '../organisms/styles_dialog.dart';
import '../organisms/table_size_dialog.dart';
import '../organisms/status_bar.dart';
import '../organisms/unsaved_dialog.dart';
import '../templates/editor_template.dart';
import '../tokens/tokens.dart';

/// A tela do editor: a faixa (ou os menus do tema 97), a barra de
/// localizar, a página, o painel Formatar e a barra de status.
class EditorPage extends StatefulWidget {
  const EditorPage({
    super.key,
    required this.workspace,
    required this.settings,
    this.window,
    this.scrollController,
    this.showMemory = true,
  });

  final Workspace workspace;
  final Settings settings;
  final AppWindow? window;
  final ScrollController? scrollController;

  /// Mostra o RSS na barra de status (útil enquanto as metas de memória são
  /// medidas).
  final bool showMemory;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

/// Os temas como comandos (a paleta e o menu Exibir do tema 97 os mostram).
const themeCommandPrefix = 'tema.';

class _EditorPageState extends State<EditorPage> implements EditorViewActions {
  CommandRegistry? _commands;
  final _docFocus = FocusNode(debugLabel: 'documento');
  bool _fileOpen = false;
  RibbonTab _tab = RibbonTab.home;

  /// A barra de localizar: null fechada; true com a linha de substituir.
  bool? _find;
  final _findKey = GlobalKey<FindBarState>();
  bool _reveal = false;
  Timer? _memoryTimer;
  int _rssMb = 0;

  DocumentController get doc => widget.workspace.doc;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettings);
    if (widget.showMemory) {
      _readMemory();
      _memoryTimer = Timer.periodic(const Duration(seconds: 2), (_) => _readMemory());
    }
  }

  void _readMemory() {
    final mb = ProcessInfo.currentRss >> 20;
    if (mb != _rssMb && mounted) setState(() => _rssMb = mb);
  }

  void _onSettings() {
    _commands?.scheme = widget.settings.shortcuts;
    if (mounted) setState(() {});
  }

  // ------------------------------------------------- EditorViewActions --

  @override
  bool get inspectorOpen => widget.settings.inspector;

  @override
  bool get revealOpen => _reveal && widget.settings.inspector;

  @override
  void openFind({required bool replace}) {
    if (_find != null && _find == replace) {
      _findKey.currentState?.focusField();
      return;
    }
    setState(() {
      _find = replace;
      _fileOpen = false;
    });
  }

  void _closeFind() {
    setState(() => _find = null);
    _backToDocument();
  }

  @override
  void openPalette() => unawaited(
    showCommandPalette(context, _commands!).then((id) {
      if (id == null) _backToDocument();
    }),
  );

  @override
  void toggleInspector() {
    widget.settings.inspector = !widget.settings.inspector;
  }

  @override
  void toggleReveal() {
    setState(() => _reveal = !revealOpen);
    if (_reveal && !widget.settings.inspector) widget.settings.inspector = true;
  }

  @override
  void insertImage() => unawaited(() async {
    final path = await widget.workspace.dialogs.pickImage(label: AppLocalizations.of(context).fileTypeImages);
    if (path != null) doc.insertImage(path);
    _backToDocument();
  }());

  @override
  void insertTable() => unawaited(() async {
    final size = await showTableSizeDialog(context);
    if (size != null) doc.insertTable(size.$1, size.$2);
    _backToDocument();
  }());

  @override
  void newStyle() => unawaited(() async {
    final name = await showNewStyleDialog(context, doc);
    if (name != null) doc.newStyleFromSelection(name);
    _backToDocument();
  }());

  @override
  void manageStyles() => unawaited(showStylesDialog(context, doc).then((_) => _backToDocument()));

  @override
  void openFilePanel() => setState(() => _fileOpen = true);

  @override
  void about() {
    final l10n = AppLocalizations.of(context);
    final version = RegExp(r'"ProductVersion":\s*"([^"]*)"').firstMatch(doc.engineVersion)?.group(1) ?? '';
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WLabel(l10n.appTitle, heading: true),
                const SizedBox(height: 12),
                WLabel(l10n.aboutText(version), maxLines: 3),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: WTextButton(label: l10n.dialogClose, onPressed: () => Navigator.of(context).pop()),
                ),
              ],
            ),
          ),
        ),
      ).then((_) => _backToDocument()),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    // Os rótulos dos comandos vêm da l10n, que só existe com o contexto.
    if (_commands == null) {
      final registry = CommandRegistry(scheme: widget.settings.shortcuts);
      registerEditorCommands(registry, doc: doc, workspace: widget.workspace, l10n: l10n);
      registerViewCommands(registry, doc: doc, view: this, l10n: l10n);
      for (final (id, label) in [
        ('claro', l10n.themeClaro),
        ('escuro', l10n.themeEscuro),
        ('classico97', l10n.themeClassico),
      ]) {
        registry.register(
          Command(
            id: '$themeCommandPrefix$id',
            label: label,
            icon: Icons.palette_outlined,
            run: () => widget.settings.theme = id,
            isActive: () => widget.settings.theme == id,
          ),
        );
      }
      _commands = registry;
    }
    widget.workspace
      ..labels = FileDialogLabels(
        documents: l10n.fileTypeDocuments,
        untitled: l10n.untitled,
        formats: {DocFormat.odt: l10n.formatOdt, DocFormat.docx: l10n.formatDocx},
      )
      ..onUnsaved = () => showUnsavedDialog(context, _documentName(l10n));
  }

  /// Memoização: a faixa e o painel Formatar só se refazem quando muda o
  /// que eles mostram, e não a cada ladrilho novo ao rolar (D-037).
  final _memo = <String, (Object, Widget)>{};

  Widget _memoized(String slot, Object key, Widget Function() build) {
    if (_memo[slot] case (final k, final w) when k == key) return w;
    final w = build();
    _memo[slot] = (key, w);
    return w;
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettings);
    if (widget.workspace.onUnsaved != null) widget.workspace.onUnsaved = null;
    _memoryTimer?.cancel();
    _commands?.dispose();
    _docFocus.dispose();
    super.dispose();
  }

  String _documentName(AppLocalizations l10n) {
    final p = doc.path;
    return p == null ? l10n.untitled : File(p).uri.pathSegments.last;
  }

  String _windowTitle(AppLocalizations l10n) {
    final name = _documentName(l10n);
    if (!doc.isOpen) return l10n.appTitle;
    if (doc.readOnly) return l10n.windowTitleReadOnly(name);
    return doc.modified ? l10n.windowTitleModified(name) : l10n.windowTitle(name);
  }

  void _backToDocument() {
    if (_fileOpen) setState(() => _fileOpen = false);
    if (_docFocus.context != null) _docFocus.requestFocus();
  }

  /// Os atalhos valem com o foco em qualquer lugar da tela (na faixa, no
  /// painel Arquivo). Com o foco no documento, ele mesmo os trata antes.
  KeyEventResult _onPageKey(FocusNode node, KeyEvent event) {
    final command = _commands!.match(event, HardwareKeyboard.instance);
    if (command == null) return KeyEventResult.ignored;
    _commands!.run(command.id);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final commands = _commands!;
    return Focus(
      onKeyEvent: _onPageKey,
      child: ListenableBuilder(
        listenable: Listenable.merge([doc, commands]),
        builder: (context, _) {
          widget.window?.setTitle(_windowTitle(l10n));
          final classic = t.component == ComponentStyle.bevel;
          // Tudo o que a faixa e o painel leem e não vem do motor.
          final key = (
            doc.stateRevision,
            widget.settings.shortcuts,
            t.id, // o tema aplicado (as preferências mudam antes)
            _tab,
            _fileOpen,
            _reveal,
            _find != null,
          );
          return EditorTemplate(
            top: _memoized(
              'top',
              key,
              () => classic
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClassicMenuBar(
                          commands: commands,
                          onRan: _backToDocument,
                          extraMenus: [
                            SubmenuButton(
                              menuChildren: [
                                for (final c in commands.all.where((c) => c.id.startsWith(themeCommandPrefix)))
                                  MenuItemButton(
                                    leadingIcon: Icon(c.active ? Icons.check : null, size: 16),
                                    onPressed: c.run,
                                    child: Text(c.label),
                                  ),
                              ],
                              child: Text(l10n.menuTheme),
                            ),
                          ],
                        ),
                        ClassicToolbars(commands: commands, doc: doc, onRan: _backToDocument),
                      ],
                    )
                  : Ribbon(
                      commands: commands,
                      doc: doc,
                      fileOpen: _fileOpen,
                      tab: _tab,
                      onFile: () => setState(() => _fileOpen = !_fileOpen),
                      onTab: (tab) {
                        setState(() {
                          _tab = tab;
                          _fileOpen = false;
                        });
                        _backToDocument();
                      },
                      onRan: _backToDocument,
                      trailing: [
                        WToggle(
                          icon: Icons.dark_mode_outlined,
                          label: l10n.commandDarkPaper,
                          value: t.brightness == Brightness.dark,
                          onPressed: () => widget.settings.theme = t.brightness == Brightness.dark ? 'claro' : 'escuro',
                        ),
                      ],
                    ),
            ),
            findBar: _find != null && doc.isOpen && !_fileOpen
                ? FindBar(
                    key: _findKey,
                    doc: doc,
                    replace: _find!,
                    initialText: doc.search.query?.text ?? '',
                    onClose: _closeFind,
                  )
                : null,
            sidePanel: widget.settings.inspector && doc.isOpen && !_fileOpen
                ? _memoized(
                    'inspector',
                    key,
                    () => Inspector(doc: doc, commands: commands, reveal: _reveal, onRan: _backToDocument),
                  )
                : null,
            banner: doc.readOnly && !_fileOpen
                ? InfoBanner(
                    icon: Icons.lock_outline,
                    text: l10n.readOnlyBanner(doc.lockOwner ?? ''),
                    actionLabel: l10n.readOnlySaveCopy,
                    onAction: () => unawaited(widget.workspace.saveAs()),
                  )
                : null,
            body: _fileOpen
                ? FilePanel(
                    commands: commands,
                    workspace: widget.workspace,
                    recents: widget.workspace.recents,
                    settings: widget.settings,
                    onClose: _backToDocument,
                  )
                : !doc.isOpen || doc.documentSize.isEmpty
                ? Center(child: WLabel(_statusText(l10n), tone: WLabelTone.muted))
                : DocumentView(
                    doc: doc,
                    commands: commands,
                    focusNode: _docFocus,
                    semanticLabel: l10n.documentArea,
                    scrollController: widget.scrollController,
                  ),
            statusBar: StatusBar(
              fields: [
                StatusField(_statusText(l10n), tone: _statusTone(), flex: true),
                if (doc.isOpen) ...[
                  if (doc.page case (final page, final pages)) StatusField(l10n.statusPage(page, pages)),
                  if (doc.wordCount case final w?)
                    StatusField(w.selection ? l10n.statusWordsSelected(w.words) : l10n.statusWords(w.words)),
                  if (doc.readOnly) StatusField(l10n.statusReadOnly, tone: WLabelTone.normal),
                  if (doc.modified) StatusField(l10n.statusModified),
                  if (doc.commandStates['.uno:LanguageStatus'] case final lang?) StatusField(lang.split(';').first),
                ],
                if (widget.showMemory) StatusField(l10n.statusMemory(_rssMb)),
              ],
              trailing: doc.isOpen
                  ? [
                      CommandButton(commands: commands, id: CommandIds.zoomOut),
                      SizedBox(
                        width: 52,
                        child: Center(child: WLabel(l10n.statusZoom((doc.zoom * 100).round()), small: true)),
                      ),
                      CommandButton(commands: commands, id: CommandIds.zoomIn),
                    ]
                  : const [],
            ),
          );
        },
      ),
    );
  }

  WLabelTone _statusTone() =>
      doc.message is ErrorMessage || doc.message is OpenFailedMessage || doc.kitStatus == KitStatus.failed
      ? WLabelTone.danger
      : WLabelTone.muted;

  String _statusText(AppLocalizations l10n) {
    if (doc.kitStatus == KitStatus.starting) return l10n.statusStarting;
    if (doc.kitStatus == KitStatus.failed) {
      final m = doc.message;
      return l10n.statusEngineFailed(m is ErrorMessage ? m.detail : '');
    }
    return switch (doc.message) {
      SavedMessage(:final path) => l10n.statusSaved(path),
      ErrorMessage(:final detail) => l10n.statusError(detail),
      OpenFailedMessage(:final path, :final detail) => l10n.statusOpenFailed(
        path.isEmpty ? l10n.untitled : File(path).uri.pathSegments.last,
        detail,
      ),
      PluginMessage(:final text) => l10n.statusPlugin(text),
      null => switch (doc.docStatus) {
        DocStatus.opening => l10n.statusOpening,
        DocStatus.none || DocStatus.failed => l10n.statusNoDocument,
        DocStatus.open => doc.path ?? l10n.untitled,
      },
    };
  }
}
