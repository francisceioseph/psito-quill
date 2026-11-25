// Os comandos que abrem uma tela (Fase 2): localizar, a paleta, o painel
// Formatar, inserir imagem e tabela, os estilos.
//
// Command com receptor: o comando só sabe pedir; quem mostra a tela é a
// página do editor, que implementa [EditorViewActions].
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show SingleActivator;
import 'package:material_symbols_icons/symbols.dart';

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
  static const outline = 'exibir.estrutura';
  static const stylesPanel = 'exibir.estilos';
  static const collapseRibbon = 'exibir.recolherFaixa';
  static const ruler = 'exibir.regua';
  static const zen = 'exibir.zen';
  static const fitWidth = 'exibir.ajustarLargura';
  static const fitPage = 'exibir.ajustarPagina';
  static const statusBar = 'exibir.barraStatus';
  static const layoutSingle = 'exibir.umaPagina';
  static const layoutMulti = 'exibir.variasPaginas';
  static const layoutBook = 'exibir.livro';
  static const newComment = 'revisar.novoComentario';
  static const comments = 'revisar.comentarios';
  static const modeEditing = 'revisar.editando';
  static const modeReview = 'revisar.revisao';
  static const modeReading = 'revisar.leitura';
  static const changes = 'revisar.alteracoes';
  static const showChanges = 'revisar.mostrarAlteracoes';
  static const nextChange = 'revisar.proximaAlteracao';
  static const previousChange = 'revisar.alteracaoAnterior';
  static const acceptChange = 'revisar.aceitar';
  static const rejectChange = 'revisar.rejeitar';
  static const acceptAll = 'revisar.aceitarTodas';
  static const rejectAll = 'revisar.rejeitarTodas';
}

/// Os três modos do documento (D-089): editar, revisar (as alterações
/// marcadas) e ler.
enum EditMode { editing, review, reading }

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

  /// Os painéis do trilho, à esquerda (Fase 2B).
  void toggleOutline();
  bool get outlineOpen;
  void toggleStylesPanel();
  bool get stylesPanelOpen;

  /// O painel Comentários (D-088), e um comentário novo na seleção (abre o
  /// painel com o campo em foco).
  void toggleComments();
  bool get commentsOpen;
  void newComment();

  /// O modo (D-089): a Revisão liga o controle de alterações no motor; a
  /// Leitura esconde a faixa e os painéis.
  EditMode get editMode;
  void setEditMode(EditMode mode);

  /// O painel Alterações.
  void toggleChanges();
  bool get changesOpen;

  /// A faixa só com as abas (Ctrl+F1).
  void toggleRibbon();
  bool get ribbonCollapsed;

  /// As réguas (Exibir › Régua).
  void toggleRuler();
  bool get rulerShown;

  /// O modo zen (F11).
  void toggleZen();
  bool get zenOpen;

  /// O zoom que faz caber a largura da fileira de páginas ([page]: a página
  /// inteira) na área do documento.
  void zoomToFit({required bool page});

  /// Exibir › Barra de status.
  void toggleStatusBar();
  bool get statusBarShown;

  /// A disposição das páginas: "uma", "varias" ou "livro" (D-047).
  String get pageLayout;
  set pageLayout(String value);
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
      icon: Symbols.search_rounded,
      // A busca única (D-050): o texto e os comandos num campo só.
      run: view.openPalette,
      canRun: open,
      shortcuts: schemes(ctrl(LogicalKeyboardKey.keyL), ctrl(LogicalKeyboardKey.keyF)),
    ),
    Command(
      id: ViewCommandIds.replace,
      label: l10n.commandReplace,
      icon: Symbols.find_replace_rounded,
      run: () => view.openFind(replace: true),
      canRun: editable,
      shortcuts: schemes(ctrl(LogicalKeyboardKey.keyU), ctrl(LogicalKeyboardKey.keyH)),
    ),
    // O Ctrl+K nunca conflita com outro atalho (PLANO 5.4).
    Command(
      id: ViewCommandIds.palette,
      label: l10n.commandPalette,
      icon: Symbols.keyboard_command_key_rounded,
      run: view.openPalette,
      shortcuts: both(ctrl(LogicalKeyboardKey.keyK)),
    ),
    Command(
      id: ViewCommandIds.inspector,
      label: l10n.commandInspector,
      icon: Symbols.tune_rounded,
      run: view.toggleInspector,
      isActive: () => view.inspectorOpen,
      shortcuts: both(const SingleActivator(LogicalKeyboardKey.f10)),
    ),
    // Shift+F1, como no Word.
    Command(
      id: ViewCommandIds.reveal,
      label: l10n.commandRevealFormatting,
      icon: Symbols.visibility_rounded,
      run: view.toggleReveal,
      isActive: () => view.revealOpen,
      canRun: open,
      shortcuts: both(const SingleActivator(LogicalKeyboardKey.f1, shift: true)),
    ),
    Command(
      id: ViewCommandIds.insertImage,
      label: l10n.commandInsertImage,
      icon: Symbols.image_rounded,
      run: view.insertImage,
      canRun: editable,
    ),
    Command(
      id: ViewCommandIds.insertTable,
      label: l10n.commandInsertTable,
      icon: Symbols.table_chart_rounded,
      run: view.insertTable,
      canRun: editable,
    ),
    Command(
      id: ViewCommandIds.newStyle,
      label: l10n.commandNewStyle,
      icon: Symbols.style_rounded,
      run: view.newStyle,
      canRun: editable,
    ),
    Command(
      id: ViewCommandIds.updateStyle,
      label: l10n.commandUpdateStyle,
      icon: Symbols.published_with_changes_rounded,
      run: () {
        if (doc.paragraphStyleId case final s?) doc.updateStyleFromSelection(s);
      },
      canRun: () => editable() && doc.paragraphStyleId != null,
    ),
    Command(
      id: ViewCommandIds.manageStyles,
      label: l10n.commandManageStyles,
      icon: Symbols.format_paint_rounded,
      run: view.manageStyles,
      canRun: open,
    ),
    Command(
      id: ViewCommandIds.filePanel,
      label: l10n.commandFilePanel,
      icon: Symbols.history_rounded,
      run: view.openFilePanel,
    ),
    Command(
      id: ViewCommandIds.outline,
      label: l10n.commandOutline,
      icon: Symbols.toc_rounded,
      run: view.toggleOutline,
      isActive: () => view.outlineOpen,
      canRun: open,
    ),
    Command(
      id: ViewCommandIds.newComment,
      label: l10n.commandNewComment,
      icon: Symbols.add_comment_rounded,
      run: view.newComment,
      canRun: editable,
      shortcuts: both(const SingleActivator(LogicalKeyboardKey.keyC, control: true, alt: true)),
    ),
    Command(
      id: ViewCommandIds.comments,
      label: l10n.commandComments,
      icon: Symbols.comment_rounded,
      run: view.toggleComments,
      isActive: () => view.commentsOpen,
      canRun: open,
    ),
    Command(
      id: ViewCommandIds.modeEditing,
      label: l10n.modeEditing,
      icon: Symbols.edit_rounded,
      run: () => view.setEditMode(EditMode.editing),
      isActive: () => view.editMode == EditMode.editing,
      canRun: open,
    ),
    // Ctrl+Shift+E liga e desliga a Revisão, como no Word.
    Command(
      id: ViewCommandIds.modeReview,
      label: l10n.modeReview,
      icon: Symbols.rate_review_rounded,
      run: () => view.setEditMode(view.editMode == EditMode.review ? EditMode.editing : EditMode.review),
      isActive: () => view.editMode == EditMode.review,
      canRun: () => doc.isOpen && !doc.readOnly,
      shortcuts: both(const SingleActivator(LogicalKeyboardKey.keyE, control: true, shift: true)),
    ),
    Command(
      id: ViewCommandIds.modeReading,
      label: l10n.modeReading,
      icon: Symbols.chrome_reader_mode_rounded,
      run: () => view.setEditMode(view.editMode == EditMode.reading ? EditMode.editing : EditMode.reading),
      isActive: () => view.editMode == EditMode.reading,
      canRun: open,
    ),
    Command(
      id: ViewCommandIds.changes,
      label: l10n.commandChanges,
      icon: Symbols.difference_rounded,
      run: view.toggleChanges,
      isActive: () => view.changesOpen,
      canRun: open,
    ),
    Command(
      id: ViewCommandIds.showChanges,
      label: l10n.commandShowChanges,
      icon: Symbols.visibility_rounded,
      run: doc.toggleShowChanges,
      isActive: () => doc.showChanges,
      canRun: open,
    ),
    Command(
      id: ViewCommandIds.previousChange,
      label: l10n.commandPreviousChange,
      icon: Symbols.arrow_upward_rounded,
      run: () => doc.nextChange(back: true),
      canRun: () => doc.isOpen && doc.hasChanges,
    ),
    Command(
      id: ViewCommandIds.nextChange,
      label: l10n.commandNextChange,
      icon: Symbols.arrow_downward_rounded,
      run: doc.nextChange,
      canRun: () => doc.isOpen && doc.hasChanges,
    ),
    Command(
      id: ViewCommandIds.acceptChange,
      label: l10n.commandAcceptChange,
      icon: Symbols.check_rounded,
      run: doc.acceptCurrentChange,
      canRun: () => doc.canEdit && doc.hasCurrentChange,
    ),
    Command(
      id: ViewCommandIds.rejectChange,
      label: l10n.commandRejectChange,
      icon: Symbols.close_rounded,
      run: doc.rejectCurrentChange,
      canRun: () => doc.canEdit && doc.hasCurrentChange,
    ),
    Command(
      id: ViewCommandIds.acceptAll,
      label: l10n.commandAcceptAll,
      icon: Symbols.done_all_rounded,
      run: doc.acceptAllChanges,
      canRun: () => doc.canEdit && doc.hasChanges,
    ),
    Command(
      id: ViewCommandIds.rejectAll,
      label: l10n.commandRejectAll,
      icon: Symbols.remove_done_rounded,
      run: doc.rejectAllChanges,
      canRun: () => doc.canEdit && doc.hasChanges,
    ),
    Command(
      id: ViewCommandIds.stylesPanel,
      label: l10n.commandStylesPanel,
      icon: Symbols.style_rounded,
      run: view.toggleStylesPanel,
      isActive: () => view.stylesPanelOpen,
      canRun: open,
    ),
    // Ctrl+F1, como no Word.
    Command(
      id: ViewCommandIds.collapseRibbon,
      label: l10n.commandCollapseRibbon,
      icon: Symbols.expand_less_rounded,
      run: view.toggleRibbon,
      isActive: () => view.ribbonCollapsed,
      shortcuts: both(ctrl(LogicalKeyboardKey.f1)),
    ),
    Command(
      id: ViewCommandIds.ruler,
      label: l10n.commandRuler,
      icon: Symbols.straighten_rounded,
      run: view.toggleRuler,
      isActive: () => view.rulerShown,
    ),
    // F11, como a tela cheia dos navegadores (Esc também sai).
    Command(
      id: ViewCommandIds.zen,
      label: l10n.commandZen,
      icon: Symbols.center_focus_strong_rounded,
      run: view.toggleZen,
      isActive: () => view.zenOpen,
      canRun: open,
      shortcuts: both(const SingleActivator(LogicalKeyboardKey.f11)),
    ),
    Command(
      id: ViewCommandIds.fitWidth,
      label: l10n.commandFitWidth,
      icon: Symbols.fit_page_width_rounded,
      run: () => view.zoomToFit(page: false),
      canRun: open,
    ),
    Command(
      id: ViewCommandIds.fitPage,
      label: l10n.commandFitPage,
      icon: Symbols.fit_screen_rounded,
      run: () => view.zoomToFit(page: true),
      canRun: open,
    ),
    Command(
      id: ViewCommandIds.statusBar,
      label: l10n.commandStatusBar,
      icon: Symbols.bottom_navigation_rounded,
      run: view.toggleStatusBar,
      isActive: () => view.statusBarShown,
    ),
    for (final (id, value, label, icon) in [
      (ViewCommandIds.layoutSingle, 'uma', l10n.layoutSingle, Symbols.description_rounded),
      (ViewCommandIds.layoutMulti, 'varias', l10n.layoutMulti, Symbols.view_module_rounded),
      (ViewCommandIds.layoutBook, 'livro', l10n.layoutBook, Symbols.menu_book_rounded),
    ])
      Command(
        id: id,
        label: label,
        icon: icon,
        run: () => view.pageLayout = value,
        isActive: () => view.pageLayout == value,
        canRun: open,
      ),
    Command(
      id: ViewCommandIds.about,
      label: l10n.commandAbout,
      icon: Symbols.info_rounded,
      run: view.about,
    ),
  ]) {
    registry.register(c);
  }
}
