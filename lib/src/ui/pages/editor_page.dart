import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

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
import '../organisms/doc_tabs.dart';
import '../organisms/document_view.dart';
import '../organisms/file_panel.dart';
import '../organisms/find_panel.dart';
import '../organisms/inspector.dart';
import '../organisms/nav_rail.dart';
import '../../document/outline.dart';
import '../atoms/w_segmented.dart';
import '../organisms/outline_panel.dart';
import '../organisms/ruler.dart';
import '../organisms/ribbon.dart';
import '../organisms/styles_dialog.dart';
import '../organisms/styles_panel.dart';
import '../organisms/table_size_dialog.dart';
import '../organisms/status_bar.dart';
import '../organisms/unsaved_dialog.dart';
import '../organisms/zen_view.dart';
import '../style_labels.dart';
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

/// Os painéis do trilho, à esquerda. Localizar abre a barra de localizar,
/// não um painel.
enum _LeftPanel { outline, find, styles }

/// Os temas como comandos (a paleta e o menu Exibir do tema 97 os mostram).
const themeCommandPrefix = 'tema.';

class _EditorPageState extends State<EditorPage> implements EditorViewActions {
  CommandRegistry? _commands;
  final _docFocus = FocusNode(debugLabel: 'documento');
  bool _fileOpen = false;
  RibbonTab _tab = RibbonTab.home;

  /// A barra de localizar: null fechada; true com a linha de substituir.
  bool? _find;
  final _findKey = GlobalKey<FindPanelState>();
  bool _reveal = false;

  /// O painel da esquerda, aberto pelo trilho.
  _LeftPanel? _left;
  InspectorPart _part = InspectorPart.text;

  DocumentController get doc => widget.workspace.doc;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettings);
    _viewport.addListener(_applyLayout);
  }

  /// Aplica a disposição das páginas (D-047). Em "Várias", as colunas saem
  /// do zoom e da largura da área; o motor só recebe quando o número muda.
  void _applyLayout() {
    if (!doc.isOpen) return;
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

  void _onSettings() {
    _commands?.scheme = widget.settings.shortcuts;
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
  void openFilePanel() => setState(() => _fileOpen = true);

  @override
  bool get outlineOpen => _left == _LeftPanel.outline;

  @override
  void toggleOutline() => _setLeft(outlineOpen ? null : _LeftPanel.outline);

  /// Abre um painel da esquerda. A Estrutura aberta pede ao controlador que
  /// refaça a cópia nas pausas da digitação (D-047).
  void _setLeft(_LeftPanel? p) {
    setState(() => _left = p);
    doc.liveOutline = p == _LeftPanel.outline;
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
    final l10n = AppLocalizations.of(context);
    // Os rótulos dos comandos vêm da l10n, que só existe com o contexto.
    if (_commands == null) {
      final registry = CommandRegistry(scheme: widget.settings.shortcuts);
      registerEditorCommands(registry, doc: doc, workspace: widget.workspace, l10n: l10n);
      registerViewCommands(registry, doc: doc, view: this, l10n: l10n);
      for (final (id, label) in [
        ('claro', l10n.themeClaro),
        ('escuro', l10n.themeEscuro),
        ('sepia', l10n.themeSepia),
        ('classico97', l10n.themeClassico),
      ]) {
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
    widget.settings.removeListener(_onSettings);
    if (widget.workspace.onUnsaved != null) widget.workspace.onUnsaved = null;
    _commands?.dispose();
    _docFocus.dispose();
    HardwareKeyboard.instance.removeHandler(_zenEscape);
    _viewport.removeListener(_applyLayout);
    _viewport.dispose();
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
          if (widget.settings.zen && doc.isOpen && !doc.documentSize.isEmpty) return _zenView(l10n);
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
            _left,
            _part,
            widget.settings.inspector, // o trilho da direita marca a seção aberta
            widget.settings.ribbonCollapsed,
            widget.settings.recentFonts,
            widget.settings.pageLayout,
          );
          // A barra de status e a Estrutura leem também a página e as palavras.
          final statusKey = (key, doc.statusRevision);
          return EditorTemplate(
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
                      onFile: () => setState(() => _fileOpen = !_fileOpen),
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
            rail: classic || _fileOpen || !doc.isOpen
                ? null
                : _memoized(
                    'rail',
                    key,
                    () => NavRail<_LeftPanel?>(
                      label: l10n.railLabel,
                      items: [
                        NavRailItem(_LeftPanel.outline, Symbols.toc_rounded, l10n.outlineTitle),
                        NavRailItem(_LeftPanel.find, Symbols.find_replace_rounded, l10n.railFind,
                            tooltip: commands.tooltipOf(ViewCommandIds.replace)),
                        NavRailItem(_LeftPanel.styles, Symbols.style_rounded, l10n.ribbonStyles),
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
            leftPanel: _fileOpen || !doc.isOpen
                ? null
                // Localizar e substituir (D-062): por cima do painel da
                // esquerda que estiver aberto, que volta ao fechar.
                : _find != null
                ? FindPanel(
                    key: _findKey,
                    doc: doc,
                    closeLabel: l10n.findClose,
                    initialText: _findSeed ?? doc.search.query?.text ?? '',
                    onClose: _closeFind,
                  )
                : _left == null
                ? null
                : _memoized(
                    'left',
                    statusKey,
                    () => switch (_left!) {
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
            banner: doc.readOnly && !_fileOpen
                ? InfoBanner(
                    icon: Symbols.lock_outline_rounded,
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
                : _withRulers(
                    DocumentView(
                      doc: doc,
                      commands: commands,
                      focusNode: _docFocus,
                      semanticLabel: l10n.documentArea,
                      scrollController: widget.scrollController,
                      viewport: _viewport,
                    ),
                  ),
            statusBar: _memoized(
              'status',
              statusKey,
              () => StatusBar(
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
                        priority: 1,
                      ),
                    if (doc.commandStates['.uno:LanguageStatus'] case final lang?)
                      StatusField(
                        lang.split(';').first,
                        icon: Symbols.spellcheck_rounded,
                        priority: 2,
                      ),
                    if (doc.readOnly) StatusField(l10n.statusReadOnly, tone: WLabelTone.normal, priority: 2),
                    if (doc.modified) StatusField(l10n.statusModified, priority: 2),
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
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
      words: w == null ? null : l10n.statusWords(w.words),
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
      null => switch (doc.docStatus) {
        DocStatus.opening => l10n.statusOpening,
        DocStatus.none || DocStatus.failed => l10n.statusNoDocument,
        DocStatus.open => doc.path ?? l10n.untitled,
      },
    };
  }
}
