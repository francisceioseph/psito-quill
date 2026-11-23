// Os menus do tema Clássico 97, montados só com ids do CommandRegistry
// (PLANO 5.2: nenhum comando existe num lugar só). A paleta (Ctrl+K) usa os
// mesmos menus para dizer de onde vem cada comando.
import '../../l10n/gen/app_localizations.dart';
import 'commands_document.dart';
import 'commands_view.dart';

/// Um menu: o título e os ids, com null para o separador.
class MenuSpec {
  const MenuSpec(this.title, this.items);
  final String title;
  final List<String?> items;
}

List<MenuSpec> editorMenus(AppLocalizations l10n) => [
      MenuSpec(l10n.menuFile, const [
        CommandIds.newDocument,
        CommandIds.open,
        null,
        CommandIds.save,
        CommandIds.saveAs,
        null,
        ViewCommandIds.filePanel,
      ]),
      MenuSpec(l10n.menuEdit, const [
        CommandIds.undo,
        CommandIds.redo,
        null,
        CommandIds.cut,
        CommandIds.copy,
        CommandIds.paste,
        CommandIds.selectAll,
        null,
        ViewCommandIds.find,
        ViewCommandIds.replace,
      ]),
      MenuSpec(l10n.menuView, const [
        ViewCommandIds.inspector,
        ViewCommandIds.reveal,
        CommandIds.formattingMarks,
        null,
        CommandIds.zoomIn,
        CommandIds.zoomOut,
        CommandIds.zoomReset,
        null,
        ViewCommandIds.palette,
      ]),
      MenuSpec(l10n.menuInsert, const [
        CommandIds.pageBreak,
        null,
        ViewCommandIds.insertImage,
        ViewCommandIds.insertTable,
      ]),
      MenuSpec(l10n.menuFormat, const [
        CommandIds.bold,
        CommandIds.italic,
        CommandIds.underline,
        CommandIds.strikeout,
        CommandIds.superscript,
        CommandIds.subscript,
        null,
        CommandIds.alignLeft,
        CommandIds.alignCenter,
        CommandIds.alignRight,
        CommandIds.justify,
        null,
        CommandIds.lineSpacing1,
        CommandIds.lineSpacing15,
        CommandIds.lineSpacing2,
        CommandIds.spaceMore,
        CommandIds.spaceLess,
        null,
        CommandIds.bullets,
        CommandIds.numbering,
        CommandIds.indentMore,
        CommandIds.indentLess,
        null,
        CommandIds.portrait,
        CommandIds.landscape,
        null,
        CommandIds.wrapOff,
        CommandIds.wrapIdeal,
        CommandIds.wrapThrough,
        null,
        CommandIds.clearFormatting,
      ]),
      MenuSpec(l10n.menuStyles, const [
        CommandIds.bodyText,
        CommandIds.heading1,
        CommandIds.heading2,
        CommandIds.heading3,
        null,
        ViewCommandIds.newStyle,
        ViewCommandIds.updateStyle,
        ViewCommandIds.manageStyles,
      ]),
      MenuSpec(l10n.menuTools, const [
        CommandIds.spellOnline,
      ]),
      MenuSpec(l10n.menuTable, const [
        ViewCommandIds.insertTable,
        null,
        CommandIds.rowAbove,
        CommandIds.rowBelow,
        CommandIds.columnLeft,
        CommandIds.columnRight,
        null,
        CommandIds.deleteRow,
        CommandIds.deleteColumn,
        CommandIds.deleteTable,
        null,
        CommandIds.mergeCells,
      ]),
      MenuSpec(l10n.menuHelp, const [
        ViewCommandIds.palette,
        ViewCommandIds.about,
      ]),
    ];
