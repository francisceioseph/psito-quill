// Inserir tabela: uma grade como a do Word. O mouse escolhe passando por
// cima; o teclado, com as setas. Enter insere.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../tokens/tokens.dart';

const _maxColumns = 10, _maxRows = 8;

/// Devolve (linhas, colunas), ou null se cancelou.
Future<(int, int)?> showTableSizeDialog(BuildContext context) =>
    showDialog<(int, int)>(context: context, builder: (_) => const TableSizeDialog());

class TableSizeDialog extends StatefulWidget {
  const TableSizeDialog({super.key});

  @override
  State<TableSizeDialog> createState() => _TableSizeDialogState();
}

class _TableSizeDialogState extends State<TableSizeDialog> {
  int _rows = 2, _columns = 3;

  void _set(int rows, int columns) => setState(() {
        _rows = rows.clamp(1, _maxRows);
        _columns = columns.clamp(1, _maxColumns);
      });

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    switch (e.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        _set(_rows, _columns + 1);
      case LogicalKeyboardKey.arrowLeft:
        _set(_rows, _columns - 1);
      case LogicalKeyboardKey.arrowDown:
        _set(_rows + 1, _columns);
      case LogicalKeyboardKey.arrowUp:
        _set(_rows - 1, _columns);
      case LogicalKeyboardKey.enter:
        Navigator.of(context).pop((_rows, _columns));
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    const cell = 22.0;
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(t.space.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          WLabel(l10n.commandInsertTable.replaceAll('…', ''), heading: true),
          SizedBox(height: t.space.md),
          Focus(
            autofocus: true,
            onKeyEvent: _onKey,
            child: Semantics(
              label: l10n.commandInsertTable,
              value: l10n.tableSize(_columns, _rows),
              liveRegion: true,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (var r = 1; r <= _maxRows; r++)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    for (var c = 1; c <= _maxColumns; c++)
                      MouseRegion(
                        onEnter: (_) => _set(r, c),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop((r, c)),
                          child: Container(
                            width: cell,
                            height: cell,
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: r <= _rows && c <= _columns ? t.colors.accentSoft : t.colors.paper,
                              border: Border.all(
                                color: r <= _rows && c <= _columns ? t.colors.accent : t.colors.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ]),
              ]),
            ),
          ),
          SizedBox(height: t.space.md),
          Row(children: [
            WLabel(l10n.tableSize(_columns, _rows)),
            const Spacer(),
            WTextButton(label: l10n.dialogCancel, onPressed: () => Navigator.of(context).pop()),
            SizedBox(width: t.space.sm),
            WTextButton(
              label: l10n.commandInsertTable.replaceAll('…', ''),
              selected: true,
              onPressed: () => Navigator.of(context).pop((_rows, _columns)),
            ),
          ]),
        ]),
      ),
    );
  }
}
