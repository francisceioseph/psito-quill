// A página: ladrilhos do motor + cursor, seleção e entrada, desenhados aqui.
//
// - Os ladrilhos são texturas (uma por vaga do cache nativo), posicionadas
//   pela grade em twips. Rolar é só mover widgets: o motor só é chamado para
//   desenhar o que entrou na tela.
// - O cursor pisca no Flutter, sem tocar no motor. A seleção usa a cor do
//   tema.
// - Teclas: primeiro os atalhos do CommandRegistry; o resto vai para o motor.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../commands/command_registry.dart';
import '../../document/document_controller.dart';
import '../../kit/lok/vcl_keys.dart';
import '../../kit/quill_kit.dart';
import '../tokens/tokens.dart';

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

  Rect toLocal(Rect twips) => Rect.fromLTWH(origin.dx + twips.left * pxPerTwip, origin.dy + twips.top * pxPerTwip,
      twips.width * pxPerTwip, twips.height * pxPerTwip);

  Offset toTwips(Offset local) => (local - origin) / pxPerTwip;

  /// A parte do documento visível com a rolagem [scrollY], em twips.
  Rect visibleTwips(double scrollY) {
    final top = (scrollY - origin.dy) / pxPerTwip;
    final left = math.max(0.0, -origin.dx / pxPerTwip);
    return Rect.fromLTWH(left, math.max(0.0, top), viewSize.width / pxPerTwip,
        viewSize.height / pxPerTwip + math.min(0.0, top));
  }
}

class DocumentView extends StatefulWidget {
  const DocumentView({
    super.key,
    required this.doc,
    required this.commands,
    required this.semanticLabel,
    this.zoom = 1.0,
    this.scrollController,
    this.focusNode,
  });

  final DocumentController doc;
  final CommandRegistry commands;
  final String semanticLabel;
  final double zoom;
  final ScrollController? scrollController;
  final FocusNode? focusNode;

  @override
  State<DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<DocumentView> {
  late ScrollController _scroll = widget.scrollController ?? ScrollController();
  late FocusNode _focus = widget.focusNode ?? FocusNode(debugLabel: 'documento');
  PageGeometry? _geometry;
  int _scaleMilli = 1000;
  Timer? _blink;
  bool _caretOn = true;
  DateTime _lastDown = DateTime(0);
  Offset _lastDownPos = Offset.zero;
  int _clicks = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_pushViewport);
    widget.doc.addListener(_onDoc);
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
    if (old.focusNode != widget.focusNode && widget.focusNode != null) _focus = widget.focusNode!;
  }

  @override
  void dispose() {
    _blink?.cancel();
    _scroll.removeListener(_pushViewport);
    widget.doc.removeListener(_onDoc);
    if (widget.scrollController == null) _scroll.dispose();
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  DocStatus? _lastStatus;
  void _onDoc() {
    final status = widget.doc.docStatus;
    if (status != _lastStatus) {
      _lastStatus = status;
      // Documento novo: a tela inteira precisa de ladrilhos.
      if (status == DocStatus.open) WidgetsBinding.instance.addPostFrameCallback((_) => _pushViewport());
    }
    if (mounted) setState(() {});
  }

  void _restartBlink() {
    _blink?.cancel();
    _caretOn = true;
    _blink = Timer.periodic(const QuillMotion().caretBlink, (_) {
      if (mounted) setState(() => _caretOn = !_caretOn);
    });
  }

  void _pushViewport() {
    final g = _geometry;
    if (g == null || !_scroll.hasClients) return;
    widget.doc.setViewport(g.visibleTwips(_scroll.offset), _scaleMilli);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final keyboard = HardwareKeyboard.instance;
    final command = widget.commands.match(event, keyboard);
    if (command != null) {
      widget.commands.run(command.id);
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final stroke = vclKeyFor(event,
        shift: keyboard.isShiftPressed, control: keyboard.isControlPressed, alt: keyboard.isAltPressed);
    if (stroke == null) return KeyEventResult.ignored;
    widget.doc.postKey(stroke.charCode, stroke.keyCode);
    _restartBlink();
    return KeyEventResult.handled;
  }

  void _pointer(PointerEvent e, MouseEventType type) {
    final g = _geometry;
    if (g == null || widget.doc.docStatus != DocStatus.open) return;
    if (type == MouseEventType.down) {
      _focus.requestFocus();
      final now = DateTime.now();
      final near = (e.localPosition - _lastDownPos).distance < 4;
      _clicks = now.difference(_lastDown) < kDoubleTapTimeout && near ? (_clicks % 3) + 1 : 1;
      _lastDown = now;
      _lastDownPos = e.localPosition;
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

    return LayoutBuilder(builder: (context, constraints) {
      final g = PageGeometry(zoom: widget.zoom, viewSize: constraints.biggest, documentTwips: doc.documentSize);
      final scaleMilli = (dpr * widget.zoom * 1000).round();
      final changed = _geometry == null ||
          _geometry!.viewSize != g.viewSize ||
          _geometry!.documentTwips != g.documentTwips ||
          _scaleMilli != scaleMilli;
      _geometry = g;
      _scaleMilli = scaleMilli;
      if (changed) WidgetsBinding.instance.addPostFrameCallback((_) => _pushViewport());

      final tileSize = doc.kit.tileSize;
      final children = <Widget>[
        for (final tile in doc.tiles)
          Positioned.fromRect(
            rect: g.toLocal(tileRectTwips(tile.key, tileSize)),
            child: tile.textureId >= 0
                ? Texture(textureId: tile.textureId, filterQuality: FilterQuality.none)
                : ColoredBox(color: t.colors.paper),
          ),
        for (final r in doc.selection)
          Positioned.fromRect(rect: g.toLocal(r), child: ColoredBox(color: t.colors.selection)),
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
        label: widget.semanticLabel,
        textField: true,
        multiline: true,
        child: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _onKey,
          onFocusChange: (_) => setState(() {}),
          child: ColoredBox(
            color: t.colors.backdrop,
            child: Scrollbar(
              controller: _scroll,
              child: SingleChildScrollView(
                controller: _scroll,
                child: Listener(
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
      );
    });
  }
}
