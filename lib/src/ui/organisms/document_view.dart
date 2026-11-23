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

import 'package:flutter/gestures.dart' show GestureBinding, PointerScrollEvent, PointerSignalEvent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../commands/command_registry.dart';
import '../../document/document_controller.dart';
import '../../kit/lok/vcl_keys.dart';
import '../../kit/quill_kit.dart';
import '../tokens/tokens.dart';
import 'click_counter.dart';

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

class DocumentView extends StatefulWidget {
  const DocumentView({
    super.key,
    required this.doc,
    required this.commands,
    required this.semanticLabel,
    this.scrollController,
    this.focusNode,
  });

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
  void _onDoc() {
    final status = widget.doc.docStatus;
    if (status != _lastStatus) {
      _lastStatus = status;
      // Documento novo: a tela inteira precisa de ladrilhos.
      if (status == DocStatus.open) WidgetsBinding.instance.addPostFrameCallback((_) => _pushViewport());
      _syncInput();
    }
    if (widget.doc.cursor != _lastCursor) {
      _lastCursor = widget.doc.cursor;
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendCaretRect());
    }
    if (mounted) setState(() {});
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
      widget.doc.insertText(''); // pré-edição cancelada
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
    widget.doc.setViewport(g.visibleTwips(s.dx, s.dy), _scaleMilli);
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

  void _pointer(PointerEvent e, MouseEventType type) {
    final g = _geometry;
    if (g == null || widget.doc.docStatus != DocStatus.open) return;
    if (type == MouseEventType.down) {
      _focus.requestFocus();
      _clicks = lokClickCount(
        _clickCounter.down(DateTime.now(), e.localPosition),
        control: HardwareKeyboard.instance.isControlPressed,
      );
    }
    if (type == MouseEventType.move && e.buttons == 0) return;
    widget.doc.postMouse(type, g.toTwips(e.localPosition), count: type == MouseEventType.move ? 1 : _clicks);
    _restartBlink();
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final doc = widget.doc;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final g = PageGeometry(zoom: doc.zoom, viewSize: constraints.biggest, documentTwips: doc.documentSize);
        final scaleMilli = (dpr * doc.zoom * 1000).round();
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
          for (final r in doc.selection)
            Positioned.fromRect(
              rect: g.toLocal(r),
              child: ColoredBox(color: t.colors.selection),
            ),
          if (doc.cursorVisible && doc.cursor != Rect.zero && _caretOn && _focus.hasFocus)
            Positioned.fromRect(
              rect: () {
                final r = g.toLocal(doc.cursor);
                return Rect.fromLTWH(r.left, r.top, math.max(1.5, r.width), r.height);
              }(),
              child: ColoredBox(color: t.colors.cursor),
            ),
        ];

        return Semantics(
          key: _boxKey,
          label: widget.semanticLabel,
          textField: true,
          multiline: true,
          readOnly: !doc.canEdit,
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
}
