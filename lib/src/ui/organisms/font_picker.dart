// A lista de fontes da faixa (Fase 2B, Etapa 3, D-045): cada nome desenhado
// na própria fonte, como no Office 2007, com a busca, os filtros (com
// serifa, sem serifa, mono) e as seções "Neste documento", "Recentes" e
// "Todas".
//
// A lista é preguiçosa (ListView.builder com altura fixa): só as fontes
// visíveis são construídas, e só elas carregam a fonte do disco. Um sistema
// tem centenas.
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../kit/quill_kit.dart' show FontClass;
import '../atoms/w_button.dart';
import '../atoms/w_chip.dart';
import '../atoms/w_label.dart';
import '../atoms/w_text_field.dart';
import '../tokens/tokens.dart';

enum FontFilter { all, serif, sans, mono }

/// Um item da lista: o título de uma seção ou uma fonte.
@immutable
class FontListItem {
  const FontListItem.header(this.text) : header = true;
  const FontListItem.font(this.text) : header = false;
  final String text;
  final bool header;

  @override
  bool operator ==(Object other) => other is FontListItem && other.text == text && other.header == header;

  @override
  int get hashCode => Object.hash(text, header);
}

/// A lista achatada, com as seções. Uma fonte aparece em "Neste documento"
/// e em "Recentes" e também em "Todas" (como no Word).
List<FontListItem> fontListItems({
  required List<String> all,
  required List<String> inDocument,
  required List<String> recent,
  required Map<String, int> classes,
  required String query,
  required FontFilter filter,
  required ({String inDocument, String recent, String all}) titles,
}) {
  final q = query.trim().toLowerCase();
  final installed = all.toSet();
  bool keep(String f) {
    if (!installed.contains(f)) return false;
    if (q.isNotEmpty && !f.toLowerCase().contains(q)) return false;
    final c = classes[f] ?? 0;
    return switch (filter) {
      FontFilter.all => true,
      FontFilter.serif => c & FontClass.serif != 0,
      FontFilter.sans => c & FontClass.sans != 0,
      FontFilter.mono => c & FontClass.mono != 0,
    };
  }

  final items = <FontListItem>[];
  void section(String title, Iterable<String> fonts) {
    final kept = fonts.where(keep).toList();
    if (kept.isEmpty) return;
    items.add(FontListItem.header(title));
    items.addAll(kept.map(FontListItem.font));
  }

  section(titles.inDocument, inDocument);
  section(titles.recent, recent);
  section(titles.all, all);
  return items;
}

class FontPicker extends StatelessWidget {
  const FontPicker({
    super.key,
    required this.current,
    required this.fonts,
    required this.inDocument,
    required this.recent,
    required this.classes,
    required this.onSelected,
    this.onClosed,
    this.width = 170,
  });

  final String? current;
  final List<String> fonts, inDocument, recent;
  final Map<String, int> classes;

  /// null: desligado (só leitura, ou a lista ainda não chegou).
  final ValueChanged<String>? onSelected;
  final VoidCallback? onClosed;
  final double width;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final name = current ?? '';
    return MenuAnchor(
      onClose: onClosed,
      style: const MenuStyle(padding: WidgetStatePropertyAll(EdgeInsets.zero)),
      menuChildren: [
        _FontPanel(
          current: current,
          fonts: fonts,
          inDocument: inDocument,
          recent: recent,
          classes: classes,
          onSelected: (f) => onSelected?.call(f),
        ),
      ],
      builder: (context, controller, _) => WControlSurface(
        tooltip: l10n.fieldFont,
        selected: false,
        outlined: true,
        width: width,
        trailingIcon: Symbols.arrow_drop_down_rounded,
        onPressed: onSelected == null ? null : () => controller.isOpen ? controller.close() : controller.open(),
        semantics: (child) => Semantics(
          container: true,
          button: true,
          enabled: onSelected != null,
          label: l10n.fieldFont,
          value: name,
          child: child,
        ),
        // O nome atual na própria fonte, como no Word.
        child: Row(children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: t.colors.onFrame, fontSize: t.font.ui, fontFamily: name.isEmpty ? t.font.family : name),
            ),
          ),
          Icon(Symbols.arrow_drop_down_rounded, size: t.density.icon - 2, color: t.colors.onFrameMuted),
        ]),
      ),
    );
  }
}

class _FontPanel extends StatefulWidget {
  const _FontPanel({
    required this.current,
    required this.fonts,
    required this.inDocument,
    required this.recent,
    required this.classes,
    required this.onSelected,
  });

  final String? current;
  final List<String> fonts, inDocument, recent;
  final Map<String, int> classes;
  final ValueChanged<String> onSelected;

  @override
  State<_FontPanel> createState() => _FontPanelState();
}

class _FontPanelState extends State<_FontPanel> {
  final _query = TextEditingController();
  FontFilter _filter = FontFilter.all;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<FontListItem> _items(AppLocalizations l10n) => fontListItems(
        all: widget.fonts,
        inDocument: widget.inDocument,
        recent: widget.recent,
        classes: widget.classes,
        query: _query.text,
        filter: _filter,
        titles: (inDocument: l10n.fontInDocument, recent: l10n.fontRecent, all: l10n.fontAll),
      );

  void _pick(String font) {
    widget.onSelected(font);
    MenuController.maybeOf(context)?.close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final c = t.colors;
    final items = _items(l10n);
    final rowHeight = t.density.control + t.space.xs;
    return SizedBox(
      width: 300,
      height: 420,
      child: Padding(
        padding: EdgeInsets.all(t.space.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          WTextField(
            label: l10n.fontSearch,
            controller: _query,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            // Enter: a primeira fonte que sobrou.
            onSubmitted: (_) {
              // Pela busca de agora, não pela da última construção.
              final first = _items(l10n).where((i) => !i.header).firstOrNull;
              if (first != null) _pick(first.text);
            },
          ),
          SizedBox(height: t.space.sm),
          Semantics(
            container: true,
            label: l10n.fontFilters,
            child: Wrap(spacing: t.space.xs, runSpacing: t.space.xs, children: [
              for (final (f, label) in [
                (FontFilter.all, l10n.fontAll),
                (FontFilter.serif, l10n.fontSerif),
                (FontFilter.sans, l10n.fontSans),
                (FontFilter.mono, l10n.fontMono),
              ])
                WChip(label: label, selected: _filter == f, onPressed: () => setState(() => _filter = f)),
            ]),
          ),
          SizedBox(height: t.space.sm),
          Expanded(
            child: items.isEmpty
                ? Padding(
                    padding: EdgeInsets.only(top: t.space.md),
                    child: WLabel(l10n.fontNone, tone: WLabelTone.muted),
                  )
                // primary: false — o menu já tem a rolagem dele.
                : ListView.builder(
                    primary: false,
                    itemCount: items.length,
                    itemExtent: rowHeight,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      if (item.header) {
                        return Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: t.space.md, bottom: t.space.xs),
                            child: Semantics(header: true, child: WLabel(item.text, small: true, tone: WLabelTone.muted)),
                          ),
                        );
                      }
                      final on = item.text == widget.current;
                      return WControlSurface(
                        tooltip: null,
                        selected: on,
                        onPressed: () => _pick(item.text),
                        semantics: (child) => Semantics(container: true, button: true, selected: on, label: item.text, child: child),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: on ? c.onAccentSoft : c.onFrame, fontSize: 15, fontFamily: item.text),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
