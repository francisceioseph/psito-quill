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
}
