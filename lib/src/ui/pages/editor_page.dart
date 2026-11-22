import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_document.dart';
import '../../document/document_controller.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../organisms/document_view.dart';
import '../organisms/status_bar.dart';
import '../organisms/toolbar.dart';
import '../templates/editor_template.dart';
import '../tokens/tokens.dart';

/// A tela do editor (Fase 0): barra com Negrito e Salvar, a página e o status.
class EditorPage extends StatefulWidget {
  const EditorPage({
    super.key,
    required this.doc,
    required this.onToggleDark,
    this.scrollController,
    this.showMemory = true,
  });

  final DocumentController doc;
  final VoidCallback onToggleDark;
  final ScrollController? scrollController;

  /// Mostra o RSS na barra de status (útil enquanto as metas de memória são
  /// medidas).
  final bool showMemory;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  CommandRegistry? _commands;
  Timer? _memoryTimer;
  int _rssMb = 0;

  @override
  void initState() {
    super.initState();
    if (widget.showMemory) {
      _readMemory();
      _memoryTimer = Timer.periodic(const Duration(seconds: 2), (_) => _readMemory());
    }
  }

  void _readMemory() {
    final mb = ProcessInfo.currentRss >> 20;
    if (mb != _rssMb && mounted) setState(() => _rssMb = mb);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Os rótulos dos comandos vêm da l10n, que só existe com o contexto.
    if (_commands == null) {
      final registry = CommandRegistry();
      registerDocumentCommands(registry, widget.doc, AppLocalizations.of(context));
      _commands = registry;
    }
  }

  @override
  void dispose() {
    _memoryTimer?.cancel();
    _commands?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final commands = _commands!;
    return ListenableBuilder(
      listenable: widget.doc,
      builder: (context, _) {
        // Reconstruir aqui também redesenha a barra: o estado dos botões
        // (negrito ligado) vem do documento.
        return EditorTemplate(
          toolbar: Toolbar(
            commands: commands,
            ids: const [CommandIds.bold, CommandIds.save],
            trailing: [
              WToggle(
                icon: Icons.dark_mode_outlined,
                label: l10n.commandDarkPaper,
                value: t.brightness == Brightness.dark,
                onPressed: widget.onToggleDark,
              ),
            ],
          ),
          body: widget.doc.docStatus == DocStatus.none || widget.doc.documentSize.isEmpty
              ? Center(child: WLabel(_statusText(l10n), tone: WLabelTone.muted))
              : DocumentView(
                  doc: widget.doc,
                  commands: commands,
                  semanticLabel: l10n.documentArea,
                  scrollController: widget.scrollController,
                ),
          statusBar: StatusBar(fields: [
            StatusField(_statusText(l10n), tone: _statusTone(), flex: true),
            if (widget.doc.commandStates['.uno:PageStatus'] case final p?) StatusField(p),
            if (widget.doc.commandStates['.uno:WordCountStatus'] case final w?) StatusField(w),
            if (widget.doc.modified) StatusField(l10n.statusModified),
            if (widget.showMemory) StatusField(l10n.statusMemory(_rssMb)),
          ]),
        );
      },
    );
  }

  WLabelTone _statusTone() =>
      widget.doc.message is ErrorMessage || widget.doc.kitStatus == KitStatus.failed
          ? WLabelTone.danger
          : WLabelTone.muted;

  String _statusText(AppLocalizations l10n) {
    final doc = widget.doc;
    if (doc.kitStatus == KitStatus.starting) return l10n.statusStarting;
    if (doc.kitStatus == KitStatus.failed) {
      final m = doc.message;
      return l10n.statusEngineFailed(m is ErrorMessage ? m.detail : '');
    }
    return switch (doc.message) {
      SavedMessage(:final path) => l10n.statusSaved(path),
      ErrorMessage(:final detail) => l10n.statusError(detail),
      PluginMessage(:final text) => l10n.statusPlugin(text),
      null => switch (doc.docStatus) {
          DocStatus.opening => l10n.statusOpening,
          DocStatus.none => l10n.statusNoDocument,
          _ => doc.path ?? '',
        },
    };
  }
}
