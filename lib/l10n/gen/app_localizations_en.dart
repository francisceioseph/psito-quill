// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Psito Quill';

  @override
  String get commandBold => 'Bold';

  @override
  String get commandSave => 'Save';

  @override
  String get commandDarkPaper => 'Dark theme';

  @override
  String get documentArea => 'Document';

  @override
  String get statusStarting => 'Starting the engine…';

  @override
  String statusEngineFailed(String detail) {
    return 'The engine did not start: $detail';
  }

  @override
  String get statusOpening => 'Opening…';

  @override
  String get statusNoDocument => 'No document';

  @override
  String statusSaved(String path) {
    return 'Saved to $path';
  }

  @override
  String statusError(String detail) {
    return 'Error: $detail';
  }

  @override
  String statusPlugin(String text) {
    return 'Plugin: $text';
  }

  @override
  String get statusModified => 'modified';

  @override
  String statusMemory(int mb) {
    return '$mb MB';
  }

  @override
  String get commandNew => 'New';

  @override
  String get commandOpen => 'Open…';

  @override
  String get commandSaveAs => 'Save as…';

  @override
  String get commandUndo => 'Undo';

  @override
  String get commandRedo => 'Redo';

  @override
  String get commandCut => 'Cut';

  @override
  String get commandCopy => 'Copy';

  @override
  String get commandPaste => 'Paste';

  @override
  String get commandSelectAll => 'Select all';

  @override
  String get commandItalic => 'Italic';

  @override
  String get commandUnderline => 'Underline';

  @override
  String get commandStrikeout => 'Strikethrough';

  @override
  String get commandAlignLeft => 'Align left';

  @override
  String get commandAlignCenter => 'Center';

  @override
  String get commandAlignRight => 'Align right';

  @override
  String get commandJustify => 'Justify';

  @override
  String get commandBullets => 'Bullets';

  @override
  String get commandNumbering => 'Numbering';

  @override
  String get commandZoomIn => 'Zoom in';

  @override
  String get commandZoomOut => 'Zoom out';

  @override
  String get commandZoomReset => 'Zoom to 100%';

  @override
  String get styleDefault => 'Default';

  @override
  String get styleBody => 'Body text';

  @override
  String get styleTitle => 'Title';

  @override
  String get styleSubtitle => 'Subtitle';

  @override
  String styleHeading(int level) {
    return 'Heading $level';
  }

  @override
  String get styleQuote => 'Quotation';

  @override
  String get ribbonFile => 'File';

  @override
  String get ribbonHome => 'Home';

  @override
  String get groupClipboard => 'Clipboard';

  @override
  String get groupStyles => 'Styles';

  @override
  String get groupFont => 'Font';

  @override
  String get groupParagraph => 'Paragraph';

  @override
  String get fieldStyle => 'Paragraph style';

  @override
  String get fieldFont => 'Font';

  @override
  String get fieldFontSize => 'Font size';

  @override
  String get fileBack => 'Back to the document';

  @override
  String get recentTitle => 'Recent';

  @override
  String get recentEmpty => 'No recent files.';

  @override
  String get preferencesTitle => 'Preferences';

  @override
  String get prefTheme => 'Theme';

  @override
  String get prefShortcuts => 'Keyboard shortcuts';

  @override
  String get schemeWordPt => 'Word in Portuguese (Ctrl+N bold, Ctrl+B save)';

  @override
  String get schemeWordEn => 'Word in English (Ctrl+B bold, Ctrl+S save)';

  @override
  String get themeClaro => 'Light';

  @override
  String get themeEscuro => 'Dark';

  @override
  String readOnlyBanner(String owner) {
    return 'Read-only: $owner has this file open. To edit, save a copy.';
  }

  @override
  String get readOnlySaveCopy => 'Save a copy…';

  @override
  String get unsavedTitle => 'Save your changes?';

  @override
  String unsavedBody(String name) {
    return '“$name” has changes that have not been saved.';
  }

  @override
  String get unsavedSave => 'Save';

  @override
  String get unsavedDiscard => 'Don\'t save';

  @override
  String get unsavedCancel => 'Cancel';

  @override
  String get untitled => 'Untitled document';

  @override
  String windowTitle(String name) {
    return '$name — Psito Quill';
  }

  @override
  String windowTitleModified(String name) {
    return '• $name — Psito Quill';
  }

  @override
  String windowTitleReadOnly(String name) {
    return '$name (read-only) — Psito Quill';
  }

  @override
  String get fileTypeDocuments => 'Documents (ODT, DOCX)';

  @override
  String get formatOdt => 'ODF document (.odt)';

  @override
  String get formatDocx => 'Word document (.docx)';

  @override
  String statusPage(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String statusWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String statusWordsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words selected',
      one: '1 word selected',
    );
    return '$_temp0';
  }

  @override
  String statusZoom(int percent) {
    return '$percent%';
  }

  @override
  String get statusReadOnly => 'read-only';

  @override
  String statusOpenFailed(String name, String detail) {
    return 'Could not open $name: $detail';
  }
}
