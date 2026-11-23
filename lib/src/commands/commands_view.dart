// Os comandos que abrem uma tela (Fase 2): localizar, a paleta, o painel
// Formatar, inserir imagem e tabela, os estilos.
//
// Command com receptor: o comando só sabe pedir; quem mostra a tela é a
// página do editor, que implementa [EditorViewActions].
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show SingleActivator;

import '../../l10n/gen/app_localizations.dart';
import '../document/document_controller.dart';
import 'command_registry.dart';

abstract final class ViewCommandIds {
  static const find = 'editar.localizar';
  static const replace = 'editar.substituir';
  static const palette = 'exibir.paleta';
  static const inspector = 'exibir.inspetor';
  static const reveal = 'exibir.revelarFormatacao';
  static const insertImage = 'inserir.imagem';
  static const insertTable = 'inserir.tabela';
  static const newStyle = 'estilo.novo';
  static const updateStyle = 'estilo.atualizar';
  static const manageStyles = 'estilo.gerenciar';
  static const about = 'ajuda.sobre';
  static const filePanel = 'arquivo.painel';
}

/// O que a página do editor sabe abrir.
abstract interface class EditorViewActions {
  void openFind({required bool replace});
  void openPalette();
  void toggleInspector();
  void toggleReveal();
  bool get inspectorOpen;
  bool get revealOpen;
  void insertImage();
  void insertTable();
  void newStyle();
  void manageStyles();
  void about();

  /// O painel Arquivo (recentes e preferências).
  void openFilePanel();
}

void registerViewCommands(
  CommandRegistry registry, {
  required DocumentController doc,
  required EditorViewActions view,
  required AppLocalizations l10n,
}) {
  SingleActivator ctrl(LogicalKeyboardKey k) => SingleActivator(k, control: true);
  Map<ShortcutScheme, SingleActivator> schemes(SingleActivator pt, SingleActivator en) =>
      {ShortcutScheme.wordPt: pt, ShortcutScheme.wordEn: en};
  Map<ShortcutScheme, SingleActivator> both(SingleActivator a) => schemes(a, a);
  bool editable() => doc.canEdit;
  bool open() => doc.isOpen;

  for (final c in [
    // Ctrl+L e Ctrl+U no Word em português; Ctrl+F e Ctrl+H no em inglês.
    Command(
      id: ViewCommandIds.find,
      label: l10n.commandFind,
      icon: Icons.search,
      run: () => view.openFind(replace: false),
      canRun: open,
      shortcuts: schemes(ctrl(LogicalKeyboardKey.keyL), ctrl(LogicalKeyboardKey.keyF)),
    ),
    Command(
      id: ViewCommandIds.replace,
      label: l10n.commandReplace,
      icon: Icons.find_replace,
      run: () => view.openFind(replace: true),
      canRun: editable,
      shortcuts: schemes(ctrl(LogicalKeyboardKey.keyU), ctrl(LogicalKeyboardKey.keyH)),
    ),
    // O Ctrl+K nunca conflita com outro atalho (PLANO 5.4).
    Command(
      id: ViewCommandIds.palette,
      label: l10n.commandPalette,
      icon: Icons.keyboard_command_key,
      run: view.openPalette,
      shortcuts: both(ctrl(LogicalKeyboardKey.keyK)),
    ),
    Command(
      id: ViewCommandIds.inspector,
      label: l10n.commandInspector,
      icon: Icons.tune,
      run: view.toggleInspector,
      isActive: () => view.inspectorOpen,
      shortcuts: both(const SingleActivator(LogicalKeyboardKey.f10)),
    ),
    // Shift+F1, como no Word.
    Command(
      id: ViewCommandIds.reveal,
      label: l10n.commandRevealFormatting,
      icon: Icons.visibility_outlined,
      run: view.toggleReveal,
      isActive: () => view.revealOpen,
      canRun: open,
      shortcuts: both(const SingleActivator(LogicalKeyboardKey.f1, shift: true)),
    ),
    Command(
      id: ViewCommandIds.insertImage,
      label: l10n.commandInsertImage,
      icon: Icons.image_outlined,
      run: view.insertImage,
      canRun: editable,
    ),
    Command(
      id: ViewCommandIds.insertTable,
      label: l10n.commandInsertTable,
      icon: Icons.table_chart_outlined,
      run: view.insertTable,
      canRun: editable,
    ),
    Command(
      id: ViewCommandIds.newStyle,
      label: l10n.commandNewStyle,
      icon: Icons.style_outlined,
      run: view.newStyle,
      canRun: editable,
    ),
    Command(
      id: ViewCommandIds.updateStyle,
      label: l10n.commandUpdateStyle,
      icon: Icons.published_with_changes,
      run: () {
        if (doc.paragraphStyleId case final s?) doc.updateStyleFromSelection(s);
      },
      canRun: () => editable() && doc.paragraphStyleId != null,
    ),
    Command(
      id: ViewCommandIds.manageStyles,
      label: l10n.commandManageStyles,
      icon: Icons.format_paint_outlined,
      run: view.manageStyles,
      canRun: open,
    ),
    Command(
      id: ViewCommandIds.filePanel,
      label: l10n.commandFilePanel,
      icon: Icons.history,
      run: view.openFilePanel,
    ),
    Command(
      id: ViewCommandIds.about,
      label: l10n.commandAbout,
      icon: Icons.info_outline,
      run: view.about,
    ),
  ]) {
    registry.register(c);
  }
}
