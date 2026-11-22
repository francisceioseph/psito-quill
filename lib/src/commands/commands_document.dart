// Comandos do documento (Fase 0: Negrito e Salvar).
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show SingleActivator;

import '../../l10n/gen/app_localizations.dart';
import '../document/document_controller.dart';
import 'command_registry.dart';

abstract final class CommandIds {
  static const bold = 'formatar.negrito';
  static const save = 'arquivo.salvar';
}

void registerDocumentCommands(CommandRegistry registry, DocumentController doc, AppLocalizations l10n) {
  registry
    ..register(Command(
      id: CommandIds.bold,
      label: l10n.commandBold,
      icon: Icons.format_bold,
      run: () => doc.uno('.uno:Bold'),
      isActive: () => doc.isOn('.uno:Bold'),
      canRun: () => doc.docStatus == DocStatus.open,
      // Word em português: Ctrl+N é negrito. Em inglês, Ctrl+B.
      shortcuts: const {
        ShortcutScheme.wordPt: SingleActivator(LogicalKeyboardKey.keyN, control: true),
        ShortcutScheme.wordEn: SingleActivator(LogicalKeyboardKey.keyB, control: true),
      },
    ))
    ..register(Command(
      id: CommandIds.save,
      label: l10n.commandSave,
      icon: Icons.save_outlined,
      run: doc.save,
      canRun: () => doc.docStatus == DocStatus.open && doc.path != null,
      shortcuts: const {
        ShortcutScheme.wordPt: SingleActivator(LogicalKeyboardKey.keyB, control: true),
        ShortcutScheme.wordEn: SingleActivator(LogicalKeyboardKey.keyS, control: true),
      },
    ));
}
