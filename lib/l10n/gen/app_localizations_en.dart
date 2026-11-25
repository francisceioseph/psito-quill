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
  String get prefPrivacy => 'Privacy';

  @override
  String get prefKeepRecents => 'Keep the list of recent files';

  @override
  String get prefPrivacyNote =>
      'Nothing leaves this computer: no network, no telemetry, no log files.';

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

  @override
  String get commandFind => 'Find';

  @override
  String get commandReplace => 'Replace';

  @override
  String get commandPalette => 'Search';

  @override
  String get commandInspector => 'Format panel';

  @override
  String get commandRevealFormatting => 'Reveal formatting';

  @override
  String get commandFormattingMarks => 'Formatting marks';

  @override
  String get commandSpellOnline => 'Automatic spell check';

  @override
  String get commandInsertImage => 'Picture…';

  @override
  String get commandInsertTable => 'Table…';

  @override
  String get commandPageBreak => 'Page break';

  @override
  String get commandIndentMore => 'Increase indent';

  @override
  String get commandIndentLess => 'Decrease indent';

  @override
  String get commandLineSpacing1 => 'Single line spacing';

  @override
  String get commandLineSpacing15 => 'Line spacing 1.5';

  @override
  String get commandLineSpacing2 => 'Double line spacing';

  @override
  String get commandSpaceMore => 'More space between paragraphs';

  @override
  String get commandSpaceLess => 'Less space between paragraphs';

  @override
  String get commandSuperscript => 'Superscript';

  @override
  String get commandSubscript => 'Subscript';

  @override
  String get commandClearFormatting => 'Clear direct formatting';

  @override
  String get commandNewStyle => 'New style from selection…';

  @override
  String get commandUpdateStyle => 'Update style to match selection';

  @override
  String get commandManageStyles => 'Manage styles…';

  @override
  String get commandRowAbove => 'Insert row above';

  @override
  String get commandRowBelow => 'Insert row below';

  @override
  String get commandColumnLeft => 'Insert column left';

  @override
  String get commandColumnRight => 'Insert column right';

  @override
  String get commandDeleteRow => 'Delete row';

  @override
  String get commandDeleteColumn => 'Delete column';

  @override
  String get commandDeleteTable => 'Delete table';

  @override
  String get commandMergeCells => 'Merge cells';

  @override
  String get commandPortrait => 'Portrait';

  @override
  String get commandLandscape => 'Landscape';

  @override
  String get commandWrapOff => 'Top and bottom';

  @override
  String get commandWrapIdeal => 'Square';

  @override
  String get commandWrapThrough => 'Behind text';

  @override
  String get commandImageLeft => 'Picture left';

  @override
  String get commandImageCenter => 'Picture center';

  @override
  String get commandImageRight => 'Picture right';

  @override
  String get commandAbout => 'About Psito Quill';

  @override
  String get ribbonInsert => 'Insert';

  @override
  String get ribbonLayout => 'Layout';

  @override
  String get ribbonReview => 'Review';

  @override
  String get ribbonView => 'View';

  @override
  String get ribbonTable => 'Table';

  @override
  String get ribbonImage => 'Picture';

  @override
  String get groupPages => 'Pages';

  @override
  String get groupTables => 'Tables';

  @override
  String get groupIllustrations => 'Illustrations';

  @override
  String get groupPageSetup => 'Page setup';

  @override
  String get groupProofing => 'Proofing';

  @override
  String get groupShow => 'Show';

  @override
  String get groupZoom => 'Zoom';

  @override
  String get groupRowsColumns => 'Rows and columns';

  @override
  String get groupMerge => 'Merge';

  @override
  String get groupArrange => 'Arrange';

  @override
  String get groupEditing => 'Editing';

  @override
  String get groupSpacing => 'Spacing';

  @override
  String get fieldPageSize => 'Size';

  @override
  String get fieldMargins => 'Margins';

  @override
  String get pageSizeA4 => 'A4';

  @override
  String get pageSizeA5 => 'A5';

  @override
  String get pageSizeLetter => 'Letter';

  @override
  String get pageSizeBook6x9 => 'Book 6 × 9 in';

  @override
  String get pageSizeBook55x85 => 'Book 5.5 × 8.5 in';

  @override
  String get marginsNormal => 'Normal (2.5 cm)';

  @override
  String get marginsNarrow => 'Narrow (1.27 cm)';

  @override
  String get marginsAbnt => 'ABNT (3 and 2 cm)';

  @override
  String get marginsWide => 'Wide (5 cm sides)';

  @override
  String get findField => 'Find';

  @override
  String get replaceField => 'Replace with';

  @override
  String get findNext => 'Next';

  @override
  String get findPrevious => 'Previous';

  @override
  String get findAll => 'All';

  @override
  String get replaceOne => 'Replace';

  @override
  String get replaceAll => 'Replace all';

  @override
  String get findMatchCase => 'Match case';

  @override
  String get findWholeWord => 'Whole word';

  @override
  String get findRegex => 'Regular expression';

  @override
  String get findClose => 'Close search';

  @override
  String get findNotFound => 'No matches';

  @override
  String get paletteHint => 'A word from the text or a command';

  @override
  String get paletteEmpty => 'Nothing found';

  @override
  String get inspectorTitle => 'Format';

  @override
  String get sectionCharacter => 'Character';

  @override
  String get sectionParagraph => 'Paragraph';

  @override
  String get sectionPage => 'Page';

  @override
  String get sectionImage => 'Picture';

  @override
  String get sectionTable => 'Table';

  @override
  String get sectionReveal => 'Reveal formatting';

  @override
  String get sectionStyles => 'Styles';

  @override
  String get fieldFontColor => 'Font color';

  @override
  String get fieldHighlight => 'Highlight';

  @override
  String get colorAutomatic => 'Automatic';

  @override
  String get highlightNone => 'No highlight';

  @override
  String get fieldIndentLeft => 'Left indent';

  @override
  String get fieldIndentRight => 'Right indent';

  @override
  String get fieldIndentFirst => 'First line';

  @override
  String get fieldSpacing => 'Space before and after';

  @override
  String get fieldLineSpacing => 'Line spacing';

  @override
  String get fieldOrientation => 'Orientation';

  @override
  String get colorBlack => 'Black';

  @override
  String get colorGray => 'Gray';

  @override
  String get colorRed => 'Red';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorPurple => 'Purple';

  @override
  String get revealParagraphStyle => 'Paragraph style';

  @override
  String get revealFont => 'Font';

  @override
  String get revealEffects => 'Effects';

  @override
  String get revealAlignment => 'Alignment';

  @override
  String get revealIndents => 'Indents';

  @override
  String get revealSpacing => 'Space before and after';

  @override
  String get revealLineSpacing => 'Line spacing';

  @override
  String get revealLanguage => 'Language';

  @override
  String get revealPageStyle => 'Page style';

  @override
  String get revealColor => 'Color';

  @override
  String get revealNone => 'none';

  @override
  String get revealOther => 'other';

  @override
  String get stylesTitle => 'Styles';

  @override
  String get stylesParagraph => 'Paragraph';

  @override
  String get stylesCharacter => 'Character';

  @override
  String get stylesMine => 'My styles';

  @override
  String get stylesBuiltIn => 'Built-in styles';

  @override
  String get stylesApply => 'Apply';

  @override
  String get stylesNewTitle => 'New style from selection';

  @override
  String get stylesName => 'Style name';

  @override
  String get stylesCreate => 'Create';

  @override
  String get stylesNameTaken => 'A style with that name already exists';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogClose => 'Close';

  @override
  String get stylePreformatted => 'Preformatted text';

  @override
  String get styleFootnote => 'Footnote';

  @override
  String get styleEndnote => 'Endnote';

  @override
  String get styleCaption => 'Caption';

  @override
  String get styleSignature => 'Signature';

  @override
  String get styleFirstLineIndent => 'First line indent';

  @override
  String get styleHangingIndent => 'Hanging indent';

  @override
  String get styleBodyIndent => 'Body text indent';

  @override
  String get styleHeader => 'Header';

  @override
  String get styleFooter => 'Footer';

  @override
  String get styleTableContents => 'Table contents';

  @override
  String get styleTableHeading => 'Table heading';

  @override
  String get styleList => 'List';

  @override
  String get styleListContents => 'List contents';

  @override
  String get styleMarginalia => 'Marginalia';

  @override
  String get styleAppendix => 'Appendix';

  @override
  String get styleHeadingBase => 'Heading (base)';

  @override
  String get styleEmphasis => 'Emphasis';

  @override
  String get styleStrongEmphasis => 'Strong emphasis';

  @override
  String get styleCitation => 'Citation';

  @override
  String get contextIgnore => 'Ignore';

  @override
  String get contextIgnoreAll => 'Ignore all';

  @override
  String get contextNoSuggestions => 'No suggestions';

  @override
  String get themeClassico => 'Classic 97';

  @override
  String get menuFile => 'File';

  @override
  String get menuEdit => 'Edit';

  @override
  String get menuView => 'View';

  @override
  String get menuInsert => 'Insert';

  @override
  String get menuFormat => 'Format';

  @override
  String get menuStyles => 'Styles';

  @override
  String get menuTools => 'Tools';

  @override
  String get menuTable => 'Table';

  @override
  String get menuHelp => 'Help';

  @override
  String get menuRecent => 'Recent';

  @override
  String get menuTheme => 'Theme';

  @override
  String get toolbarStandard => 'Standard';

  @override
  String get toolbarFormatting => 'Formatting';

  @override
  String aboutText(String version) {
    return 'A text editor for long books, built on LibreOffice $version.';
  }

  @override
  String findCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
      zero: 'no matches',
    );
    return '$_temp0';
  }

  @override
  String findReplaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replaced',
      one: '1 replaced',
      zero: 'nothing replaced',
    );
    return '$_temp0';
  }

  @override
  String tableSize(int columns, int rows) {
    return '$columns × $rows table';
  }

  @override
  String measureCm(String value) {
    return '$value cm';
  }

  @override
  String imageSizeCm(String width, String height) {
    return '$width × $height cm';
  }

  @override
  String percentValue(int value) {
    return '$value%';
  }

  @override
  String get unitCm => 'cm';

  @override
  String get fileTypeImages => 'Pictures';

  @override
  String get commandFilePanel => 'Recent files and preferences…';

  @override
  String get outlineTitle => 'Outline';

  @override
  String get outlineClose => 'Close the outline';

  @override
  String get outlineEmpty =>
      'The document headings show up here (the Heading 1, 2 and 3 styles).';

  @override
  String get railLabel => 'Panels';

  @override
  String get stylesPanelClose => 'Close the styles';

  @override
  String get ribbonStyles => 'Styles';

  @override
  String get ribbonCollapse => 'Collapse';

  @override
  String get ribbonCollapseTip => 'Collapse the ribbon';

  @override
  String get ribbonExpandTip => 'Show the ribbon';

  @override
  String get ribbonTabs => 'Ribbon tabs';

  @override
  String get searchCommands => 'Search the text and commands';

  @override
  String get inspectorClose => 'Close the Format panel';

  @override
  String get inspectorSections => 'Panel section';

  @override
  String get sectionText => 'Text';

  @override
  String get fontGrow => 'Grow font';

  @override
  String get fontShrink => 'Shrink font';

  @override
  String get moreStyles => 'More styles';

  @override
  String get commandLineSpacingMenu => 'Line spacing';

  @override
  String get zoomSlider => 'Zoom';

  @override
  String zoomPercent(int percent) {
    return '$percent %';
  }

  @override
  String statusStyle(Object name) {
    return 'Style: $name';
  }

  @override
  String get commandCollapseRibbon => 'Collapse the ribbon';

  @override
  String get commandOutline => 'Outline panel';

  @override
  String get commandStylesPanel => 'Styles panel';

  @override
  String get styleSampleBody => 'Once upon a time';

  @override
  String get styleSampleHeading => 'Chapter';

  @override
  String get styleSampleQuote => 'she said';

  @override
  String get styleSampleOther => 'Aa';

  @override
  String styleCardApplied(Object name) {
    return 'Style $name, applied';
  }

  @override
  String styleCard(Object name) {
    return 'Style $name';
  }

  @override
  String colorMenuMore(Object name, Object value) {
    return '$name: $value';
  }

  @override
  String get fieldWidth => 'Width';

  @override
  String get fieldHeight => 'Height';

  @override
  String get keepRatio => 'Keep the proportion';

  @override
  String get groupSize => 'Size';

  @override
  String get fontSearch => 'Search for a font';

  @override
  String get fontInDocument => 'In this document';

  @override
  String get fontRecent => 'Recent';

  @override
  String get fontAll => 'All';

  @override
  String get fontSerif => 'Serif';

  @override
  String get fontSans => 'Sans serif';

  @override
  String get fontMono => 'Mono';

  @override
  String get fontNone => 'No font with that name';

  @override
  String get fontFilters => 'Filter the fonts';

  @override
  String get stylesSearch => 'Search for a style';

  @override
  String get stylesKind => 'Style kind';

  @override
  String get stylesFromBook => 'From the book';

  @override
  String get stylesFromLibreOffice => 'From LibreOffice';

  @override
  String get stylesNone => 'No style with that name';

  @override
  String get revealDirect => 'direct';

  @override
  String get revealFromStyle => 'style';

  @override
  String get revealClearDirect => 'Remove direct formatting';

  @override
  String get rulerFirstLine => 'First line indent';

  @override
  String get rulerLeftIndent => 'Left indent';

  @override
  String get rulerRightIndent => 'Right indent';

  @override
  String get rulerHorizontal => 'Ruler';

  @override
  String get rulerVertical => 'Vertical ruler';

  @override
  String get commandRuler => 'Ruler';

  @override
  String get prefRulerUnit => 'Ruler unit';

  @override
  String get unitMm => 'mm';

  @override
  String get unitInch => 'in';

  @override
  String get unitPt => 'pt';

  @override
  String get layoutLabel => 'Page layout';

  @override
  String get layoutSingle => 'One page';

  @override
  String get layoutMulti => 'Multiple pages';

  @override
  String get layoutBook => 'Book (spreads)';

  @override
  String get themeSepia => 'Sepia';

  @override
  String get commandZen => 'Zen mode';

  @override
  String get zenExitHint => 'Esc or F11 exits';

  @override
  String get zenFocus => 'Focus on the paragraph';

  @override
  String get zenTypewriter => 'Typewriter';

  @override
  String get zenPaper => 'Paper';

  @override
  String get zenOptions => 'Zen mode options';

  @override
  String zenSession(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min this session',
      one: '1 min this session',
      zero: 'just started',
    );
    return '$_temp0';
  }

  @override
  String get ribbonMoreFont => 'More font options';

  @override
  String get searchSectionDocument => 'In the document';

  @override
  String get searchSectionCommands => 'Commands';

  @override
  String get searchSearching => 'Searching the document…';

  @override
  String get searchNoHits => 'Nothing in the document';

  @override
  String searchPage(int page) {
    return 'p. $page';
  }

  @override
  String searchMoreHits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'and $count more matches',
      one: 'and 1 more match',
    );
    return '$_temp0';
  }

  @override
  String get searchFindOptions => 'Find and replace, with options…';

  @override
  String searchHitLabel(String text, int page) {
    return '$text, page $page';
  }

  @override
  String searchHitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String get railFindReplace => 'Find and replace';

  @override
  String get commandCloseTab => 'Close tab';

  @override
  String get commandNextTab => 'Next tab';

  @override
  String get commandPreviousTab => 'Previous tab';

  @override
  String get tabsLabel => 'Open documents';

  @override
  String tabCloseNamed(String name) {
    return 'Close $name';
  }

  @override
  String tabModifiedNamed(String name) {
    return '$name, with unsaved changes';
  }

  @override
  String get stylesMore => 'More styles';

  @override
  String get railFind => 'Find';

  @override
  String get commandKeepWithNext => 'Keep with next';

  @override
  String get commandSeparateFromNext => 'Allow separating from next';

  @override
  String get commandKeepLines => 'Keep lines together';

  @override
  String get commandSplitLines => 'Allow splitting lines';

  @override
  String get contextStyle => 'Style';

  @override
  String get contextParagraph => 'Paragraph';

  @override
  String get fieldIndents => 'Indents';

  @override
  String get fieldIndentLeftShort => 'Left';

  @override
  String get fieldIndentFirstShort => 'First line';

  @override
  String get fieldIndentRightShort => 'Right';

  @override
  String get findPanelTitle => 'Find and replace';

  @override
  String get findHitsList => 'Matches in the document';

  @override
  String get commandFitWidth => 'Fit width';

  @override
  String get commandFitPage => 'Fit page';

  @override
  String get statusZoomTip => 'Zoom';

  @override
  String get statusLanguageTip => 'Language and spelling';

  @override
  String get statusWordsTip => 'Document statistics';

  @override
  String get statusInfoPages => 'Pages';

  @override
  String get statusInfoWords => 'Words';

  @override
  String get statusInfoCharacters => 'Characters';

  @override
  String get statusInfoSelected => 'Selected words';

  @override
  String get languageForSelection => 'Language of the selection';

  @override
  String get languageForParagraph => 'Language of the paragraph';

  @override
  String get languageNone => 'No spell checking';

  @override
  String get languageReset => 'Back to the style\'s language';

  @override
  String get recentHeading => 'Recent files';

  @override
  String get recentName => 'Name';

  @override
  String get recentFolder => 'Folder';

  @override
  String get recentModified => 'Modified';

  @override
  String get recentMissing => 'Not found';

  @override
  String get fileInfo => 'Info';

  @override
  String get infoFolder => 'Folder';

  @override
  String get infoSize => 'Size';

  @override
  String get infoModified => 'Modified';

  @override
  String get infoNotSaved => 'Not saved yet';

  @override
  String get infoOpenFolder => 'Open the file\'s folder';

  @override
  String sizeBytes(int n) {
    return '$n bytes';
  }

  @override
  String sizeKb(int n) {
    return '$n KB';
  }

  @override
  String sizeMb(String n) {
    return '$n MB';
  }

  @override
  String get decimalSeparator => '.';

  @override
  String get prefStart => 'When Quill opens without a file';

  @override
  String get prefStartScreen => 'Start screen';

  @override
  String get prefStartBlank => 'Blank document';

  @override
  String get startTitle => 'Start';

  @override
  String get startBlank => 'Blank document';

  @override
  String get startOpen => 'Open a file…';

  @override
  String get statusMoreInfo => 'More info…';

  @override
  String get commandStatusBar => 'Status bar';

  @override
  String get groupPageLayout => 'Pages';

  @override
  String get groupWindow => 'Window';

  @override
  String get groupModes => 'Modes';

  @override
  String get busyOpening => 'Opening…';

  @override
  String get busySaving => 'Saving…';

  @override
  String get busyWorking => 'Working…';

  @override
  String get themeHighContrastDark => 'High contrast dark';

  @override
  String get themeHighContrastLight => 'High contrast light';

  @override
  String get prefGeneral => 'General';

  @override
  String get prefAppearance => 'Appearance';

  @override
  String get prefAccessibility => 'Accessibility';

  @override
  String get prefZoomOnOpen => 'Zoom when opening a document';

  @override
  String get prefUiScale => 'Interface size';

  @override
  String get prefUiScaleNote =>
      'Everything grows together: text, buttons, icons and the page. On top of the system text size.';

  @override
  String get prefComfortable => 'Larger buttons';

  @override
  String get prefCaretWidth => 'Text cursor thickness';

  @override
  String prefCaretPx(int n) {
    return '$n px';
  }

  @override
  String get prefCaretBlink => 'The text cursor blinks';

  @override
  String get prefReduceMotion => 'Reduce motion';

  @override
  String get prefReduceMotionNote =>
      'No animations in the interface. Quill also follows the system setting.';

  @override
  String get prefSpellColor => 'Spelling mark color';

  @override
  String get prefSpellColorNote => 'Takes effect the next time Quill opens.';

  @override
  String get prefScreenReaderDoc => 'Document text for the screen reader';

  @override
  String get prefScreenReaderDocNote =>
      'Turns on by itself when a screen reader is active. When on, the engine works a little more on each key.';

  @override
  String get menuBook => 'Book';

  @override
  String get railBinder => 'Binder';

  @override
  String get binderTitle => 'Binder';

  @override
  String get commandBinder => 'Binder';

  @override
  String get commandNewBook => 'New book…';

  @override
  String get commandOpenBook => 'Open book…';

  @override
  String get commandImportManuscript => 'Import a manuscript…';

  @override
  String get commandCloseBook => 'Close the book';

  @override
  String get commandNewChapter => 'New chapter';

  @override
  String get commandNewPart => 'New part';

  @override
  String get newChapterTitle => 'New chapter';

  @override
  String get newPartTitle => 'New part';

  @override
  String get firstChapterTitle => 'Chapter 1';

  @override
  String get importUntitled => 'Opening';

  @override
  String get chapterStatusDraft => 'Draft';

  @override
  String get chapterStatusRevision => 'Revision';

  @override
  String get chapterStatusDone => 'Done';

  @override
  String get binderRename => 'Rename';

  @override
  String get binderOpen => 'Open';

  @override
  String get binderDelete => 'Move to trash';

  @override
  String get binderDeleteTitle => 'Move to trash?';

  @override
  String binderDeleteChapter(String title) {
    return '“$title” leaves the book. The file goes to the trash folder inside the book and is not deleted.';
  }

  @override
  String binderDeletePart(String title) {
    return 'The part “$title” leaves the book. Its chapters stay, in its place.';
  }

  @override
  String get binderSynopsis => 'Synopsis';

  @override
  String get binderSynopsisHint => 'What this chapter is about';

  @override
  String get binderStatus => 'Status';

  @override
  String get binderLabel => 'Label';

  @override
  String get labelNone => 'No label';

  @override
  String get labelRed => 'Red';

  @override
  String get labelOrange => 'Orange';

  @override
  String get labelGreen => 'Green';

  @override
  String get labelBlue => 'Blue';

  @override
  String get labelPurple => 'Purple';

  @override
  String binderWords(int count) {
    return '$count words';
  }

  @override
  String get binderKeysHint =>
      'Alt+arrows move, F2 renames, Delete moves to trash, → and ← show the scenes';

  @override
  String get binderEmpty => 'The book has no chapters.';

  @override
  String statusBookWords(String count) {
    return 'book $count';
  }

  @override
  String get statusBookWordsTip => 'Words in the whole book';

  @override
  String bookChapterName(String book, String chapter) {
    return '$book — $chapter';
  }

  @override
  String get newBookTitle => 'New book';

  @override
  String get bookTitleLabel => 'Book title';

  @override
  String get bookLocationLabel => 'Where to keep it';

  @override
  String bookLocationNote(String folder) {
    return 'The book becomes the folder “$folder”, with one file per chapter.';
  }

  @override
  String get chooseFolder => 'Choose folder…';

  @override
  String get chooseFolderButton => 'Choose';

  @override
  String get createButton => 'Create';

  @override
  String get importTitle => 'Import a manuscript';

  @override
  String get importReading => 'Reading the manuscript…';

  @override
  String get importLevel => 'Chapters start at headings of';

  @override
  String importLevelN(int level) {
    return 'Level $level';
  }

  @override
  String importFound(int count) {
    return '$count chapters';
  }

  @override
  String get importPartsNote => 'Headings of a higher level become parts.';

  @override
  String get importButton => 'Import';

  @override
  String importProgress(int done, int total) {
    return 'Importing chapter $done of $total…';
  }

  @override
  String importChapterWords(String title, int count) {
    return '$title · $count words';
  }

  @override
  String get fileTypeManuscripts => 'Manuscripts';

  @override
  String get bookErrorMissing => 'The book was not found.';

  @override
  String get bookErrorInvalid => 'This folder has no Quill book.';

  @override
  String get bookErrorExists => 'There is already a book in this folder.';

  @override
  String get bookErrorWrite => 'The book could not be written.';

  @override
  String get importErrorUnreadable =>
      'LibreOffice could not read this manuscript.';

  @override
  String get importErrorEmpty => 'The manuscript has no text.';

  @override
  String get startNewBook => 'New book';

  @override
  String get startImport => 'Import a manuscript';

  @override
  String get recentBook => 'Book';

  @override
  String get binderClose => 'Close the binder';

  @override
  String get prefAutosave => 'Autosave';

  @override
  String get prefAutosaveNote =>
      'Every minute with changes, a recovery copy is kept on your computer, in Quill\'s folder. If Quill closes unexpectedly, it shows up on the start screen.';

  @override
  String get recoverHeading => 'Recover files';

  @override
  String get recoverNote =>
      'Quill closed without saving these documents. Recover opens the copy as a new document; save it to keep it.';

  @override
  String recoverRow(String name, String when) {
    return '$name, copy from $when';
  }

  @override
  String get recoverOpen => 'Recover';

  @override
  String get recoverDiscard => 'Discard';

  @override
  String get recoverDiscardTitle => 'Discard the copy?';

  @override
  String recoverDiscardBody(String name) {
    return 'The recovery copy of “$name” will be deleted. The saved file, if any, does not change.';
  }

  @override
  String recoveredName(String name) {
    return '$name (recovered)';
  }

  @override
  String get commandHeader => 'Header';

  @override
  String get commandFooter => 'Footer';

  @override
  String get commandRemoveHeader => 'Remove header';

  @override
  String get commandRemoveFooter => 'Remove footer';

  @override
  String get commandFirstPageDifferent => 'Different first page';

  @override
  String get commandLeftRightDifferent => 'Different even pages';

  @override
  String get commandPageNumber => 'Page number';

  @override
  String get commandPageCount => 'Page count';

  @override
  String get commandDateField => 'Date';

  @override
  String get commandTimeField => 'Time';

  @override
  String get commandHyphenation => 'Automatic hyphenation';

  @override
  String get commandHyphenateParagraph => 'Hyphenate this paragraph';

  @override
  String get commandNoHyphenateParagraph => 'Don\'t hyphenate this paragraph';

  @override
  String commandDropCap(int n) {
    return 'Drop cap ($n lines)';
  }

  @override
  String get commandRemoveDropCap => 'Remove drop cap';

  @override
  String get commandColumnBreak => 'Column break';

  @override
  String get commandBlankPage => 'Blank page';

  @override
  String get commandExportPdf => 'Export as PDF…';

  @override
  String get commandPrint => 'Print…';

  @override
  String get commandFootnote => 'Footnote';

  @override
  String get commandEndnote => 'Endnote';

  @override
  String get commandJumpFootnote => 'Go to note and back';

  @override
  String get commandLink => 'Link…';

  @override
  String get commandOpenLink => 'Open link';

  @override
  String get commandRemoveLink => 'Remove link';

  @override
  String get commandSpecialCharacter => 'Special character…';

  @override
  String get groupHeaderFooter => 'Header & footer';

  @override
  String get groupNotes => 'Notes';

  @override
  String get groupLinks => 'Links';

  @override
  String get groupSymbols => 'Symbols';

  @override
  String get groupBreaks => 'Breaks';

  @override
  String get groupHyphenation => 'Hyphenation';

  @override
  String get groupFields => 'Fields';

  @override
  String get groupTypography => 'Typography';

  @override
  String get exportPdfFilter => 'PDF document';

  @override
  String noticeExported(String path) {
    return 'Exported: $path';
  }

  @override
  String get noticeExportFailed => 'Couldn\'t export the PDF.';

  @override
  String get noticePrinted => 'Sent to the printer.';

  @override
  String noticePrintFailed(String detail) {
    return 'Couldn\'t print: $detail';
  }

  @override
  String get noticePrintNoPdf => 'The chosen printer doesn\'t accept PDF.';

  @override
  String get noticeStyleFailed => 'The engine didn\'t apply the page change.';

  @override
  String get linkDialogTitle => 'Link';

  @override
  String get linkText => 'Text';

  @override
  String get linkUrl => 'Address';

  @override
  String get linkApply => 'Apply';

  @override
  String get openLinkTitle => 'Open the link?';

  @override
  String openLinkBody(String url) {
    return 'Quill will ask the system to open this address. If it is a website, that goes to the internet:\n$url';
  }

  @override
  String get noticeLinkScheme =>
      'Quill only opens web (http, https) and e-mail (mailto) addresses.';

  @override
  String get openLinkButton => 'Open';

  @override
  String get specialCharsTitle => 'Special characters';

  @override
  String get specialCharsSearch => 'Search by name';

  @override
  String get specialCharsEmpty => 'No character with that name.';

  @override
  String specialCharInsert(String name, String char) {
    return '$name ($char)';
  }

  @override
  String get pageSectionHeaderFooter => 'Header and footer';

  @override
  String get charEmDash => 'em dash';

  @override
  String get charEnDash => 'en dash';

  @override
  String get charEllipsis => 'ellipsis';

  @override
  String get charLeftDoubleQuote => 'left double quote';

  @override
  String get charRightDoubleQuote => 'right double quote';

  @override
  String get charLeftSingleQuote => 'left single quote';

  @override
  String get charRightSingleQuote => 'right single quote, apostrophe';

  @override
  String get charLeftGuillemet => 'left guillemet';

  @override
  String get charRightGuillemet => 'right guillemet';

  @override
  String get charNoBreakSpace => 'no-break space';

  @override
  String get charNarrowNoBreakSpace => 'narrow no-break space';

  @override
  String get charSoftHyphen => 'soft hyphen';

  @override
  String get charNoBreakHyphen => 'non-breaking hyphen';

  @override
  String get charAsterism => 'asterism (scene break)';

  @override
  String get charFleuron => 'fleuron';

  @override
  String get charSection => 'section sign';

  @override
  String get charPilcrow => 'pilcrow';

  @override
  String get charDagger => 'dagger';

  @override
  String get charDoubleDagger => 'double dagger';

  @override
  String get charBullet => 'bullet';

  @override
  String get charMiddleDot => 'middle dot';

  @override
  String get charDegree => 'degree';

  @override
  String get charOrdinalA => 'feminine ordinal';

  @override
  String get charOrdinalO => 'masculine ordinal';

  @override
  String get charCopyright => 'copyright';

  @override
  String get charRegistered => 'registered';

  @override
  String get charTrademark => 'trademark';

  @override
  String get charTimes => 'multiplication';

  @override
  String get charDivide => 'division';

  @override
  String get charPlusMinus => 'plus-minus';

  @override
  String get charApprox => 'approximately';

  @override
  String get charNotEqual => 'not equal';

  @override
  String get charLessEqual => 'less or equal';

  @override
  String get charGreaterEqual => 'greater or equal';

  @override
  String get charHalf => 'one half';

  @override
  String get charQuarter => 'one quarter';

  @override
  String get charThreeQuarters => 'three quarters';

  @override
  String get charEuro => 'euro';

  @override
  String get charPound => 'pound';

  @override
  String get charYen => 'yen';

  @override
  String get charArrowRight => 'right arrow';

  @override
  String get charArrowLeft => 'left arrow';

  @override
  String get charStar => 'star';

  @override
  String get charPrime => 'prime';

  @override
  String get charDoublePrime => 'double prime';

  @override
  String binderScenes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scenes',
      one: '1 scene',
    );
    return '$_temp0';
  }

  @override
  String binderScene(int number) {
    return 'Scene $number';
  }

  @override
  String get binderSceneHint =>
      'Enter goes to the scene; left arrow returns to the chapter';

  @override
  String get commandNewScene => 'New scene';

  @override
  String get commandSplitChapter => 'Split chapter here';

  @override
  String get commandJoinChapter => 'Join with next chapter';

  @override
  String get commandConvertScenes => 'Convert separators into scenes';

  @override
  String splitContinuationTitle(String title) {
    return '$title (continued)';
  }

  @override
  String splitDone(String title) {
    return 'The rest of the chapter became “$title”, right after it';
  }

  @override
  String get splitNothing =>
      'Nothing to split: the cursor is at the start or end of the chapter';

  @override
  String get splitFailed =>
      'Couldn\'t split the chapter. The text is unchanged.';

  @override
  String get joinConfirmTitle => 'Join the chapters?';

  @override
  String joinConfirmBody(String next, String current) {
    return 'The text of “$next” goes to the end of “$current”, which is saved. The file of “$next” goes to the book\'s trash.';
  }

  @override
  String get joinConfirm => 'Join';

  @override
  String joinDone(String title) {
    return '“$title” was joined to this chapter';
  }

  @override
  String get joinNoNext => 'This is the last chapter of the book';

  @override
  String joinNextModified(String title) {
    return 'Save or close “$title” before joining';
  }

  @override
  String get joinFailed => 'Couldn\'t join the chapters';

  @override
  String scenesConverted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count separators became scenes',
      one: '1 separator became a scene',
    );
    return '$_temp0';
  }

  @override
  String get scenesNone => 'No loose separators (* * *, #) in this document';

  @override
  String get scenesFailed => 'Couldn\'t create the Scene style';

  @override
  String importScenes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scene separators (* * *) go to the Scene style',
      one: '1 scene separator (* * *) goes to the Scene style',
    );
    return '$_temp0';
  }

  @override
  String get busyWorkingChapters => 'Reorganizing chapters';

  @override
  String get findScope => 'Search in';

  @override
  String get findScopeChapter => 'This chapter';

  @override
  String get findScopeBook => 'Whole book';

  @override
  String get findBadRegex => 'Invalid regular expression';

  @override
  String get bookHitsList => 'Matches in the book';

  @override
  String bookHitsCount(int count, int chapters) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    String _temp1 = intl.Intl.pluralLogic(
      chapters,
      locale: localeName,
      other: '$chapters chapters',
      one: '1 chapter',
    );
    return '$_temp0 in $_temp1';
  }

  @override
  String bookChapterHits(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    return '$title, $_temp0';
  }

  @override
  String bookMoreHits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more in this chapter: open it and search there',
      one: '1 more in this chapter: open it and search there',
    );
    return '$_temp0';
  }

  @override
  String bookHitLabel(String text, String chapter, int page) {
    return '$text, $chapter, page $page';
  }

  @override
  String bookUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters could not be read',
      one: '1 chapter could not be read',
    );
    return '$_temp0';
  }

  @override
  String get commandTakeSnapshot => 'Take a chapter snapshot';

  @override
  String get commandSnapshots => 'Chapter snapshots…';

  @override
  String get binderSnapshots => 'Snapshots…';

  @override
  String snapshotsTitle(String chapter) {
    return 'Snapshots of $chapter';
  }

  @override
  String get snapshotName => 'Snapshot name (optional)';

  @override
  String get snapshotTake => 'Take now';

  @override
  String get snapshotsEmpty =>
      'No snapshots yet. A snapshot keeps the chapter as it is now, so you can compare with it or go back to it later.';

  @override
  String get snapshotAuto => 'Automatic';

  @override
  String get snapshotUnnamed => 'Unnamed';

  @override
  String snapshotWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get snapshotCompare => 'Open alongside, read-only';

  @override
  String get snapshotRestore => 'Restore';

  @override
  String get snapshotDelete => 'Delete';

  @override
  String get snapshotRestoreTitle => 'Restore the snapshot?';

  @override
  String snapshotRestoreBody(String when) {
    return 'The chapter goes back to how it was on $when. The current text, including unsaved changes, is kept in a \"Before restoring\" snapshot.';
  }

  @override
  String get snapshotBeforeRestore => 'Before restoring';

  @override
  String get snapshotDeleteTitle => 'Delete the snapshot?';

  @override
  String snapshotDeleteBody(String when) {
    return 'The snapshot from $when goes to the book\'s trash.';
  }

  @override
  String snapshotTaken(String chapter) {
    return 'Snapshot of $chapter taken';
  }

  @override
  String get snapshotFailed => 'Couldn\'t take the snapshot';

  @override
  String snapshotRestored(String when) {
    return 'The chapter is back to $when';
  }

  @override
  String get snapshotRestoreFailed => 'Couldn\'t restore the snapshot';

  @override
  String get snapshotCompareFailed => 'Couldn\'t open the snapshot';

  @override
  String get prefAutoSnapshots => 'Automatic chapter snapshots';

  @override
  String get prefAutoSnapshotsNote =>
      'On the first save of each day, Quill keeps how the chapter was before, in the book\'s \"versoes\" folder. The last 30 of each chapter are kept.';

  @override
  String snapshotLabel(String chapter, String when) {
    return '$chapter, $when';
  }

  @override
  String snapshotTab(String label) {
    return 'Snapshot: $label';
  }

  @override
  String snapshotViewingBanner(String label) {
    return 'Snapshot of $label, read-only. To compare, switch to the chapter tab and back.';
  }

  @override
  String get snapshotCloseView => 'Close the snapshot';

  @override
  String get railNotes => 'Notes';

  @override
  String get commandNotes => 'Book notes';

  @override
  String get commandNewNote => 'New note';

  @override
  String get notesTitle => 'Notes';

  @override
  String get notesClose => 'Close the notes';

  @override
  String get notesSearch => 'Search the notes';

  @override
  String get notesAll => 'All';

  @override
  String get notesEmpty =>
      'No notes yet. Characters, places, factions, terms and the timeline live here, in the book\'s \"notas\" folder.';

  @override
  String get notesNoMatch => 'No note matches.';

  @override
  String get notesBack => 'Back to the notes';

  @override
  String get noteNewName => 'New note';

  @override
  String get noteDelete => 'Move the note to the trash';

  @override
  String get noteDeleteTitle => 'Move the note to the trash?';

  @override
  String noteDeleteBody(String name) {
    return 'The note \"$name\" goes to the book\'s trash.';
  }

  @override
  String get noteName => 'Name';

  @override
  String get noteKind => 'Type';

  @override
  String get noteAliases => 'Aliases';

  @override
  String get noteAliasesHint => 'Aliases, separated by commas';

  @override
  String get noteText => 'Text';

  @override
  String get noteTextHint =>
      'Write here. [[Name]] links to another note or to a chapter.';

  @override
  String get noteLinks => 'Links';

  @override
  String get noteMentions => 'Mentioned in';

  @override
  String noteCreateLink(String name) {
    return 'Create $name';
  }

  @override
  String get noteTimelineEmpty =>
      'No events yet. Write one per line, in the Text: \"- Year 3: the Dust arrives\".';

  @override
  String get noteKindCharacter => 'Character';

  @override
  String get noteKindPlace => 'Place';

  @override
  String get noteKindFaction => 'Faction';

  @override
  String get noteKindTerm => 'Term';

  @override
  String get noteKindTimeline => 'Timeline';

  @override
  String get noteKindCharacters => 'Characters';

  @override
  String get noteKindPlaces => 'Places';

  @override
  String get noteKindFactions => 'Factions';

  @override
  String get noteKindTerms => 'Terms';

  @override
  String get commandGoals => 'Goals…';

  @override
  String statusGoalToday(String done, String goal) {
    return 'today $done/$goal';
  }

  @override
  String get statusGoalTodayTip => 'Today\'s word goal';

  @override
  String statusGoalSession(String done, String goal) {
    return 'session $done/$goal';
  }

  @override
  String zenGoal(String done, String goal) {
    return 'goal $done/$goal';
  }

  @override
  String goalsTitle(String book) {
    return 'Goals for $book';
  }

  @override
  String get goalsBook => 'Book words';

  @override
  String get goalsDaily => 'Words per day';

  @override
  String get goalsSession => 'Words this session';

  @override
  String get goalsEmptyHint => 'Empty: no goal';

  @override
  String get goalsSessionHint =>
      'The session goal lasts until the book is closed.';

  @override
  String get goalsDeadline => 'Deadline';

  @override
  String get goalsNoDeadline => 'No deadline';

  @override
  String get goalsPickDeadline => 'Pick the deadline';

  @override
  String get goalsClearDeadline => 'Remove the deadline';

  @override
  String goalsBookProgress(String words, String goal, int percent) {
    return 'Book: $words of $goal words ($percent%)';
  }

  @override
  String goalsBookWords(String words) {
    return 'Book: $words words';
  }

  @override
  String goalsPace(String words, String perDay) {
    return '$words words to go: $perDay a day';
  }

  @override
  String goalsDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
      zero: 'the deadline has passed',
    );
    return '$_temp0';
  }

  @override
  String get goalsReached => 'The book goal has been reached.';

  @override
  String goalsToday(String words, String goal) {
    return 'Today: $words of $goal';
  }

  @override
  String goalsTodayWords(String words) {
    return 'Today: $words words';
  }

  @override
  String goalsSessionProgress(String words, String goal) {
    return 'Session: $words of $goal';
  }

  @override
  String get goalsChartTitle => 'The last 30 days';

  @override
  String goalsChartLabel(String total, String best) {
    return 'The last 30 days: $total words, $best on the best day';
  }

  @override
  String get goalsSave => 'Save';

  @override
  String get commandCorkboard => 'Corkboard';

  @override
  String corkTitle(String book) {
    return '$book corkboard';
  }

  @override
  String get corkScope => 'Cards from';

  @override
  String get corkAll => 'All chapters';

  @override
  String get corkBack => 'Back to the page';

  @override
  String get corkEmpty => 'No chapters here.';

  @override
  String corkWords(String count) {
    return '$count words';
  }

  @override
  String get corkSynopsis => 'Synopsis';

  @override
  String get corkNoSynopsis => 'No synopsis';

  @override
  String get corkEditSynopsis => 'Edit the synopsis';

  @override
  String get corkKeysHint =>
      'Arrows move the focus, Alt+arrows move the card, Enter opens, F2 edits the synopsis, Esc goes back to the page';

  @override
  String get commandCompile => 'Compile book…';

  @override
  String compileTitle(String book) {
    return 'Compile $book';
  }

  @override
  String get compileChapters => 'Chapters';

  @override
  String compileChapterCount(int count, int total, String words) {
    return '$count of $total chapters · $words words';
  }

  @override
  String get compileSelectAll => 'All';

  @override
  String get compileSelectDone => 'Only done';

  @override
  String get compileSelectNone => 'None';

  @override
  String get compileTitlePage => 'Title page';

  @override
  String get compileBookTitle => 'Title';

  @override
  String get compileSubtitle => 'Subtitle';

  @override
  String get compileAuthor => 'Author';

  @override
  String get compileToc => 'Table of contents';

  @override
  String get compileTocTitle => 'Contents title';

  @override
  String get compileTocDefault => 'Contents';

  @override
  String get compilePageBreaks => 'Each chapter starts on a new page';

  @override
  String get compilePartTitles => 'Each part title on its own page';

  @override
  String get compileChapterTitles =>
      'Add the chapter title when it does not start with a heading';

  @override
  String get compileScenes => 'Scene separator';

  @override
  String get compileScenesKeep => 'As is (Scene style)';

  @override
  String get compileScenesStars => '* * *';

  @override
  String get compileScenesHash => '#';

  @override
  String get compileFormat => 'Format';

  @override
  String get compileFormatPdf => 'PDF, with bookmarks';

  @override
  String get compileFormatEpub => 'EPUB, e-book';

  @override
  String get compileFormatDocx => 'DOCX, Word';

  @override
  String get compileFormatOdt => 'ODT, LibreOffice';

  @override
  String compileFileFilter(String format) {
    return 'Book in $format';
  }

  @override
  String get compileRun => 'Compile…';

  @override
  String compileProgressChapters(int done, int total) {
    return 'Reading chapter $done of $total';
  }

  @override
  String get compileProgressJoining => 'Joining the chapters';

  @override
  String get compileProgressWriting =>
      'Writing the book (the engine lays out every page)';

  @override
  String compileDone(String path) {
    return 'Book compiled to $path';
  }

  @override
  String compileFailedChapter(String chapter) {
    return 'Could not read the chapter \"$chapter\".';
  }

  @override
  String get compileFailed => 'Could not write the compiled book.';

  @override
  String get compileNoChapters => 'No chapter chosen.';

  @override
  String get compileCancelled => 'Compile cancelled.';

  @override
  String get compileModel => 'Template';

  @override
  String get compileModelNone => 'No template';

  @override
  String get compileModelManuscript => 'Manuscript';

  @override
  String get compileModelSixByNine => '6×9 book';

  @override
  String get compileModelEbook => 'E-book';

  @override
  String compileModelChanged(String name) {
    return '$name (changed)';
  }

  @override
  String get compileModelSave => 'Save as template…';

  @override
  String get compileModelRename => 'Rename…';

  @override
  String get compileModelDelete => 'Delete template';

  @override
  String get compileModelName => 'Template name';

  @override
  String get compileModelSaveTitle => 'Save as template';

  @override
  String get compileModelRenameTitle => 'Rename template';

  @override
  String get compileModelOk => 'Save';

  @override
  String compileModelSaved(String name) {
    return 'Template \"$name\" saved in the book.';
  }

  @override
  String compileModelDeleted(String name) {
    return 'Template \"$name\" deleted.';
  }

  @override
  String get compileModelWriteFailed =>
      'Could not write the book\'s compilar.json.';

  @override
  String get compileLook => 'Look';

  @override
  String get compileKeep => 'The chapter\'s';

  @override
  String get compilePage => 'Page';

  @override
  String get compilePageA4 => 'A4';

  @override
  String get compilePageLetter => 'Letter';

  @override
  String get compilePageA5 => 'A5';

  @override
  String get compilePageSixByNine => '6 × 9 in (mirrored)';

  @override
  String get compileFont => 'Body font';

  @override
  String get compileFontSize => 'Body size';

  @override
  String compileFontSizePt(int size) {
    return '$size pt';
  }

  @override
  String get compileSpacing => 'Line spacing';

  @override
  String get compileSpacingSingle => 'Single';

  @override
  String get compileSpacingOneHalf => '1.5 lines';

  @override
  String get compileSpacingDouble => 'Double';

  @override
  String get compileIndent => 'First-line indent';

  @override
  String get compileIndentOn => 'Indented';

  @override
  String get compileIndentOff => 'Not indented';

  @override
  String get compileHeaders => 'Headers';

  @override
  String get compileHeadersNone => 'None';

  @override
  String get compileHeadersManuscript => 'Surname / title / page';

  @override
  String get compileHeadersBook => 'Alternating: book and chapter';

  @override
  String get compileRightPage => 'Each chapter starts on a right-hand page';

  @override
  String get compileCover => 'Cover';

  @override
  String get compileCoverNone => 'No cover';

  @override
  String get compileCoverPick => 'Choose image…';

  @override
  String get compileCoverRemove => 'Remove cover';

  @override
  String get menuReview => 'Review';

  @override
  String get groupComments => 'Comments';

  @override
  String get commandNewComment => 'New comment';

  @override
  String get commandComments => 'Comments panel';

  @override
  String get railComments => 'Comments';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get commentsClose => 'Close comments';

  @override
  String get commentsNew => 'New comment';

  @override
  String get commentsNewHint => 'Select some text and write here';

  @override
  String get commentsAdd => 'Comment';

  @override
  String commentsShowResolved(int count) {
    return 'Show resolved ($count)';
  }

  @override
  String get commentsEmpty =>
      'No comments in this chapter. Select some text, write above and click Comment (Ctrl+Alt+C).';

  @override
  String get commentsAllResolved => 'All comments are resolved.';

  @override
  String get commentsReply => 'Reply';

  @override
  String get commentsReplyField => 'Reply';

  @override
  String get commentsSend => 'Reply';

  @override
  String get commentsCancel => 'Cancel';

  @override
  String get commentsResolve => 'Resolve';

  @override
  String get commentsReopen => 'Reopen';

  @override
  String get commentsDelete => 'Delete thread';

  @override
  String get commentsResolved => 'Resolved';

  @override
  String get commentsNoAuthor => 'No author';

  @override
  String commentsOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open comments',
      one: '1 open comment',
    );
    return '$_temp0';
  }

  @override
  String get prefAuthorName => 'Your name in comments';

  @override
  String prefAuthorNameNote(String name) {
    return 'Empty: your account name ($name). Applies to chapters opened afterwards.';
  }

  @override
  String get modeEditing => 'Editing';

  @override
  String get modeReview => 'Review';

  @override
  String get modeReading => 'Reading';

  @override
  String get modeLabel => 'Mode';

  @override
  String get modeReadingExit => 'Leave reading (Esc)';

  @override
  String get modeReadingHint => 'Arrows and Page Down turn the pages.';

  @override
  String get groupTracking => 'Tracking';

  @override
  String get groupChanges => 'Changes';

  @override
  String get groupReading => 'Reading';

  @override
  String get commandChanges => 'Changes panel';

  @override
  String get commandShowChanges => 'Show changes';

  @override
  String get commandPreviousChange => 'Previous change';

  @override
  String get commandNextChange => 'Next change';

  @override
  String get commandAcceptChange => 'Accept change';

  @override
  String get commandRejectChange => 'Reject change';

  @override
  String get commandAcceptAll => 'Accept all';

  @override
  String get commandRejectAll => 'Reject all';

  @override
  String get railChanges => 'Changes';

  @override
  String get changesTitle => 'Changes';

  @override
  String get changesClose => 'Close changes';

  @override
  String get changesTracking => 'Review: track what I change';

  @override
  String get changesShow => 'Show on the page';

  @override
  String get changesEmpty =>
      'No changes in this chapter. Turn on Review (Ctrl+Shift+E) to track what you change.';

  @override
  String changesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes',
      one: '1 change',
    );
    return '$_temp0';
  }

  @override
  String get changesAccept => 'Accept';

  @override
  String get changesReject => 'Reject';

  @override
  String get changeInsert => 'Insertion';

  @override
  String get changeDelete => 'Deletion';

  @override
  String get changeFormat => 'Formatting';

  @override
  String get changeOther => 'Change';

  @override
  String get ribbonReferences => 'References';

  @override
  String get menuReferences => 'References';

  @override
  String get groupToc => 'Contents';

  @override
  String get groupCaptions => 'Captions';

  @override
  String get groupBookmarks => 'Bookmarks';

  @override
  String get groupIndex => 'Index';

  @override
  String get commandTocHere => 'Insert table of contents';

  @override
  String get tocTitleDefault => 'Contents';

  @override
  String get commandUpdateIndexes => 'Update contents and indexes';

  @override
  String get commandCaption => 'Insert caption';

  @override
  String get captionFigure => 'Figure';

  @override
  String get captionTable => 'Table';

  @override
  String get commandFigureTable => 'Table of figures';

  @override
  String get figureTableTitle => 'Table of figures';

  @override
  String get commandTableTable => 'List of tables';

  @override
  String get tableTableTitle => 'List of tables';

  @override
  String get commandBookmark => 'Bookmark';

  @override
  String get commandCrossReference => 'Cross-reference';

  @override
  String get commandMarkEntry => 'Mark index entry';

  @override
  String get commandMarkAll => 'Mark all occurrences';

  @override
  String get commandIndex => 'Insert index';

  @override
  String get indexTitle => 'Index';

  @override
  String get bookmarkDialogTitle => 'Bookmarks';

  @override
  String get bookmarkName => 'New bookmark name';

  @override
  String get bookmarkBadName =>
      'The name can\'t start with _ or contain / \\ @ : * ? \" ; , . # |';

  @override
  String get bookmarkExists => 'There\'s already a bookmark with this name.';

  @override
  String get bookmarkListTitle => 'In this chapter';

  @override
  String get bookmarkNone => 'No bookmarks yet.';

  @override
  String bookmarkGo(String name) {
    return 'Go to $name';
  }

  @override
  String bookmarkDelete(String name) {
    return 'Delete $name';
  }

  @override
  String get bookmarkInsert => 'Insert';

  @override
  String get crossRefTitle => 'Cross-reference';

  @override
  String get crossRefKind => 'Refer to';

  @override
  String get crossRefHeadings => 'Headings';

  @override
  String get crossRefBookmarks => 'Bookmarks';

  @override
  String get crossRefCaptions => 'Captions';

  @override
  String get crossRefNoHeadings => 'No headings in this chapter.';

  @override
  String get crossRefNoCaptions =>
      'No captions in this chapter. Select an image or go into a table and use Insert caption.';

  @override
  String get crossRefInsertAs => 'Insert as';

  @override
  String get crossRefFormatText => 'The text';

  @override
  String get crossRefFormatCaption => 'Figure and number';

  @override
  String get crossRefFormatPage => 'The page';

  @override
  String get crossRefFormatAboveBelow => 'Above or below';

  @override
  String get crossRefInsert => 'Insert';

  @override
  String crossRefOtherChapter(String bookmark, String chapter) {
    return '$bookmark (in $chapter)';
  }

  @override
  String get compileIndex => 'Index at the end';

  @override
  String get compileFigures => 'Table of figures after the contents';

  @override
  String get compileReferencesNote =>
      'The entries marked in the chapters and the image captions go here.';

  @override
  String get commandParagraph => 'Paragraph…';

  @override
  String get paragraphDialogTitle => 'Paragraph';

  @override
  String get paragraphDialogParts => 'Paragraph sections';

  @override
  String get paragraphPartBackground => 'Background';

  @override
  String get paragraphPartSpacing => 'Spacing';

  @override
  String get paragraphPartBorders => 'Borders';

  @override
  String get paragraphPartTabs => 'Tabs';

  @override
  String get paragraphBackground => 'Paragraph background';

  @override
  String get paragraphBackgroundNone => 'No background';

  @override
  String get paragraphBackgroundNote =>
      'The color applies to the selected paragraphs, from margin to margin.';

  @override
  String get paragraphNoSpaceSameStyle =>
      'Don\'t add space between paragraphs of the same style';

  @override
  String get paragraphNoSpaceNote =>
      'The box starts as the paragraph style has it: the engine doesn\'t tell what was changed in this paragraph alone.';

  @override
  String get paragraphApply => 'Apply';

  @override
  String get borderSides => 'Where';

  @override
  String get borderNone => 'None';

  @override
  String get borderBox => 'Box';

  @override
  String get borderTop => 'Top';

  @override
  String get borderBottom => 'Bottom';

  @override
  String get borderTopBottom => 'Top and bottom';

  @override
  String get borderLeft => 'Left';

  @override
  String get borderWeight => 'Width';

  @override
  String get borderThin => 'Thin';

  @override
  String get borderMedium => 'Medium';

  @override
  String get borderThick => 'Thick';

  @override
  String get borderColor => 'Border color';

  @override
  String get tabsCurrent => 'The paragraph\'s tabs';

  @override
  String get tabsNone => 'No tabs, only the default ones.';

  @override
  String tabsItem(String position, String align, String leader) {
    return '$position, $align, $leader';
  }

  @override
  String tabsRemove(String position) {
    return 'Remove the tab at $position';
  }

  @override
  String get tabsNew => 'New tab';

  @override
  String get tabsPosition => 'Position in cm';

  @override
  String get tabsAlign => 'Alignment';

  @override
  String get tabsLeader => 'Leader';

  @override
  String get tabAlignLeft => 'Left';

  @override
  String get tabAlignCenter => 'Center';

  @override
  String get tabAlignRight => 'Right';

  @override
  String get tabAlignDecimal => 'Decimal';

  @override
  String get tabLeaderNone => 'No leader';

  @override
  String get tabLeaderDots => 'Dots';

  @override
  String get tabLeaderDashes => 'Dashes';

  @override
  String get tabLeaderLine => 'Line';

  @override
  String get tabsAdd => 'Add';

  @override
  String get tabsClear => 'Remove all';

  @override
  String get outlineStart => 'Beginning of document';

  @override
  String get outlineLevels => 'Show up to level';

  @override
  String get outlineAllLevels => 'All levels';

  @override
  String outlineLevelN(int n) {
    return 'Up to level $n';
  }

  @override
  String get outlineExpandAll => 'Expand all';

  @override
  String get outlineCollapseAll => 'Collapse all';

  @override
  String outlineExpand(String title) {
    return 'Expand $title';
  }

  @override
  String outlineCollapse(String title) {
    return 'Collapse $title';
  }

  @override
  String get infoCharactersWithSpaces => 'Characters (with spaces)';

  @override
  String get infoCharactersNoSpaces => 'Characters (no spaces)';

  @override
  String get infoParagraphs => 'Paragraphs';

  @override
  String get infoProperties => 'Properties';

  @override
  String get infoTitle => 'Title';

  @override
  String get infoSubject => 'Subject';

  @override
  String get infoAuthor => 'Author';

  @override
  String get infoKeywords => 'Tags, separated by commas';

  @override
  String get infoComment => 'Comment';

  @override
  String get infoApplyProperties => 'Apply the properties';

  @override
  String get infoUndoProperties => 'Discard the changes';

  @override
  String get commandPaintbrush => 'Copy formatting';

  @override
  String get commandChangeCase => 'Change case';

  @override
  String get commandCaseSentence => 'Sentence case';

  @override
  String get commandCaseLower => 'lowercase';

  @override
  String get commandCaseUpper => 'UPPERCASE';

  @override
  String get commandCaseTitle => 'Capitalize Each Word';

  @override
  String get commandCaseToggle => 'tOGGLE cASE';

  @override
  String get commandMultilevelList => 'Multilevel list';

  @override
  String get commandListDecimal => 'List 1 · 1.1 · 1.1.1';

  @override
  String get commandListRoman => 'List I. · A. · 1.';

  @override
  String get commandListLetters => 'List A. · 1. · a.';

  @override
  String get commandListParenthesis => 'List 1) · a) · 1)';

  @override
  String get commandListBullets => 'Multilevel bullets';

  @override
  String get commandListLevelDown => 'Demote list item';

  @override
  String get commandListLevelUp => 'Promote list item';

  @override
  String commandColumns(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n columns',
      one: 'One column',
    );
    return '$_temp0';
  }

  @override
  String get commandLineNumbers => 'Line numbers';

  @override
  String get commandWatermark => 'Watermark…';

  @override
  String get commandRemoveWatermark => 'Remove the watermark';

  @override
  String get commandArrangeFront => 'Bring to front';

  @override
  String get commandArrangeForward => 'Bring forward';

  @override
  String get commandArrangeBackward => 'Send backward';

  @override
  String get commandArrangeBack => 'Send to back';

  @override
  String get commandTextBox => 'Text box';

  @override
  String get commandDateTime => 'Date and time';

  @override
  String get groupColumns => 'Columns';

  @override
  String get groupPageBackground => 'Page background';

  @override
  String get groupOrder => 'Order';

  @override
  String get groupText => 'Text';

  @override
  String get pageColor => 'Page color';

  @override
  String get pageColorNone => 'No color';

  @override
  String get pageColorCream => 'Cream';

  @override
  String get pageColorGray => 'Light gray';

  @override
  String get pageColorBlue => 'Light blue';

  @override
  String get pageColorGreen => 'Light green';

  @override
  String get pageColorYellow => 'Light yellow';

  @override
  String get watermarkTitle => 'Watermark';

  @override
  String get watermarkText => 'The text';

  @override
  String get watermarkHint => 'DRAFT';

  @override
  String get watermarkColor => 'The color';

  @override
  String watermarkColorN(int n) {
    return 'Color $n';
  }

  @override
  String get watermarkLayout => 'The direction';

  @override
  String get watermarkDiagonal => 'Diagonal';

  @override
  String get watermarkHorizontal => 'Horizontal';

  @override
  String get watermarkNote =>
      'The watermark goes in the header of each page. Removing the header removes it too.';

  @override
  String get watermarkApply => 'Apply';

  @override
  String get prefSpellIgnoreUpper => 'Don\'t check words in UPPERCASE';

  @override
  String get prefSpellIgnoreDigits => 'Don\'t check words with numbers';

  @override
  String get prefSpellRulesNote =>
      'The spelling rules apply the next time Quill opens: LibreOffice only reads them when it starts.';

  @override
  String get prefQuickAccess => 'Quick access';

  @override
  String get prefQuickAccessNote =>
      'The buttons before File, on the ribbon. Up to 12.';

  @override
  String prefQuickAccessUp(String name) {
    return 'Move $name up';
  }

  @override
  String prefQuickAccessDown(String name) {
    return 'Move $name down';
  }

  @override
  String prefQuickAccessRemove(String name) {
    return 'Remove $name';
  }

  @override
  String get prefQuickAccessAdd => 'Add a command';

  @override
  String get prefQuickAccessDefault => 'Restore the default';

  @override
  String get prefShortcutsNote =>
      'Each command can have its own shortcut, over the chosen set. The highlighted ones are yours.';

  @override
  String get prefShortcutsFilter => 'Search a command or shortcut';

  @override
  String get prefShortcutsResetAll => 'Reset all to the set';

  @override
  String get prefShortcutChange => 'Change';

  @override
  String shortcutDialogTitle(String name) {
    return 'Shortcut for $name';
  }

  @override
  String get shortcutNone => 'No shortcut now.';

  @override
  String shortcutCurrent(String keys) {
    return 'Now: $keys';
  }

  @override
  String get shortcutPress => 'Press the shortcut keys';

  @override
  String get shortcutUnusable =>
      'Use Ctrl or Alt with a key, or an F key: a letter alone is text.';

  @override
  String shortcutTaken(String name) {
    return 'This is already the shortcut for $name. Assigning removes it there.';
  }

  @override
  String get shortcutRemove => 'No shortcut';

  @override
  String get shortcutReset => 'The set\'s';

  @override
  String get shortcutAssign => 'Assign';

  @override
  String get commandNewFromTemplate => 'New from template…';

  @override
  String get commandSaveAsTemplate => 'Save as template…';

  @override
  String get commandSaveBookTemplate =>
      'Save the styles as the book\'s template';

  @override
  String get templatesNewTitle => 'New from template';

  @override
  String templatesNone(String folder) {
    return 'No templates yet. \"Save as template\" stores a document\'s styles in $folder.';
  }

  @override
  String get templatesOfBook => 'The book\'s styles (estilos.ott)';

  @override
  String get templatesOpenFolder => 'Open the templates folder';

  @override
  String get templatesOpenFailed => 'The template didn\'t open.';

  @override
  String get templatesSaveTitle => 'Save as template';

  @override
  String get templatesSaveNote =>
      'The template keeps this document\'s styles (the page, paragraphs, headings), without the text.';

  @override
  String get templatesName => 'The template\'s name';

  @override
  String get templatesExists => 'A template with this name already exists.';

  @override
  String get templatesReplace => 'Replace';

  @override
  String get templatesSave => 'Save';

  @override
  String templatesSaved(String name) {
    return 'The template $name was saved.';
  }

  @override
  String get templatesBookSaved =>
      'The styles are now the book\'s template: new chapters start from it.';

  @override
  String get templatesSaveFailed => 'The template wasn\'t saved.';
}
