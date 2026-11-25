// A página: ladrilhos do motor + cursor, seleção e entrada, desenhados aqui.
//
// - Os ladrilhos são texturas (uma por vaga do cache nativo), posicionadas
//   pela grade em twips. Rolar é só mover widgets: o motor só é chamado para
//   desenhar o que entrou na tela.
// - O cursor pisca no Flutter, sem tocar no motor. A seleção usa a cor do
//   tema.
// - Teclas: primeiro os atalhos do CommandRegistry. As de edição e de
//   navegação (setas, Enter, Backspace) vão direto ao motor. O texto vem pelo
//   TextInput do sistema (o IME do GTK): é assim que `´` + `a` vira `á` no
//   ABNT2. A pré-edição aparece no documento até ser confirmada.
// - Ctrl+letra que não é atalho do Quill não vai ao motor: os atalhos são só
//   os do CommandRegistry, no jogo escolhido.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart'
    show GestureBinding, PointerScrollEvent, PointerSignalEvent, kPrimaryMouseButton, kSecondaryMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../commands/command_registry.dart';
import '../../document/document_controller.dart';
import '../../kit/lok/vcl_keys.dart';
import '../../kit/quill_kit.dart';
import '../tokens/tokens.dart';
import 'click_counter.dart';
import 'engine_context_menu.dart';
import '../templates/ui_zoom.dart';

/// As 8 alças de uma imagem selecionada, em twips: os cantos e os meios dos
/// lados, como o LibreOffice as numera (1 a 8, da esquerda para a direita e
/// de cima para baixo).
List<Offset> graphicHandles(Rect r) => [
      r.topLeft,
      r.topCenter,
      r.topRight,
      r.centerLeft,
      r.centerRight,
      r.bottomLeft,
      r.bottomCenter,
      r.bottomRight,
    ];

/// Para onde a imagem iria ao arrastar a alça [handle] (ou o corpo, com
/// null) por [delta] (twips). Só para a prévia: o motor decide o resultado
/// (ele mantém a proporção nos cantos).
Rect graphicDragPreview(Rect r, int? handle, Offset delta) {
  if (handle == null) return r.shift(delta);
  var (l, t, rt, b) = (r.left, r.top, r.right, r.bottom);
  if ({0, 3, 5}.contains(handle)) l += delta.dx;
  if ({2, 4, 7}.contains(handle)) rt += delta.dx;
  if ({0, 1, 2}.contains(handle)) t += delta.dy;
  if ({5, 6, 7}.contains(handle)) b += delta.dy;
  return Rect.fromLTRB(math.min(l, rt), math.min(t, b), math.max(l, rt), math.max(t, b));
}

/// Lado do ladrilho em twips para a escala (igual ao nativo, tile_cache.cc).
double tileTwips(int scaleMilli, int tileSize) => tileSize * twipsPerPixel * 1000 / scaleMilli;

/// Retângulo do ladrilho em twips, com as bordas arredondadas como no nativo.
Rect tileRectTwips(TileKey k, int tileSize) {
  final t = tileTwips(k.scaleMilli, tileSize);
  final x0 = (k.col * t).roundToDouble(), x1 = ((k.col + 1) * t).roundToDouble();
  final y0 = (k.row * t).roundToDouble(), y1 = ((k.row + 1) * t).roundToDouble();
  return Rect.fromLTRB(x0, y0, x1, y1);
}

/// A geometria da vista: converte entre pixels lógicos do conteúdo e twips.
class PageGeometry {
  const PageGeometry({required this.zoom, required this.viewSize, required this.documentTwips, this.padding = 24});

  final double zoom;
  final Size viewSize;
  final Size documentTwips;
  final double padding;

  double get pxPerTwip => zoom / twipsPerPixel;
  double get documentWidth => documentTwips.width * pxPerTwip;
  double get documentHeight => documentTwips.height * pxPerTwip;
  double get contentWidth => math.max(viewSize.width, documentWidth + 2 * padding);
  double get contentHeight => documentHeight + 2 * padding;

  /// Onde começa o documento dentro do conteúdo (centralizado na largura).
  Offset get origin => Offset((contentWidth - documentWidth) / 2, padding);

  Rect toLocal(Rect twips) => Rect.fromLTWH(
    origin.dx + twips.left * pxPerTwip,
    origin.dy + twips.top * pxPerTwip,
    twips.width * pxPerTwip,
    twips.height * pxPerTwip,
  );

  Offset toTwips(Offset local) => (local - origin) / pxPerTwip;

  /// A parte do documento visível com a rolagem ([scrollX], [scrollY]), em
  /// twips. Só o documento: o fundo dos lados não pede ladrilhos ao motor.
  Rect visibleTwips(double scrollX, double scrollY) {
    final left = (scrollX - origin.dx) / pxPerTwip;
    final top = (scrollY - origin.dy) / pxPerTwip;
    final x = math.max(0.0, left), y = math.max(0.0, top);
    final width = math.min(viewSize.width / pxPerTwip + math.min(0.0, left), documentTwips.width - x);
    final height = math.min(viewSize.height / pxPerTwip + math.min(0.0, top), documentTwips.height - y);
    return Rect.fromLTWH(x, y, math.max(0.0, width), math.max(0.0, height));
  }

  /// A rolagem que põe o ponto [twips] do documento sob o ponto [anchor] da
  /// tela (para o zoom não fazer a página pular).
  Offset scrollFor(Offset twips, Offset anchor) => origin + twips * pxPerTwip - anchor;
}

/// O zoom que faz a fileira de páginas caber na largura da vista ([whole]:
/// a página inteira, também na altura). [rowTwips] é a largura do documento
/// (a fileira, com o espaço em volta) e [pageHeightTwips] a altura de uma
/// página com o espaço de cima. O zoom é arredondado para baixo, em passos
/// de 5 %, como o do controlador.
double fitZoom(Size view, {required double rowTwips, required double pageHeightTwips, required bool whole, double padding = 24}) {
  if (rowTwips <= 0 || view.isEmpty) return 1;
  final w = (view.width - 2 * padding) * twipsPerPixel / rowTwips;
  final h = pageHeightTwips <= 0 ? w : (view.height - padding) * twipsPerPixel / pageHeightTwips;
  final z = whole ? math.min(w, h) : w;
  return (z * 20).floorToDouble() / 20;
}

/// Onde a página está na tela, para as réguas (D-046): a borda esquerda e
/// a de cima do documento, em pixels da área da página (já com a rolagem),
/// e a escala. As réguas só se repintam com isto; nada se reconstrói.
@immutable
class DocViewport {
  const DocViewport({required this.left, required this.top, required this.pxPerTwip, required this.viewSize});
  final double left, top, pxPerTwip;
  final Size viewSize;

  @override
  bool operator ==(Object other) =>
      other is DocViewport && other.left == left && other.top == top && other.pxPerTwip == pxPerTwip && other.viewSize == viewSize;

  @override
  int get hashCode => Object.hash(left, top, pxPerTwip, viewSize);
}

class DocumentView extends StatefulWidget {
  const DocumentView({
    super.key,
    required this.doc,
    required this.commands,
    required this.semanticLabel,
    this.scrollController,
    this.focusNode,
    this.viewport,
    this.typewriter = false,
    this.focusLines = 0,
    this.caretWidth = 1.5,
    this.caretBlink = true,
  });

  /// Máquina de escrever (o modo zen): a linha do cursor fica no meio da
  /// tela. Só a rolagem do Flutter; o motor não sabe.
  final bool typewriter;

  /// A espessura do cursor, em pixels, e se ele pisca (Acessibilidade,
  /// D-067).
  final double caretWidth;
  final bool caretBlink;

  /// Foco (o modo zen): escurece o que está a mais de [focusLines] linhas do
  /// cursor, para cima e para baixo. 0: desligado.
  final int focusLines;

  /// Recebe onde a página está, a cada rolagem ou zoom (as réguas).
  final ValueNotifier<DocViewport?>? viewport;

  final DocumentController doc;
  final CommandRegistry commands;
  final String semanticLabel;
  final ScrollController? scrollController;
  final FocusNode? focusNode;

  @override
  State<DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<DocumentView> with TextInputClient {
  late ScrollController _scroll = widget.scrollController ?? ScrollController();
  late FocusNode _focus = widget.focusNode ?? FocusNode(debugLabel: 'documento');
  PageGeometry? _geometry;
  int _scaleMilli = 1000;
  Timer? _blink;
  bool _caretOn = true;
  final _clickCounter = ClickCounter();
  int _clicks = 1;
  final _hscroll = ScrollController();

  /// Onde ancorar o próximo zoom, na tela (o ponteiro, no Ctrl+roda). null:
  /// o centro da tela.
  Offset? _zoomAnchor;

  TextInputConnection? _input;
  bool _composing = false;
  final GlobalKey _boxKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();

  /// O clique direito em curso (o botão solto não vai ao motor).
  bool _secondary = false;
  bool _menuShowing = false;

  /// Arrastando a imagem: de onde (twips), por qual alça (null: o corpo) e
  /// até onde.
  ({Offset from, int? handle, Offset to})? _graphicDrag;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_pushViewport);
    _hscroll.addListener(_pushViewport);
    widget.doc.addListener(_onDoc);
    _focus.addListener(_onFocus);
    _restartBlink();
  }

  @override
  void didUpdateWidget(DocumentView old) {
    super.didUpdateWidget(old);
    if (old.doc != widget.doc) {
      old.doc.removeListener(_onDoc);
      widget.doc.addListener(_onDoc);
    }
    if (old.scrollController != widget.scrollController && widget.scrollController != null) {
      _scroll.removeListener(_pushViewport);
      _scroll = widget.scrollController!;
      _scroll.addListener(_pushViewport);
    }
    if (old.focusNode != widget.focusNode && widget.focusNode != null) {
      _focus.removeListener(_onFocus);
      _focus = widget.focusNode!;
      _focus.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _closeInput();
    _focus.removeListener(_onFocus);
    _blink?.cancel();
    _scroll.removeListener(_pushViewport);
    _hscroll
      ..removeListener(_pushViewport)
      ..dispose();
    widget.doc.removeListener(_onDoc);
    if (widget.scrollController == null) _scroll.dispose();
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  DocStatus? _lastStatus;
  Rect _lastCursor = Rect.zero;
  late int _lastTab = widget.doc.tabRevision;

  /// Trocou de aba (D-054): volta à rolagem dela, com o tamanho dela já na
  /// tela, e pede os ladrilhos.
  void _restoreTabScroll(Offset want) {
    for (final (controller, value) in [(_hscroll, want.dx), (_scroll, want.dy)]) {
      if (!controller.hasClients) continue;
      final p = controller.position;
      controller.jumpTo(value.clamp(p.minScrollExtent, p.maxScrollExtent));
    }
    _pushViewport();
  }

  void _onDoc() {
    if (widget.doc.tabRevision != _lastTab) {
      _lastTab = widget.doc.tabRevision;
      _lastCursor = widget.doc.cursor;
      // Agora: até o quadro seguinte, a rolagem pode mexer sozinha (o tamanho
      // do outro documento) e escrever por cima.
      final want = widget.doc.scrollPosition;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _restoreTabScroll(want);
      });
    }
    final status = widget.doc.docStatus;
    if (status != _lastStatus) {
      _lastStatus = status;
      // Documento novo: a tela inteira precisa de ladrilhos.
      if (status == DocStatus.open) WidgetsBinding.instance.addPostFrameCallback((_) => _pushViewport());
      _syncInput();
    }
    if (widget.doc.contextMenu != null && !_menuShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showContextMenu());
    }
    if (widget.doc.cursor != _lastCursor) {
      _lastCursor = widget.doc.cursor;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendCaretRect();
        if (widget.typewriter) {
          _centerCaret();
        } else {
          _revealCaret();
        }
      });
    }
    if (mounted) setState(() {});
  }

  /// O cursor saiu da área (o salto a um título, a busca, as setas na beira
  /// da página): a vista rola até ele (D-072). Perto, só o bastante para ele
  /// caber com uma margem; longe (mais de uma tela), com ele no meio. Rolar
  /// com a roda não move o cursor, então não puxa a vista de volta.
  void _revealCaret() {
    final g = _geometry;
    final c = widget.doc.cursor;
    if (!mounted || g == null || c == Rect.zero) return;
    final caret = g.toLocal(c);
    var moved = false;
    for (final (controller, lo, hi, size) in [
      (_scroll, caret.top, caret.bottom, g.viewSize.height),
      (_hscroll, caret.left, caret.right, g.viewSize.width),
    ]) {
      if (!controller.hasClients) continue;
      final p = controller.position;
      final margin = math.min(16.0, size / 8);
      final start = p.pixels, end = p.pixels + size;
      if (lo >= start + margin && hi <= end - margin) continue;
      final far = lo > end + size || hi < start - size;
      final target = far
          ? (lo + hi) / 2 - size / 2
          : lo < start + margin
              ? lo - margin
              : hi - size + margin;
      final clamped = target.clamp(p.minScrollExtent, p.maxScrollExtent);
      if ((clamped - p.pixels).abs() > 1) {
        controller.jumpTo(clamped);
        moved = true;
      }
    }
    if (moved) _pushViewport();
  }

  /// A linha do cursor no meio da área (a máquina de escrever).
  void _centerCaret() {
    final g = _geometry;
    final c = widget.doc.cursor;
    if (g == null || c == Rect.zero || !_scroll.hasClients) return;
    final p = _scroll.position;
    final target = (g.toLocal(c).center.dy - g.viewSize.height / 2).clamp(p.minScrollExtent, p.maxScrollExtent);
    if ((target - p.pixels).abs() > 1) _scroll.jumpTo(target);
  }

  // ------------------------------------------------- entrada pelo sistema --

  void _onFocus() {
    _syncInput();
    if (mounted) setState(() {});
  }

  /// Com o foco e um documento editável, a conexão com o IME fica aberta.
  void _syncInput() {
    final want = _focus.hasFocus && widget.doc.canEdit;
    if (want && (_input == null || !_input!.attached)) {
      _input =
          TextInput.attach(
              this,
              const TextInputConfiguration(
                inputType: TextInputType.multiline,
                inputAction: TextInputAction.newline,
                autocorrect: false,
                enableSuggestions: false,
                enableIMEPersonalizedLearning: false,
              ),
            )
            ..setEditingState(TextEditingValue.empty)
            ..show();
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendCaretRect());
    } else if (!want) {
      _closeInput();
    }
  }

  void _closeInput() {
    if (_composing) {
      widget.doc.insertText('');
      _composing = false;
    }
    _input?.close();
    _input = null;
  }

  /// Onde está o cursor, para o IME pôr a janela de candidatos ao lado.
  void _sendCaretRect() {
    final input = _input;
    final g = _geometry;
    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    if (input == null || !input.attached || g == null || box == null || !box.attached) return;
    input.setEditableSizeAndTransform(box.size, box.getTransformTo(null));
    final caret = g.toLocal(widget.doc.cursor).shift(-_scrollOffset);
    input.setCaretRect(caret);
  }

  @override
  TextEditingValue? get currentTextEditingValue => TextEditingValue.empty;

  @override
  AutofillScope? get currentAutofillScope => null;

  /// O IME manda o valor inteiro. O Quill o mantém vazio: o que chega é o
  /// texto novo. Com "composing", ainda é pré-edição.
  @override
  void updateEditingValue(TextEditingValue value) {
    final composing = value.composing;
    if (composing.isValid && !composing.isCollapsed) {
      _composing = true;
      widget.doc.composeText(composing.textInside(value.text));
      return;
    }
    if (value.text.isNotEmpty) {
      widget.doc.insertText(value.text);
    } else if (_composing) {
      widget.doc.cancelComposition();
    }
    _composing = false;
    _input?.setEditingState(TextEditingValue.empty);
    _restartBlink();
  }

  @override
  void performAction(TextInputAction action) {
    if (action == TextInputAction.newline) widget.doc.postKey(13, VclKey.enter);
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void connectionClosed() {
    _input = null;
    _composing = false;
  }

  void _restartBlink() {
    _blink?.cancel();
    _caretOn = true;
    if (!widget.caretBlink) return;
    _blink = Timer.periodic(const QuillMotion().caretBlink, (_) {
      if (mounted) setState(() => _caretOn = !_caretOn);
    });
  }

  Offset get _scrollOffset =>
      Offset(_hscroll.hasClients ? _hscroll.offset : 0, _scroll.hasClients ? _scroll.offset : 0);

  void _pushViewport() {
    final g = _geometry;
    if (g == null || !_scroll.hasClients) return;
    final s = _scrollOffset;
    widget.doc.scrollPosition = s;
    widget.doc.setViewport(g.visibleTwips(s.dx, s.dy), _scaleMilli);
    // O ValueNotifier só avisa se o valor mudou (o == de DocViewport).
    widget.viewport?.value = DocViewport(
      left: g.origin.dx - s.dx,
      top: g.origin.dy - s.dy,
      pxPerTwip: g.pxPerTwip,
      viewSize: g.viewSize,
    );
  }

  /// O zoom mudou: rola para o ponto que estava sob a âncora continuar lá.
  void _keepAnchor(PageGeometry before, PageGeometry after) {
    final anchor = _zoomAnchor ?? Offset(before.viewSize.width / 2, before.viewSize.height / 2);
    _zoomAnchor = null;
    final point = before.toTwips(anchor + _scrollOffset);
    final target = after.scrollFor(point, anchor);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final (controller, value) in [(_hscroll, target.dx), (_scroll, target.dy)]) {
        if (!controller.hasClients) continue;
        final p = controller.position;
        controller.jumpTo(value.clamp(p.minScrollExtent, p.maxScrollExtent));
      }
      _pushViewport();
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    // Ocupado (D-066): o motor abre ou salva, e as teclas param.
    if (widget.doc.busy != null) return KeyEventResult.handled;
    final keyboard = HardwareKeyboard.instance;
    // No meio de uma composição, as teclas são do IME.
    if (_composing) return KeyEventResult.ignored;
    final command = widget.commands.match(event, keyboard);
    if (command != null) {
      widget.commands.run(command.id);
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final route = routeKey(event, control: keyboard.isControlPressed, alt: keyboard.isAltPressed);
    switch (route) {
      case KeyRoute.textInput:
        // Sem conexão com o IME (testes, ou o sistema não deu), o caractere
        // vai como texto mesmo.
        if (_input == null || !_input!.attached) {
          final ch = event.character;
          if (ch != null && widget.doc.canEdit) widget.doc.insertText(ch);
          return ch == null ? KeyEventResult.ignored : KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      case KeyRoute.swallow:
        return KeyEventResult.handled;
      case KeyRoute.engine:
        final stroke = vclKeyFor(
          event,
          shift: keyboard.isShiftPressed,
          control: keyboard.isControlPressed,
          alt: keyboard.isAltPressed,
        );
        if (stroke == null) return KeyEventResult.ignored;
        // Só leitura: só navegar (setas, Page Up…), não apagar.
        if (!widget.doc.canEdit && !isNavigationKey(event.logicalKey)) return KeyEventResult.handled;
        widget.doc.postKey(stroke.charCode, stroke.keyCode);
        _restartBlink();
        return KeyEventResult.handled;
    }
  }

  void _onPointerSignal(PointerSignalEvent e) {
    // Ctrl + roda do mouse: zoom.
    if (e is PointerScrollEvent && HardwareKeyboard.instance.isControlPressed) {
      GestureBinding.instance.pointerSignalResolver.register(e, (event) {
        final dy = (event as PointerScrollEvent).scrollDelta.dy;
        _zoomAnchor = event.localPosition - _scrollOffset;
        if (dy < 0) {
          widget.doc.zoomIn();
        } else if (dy > 0) {
          widget.doc.zoomOut();
        }
      });
    }
  }

  Future<void> _showContextMenu() async {
    final menu = widget.doc.contextMenu;
    final g = _geometry;
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (menu == null || g == null || box == null || _menuShowing || !mounted) return;
    _menuShowing = true;
    widget.doc.clearContextMenu();
    final local = g.toLocal(Rect.fromLTWH(menu.twips.dx, menu.twips.dy, 0, 0)).topLeft;
    await showEngineContextMenu(
      context,
      position: box.localToGlobal(local),
      doc: widget.doc,
      commands: widget.commands,
      engine: menu.items,
    );
    _menuShowing = false;
    if (mounted) _focus.requestFocus();
  }

  /// A alça da imagem sob [local] (pixels), ou null; -1 se é o corpo.
  int? _graphicHit(PageGeometry g, Offset local) {
    final r = widget.doc.graphic;
    if (r == null) return null;
    final handles = graphicHandles(r);
    for (var i = 0; i < handles.length; i++) {
      final p = g.toLocal(Rect.fromLTWH(handles[i].dx, handles[i].dy, 0, 0)).topLeft;
      if ((p - local).distance <= 8) return i;
    }
    return g.toLocal(r).contains(local) ? -1 : null;
  }

  /// Arrastar a imagem é do Quill (com a prévia); só o resultado vai ao
  /// motor, pelo setGraphicSelection.
  bool _graphicPointer(PointerEvent e, MouseEventType type, PageGeometry g) {
    final drag = _graphicDrag;
    switch (type) {
      case MouseEventType.down:
        if (!widget.doc.canEdit || e.buttons != kPrimaryMouseButton) return false;
        final hit = _graphicHit(g, e.localPosition);
        if (hit == null) return false;
        final from = hit >= 0 ? graphicHandles(widget.doc.graphic!)[hit] : g.toTwips(e.localPosition);
        setState(() => _graphicDrag = (from: from, handle: hit >= 0 ? hit : null, to: from));
        _focus.requestFocus();
        return true;
      case MouseEventType.move:
        if (drag == null) return false;
        setState(() => _graphicDrag = (from: drag.from, handle: drag.handle, to: g.toTwips(e.localPosition)));
        return true;
      case MouseEventType.up:
        if (drag == null) return false;
        setState(() => _graphicDrag = null);
        if ((drag.to - drag.from).distance * g.pxPerTwip > 3) widget.doc.dragGraphic(drag.from, drag.to);
        return true;
    }
  }

  /// O clique com Ctrl está procurando um link.
  bool _linkProbe = false;

  void _pointer(PointerEvent e, MouseEventType type) {
    final g = _geometry;
    if (g == null || widget.doc.docStatus != DocStatus.open) return;
    // Clique direito: o motor põe o cursor ali e responde com o menu dele.
    if (type == MouseEventType.down && e.buttons & kSecondaryMouseButton != 0) {
      _secondary = true;
      _focus.requestFocus();
      widget.doc.requestContextMenu(g.toTwips(e.localPosition));
      return;
    }
    if (_secondary) {
      if (type == MouseEventType.up) _secondary = false;
      return;
    }
    if (_graphicPointer(e, type, g)) return;
    if (type == MouseEventType.down) {
      _focus.requestFocus();
      final clicks = _clickCounter.down(DateTime.now(), e.localPosition);
      _clicks = lokClickCount(clicks, control: HardwareKeyboard.instance.isControlPressed);
      // Ctrl+clique (D-076): primeiro um clique simples; se o cursor parar
      // num link, a página pergunta se abre; senão, seleciona a frase, como
      // antes.
      _linkProbe = clicks == 1 && HardwareKeyboard.instance.isControlPressed;
      if (_linkProbe) _clicks = 1;
    }
    if (type == MouseEventType.move && e.buttons == 0) return;
    final at = g.toTwips(e.localPosition);
    widget.doc.postMouse(type, at, count: type == MouseEventType.move ? 1 : _clicks);
    if (type == MouseEventType.up && _linkProbe) {
      _linkProbe = false;
      widget.doc.expectLinkClick(otherwise: () {
        widget.doc.postMouse(MouseEventType.down, at, count: 3);
        widget.doc.postMouse(MouseEventType.up, at, count: 3);
      });
    }
    _restartBlink();
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final doc = widget.doc;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // A interface maior não aumenta a página (D-070): aqui dentro, um pixel
    // lógico vale [UiZoom.of] pixels da tela, e o zoom compensa.
    final zoom = doc.zoom / UiZoom.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final g = PageGeometry(zoom: zoom, viewSize: constraints.biggest, documentTwips: doc.documentSize);
        final scaleMilli = (dpr * zoom * 1000).round();
        final before = _geometry;
        if (before != null && before.zoom != g.zoom && !before.documentTwips.isEmpty) _keepAnchor(before, g);
        final changed =
            _geometry == null ||
            _geometry!.zoom != g.zoom ||
            _geometry!.viewSize != g.viewSize ||
            _geometry!.documentTwips != g.documentTwips ||
            _scaleMilli != scaleMilli;
        _geometry = g;
        _scaleMilli = scaleMilli;
        if (changed) WidgetsBinding.instance.addPostFrameCallback((_) => _pushViewport());

        final tileSize = doc.kit.tileSize;
        final children = <Widget>[
          // Os da escala anterior, esticados, por baixo: no zoom, a página não
          // fica em branco até os novos chegarem.
          for (final tile in doc.staleTiles)
            if (tile.textureId >= 0)
              Positioned.fromRect(
                rect: g.toLocal(tileRectTwips(tile.key, tileSize)),
                child: Texture(textureId: tile.textureId, filterQuality: FilterQuality.low),
              ),
          for (final tile in doc.tiles)
            Positioned.fromRect(
              rect: g.toLocal(tileRectTwips(tile.key, tileSize)),
              child: tile.textureId >= 0
                  ? Texture(textureId: tile.textureId, filterQuality: FilterQuality.none)
                  : ColoredBox(color: t.colors.paper),
            ),
          // Os trechos comentados e ainda abertos (D-088): o motor não os
          // pinta nos ladrilhos (LOK_FEATURE_NO_TILED_ANNOTATIONS).
          for (final cm in doc.comments)
            if (!cm.isReply && !cm.resolved)
              for (final r in cm.range)
                Positioned.fromRect(
                  rect: g.toLocal(r),
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.colors.tertiaryContainer.withValues(alpha: 0.55),
                        border: Border(bottom: BorderSide(color: t.colors.tertiary, width: 2)),
                      ),
                    ),
                  ),
                ),
          // As outras ocorrências da busca (a atual vem como seleção).
          for (final r in doc.searchHighlights)
            Positioned.fromRect(
              rect: g.toLocal(r),
              child: IgnorePointer(child: ColoredBox(color: t.colors.accentSoft.withValues(alpha: 0.5))),
            ),
          for (final r in doc.selection)
            Positioned.fromRect(
              rect: g.toLocal(r),
              child: ColoredBox(color: t.colors.selection),
            ),
          if (doc.graphic case final r?) ..._graphicFrame(t, g, r),
          // O foco do modo zen: o papel por cima do que está longe do cursor.
          if (widget.focusLines > 0 && doc.cursor != Rect.zero) ...() {
            final r = g.toLocal(doc.cursor);
            final band = r.height * (widget.focusLines + 0.5);
            final dim = t.colors.paper.withValues(alpha: 0.72);
            final page = g.toLocal(Offset.zero & doc.documentSize);
            return [
              Positioned.fromRect(
                rect: Rect.fromLTRB(page.left, page.top, page.right, math.max(page.top, r.center.dy - band)),
                child: IgnorePointer(child: ColoredBox(color: dim)),
              ),
              Positioned.fromRect(
                rect: Rect.fromLTRB(page.left, math.min(page.bottom, r.center.dy + band), page.right, page.bottom),
                child: IgnorePointer(child: ColoredBox(color: dim)),
              ),
            ];
          }(),
          if (doc.cursorVisible && doc.cursor != Rect.zero && _caretOn && _focus.hasFocus)
            Positioned.fromRect(
              rect: () {
                final r = g.toLocal(doc.cursor);
                return Rect.fromLTWH(r.left, r.top, math.max(widget.caretWidth, r.width), r.height);
              }(),
              child: ColoredBox(color: t.colors.cursor),
            ),
        ];

        return DocumentSemantics(
          key: _boxKey,
          label: widget.semanticLabel,
          readOnly: !doc.canEdit,
          text: doc.a11yParagraph,
          caret: doc.a11yCaret,
          child: Focus(
            focusNode: _focus,
            autofocus: true,
            onKeyEvent: _onKey,
            onFocusChange: (_) => setState(() {}),
            child: ColoredBox(
              color: t.colors.backdrop,
              // Rolagem nas duas direções: com zoom alto, a página fica mais
              // larga que a janela.
              child: Scrollbar(
                controller: _scroll,
                notificationPredicate: (n) => n.depth == 0,
                child: Scrollbar(
                  controller: _hscroll,
                  notificationPredicate: (n) => n.depth == 1,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    child: SingleChildScrollView(
                      controller: _hscroll,
                      scrollDirection: Axis.horizontal,
                      child: Listener(
                        onPointerSignal: _onPointerSignal,
                        onPointerDown: (e) => _pointer(e, MouseEventType.down),
                        onPointerMove: (e) => _pointer(e, MouseEventType.move),
                        onPointerUp: (e) => _pointer(e, MouseEventType.up),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.text,
                          child: SizedBox(
                            key: _contentKey,
                            width: g.contentWidth,
                            height: g.contentHeight,
                            child: Stack(clipBehavior: Clip.hardEdge, children: children),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// A moldura e as alças da imagem selecionada; ao arrastar, a prévia.
  List<Widget> _graphicFrame(QuillTokens t, PageGeometry g, Rect twips) {
    final drag = _graphicDrag;
    final r = drag == null ? twips : graphicDragPreview(twips, drag.handle, drag.to - drag.from);
    final local = g.toLocal(r);
    const h = 8.0;
    return [
      Positioned.fromRect(
        rect: local,
        child: IgnorePointer(
          child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: t.colors.accent, width: 1.5))),
        ),
      ),
      for (final p in graphicHandles(r))
        Positioned.fromRect(
          rect: Rect.fromCenter(center: g.toLocal(Rect.fromLTWH(p.dx, p.dy, 0, 0)).topLeft, width: h, height: h),
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(color: t.colors.paper, border: Border.all(color: t.colors.accent, width: 1.5)),
            ),
          ),
        ),
    ];
  }
}

/// O documento para o leitor de tela (D-067): um campo de texto com várias
/// linhas, cujo valor é o parágrafo do cursor (o motor manda com a
/// acessibilidade ligada) e a seleção é a posição do cursor nele. Sem a
/// acessibilidade, só o nome e o papel de campo de texto.
class DocumentSemantics extends SingleChildRenderObjectWidget {
  const DocumentSemantics({
    super.key,
    required this.label,
    required this.readOnly,
    required this.text,
    required this.caret,
    super.child,
  });

  final String label;
  final bool readOnly;
  final String? text;
  final int caret;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDocumentSemantics(label, readOnly, text, caret, Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderDocumentSemantics).update(label, readOnly, text, caret);
}

class _RenderDocumentSemantics extends RenderProxyBox {
  _RenderDocumentSemantics(this._label, this._readOnly, this._text, this._caret, this._direction);

  String _label;
  bool _readOnly;
  String? _text;
  int _caret;
  final TextDirection _direction;

  void update(String label, bool readOnly, String? text, int caret) {
    if (label == _label && readOnly == _readOnly && text == _text && caret == _caret) return;
    _label = label;
    _readOnly = readOnly;
    _text = text;
    _caret = caret;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..label = _label
      ..isTextField = true
      ..isMultiline = true
      ..isReadOnly = _readOnly
      ..textDirection = _direction;
    final text = _text;
    if (text != null) {
      config
        ..value = text
        ..textSelection = TextSelection.collapsed(offset: _caret.clamp(0, text.length));
    }
  }
}
