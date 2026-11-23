import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_document.dart';
import '../../document/document_controller.dart';
import '../../document/workspace.dart';
import '../../files/app_window.dart';
import '../../files/file_dialogs.dart';
import '../../settings/settings.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../molecules/command_button.dart';
import '../molecules/info_banner.dart';
import '../organisms/document_view.dart';
import '../organisms/file_panel.dart';
import '../organisms/ribbon.dart';
import '../organisms/status_bar.dart';
import '../organisms/unsaved_dialog.dart';
import '../templates/editor_template.dart';
import '../tokens/tokens.dart';

/// A tela do editor: a faixa (Arquivo e Início), a página e a barra de status.
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

class _EditorPageState extends State<EditorPage> {
  CommandRegistry? _commands;
  final _docFocus = FocusNode(debugLabel: 'documento');
  bool _fileOpen = false;
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

  void _onSettings() => _commands?.scheme = widget.settings.shortcuts;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    // Os rótulos dos comandos vêm da l10n, que só existe com o contexto.
    if (_commands == null) {
      final registry = CommandRegistry(scheme: widget.settings.shortcuts);
      registerEditorCommands(registry, doc: doc, workspace: widget.workspace, l10n: l10n);
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
          return EditorTemplate(
            ribbon: Ribbon(
              commands: commands,
              doc: doc,
              fileOpen: _fileOpen,
              onFile: () => setState(() => _fileOpen = !_fileOpen),
              onHome: _backToDocument,
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

  WLabelTone _statusTone() => doc.message is ErrorMessage ||
          doc.message is OpenFailedMessage ||
          doc.kitStatus == KitStatus.failed
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
      OpenFailedMessage(:final path, :final detail) =>
        l10n.statusOpenFailed(path.isEmpty ? l10n.untitled : File(path).uri.pathSegments.last, detail),
      PluginMessage(:final text) => l10n.statusPlugin(text),
      null => switch (doc.docStatus) {
          DocStatus.opening => l10n.statusOpening,
          DocStatus.none || DocStatus.failed => l10n.statusNoDocument,
          DocStatus.open => doc.path ?? l10n.untitled,
        },
    };
  }
}
