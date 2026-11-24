import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../book/book.dart';
import '../../book/book_controller.dart';
import '../../book/docx_import.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_book.dart';
import '../../commands/commands_document.dart';
import '../../commands/commands_page.dart';
import '../../commands/commands_view.dart';
import '../../document/document_controller.dart';
import '../../document/workspace.dart';
import '../../files/app_window.dart';
import '../../files/file_dialogs.dart';
import '../../settings/settings.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../molecules/command_button.dart';
import '../molecules/command_menu.dart';
import '../molecules/info_banner.dart';
import '../organisms/binder_panel.dart';
import '../organisms/book_dialogs.dart';
import '../organisms/snapshots_dialog.dart';
import '../organisms/classic_bars.dart';
import '../organisms/command_palette.dart';
import '../organisms/corkboard.dart';
import '../organisms/doc_tabs.dart';
import '../organisms/document_view.dart';
import '../organisms/file_panel.dart';
import '../organisms/find_panel.dart';
import '../organisms/goals_dialog.dart';
import '../organisms/inspector.dart';
import '../organisms/nav_rail.dart';
import '../organisms/notes_panel.dart';
import '../../document/outline.dart';
import '../atoms/w_segmented.dart';
import '../organisms/outline_panel.dart';
import '../organisms/page_dialogs.dart';
import '../organisms/ruler.dart';
import '../organisms/start_screen.dart';
import '../organisms/ribbon.dart';
import '../organisms/styles_dialog.dart';
import '../organisms/styles_panel.dart';
import '../organisms/table_size_dialog.dart';
import '../organisms/status_bar.dart';
import '../organisms/unsaved_dialog.dart';
import '../organisms/zen_view.dart';
import '../style_labels.dart';
import '../theme_labels.dart';
import '../templates/editor_template.dart';
import '../templates/ui_zoom.dart';
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

/// Os painéis do trilho, à esquerda. Localizar abre a barra de localizar,
/// não um painel.
enum _LeftPanel { binder, notes, outline, find, styles }

/// Os temas como comandos (a paleta e o menu Exibir do tema 97 os mostram).
const themeCommandPrefix = 'tema.';

class _EditorPageState extends State<EditorPage> implements EditorViewActions, BookViewActions, PageViewActions {
  CommandRegistry? _commands;
  final _docFocus = FocusNode(debugLabel: 'documento');
  bool _fileOpen = false;
  RibbonTab _tab = RibbonTab.home;

  /// A barra de localizar: null fechada; true com a linha de substituir.
  bool? _find;
  final _findKey = GlobalKey<FindPanelState>();
  final _notesKey = GlobalKey<NotesPanelState>();
  bool _reveal = false;

  /// O painel da esquerda, aberto pelo trilho.
  _LeftPanel? _left;

  /// A cortiça no lugar da página (D-084).
  bool _cork = false;
  InspectorPart _part = InspectorPart.text;

  DocumentController get doc => widget.workspace.doc;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettings);
    _viewport.addListener(_applyLayout);
    books.addListener(_onBook);
    // O Ctrl+clique num link (D-076): pergunta antes de abrir.
    doc.onLinkClicked = openLink;
  }

  // ------------------------------------------ a Etapa 4 (D-076) --

  @override
  void exportPdf() => unawaited(_exportPdf());
  Future<void> _exportPdf() async {
    final l10n = AppLocalizations.of(context);
    final current = doc.path;
    final name = current == null ? l10n.untitled : File(current).uri.pathSegments.last.replaceFirst(RegExp(r'\.[^.]*$'), '');
    final target = await widget.workspace.dialogs.pickExportPdf(
      suggestedName: '$name.pdf',
      initialDirectory: current == null ? null : File(current).parent.path,
      label: l10n.exportPdfFilter,
    );
    if (target == null || !mounted) return;
    final ok = await doc.exportPdf(target);
    if (!mounted) return;
    doc.notice(ok ? l10n.noticeExported(target) : l10n.noticeExportFailed);
  }

  @override
  void printDocument() => unawaited(_print());
  Future<void> _print() async {
    final l10n = AppLocalizations.of(context);
    final result = await doc.printDocument(_documentName(l10n));
    if (!mounted) return;
    switch (result.outcome) {
      case PrintOutcome.sent:
        doc.notice(l10n.noticePrinted);
      case PrintOutcome.cancelled:
        break;
      case PrintOutcome.failed:
        doc.notice(result.error == 'sem-pdf' ? l10n.noticePrintNoPdf : l10n.noticePrintFailed(result.error));
    }
  }

  @override
  void editLink() => unawaited(_editLink());
  Future<void> _editLink() async {
    final current = doc.link;
    final answer = await showLinkDialog(context, text: current?.text ?? '', url: current?.url ?? '');
    if (answer == null || !mounted) return;
    doc.insertLink(answer.$1, answer.$2);
    _docFocus.requestFocus();
  }

  @override
  void openLink(DocLink link) => unawaited(_openLink(link));
  Future<void> _openLink(DocLink link) async {
    // Só a web e o e-mail: um `file:` levaria o xdg-open a rodar um script
    // ou um .desktop do disco.
    final scheme = Uri.tryParse(link.url.trim())?.scheme.toLowerCase();
    if (!const {'http', 'https', 'mailto'}.contains(scheme)) {
      doc.notice(AppLocalizations.of(context).noticeLinkScheme);
      return;
    }
    if (!mounted || !await confirmOpenLink(context, link.url)) return;
    // O sistema abre (o navegador, o leitor de e-mail): só depois do "Abrir".
    try {
      await Process.start('xdg-open', [link.url], mode: ProcessStartMode.detached);
    } on ProcessException {
      // Sem o xdg-open: nada a fazer.
    }
  }

  @override
  void specialCharacter() => unawaited(_specialCharacter());
  Future<void> _specialCharacter() async {
    final char = await showSpecialCharacters(context);
    if (char == null || !mounted) return;
    doc.insertText(char);
    _docFocus.requestFocus();
  }

  BookController get books => widget.workspace.book;

  /// O livro abriu: o fichário aparece; fechou: some (D-071).
  String? _bookDir;
  void _onBook() {
    if (books.dir == _bookDir) return;
    _bookDir = books.dir;
    if (!books.isOpen && _cork) setState(() => _cork = false);
    if (books.isOpen) {
      _setLeft(_LeftPanel.binder);
    } else if (_left == _LeftPanel.binder || _left == _LeftPanel.notes) {
      _setLeft(null);
    }
  }

  void _showError(String text) =>
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  String _bookError(AppLocalizations l10n, BookError e) => switch (e) {
        BookError.missing => l10n.bookErrorMissing,
        BookError.invalid || BookError.newerFormat => l10n.bookErrorInvalid,
        BookError.exists => l10n.bookErrorExists,
        BookError.writeFailed => l10n.bookErrorWrite,
      };

  @override
  bool get binderOpen => _left == _LeftPanel.binder;

  @override
  bool get corkboardOpen => _cork && books.isOpen;

  @override
  void toggleCorkboard() {
    if (!books.isOpen && !_cork) return;
    if (_fileOpen) _fileOpen = false;
    setState(() => _cork = !_cork);
    if (!_cork) _backToDocument();
  }

  /// Abre o capítulo e volta da cortiça para a página.
  void _openFromCork(BookNode chapter) {
    widget.workspace.openChapter(chapter);
    setState(() => _cork = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _backToDocument());
  }

  @override
  void toggleBinder() => _setLeft(binderOpen ? null : _LeftPanel.binder);

  @override
  bool get notesOpen => _left == _LeftPanel.notes;

  @override
  void toggleNotes() => _setLeft(notesOpen ? null : _LeftPanel.notes);

  /// Abre as notas, se preciso, e cria uma nota nova nelas (D-082).
  @override
  void newNote() {
    if (!books.isOpen) return;
    if (_find != null) _closeFind();
    if (!notesOpen) _setLeft(_LeftPanel.notes);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notesKey.currentState?.newNote());
  }

  @override
  void newBook() => unawaited(_newBook());
  Future<void> _newBook() async {
    final l10n = AppLocalizations.of(context);
    final answer = await showNewBookDialog(context, widget.workspace.dialogs);
    if (answer == null || !mounted) return;
    if (!await widget.workspace.closeBook()) return;
    try {
      final book = await books.create(answer.$2, answer.$1, firstChapter: l10n.firstChapterTitle);
      widget.workspace.adoptBook(answer.$2, book);
    } on BookException catch (e) {
      _showError(_bookError(l10n, e.error));
    }
  }

  @override
  void openBook() => unawaited(_openBook());
  Future<void> _openBook() async {
    final l10n = AppLocalizations.of(context);
    final dir = await widget.workspace.dialogs.pickDirectory(label: l10n.commandOpenBook);
    if (dir == null || !mounted) return;
    final error = await widget.workspace.openBook(dir);
    if (error != null) _showError(_bookError(l10n, error));
  }

  @override
  void importManuscript() => unawaited(_importManuscript());
  Future<void> _importManuscript() async {
    final l10n = AppLocalizations.of(context);
    final path = await widget.workspace.dialogs.pickManuscript(label: l10n.fileTypeManuscripts);
    if (path == null || !mounted) return;
    final result = await showImportDialog(
      context,
      manuscript: path,
      importer: DocxImporter(doc.kit),
      dialogs: widget.workspace.dialogs,
    );
    if (result == null) return;
    if (!await widget.workspace.closeBook()) return;
    widget.workspace.adoptBook(result.$1, result.$2);
  }

  /// O capítulo da tela, se é do livro.
  BookNode? get _currentChapter => books.chapterAt(doc.path);

  @override
  void newChapter() => unawaited(_newChapter());
  Future<void> _newChapter() async {
    final l10n = AppLocalizations.of(context);
    try {
      final node = await books.addChapter(l10n.newChapterTitle, afterId: _currentChapter?.id);
      widget.workspace.openChapter(node);
      if (!binderOpen) _setLeft(_LeftPanel.binder);
    } on BookException catch (e) {
      _showError(_bookError(l10n, e.error));
    }
  }

  // ----------------------------------------------- as cenas (D-079) --

  void _notice(String text) => doc.notice(text);

  @override
  void newScene() => unawaited(_newScene());
  Future<void> _newScene() async {
    final l10n = AppLocalizations.of(context);
    if (!await doc.insertScene()) {
      if (mounted && doc.isOpen) _notice(l10n.scenesFailed);
      return;
    }
    _backToDocument();
  }

  @override
  void convertScenes() => unawaited(_convertScenes());
  Future<void> _convertScenes() async {
    final l10n = AppLocalizations.of(context);
    final n = await doc.convertSceneSeparators();
    if (!mounted) return;
    _notice(switch (n) {
      < 0 => l10n.scenesFailed,
      0 => l10n.scenesNone,
      _ => l10n.scenesConverted(n),
    });
  }

  @override
  void splitChapter() => unawaited(_splitChapter());
  Future<void> _splitChapter() async {
    final l10n = AppLocalizations.of(context);
    final current = _currentChapter;
    if (current == null) return;
    final r = await widget.workspace.splitChapterHere(fallbackTitle: l10n.splitContinuationTitle(current.title));
    if (!mounted) return;
    _notice(switch (r.error) {
      null => l10n.splitDone(r.created!.title),
      ChapterEditError.nothingToSplit => l10n.splitNothing,
      _ => l10n.splitFailed,
    });
    if (r.created != null && !binderOpen) _setLeft(_LeftPanel.binder);
  }

  @override
  void joinChapter() => unawaited(_joinChapter());
  Future<void> _joinChapter() async {
    final l10n = AppLocalizations.of(context);
    final current = _currentChapter;
    final next = widget.workspace.nextChapter;
    if (current == null) return;
    if (next == null) {
      _notice(l10n.joinNoNext);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.joinConfirmTitle),
        content: Text(l10n.joinConfirmBody(next.title, current.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.dialogCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.joinConfirm)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final error = await widget.workspace.joinWithNext();
    if (!mounted) return;
    _notice(switch (error) {
      null => l10n.joinDone(next.title),
      ChapterEditError.noNext => l10n.joinNoNext,
      ChapterEditError.nextModified => l10n.joinNextModified(next.title),
      _ => l10n.joinFailed,
    });
  }

  // ------------------------------------- os instantâneos (D-081) --

  @override
  void takeSnapshot() => unawaited(_takeSnapshot());
  Future<void> _takeSnapshot() async {
    final l10n = AppLocalizations.of(context);
    final current = _currentChapter;
    if (current == null) return;
    final s = await widget.workspace.takeSnapshot(current);
    if (!mounted) return;
    _notice(s == null ? l10n.snapshotFailed : l10n.snapshotTaken(current.title));
  }

  /// As palavras de hoje (D-083), com o capítulo da tela pelo motor; null
  /// sem livro ou antes da primeira contagem.
  int? get _writtenToday {
    final current = _currentChapter, w = doc.wordCount;
    return books.writtenToday(liveId: current?.id, liveWords: w == null || w.selection ? null : w.words);
  }

  /// As palavras do livro, com o capítulo da tela pelo motor.
  int get _bookWordsNow {
    final book = books.book, current = _currentChapter, w = doc.wordCount;
    if (book == null) return 0;
    if (current == null || w == null || w.selection) return book.words;
    return book.words - current.words + w.words;
  }

  @override
  void showGoals() {
    if (!books.isOpen) return;
    unawaited(showGoalsDialog(context, books: books, bookWords: _bookWordsNow, today: _writtenToday ?? 0));
  }

  @override
  void showSnapshots() {
    final current = _currentChapter;
    if (current != null) unawaited(_showSnapshots(current));
  }

  Future<void> _showSnapshots(BookNode chapter) async {
    final request = await showSnapshotsDialog(context, workspace: widget.workspace, chapter: chapter, onNotice: _notice);
    if (request == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    if (!widget.workspace.viewSnapshot(chapter, request.snapshot, label: l10n.snapshotLabel(chapter.title, request.when))) {
      _notice(l10n.snapshotCompareFailed);
      return;
    }
    _backToDocument();
  }


  @override
  void newPart() {
    books.addPart(AppLocalizations.of(context).newPartTitle, afterId: _currentChapter?.id);
    if (!binderOpen) _setLeft(_LeftPanel.binder);
  }

  /// Aplica a disposição das páginas (D-047). Em "Várias", as colunas saem
  /// do zoom e da largura da área; o motor só recebe quando o número muda.
  void _applyLayout() {
    if (!doc.isOpen) return;
    _applyOpenZoom();
    switch (widget.settings.pageLayout) {
      case 'livro':
        doc.setViewLayout(columns: 2, book: true);
      case 'varias':
        final v = _viewport.value;
        if (v == null) return;
        // A largura de uma página: a da régua do motor, ou a A4.
        final pageTwips = (doc.ruler?.pageWidth ?? 21000) * 1440 / 2540;
        final per = (pageTwips + pageGapTwips) * v.pxPerTwip;
        final columns = per <= 0 ? 1 : ((v.viewSize.width - 48) / per).floor().clamp(1, 12);
        doc.setViewLayout(columns: columns);
      default:
        doc.setViewLayout(columns: 1);
    }
  }

  /// O documento no leitor de tela (D-067): com a preferência, ou com um
  /// leitor de tela ativo (o `accessibleNavigation` do sistema).
  void _syncAccessibility() {
    final on = widget.settings.screenReaderDoc || (mounted && MediaQuery.accessibleNavigationOf(context));
    if (on == doc.accessibility) return;
    // Fora do build: o controlador avisa os ouvintes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) doc.setAccessibility(on);
    });
  }

  /// O zoom ao abrir (Acessibilidade, D-067): uma vez por aba, quando a área
  /// do documento já tem tamanho.
  final _zoomed = Expando<bool>('zoom ao abrir');
  void _applyOpenZoom() {
    final tab = doc.currentTab;
    if (!doc.isOpen || tab == null || _zoomed[tab] == true || _viewport.value == null) return;
    _zoomed[tab] = true;
    switch (widget.settings.zoomOnOpen) {
      case 'largura':
        zoomToFit(page: false);
      case 'pagina':
        zoomToFit(page: true);
    }
  }

  void _onSettings() {
    _commands?.scheme = widget.settings.shortcuts;
    _syncAccessibility();
    _applyLayout();
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
    _findSeed = null;
    setState(() => _find = null);
    _backToDocument();
  }

  /// A busca única (D-050): o texto e os comandos. "Com opções" abre o
  /// painel Localizar e substituir com o que foi digitado.
  @override
  void openPalette() => unawaited(
    showCommandPalette(context, _commands!, doc: doc).then((choice) {
      switch (choice) {
        case null:
          _backToDocument();
        case OpenFindOptions(:final query):
          _findSeed = query;
          openFind(replace: true);
        case GoToHit():
          _backToDocument();
        case RunCommand():
          break;
      }
    }),
  );

  /// O texto que a busca única passa ao painel Localizar.
  String? _findSeed;

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
  void manageStyles() => unawaited(showStylesDialog(context, doc, commands: _commands).then((_) => _backToDocument()));

  @override
  void openFilePanel() => _openFile(null);

  /// A seção dos bastidores ao abrir (null: a escolha do painel).
  FileSection? _fileSection;

  void _openFile(FileSection? section) => setState(() {
        _fileSection = section;
        _fileOpen = true;
      });

  @override
  bool get outlineOpen => _left == _LeftPanel.outline;

  @override
  void toggleOutline() => _setLeft(outlineOpen ? null : _LeftPanel.outline);

  /// Abre um painel da esquerda. A Estrutura aberta pede ao controlador que
  /// refaça a cópia nas pausas da digitação (D-047).
  void _setLeft(_LeftPanel? p) {
    setState(() => _left = p);
    // O fichário também: as cenas do capítulo da tela vêm da cópia (D-079).
    doc.liveOutline = p == _LeftPanel.outline || p == _LeftPanel.binder;
  }

  @override
  bool get stylesPanelOpen => _left == _LeftPanel.styles;

  @override
  void toggleStylesPanel() => _setLeft(stylesPanelOpen ? null : _LeftPanel.styles);

  @override
  bool get zenOpen => widget.settings.zen;

  /// O modo zen (D-048): tela cheia de verdade, só a página. O Esc sai por um
  /// tratador do teclado, que só existe enquanto o zen está aberto (no
  /// documento, o Esc iria para o motor).
  @override
  void toggleZen() {
    final on = !widget.settings.zen;
    widget.settings.zen = on;
    widget.window?.setFullscreen(on);
    if (on) {
      HardwareKeyboard.instance.addHandler(_zenEscape);
    } else {
      HardwareKeyboard.instance.removeHandler(_zenEscape);
    }
    _backToDocument();
  }

  bool _zenEscape(KeyEvent e) {
    if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.escape || !widget.settings.zen) return false;
    toggleZen();
    return true;
  }

  @override
  bool get rulerShown => widget.settings.ruler;

  @override
  void toggleRuler() => widget.settings.ruler = !widget.settings.ruler;

  @override
  void toggleStatusBar() => widget.settings.statusBar = !widget.settings.statusBar;

  @override
  bool get statusBarShown => widget.settings.statusBar;

  @override
  String get pageLayout => widget.settings.pageLayout;

  @override
  set pageLayout(String value) => widget.settings.pageLayout = value;

  @override
  void zoomToFit({required bool page}) {
    final v = _viewport.value;
    if (v == null || doc.documentSize.isEmpty) return;
    final h = switch (doc.pageSizeMm100) {
      (_, final h) => h * 1440 / 2540 + pageGapTwips,
      null => 0.0,
    };
    // O ajuste é medido nos pixels da vista; o zoom da página é na tela (D-070).
    final fit = fitZoom(v.viewSize, rowTwips: doc.documentSize.width, pageHeightTwips: h, whole: page);
    doc.setZoom(fit * UiZoom.of(context));
  }

  /// Onde a página está na tela, para as réguas (D-046).
  final _viewport = ValueNotifier<DocViewport?>(null);

  @override
  bool get ribbonCollapsed => widget.settings.ribbonCollapsed;

  @override
  void toggleRibbon() => widget.settings.ribbonCollapsed = !widget.settings.ribbonCollapsed;

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
    _syncAccessibility();
    final l10n = AppLocalizations.of(context);
    // Os rótulos dos comandos vêm da l10n, que só existe com o contexto.
    if (_commands == null) {
      final registry = CommandRegistry(scheme: widget.settings.shortcuts);
      registerEditorCommands(registry, doc: doc, workspace: widget.workspace, l10n: l10n);
      registerViewCommands(registry, doc: doc, view: this, l10n: l10n);
      registerBookCommands(registry, doc: doc, workspace: widget.workspace, view: this, l10n: l10n);
      registerPageCommands(registry, doc: doc, view: this, l10n: l10n);
      for (final (id, label) in themeChoices(l10n)) {
        registry.register(
          Command(
            id: '$themeCommandPrefix$id',
            label: label,
            icon: Symbols.palette_rounded,
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
    if (doc.onLinkClicked == openLink) doc.onLinkClicked = null;
    widget.settings.removeListener(_onSettings);
    books.removeListener(_onBook);
    if (widget.workspace.onUnsaved != null) widget.workspace.onUnsaved = null;
    _commands?.dispose();
    _docFocus.dispose();
    HardwareKeyboard.instance.removeHandler(_zenEscape);
    _viewport.removeListener(_applyLayout);
    _viewport.dispose();
    super.dispose();
  }

  String _documentName(AppLocalizations l10n) {
    if (doc.recovered case final r?) return l10n.recoveredName(r.name ?? l10n.untitled);
    final p = doc.path;
    final chapter = books.chapterAt(p);
    if (chapter != null) return l10n.bookChapterName(books.book!.title, chapter.title);
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
    // Ocupado (D-066): as teclas param, também os atalhos.
    if (doc.busy != null) return KeyEventResult.handled;
    if (_fieldKeeps(event)) return KeyEventResult.ignored;
    final command = _commands!.match(event, HardwareKeyboard.instance);
    if (command == null) return KeyEventResult.ignored;
    _commands!.run(command.id);
    return KeyEventResult.handled;
  }

  static final _fieldKeys = {
    LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyV, LogicalKeyboardKey.keyX, //
    LogicalKeyboardKey.keyZ, LogicalKeyboardKey.keyY, LogicalKeyboardKey.backspace, LogicalKeyboardKey.delete,
    LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.home, LogicalKeyboardKey.end,
  };

  /// Com o foco num campo de texto (uma nota, a busca, a sinopse), as teclas
  /// de editar texto são do campo: Ctrl+Z desfaz a nota, não o capítulo
  /// (D-082). Os outros atalhos (salvar, os painéis, as F-teclas) valem.
  bool _fieldKeeps(KeyEvent event) {
    final focus = FocusManager.instance.primaryFocus?.context;
    if (focus == null || focus.findAncestorWidgetOfExactType<EditableText>() == null) return false;
    final k = HardwareKeyboard.instance;
    if (k.isAltPressed) return false;
    if (!k.isControlPressed && !k.isMetaPressed) {
      // Sem Ctrl, só as F-teclas e o Esc saem do campo.
      final key = event.logicalKey;
      return key != LogicalKeyboardKey.escape &&
          !(key.keyId >= LogicalKeyboardKey.f1.keyId && key.keyId <= LogicalKeyboardKey.f24.keyId);
    }
    return _fieldKeys.contains(event.logicalKey);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final commands = _commands!;
    return Focus(
      onKeyEvent: _onPageKey,
      child: ListenableBuilder(
        listenable: Listenable.merge([doc, commands, books]),
        builder: (context, _) {
          widget.window?.setTitle(_windowTitle(l10n));
          if (widget.settings.zen && doc.isOpen && !doc.documentSize.isEmpty) return _zenView(l10n);
          final classic = t.component == ComponentStyle.bevel;
          // Tudo o que a faixa e o painel leem e não vem do motor.
          final key = (
            doc.stateRevision,
            books.revision, // o fichário e o título do capítulo
            widget.settings.shortcuts,
            t.id, // o tema aplicado (as preferências mudam antes)
            _tab,
            _fileOpen,
            _cork,
            _reveal,
            _find != null,
            _left,
            _part,
            widget.settings.inspector, // o trilho da direita marca a seção aberta
            widget.settings.ribbonCollapsed,
            widget.settings.recentFonts,
            widget.settings.pageLayout,
            widget.settings.ruler, // as caixas da aba Exibir
            widget.settings.statusBar,
          );
          // A barra de status e a Estrutura leem também a página e as palavras.
          final statusKey = (key, doc.statusRevision);
          return EditorTemplate(
            busy: doc.busy != null,
            top: _memoized(
              'top',
              key,
              () => _withTabs(classic
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
                                    leadingIcon: Icon(c.active ? Symbols.check_rounded : null, size: 16),
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
                      onFile: () => setState(() {
                        _fileSection = null;
                        _fileOpen = !_fileOpen;
                      }),
                      onTab: (tab) {
                        setState(() {
                          _tab = tab;
                          _fileOpen = false;
                        });
                        // Com a faixa recolhida, a aba a mostra de novo.
                        if (widget.settings.ribbonCollapsed) widget.settings.ribbonCollapsed = false;
                        _backToDocument();
                      },
                      onRan: _backToDocument,
                      collapsed: widget.settings.ribbonCollapsed,
                      onToggleCollapsed: toggleRibbon,
                      onSearch: openPalette,
                      onStylesPanel: toggleStylesPanel,
                      recentFonts: widget.settings.recentFonts,
                      onFontUsed: widget.settings.useFont,
                      trailing: [
                        WToggle(
                          icon: Symbols.dark_mode_rounded,
                          label: l10n.commandDarkPaper,
                          value: t.brightness == Brightness.dark,
                          onPressed: () => widget.settings.theme = t.brightness == Brightness.dark ? 'claro' : 'escuro',
                        ),
                      ],
                    )),
            ),
            rail: classic || _fileOpen || !(doc.isOpen || books.isOpen)
                ? null
                : _memoized(
                    'rail',
                    key,
                    () => NavRail<_LeftPanel?>(
                      label: l10n.railLabel,
                      items: [
                        if (books.isOpen) ...[
                          NavRailItem(_LeftPanel.binder, Symbols.account_tree_rounded, l10n.railBinder),
                          NavRailItem(_LeftPanel.notes, Symbols.sticky_note_2_rounded, l10n.railNotes),
                        ],
                        if (doc.isOpen) ...[
                          NavRailItem(_LeftPanel.outline, Symbols.toc_rounded, l10n.outlineTitle),
                          NavRailItem(_LeftPanel.find, Symbols.find_replace_rounded, l10n.railFind,
                              tooltip: commands.tooltipOf(ViewCommandIds.replace)),
                          NavRailItem(_LeftPanel.styles, Symbols.style_rounded, l10n.ribbonStyles),
                        ],
                      ],
                      selected: _find != null ? _LeftPanel.find : _left,
                      onSelected: (p) {
                        if (p == _LeftPanel.find || (p == null && _find != null)) {
                          _find == null ? openFind(replace: true) : _closeFind();
                          return;
                        }
                        _setLeft(p);
                      },
                    ),
                  ),
            leftPanel: _fileOpen || !(doc.isOpen || (books.isOpen && (_left == _LeftPanel.binder || _left == _LeftPanel.notes)))
                ? null
                // Localizar e substituir (D-062): por cima do painel da
                // esquerda que estiver aberto, que volta ao fechar.
                : _find != null && doc.isOpen
                ? FindPanel(
                    key: _findKey,
                    doc: doc,
                    closeLabel: l10n.findClose,
                    initialText: _findSeed ?? doc.search.query?.text ?? '',
                    onClose: _closeFind,
                    searchBook: books.book != null ? widget.workspace.searchBook : null,
                    onOpenBookHit: widget.workspace.openBookHit,
                  )
                : _left == null
                ? null
                : _memoized(
                    'left',
                    statusKey,
                    () => switch (_left!) {
                      _LeftPanel.binder => BinderPanel(
                          books: books,
                          currentPath: doc.path,
                          onOpen: (chapter) => _cork ? _openFromCork(chapter) : widget.workspace.openChapter(chapter),
                          scenes: doc.snapshot.scenes,
                          onOpenScene: (chapter, scene) {
                            widget.workspace.openChapter(chapter, scene: scene);
                            _backToDocument();
                          },
                          onNewChapter: newChapter,
                          onNewPart: newPart,
                          onSnapshots: (chapter) => unawaited(_showSnapshots(chapter)),
                          onCorkboard: toggleCorkboard,
                          onClose: toggleBinder,
                          closeLabel: l10n.binderClose,
                        ),
                      _LeftPanel.notes => NotesPanel(
                          key: _notesKey,
                          bookDir: books.dir!,
                          chapters: () => books.book?.chapters.toList() ?? const [],
                          onOpenChapter: widget.workspace.openChapter,
                          onClose: toggleNotes,
                          closeLabel: l10n.notesClose,
                        ),
                      _LeftPanel.outline => OutlinePanel(
                          entries: doc.snapshot.outline,
                          current: currentHeading(doc.snapshot.outline, doc.page?.$1),
                          onJump: (i) {
                            doc.goToHeading(doc.snapshot.outline[i]);
                            _backToDocument();
                          },
                          onClose: toggleOutline,
                        ),
                      _LeftPanel.styles || _LeftPanel.find => StylesPanel(
                          doc: doc,
                          commands: commands,
                          onClose: toggleStylesPanel,
                          onRan: _backToDocument,
                        ),
                    },
                  ),
            sidePanel: widget.settings.inspector && doc.isOpen && !_fileOpen
                ? _memoized(
                    'inspector',
                    key,
                    () => Inspector(
                      doc: doc,
                      commands: commands,
                      reveal: _reveal,
                      part: _part,
                      onPart: (p) => setState(() => _part = p),
                      onClose: toggleInspector,
                      onRan: _backToDocument,
                      sectionsInRail: !classic,
                    ),
                  )
                : null,
            // As seções do Formatar num trilho, como as do OnlyOffice
            // (D-062): escolher abre o painel nela; a aberta fecha.
            rightRail: classic || _fileOpen || !doc.isOpen
                ? null
                : _memoized(
                    'rightRail',
                    key,
                    () => NavRail<InspectorPart>(
                      label: l10n.inspectorSections,
                      items: [
                        for (final p in InspectorPart.values)
                          if ((p != InspectorPart.image || doc.graphic != null) && (p != InspectorPart.table || doc.inTable))
                            NavRailItem(p, inspectorPartIcon(p), inspectorPartLabel(l10n, p),
                                tooltip: p == InspectorPart.text ? commands.tooltipOf(ViewCommandIds.inspector) : null),
                      ],
                      selected: widget.settings.inspector ? shownInspectorPart(_part, doc) : null,
                      onSelected: (p) {
                        if (p == null) {
                          toggleInspector();
                          return;
                        }
                        setState(() => _part = p);
                        if (!widget.settings.inspector) widget.settings.inspector = true;
                      },
                    ),
                  ),
            banner: _fileOpen
                ? null
                : doc.readOnly && doc.viewing == null
                ? InfoBanner(
                    icon: Symbols.lock_outline_rounded,
                    text: l10n.readOnlyBanner(doc.lockOwner ?? ''),
                    actionLabel: l10n.readOnlySaveCopy,
                    onAction: () => unawaited(widget.workspace.saveAs()),
                  )
                : doc.viewing != null
                ? InfoBanner(
                    icon: Symbols.history_rounded,
                    text: l10n.snapshotViewingBanner(doc.viewing!),
                    actionLabel: l10n.snapshotCloseView,
                    onAction: () => unawaited(widget.workspace.closeTab()),
                  )
                : null,
            body: _fileOpen
                ? FilePanel(
                    commands: commands,
                    workspace: widget.workspace,
                    recents: widget.workspace.recents,
                    settings: widget.settings,
                    onClose: _backToDocument,
                    section: _fileSection,
                  )
                : corkboardOpen
                ? Corkboard(
                    books: books,
                    currentId: _currentChapter?.id,
                    onOpen: _openFromCork,
                    onClose: toggleCorkboard,
                  )
                : doc.tabs.isEmpty && doc.docStatus != DocStatus.opening
                ? StartScreen(workspace: widget.workspace, onNewBook: newBook, onImport: importManuscript)
                : doc.busy == BusyKind.opening
                ? const SizedBox.expand() // o progresso fica no rodapé (D-066)
                : !doc.isOpen || doc.documentSize.isEmpty
                ? Center(child: WLabel(_statusText(l10n), tone: WLabelTone.muted))
                : _withRulers(
                    DocumentView(
                      doc: doc,
                      commands: commands,
                      focusNode: _docFocus,
                      semanticLabel: l10n.documentArea,
                      scrollController: widget.scrollController,
                      viewport: _viewport,
                      caretWidth: widget.settings.caretWidth.toDouble(),
                      caretBlink: widget.settings.caretBlink,
                    ),
                  ),
            statusBar: !widget.settings.statusBar
                ? null
                : _memoized(
              'status',
              statusKey,
              () => StatusBar(
                progress: _progress(l10n),
                fields: [
                  StatusField(_statusText(l10n), tone: _statusTone(), flex: true),
                  if (doc.isOpen) ...[
                    if (doc.page case (final page, final pages))
                      StatusField(
                        l10n.statusPage(page, pages),
                        tooltip: l10n.outlineTitle,
                        onTap: toggleOutline,
                        priority: 1,
                      ),
                    if (doc.wordCount case final w?)
                      StatusField(
                        w.selection ? l10n.statusWordsSelected(w.words) : l10n.statusWords(w.words),
                        tooltip: l10n.statusWordsTip,
                        menu: _wordsMenu,
                        priority: 1,
                      ),
                    // O livro inteiro (D-071): o que está no livro.json, com o
                    // capítulo da tela pelo que o motor conta agora.
                    if (books.isOpen && _currentChapter != null)
                      StatusField(
                        l10n.statusBookWords(MaterialLocalizations.of(context).formatDecimal(_bookWordsNow)),
                        tooltip: l10n.statusBookWordsTip,
                        onTap: toggleBinder,
                        priority: 2,
                      ),
                    ..._goalFields(l10n),
                    if (doc.language case final lang?)
                      StatusField(
                        lang.tag == '-' ? l10n.languageNone : lang.name,
                        icon: Symbols.spellcheck_rounded,
                        tooltip: l10n.statusLanguageTip,
                        menu: doc.canEdit ? _languageMenu : null,
                        priority: 2,
                      ),
                    if (doc.readOnly) StatusField(l10n.statusReadOnly, tone: WLabelTone.normal, priority: 2),
                    if (doc.modified)
                      StatusField(
                        l10n.statusModified,
                        tooltip: commands.tooltipOf(CommandIds.save),
                        onTap: () => commands.run(CommandIds.save),
                        priority: 2,
                      ),
                    if (doc.paragraphStyleId case final s?)
                      StatusField(
                        styleLabel(l10n, s),
                        tooltip: l10n.ribbonStyles,
                        onTap: toggleStylesPanel,
                        priority: 3,
                      ),
                  ],
                ],
                trailing: [
                  if (widget.showMemory) ...[MemoryLabel(format: l10n.statusMemory), SizedBox(width: t.space.md)],
                  if (doc.isOpen) ...[
                    WSegmented<String>(
                      label: l10n.layoutLabel,
                      segments: [
                        WSegment('uma', l10n.layoutSingle, icon: Symbols.description_rounded, iconOnly: true),
                        WSegment('varias', l10n.layoutMulti, icon: Symbols.view_module_rounded, iconOnly: true),
                        WSegment('livro', l10n.layoutBook, icon: Symbols.menu_book_rounded, iconOnly: true),
                      ],
                      selected: widget.settings.pageLayout,
                      onChanged: (v) => widget.settings.pageLayout = v,
                      compact: true,
                    ),
                    SizedBox(width: t.space.md),
                  ],
                  if (doc.isOpen)
                    ZoomControl(
                      zoom: doc.zoom,
                      min: minZoom,
                      max: maxZoom,
                      label: l10n.zoomSlider,
                      percentLabel: l10n.zoomPercent,
                      onZoom: doc.setZoom,
                      zoomOut: CommandButton(commands: commands, id: CommandIds.zoomOut),
                      zoomIn: CommandButton(commands: commands, id: CommandIds.zoomIn),
                      menu: _zoomMenu,
                      menuTooltip: l10n.statusZoomTip,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// O progresso do motor no rodapé (D-066): abrir (com os números que o
  /// motor manda), salvar (sem número) ou um trabalho de fundo.
  Widget? _progress(AppLocalizations l10n) {
    final label = switch (doc.busy) {
      BusyKind.opening => l10n.busyOpening,
      BusyKind.saving => l10n.busySaving,
      BusyKind.working => l10n.busyWorkingChapters,
      // O nome que o motor dá ("Carregando: "), sem os dois-pontos.
      null => switch (doc.backgroundTask?.replaceAll(RegExp(r'[:\s]+$'), '')) {
          null => null,
          '' => l10n.busyWorking,
          final task => task,
        },
    };
    if (label == null) return null;
    return StatusProgress(label: label, percent: doc.progress, percentLabel: l10n.zoomPercent);
  }

  /// A meta do dia e a da sessão na barra de status (D-083); o clique abre
  /// as metas.
  List<StatusField> _goalFields(AppLocalizations l10n) {
    final book = books.book;
    if (book == null) return const [];
    final today = _writtenToday;
    if (today == null) return const [];
    final m = MaterialLocalizations.of(context);
    final session = books.sessionGoal;
    return [
      if (book.goals.daily case final goal?)
        StatusField(
          l10n.statusGoalToday(m.formatDecimal(today), m.formatDecimal(goal)),
          tone: today >= goal ? WLabelTone.normal : WLabelTone.muted,
          tooltip: l10n.statusGoalTodayTip,
          onTap: showGoals,
          priority: 2,
        ),
      if (session != null)
        StatusField(
          l10n.statusGoalSession(m.formatDecimal(books.sessionWritten(today) ?? 0), m.formatDecimal(session)),
          tooltip: l10n.goalsSession,
          onTap: showGoals,
          priority: 3,
        ),
    ];
  }

  // ------------------------------------- os menus da barra de status --

  /// As estatísticas: páginas, palavras, caracteres.
  List<Widget> _wordsMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final w = doc.wordCount;
    return [
      if (doc.page case (_, final pages)) StatusInfoRow(l10n.statusInfoPages, '$pages'),
      if (w != null) ...[
        StatusInfoRow(w.selection ? l10n.statusInfoSelected : l10n.statusInfoWords, '${w.words}'),
        StatusInfoRow(l10n.statusInfoCharacters, '${w.characters}'),
      ],
      const Divider(),
      plainMenuItem(context, l10n.statusMoreInfo, icon: Symbols.info_rounded, onPressed: () => _openFile(FileSection.info)),
    ];
  }

  /// O idioma da seleção (ou do parágrafo): os que têm ortografia
  /// instalada, sem verificação, o do estilo, e a ortografia ao digitar.
  List<Widget> _languageMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = doc.language?.tag;
    return [
      StatusInfoRow(doc.hasSelection ? l10n.languageForSelection : l10n.languageForParagraph, ''),
      for (final l in doc.languages)
        plainMenuItem(context, l.name, checked: l.tag == current, onPressed: () => doc.setLanguage(l.name)),
      plainMenuItem(context, l10n.languageNone,
          icon: Symbols.block_rounded, checked: current == '-', onPressed: () => doc.setLanguage(null)),
      plainMenuItem(context, l10n.languageReset, icon: Symbols.restart_alt_rounded, onPressed: () => doc.setLanguage(null, reset: true)),
      const Divider(),
      ...commandMenuItems(context, _commands!, [CommandIds.spellOnline]),
    ];
  }

  /// O zoom: as medidas comuns e os ajustes.
  List<Widget> _zoomMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = (doc.zoom * 100).round();
    return [
      for (final p in const [50, 75, 100, 125, 150, 200])
        plainMenuItem(context, l10n.zoomPercent(p), checked: p == now, onPressed: () => doc.setZoom(p / 100)),
      const Divider(),
      ...commandMenuItems(context, _commands!, [ViewCommandIds.fitWidth, ViewCommandIds.fitPage]),
    ];
  }

  /// A fileira das abas em cima da faixa, só com duas abas ou mais (D-054).
  Widget _withTabs(Widget bars) {
    if (doc.tabs.length < 2) return bars;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocTabStrip(doc: doc, onClose: (tab) => unawaited(widget.workspace.closeTab(tab))),
        bars,
      ],
    );
  }

  /// O modo zen: só a página, com a máquina de escrever e o foco.
  Widget _zenView(AppLocalizations l10n) {
    final s = widget.settings;
    final w = doc.wordCount;
    return ZenView(
      words: switch ([
        if (w != null) l10n.statusWords(w.words),
        if ((books.book?.goals.daily, _writtenToday) case (final goal?, final today?))
          l10n.zenGoal(MaterialLocalizations.of(context).formatDecimal(today), MaterialLocalizations.of(context).formatDecimal(goal)),
      ]) {
        [] => null,
        final parts => parts.join(' · '),
      },
      focus: s.zenFocus,
      typewriter: s.zenTypewriter,
      paper: s.zenPaper,
      onFocus: () => s.zenFocus = !s.zenFocus,
      onTypewriter: () => s.zenTypewriter = !s.zenTypewriter,
      onPaper: () => s.zenPaper = switch (s.zenPaper) {
        'sepia' => 'claro',
        'claro' => 'escuro',
        _ => 'sepia',
      },
      child: DocumentView(
        doc: doc,
        commands: _commands!,
        focusNode: _docFocus,
        semanticLabel: l10n.documentArea,
        scrollController: widget.scrollController,
        viewport: _viewport,
        typewriter: s.zenTypewriter,
        focusLines: s.zenFocus ? 2 : 0,
        caretWidth: s.caretWidth.toDouble(),
        caretBlink: s.caretBlink,
      ),
    );
  }

  /// A página com as réguas, se estiverem ligadas (Exibir › Régua).
  Widget _withRulers(Widget view) {
    if (!widget.settings.ruler) return view;
    final r = doc.ruler;
    final indents = doc.paragraphIndents;
    final pages = doc.page?.$2;
    final size = doc.documentSize;
    final margins = doc.snapshot.pageMargins;
    return RulerFrame(
      viewport: _viewport,
      unit: RulerUnit.values.asNameMap()[widget.settings.rulerUnit] ?? RulerUnit.cm,
      data: r == null
          ? null
          : RulerData(
              info: r,
              leftCm: indents['left'] ?? r.indent / 1000,
              firstLineCm: indents['firstline'] ?? 0,
              rightCm: indents['right'] ?? 0,
            ),
      // A pilha do motor: (altura − espaço) / fileiras − espaço (D-036).
      // Com páginas lado a lado, a régua vertical mede uma fileira por vez.
      pages: switch (pages == null || size.isEmpty ? 0 : pageRows(pages, columns: doc.viewColumns, book: doc.bookMode)) {
        <= 0 => null,
        final rows => (
            page: Size(size.width - 2 * pageGapTwips, (size.height - pageGapTwips) / rows - pageGapTwips),
            count: rows,
          ),
      },
      margins: margins == null ? null : (top: margins.top, bottom: margins.bottom),
      onIndents: doc.canEdit
          ? ({double? left, double? firstLine, double? right}) {
              doc.setIndents(left: left, firstLine: firstLine, right: right);
            }
          : null,
      // Duplo clique: o painel Formatar, na seção Parágrafo.
      onDoubleTap: () {
        setState(() => _part = InspectorPart.paragraph);
        if (!widget.settings.inspector) widget.settings.inspector = true;
      },
      child: view,
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
      NoticeMessage(:final text) => text,
      null => switch (doc.docStatus) {
        DocStatus.opening => l10n.statusOpening,
        DocStatus.none || DocStatus.failed => l10n.statusNoDocument,
        DocStatus.open => doc.path ?? l10n.untitled,
      },
    };
  }
}
