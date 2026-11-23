import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Psito Quill'**
  String get appTitle;

  /// No description provided for @commandBold.
  ///
  /// In pt, this message translates to:
  /// **'Negrito'**
  String get commandBold;

  /// No description provided for @commandSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get commandSave;

  /// No description provided for @commandDarkPaper.
  ///
  /// In pt, this message translates to:
  /// **'Tema escuro'**
  String get commandDarkPaper;

  /// No description provided for @documentArea.
  ///
  /// In pt, this message translates to:
  /// **'Documento'**
  String get documentArea;

  /// No description provided for @statusStarting.
  ///
  /// In pt, this message translates to:
  /// **'Ligando o motor…'**
  String get statusStarting;

  /// No description provided for @statusEngineFailed.
  ///
  /// In pt, this message translates to:
  /// **'O motor não ligou: {detail}'**
  String statusEngineFailed(String detail);

  /// No description provided for @statusOpening.
  ///
  /// In pt, this message translates to:
  /// **'Abrindo…'**
  String get statusOpening;

  /// No description provided for @statusNoDocument.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum documento'**
  String get statusNoDocument;

  /// No description provided for @statusSaved.
  ///
  /// In pt, this message translates to:
  /// **'Salvo em {path}'**
  String statusSaved(String path);

  /// No description provided for @statusError.
  ///
  /// In pt, this message translates to:
  /// **'Erro: {detail}'**
  String statusError(String detail);

  /// No description provided for @statusPlugin.
  ///
  /// In pt, this message translates to:
  /// **'Plugin: {text}'**
  String statusPlugin(String text);

  /// No description provided for @statusModified.
  ///
  /// In pt, this message translates to:
  /// **'modificado'**
  String get statusModified;

  /// No description provided for @statusMemory.
  ///
  /// In pt, this message translates to:
  /// **'{mb} MB'**
  String statusMemory(int mb);

  /// No description provided for @commandNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo'**
  String get commandNew;

  /// No description provided for @commandOpen.
  ///
  /// In pt, this message translates to:
  /// **'Abrir…'**
  String get commandOpen;

  /// No description provided for @commandSaveAs.
  ///
  /// In pt, this message translates to:
  /// **'Salvar como…'**
  String get commandSaveAs;

  /// No description provided for @commandUndo.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer'**
  String get commandUndo;

  /// No description provided for @commandRedo.
  ///
  /// In pt, this message translates to:
  /// **'Refazer'**
  String get commandRedo;

  /// No description provided for @commandCut.
  ///
  /// In pt, this message translates to:
  /// **'Recortar'**
  String get commandCut;

  /// No description provided for @commandCopy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar'**
  String get commandCopy;

  /// No description provided for @commandPaste.
  ///
  /// In pt, this message translates to:
  /// **'Colar'**
  String get commandPaste;

  /// No description provided for @commandSelectAll.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar tudo'**
  String get commandSelectAll;

  /// No description provided for @commandItalic.
  ///
  /// In pt, this message translates to:
  /// **'Itálico'**
  String get commandItalic;

  /// No description provided for @commandUnderline.
  ///
  /// In pt, this message translates to:
  /// **'Sublinhado'**
  String get commandUnderline;

  /// No description provided for @commandStrikeout.
  ///
  /// In pt, this message translates to:
  /// **'Tachado'**
  String get commandStrikeout;

  /// No description provided for @commandAlignLeft.
  ///
  /// In pt, this message translates to:
  /// **'Alinhar à esquerda'**
  String get commandAlignLeft;

  /// No description provided for @commandAlignCenter.
  ///
  /// In pt, this message translates to:
  /// **'Centralizar'**
  String get commandAlignCenter;

  /// No description provided for @commandAlignRight.
  ///
  /// In pt, this message translates to:
  /// **'Alinhar à direita'**
  String get commandAlignRight;

  /// No description provided for @commandJustify.
  ///
  /// In pt, this message translates to:
  /// **'Justificar'**
  String get commandJustify;

  /// No description provided for @commandBullets.
  ///
  /// In pt, this message translates to:
  /// **'Marcadores'**
  String get commandBullets;

  /// No description provided for @commandNumbering.
  ///
  /// In pt, this message translates to:
  /// **'Numeração'**
  String get commandNumbering;

  /// No description provided for @commandZoomIn.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar o zoom'**
  String get commandZoomIn;

  /// No description provided for @commandZoomOut.
  ///
  /// In pt, this message translates to:
  /// **'Diminuir o zoom'**
  String get commandZoomOut;

  /// No description provided for @commandZoomReset.
  ///
  /// In pt, this message translates to:
  /// **'Zoom em 100%'**
  String get commandZoomReset;

  /// No description provided for @styleDefault.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get styleDefault;

  /// No description provided for @styleBody.
  ///
  /// In pt, this message translates to:
  /// **'Corpo de texto'**
  String get styleBody;

  /// No description provided for @styleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Título do livro'**
  String get styleTitle;

  /// No description provided for @styleSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Subtítulo'**
  String get styleSubtitle;

  /// No description provided for @styleHeading.
  ///
  /// In pt, this message translates to:
  /// **'Título {level}'**
  String styleHeading(int level);

  /// No description provided for @styleQuote.
  ///
  /// In pt, this message translates to:
  /// **'Citação'**
  String get styleQuote;

  /// No description provided for @ribbonFile.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo'**
  String get ribbonFile;

  /// No description provided for @ribbonHome.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get ribbonHome;

  /// No description provided for @groupClipboard.
  ///
  /// In pt, this message translates to:
  /// **'Área de transferência'**
  String get groupClipboard;

  /// No description provided for @groupStyles.
  ///
  /// In pt, this message translates to:
  /// **'Estilos'**
  String get groupStyles;

  /// No description provided for @groupFont.
  ///
  /// In pt, this message translates to:
  /// **'Fonte'**
  String get groupFont;

  /// No description provided for @groupParagraph.
  ///
  /// In pt, this message translates to:
  /// **'Parágrafo'**
  String get groupParagraph;

  /// No description provided for @fieldStyle.
  ///
  /// In pt, this message translates to:
  /// **'Estilo de parágrafo'**
  String get fieldStyle;

  /// No description provided for @fieldFont.
  ///
  /// In pt, this message translates to:
  /// **'Fonte'**
  String get fieldFont;

  /// No description provided for @fieldFontSize.
  ///
  /// In pt, this message translates to:
  /// **'Tamanho da fonte'**
  String get fieldFontSize;

  /// No description provided for @fileBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao documento'**
  String get fileBack;

  /// No description provided for @recentTitle.
  ///
  /// In pt, this message translates to:
  /// **'Recentes'**
  String get recentTitle;

  /// No description provided for @recentEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum arquivo recente.'**
  String get recentEmpty;

  /// No description provided for @preferencesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Preferências'**
  String get preferencesTitle;

  /// No description provided for @prefTheme.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get prefTheme;

  /// No description provided for @prefShortcuts.
  ///
  /// In pt, this message translates to:
  /// **'Atalhos de teclado'**
  String get prefShortcuts;

  /// No description provided for @prefPrivacy.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade'**
  String get prefPrivacy;

  /// No description provided for @prefKeepRecents.
  ///
  /// In pt, this message translates to:
  /// **'Guardar a lista de arquivos recentes'**
  String get prefKeepRecents;

  /// No description provided for @prefPrivacyNote.
  ///
  /// In pt, this message translates to:
  /// **'Nada sai deste computador: sem rede, sem telemetria, sem arquivo de log.'**
  String get prefPrivacyNote;

  /// No description provided for @schemeWordPt.
  ///
  /// In pt, this message translates to:
  /// **'Word em português (Ctrl+N negrito, Ctrl+B salvar)'**
  String get schemeWordPt;

  /// No description provided for @schemeWordEn.
  ///
  /// In pt, this message translates to:
  /// **'Word em inglês (Ctrl+B negrito, Ctrl+S salvar)'**
  String get schemeWordEn;

  /// No description provided for @themeClaro.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get themeClaro;

  /// No description provided for @themeEscuro.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get themeEscuro;

  /// No description provided for @readOnlyBanner.
  ///
  /// In pt, this message translates to:
  /// **'Só leitura: {owner} está com este arquivo aberto. Para editar, salve uma cópia.'**
  String readOnlyBanner(String owner);

  /// No description provided for @readOnlySaveCopy.
  ///
  /// In pt, this message translates to:
  /// **'Salvar uma cópia…'**
  String get readOnlySaveCopy;

  /// No description provided for @unsavedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Salvar as alterações?'**
  String get unsavedTitle;

  /// No description provided for @unsavedBody.
  ///
  /// In pt, this message translates to:
  /// **'“{name}” tem alterações que ainda não foram salvas.'**
  String unsavedBody(String name);

  /// No description provided for @unsavedSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get unsavedSave;

  /// No description provided for @unsavedDiscard.
  ///
  /// In pt, this message translates to:
  /// **'Não salvar'**
  String get unsavedDiscard;

  /// No description provided for @unsavedCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get unsavedCancel;

  /// No description provided for @untitled.
  ///
  /// In pt, this message translates to:
  /// **'Documento sem título'**
  String get untitled;

  /// No description provided for @windowTitle.
  ///
  /// In pt, this message translates to:
  /// **'{name} — Psito Quill'**
  String windowTitle(String name);

  /// No description provided for @windowTitleModified.
  ///
  /// In pt, this message translates to:
  /// **'• {name} — Psito Quill'**
  String windowTitleModified(String name);

  /// No description provided for @windowTitleReadOnly.
  ///
  /// In pt, this message translates to:
  /// **'{name} (só leitura) — Psito Quill'**
  String windowTitleReadOnly(String name);

  /// No description provided for @fileTypeDocuments.
  ///
  /// In pt, this message translates to:
  /// **'Documentos (ODT, DOCX)'**
  String get fileTypeDocuments;

  /// No description provided for @formatOdt.
  ///
  /// In pt, this message translates to:
  /// **'Documento ODF (.odt)'**
  String get formatOdt;

  /// No description provided for @formatDocx.
  ///
  /// In pt, this message translates to:
  /// **'Documento do Word (.docx)'**
  String get formatDocx;

  /// No description provided for @statusPage.
  ///
  /// In pt, this message translates to:
  /// **'Página {page} de {pages}'**
  String statusPage(int page, int pages);

  /// No description provided for @statusWords.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 palavra} other{{count} palavras}}'**
  String statusWords(int count);

  /// No description provided for @statusWordsSelected.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 palavra selecionada} other{{count} palavras selecionadas}}'**
  String statusWordsSelected(int count);

  /// No description provided for @statusZoom.
  ///
  /// In pt, this message translates to:
  /// **'{percent} %'**
  String statusZoom(int percent);

  /// No description provided for @statusReadOnly.
  ///
  /// In pt, this message translates to:
  /// **'só leitura'**
  String get statusReadOnly;

  /// No description provided for @statusOpenFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir {name}: {detail}'**
  String statusOpenFailed(String name, String detail);

  /// No description provided for @commandFind.
  ///
  /// In pt, this message translates to:
  /// **'Localizar'**
  String get commandFind;

  /// No description provided for @commandReplace.
  ///
  /// In pt, this message translates to:
  /// **'Substituir'**
  String get commandReplace;

  /// No description provided for @commandPalette.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar'**
  String get commandPalette;

  /// No description provided for @commandInspector.
  ///
  /// In pt, this message translates to:
  /// **'Painel Formatar'**
  String get commandInspector;

  /// No description provided for @commandRevealFormatting.
  ///
  /// In pt, this message translates to:
  /// **'Revelar formatação'**
  String get commandRevealFormatting;

  /// No description provided for @commandFormattingMarks.
  ///
  /// In pt, this message translates to:
  /// **'Marcas de formatação'**
  String get commandFormattingMarks;

  /// No description provided for @commandSpellOnline.
  ///
  /// In pt, this message translates to:
  /// **'Ortografia automática'**
  String get commandSpellOnline;

  /// No description provided for @commandInsertImage.
  ///
  /// In pt, this message translates to:
  /// **'Imagem…'**
  String get commandInsertImage;

  /// No description provided for @commandInsertTable.
  ///
  /// In pt, this message translates to:
  /// **'Tabela…'**
  String get commandInsertTable;

  /// No description provided for @commandPageBreak.
  ///
  /// In pt, this message translates to:
  /// **'Quebra de página'**
  String get commandPageBreak;

  /// No description provided for @commandIndentMore.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar recuo'**
  String get commandIndentMore;

  /// No description provided for @commandIndentLess.
  ///
  /// In pt, this message translates to:
  /// **'Diminuir recuo'**
  String get commandIndentLess;

  /// No description provided for @commandLineSpacing1.
  ///
  /// In pt, this message translates to:
  /// **'Entrelinhas simples'**
  String get commandLineSpacing1;

  /// No description provided for @commandLineSpacing15.
  ///
  /// In pt, this message translates to:
  /// **'Entrelinhas 1,5'**
  String get commandLineSpacing15;

  /// No description provided for @commandLineSpacing2.
  ///
  /// In pt, this message translates to:
  /// **'Entrelinhas duplo'**
  String get commandLineSpacing2;

  /// No description provided for @commandSpaceMore.
  ///
  /// In pt, this message translates to:
  /// **'Mais espaço entre parágrafos'**
  String get commandSpaceMore;

  /// No description provided for @commandSpaceLess.
  ///
  /// In pt, this message translates to:
  /// **'Menos espaço entre parágrafos'**
  String get commandSpaceLess;

  /// No description provided for @commandSuperscript.
  ///
  /// In pt, this message translates to:
  /// **'Sobrescrito'**
  String get commandSuperscript;

  /// No description provided for @commandSubscript.
  ///
  /// In pt, this message translates to:
  /// **'Subscrito'**
  String get commandSubscript;

  /// No description provided for @commandClearFormatting.
  ///
  /// In pt, this message translates to:
  /// **'Limpar formatação direta'**
  String get commandClearFormatting;

  /// No description provided for @commandNewStyle.
  ///
  /// In pt, this message translates to:
  /// **'Novo estilo a partir da seleção…'**
  String get commandNewStyle;

  /// No description provided for @commandUpdateStyle.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar estilo pela seleção'**
  String get commandUpdateStyle;

  /// No description provided for @commandManageStyles.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar estilos…'**
  String get commandManageStyles;

  /// No description provided for @commandRowAbove.
  ///
  /// In pt, this message translates to:
  /// **'Inserir linha acima'**
  String get commandRowAbove;

  /// No description provided for @commandRowBelow.
  ///
  /// In pt, this message translates to:
  /// **'Inserir linha abaixo'**
  String get commandRowBelow;

  /// No description provided for @commandColumnLeft.
  ///
  /// In pt, this message translates to:
  /// **'Inserir coluna à esquerda'**
  String get commandColumnLeft;

  /// No description provided for @commandColumnRight.
  ///
  /// In pt, this message translates to:
  /// **'Inserir coluna à direita'**
  String get commandColumnRight;

  /// No description provided for @commandDeleteRow.
  ///
  /// In pt, this message translates to:
  /// **'Excluir linha'**
  String get commandDeleteRow;

  /// No description provided for @commandDeleteColumn.
  ///
  /// In pt, this message translates to:
  /// **'Excluir coluna'**
  String get commandDeleteColumn;

  /// No description provided for @commandDeleteTable.
  ///
  /// In pt, this message translates to:
  /// **'Excluir tabela'**
  String get commandDeleteTable;

  /// No description provided for @commandMergeCells.
  ///
  /// In pt, this message translates to:
  /// **'Mesclar células'**
  String get commandMergeCells;

  /// No description provided for @commandPortrait.
  ///
  /// In pt, this message translates to:
  /// **'Retrato'**
  String get commandPortrait;

  /// No description provided for @commandLandscape.
  ///
  /// In pt, this message translates to:
  /// **'Paisagem'**
  String get commandLandscape;

  /// No description provided for @commandWrapOff.
  ///
  /// In pt, this message translates to:
  /// **'Acima e abaixo do texto'**
  String get commandWrapOff;

  /// No description provided for @commandWrapIdeal.
  ///
  /// In pt, this message translates to:
  /// **'Texto em volta'**
  String get commandWrapIdeal;

  /// No description provided for @commandWrapThrough.
  ///
  /// In pt, this message translates to:
  /// **'Atrás do texto'**
  String get commandWrapThrough;

  /// No description provided for @commandImageLeft.
  ///
  /// In pt, this message translates to:
  /// **'Imagem à esquerda'**
  String get commandImageLeft;

  /// No description provided for @commandImageCenter.
  ///
  /// In pt, this message translates to:
  /// **'Imagem no centro'**
  String get commandImageCenter;

  /// No description provided for @commandImageRight.
  ///
  /// In pt, this message translates to:
  /// **'Imagem à direita'**
  String get commandImageRight;

  /// No description provided for @commandAbout.
  ///
  /// In pt, this message translates to:
  /// **'Sobre o Psito Quill'**
  String get commandAbout;

  /// No description provided for @ribbonInsert.
  ///
  /// In pt, this message translates to:
  /// **'Inserir'**
  String get ribbonInsert;

  /// No description provided for @ribbonLayout.
  ///
  /// In pt, this message translates to:
  /// **'Layout'**
  String get ribbonLayout;

  /// No description provided for @ribbonReview.
  ///
  /// In pt, this message translates to:
  /// **'Revisão'**
  String get ribbonReview;

  /// No description provided for @ribbonView.
  ///
  /// In pt, this message translates to:
  /// **'Exibir'**
  String get ribbonView;

  /// No description provided for @ribbonTable.
  ///
  /// In pt, this message translates to:
  /// **'Tabela'**
  String get ribbonTable;

  /// No description provided for @ribbonImage.
  ///
  /// In pt, this message translates to:
  /// **'Imagem'**
  String get ribbonImage;

  /// No description provided for @groupPages.
  ///
  /// In pt, this message translates to:
  /// **'Páginas'**
  String get groupPages;

  /// No description provided for @groupTables.
  ///
  /// In pt, this message translates to:
  /// **'Tabelas'**
  String get groupTables;

  /// No description provided for @groupIllustrations.
  ///
  /// In pt, this message translates to:
  /// **'Ilustrações'**
  String get groupIllustrations;

  /// No description provided for @groupPageSetup.
  ///
  /// In pt, this message translates to:
  /// **'Configurar página'**
  String get groupPageSetup;

  /// No description provided for @groupProofing.
  ///
  /// In pt, this message translates to:
  /// **'Revisão de texto'**
  String get groupProofing;

  /// No description provided for @groupShow.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar'**
  String get groupShow;

  /// No description provided for @groupZoom.
  ///
  /// In pt, this message translates to:
  /// **'Zoom'**
  String get groupZoom;

  /// No description provided for @groupRowsColumns.
  ///
  /// In pt, this message translates to:
  /// **'Linhas e colunas'**
  String get groupRowsColumns;

  /// No description provided for @groupMerge.
  ///
  /// In pt, this message translates to:
  /// **'Mesclar'**
  String get groupMerge;

  /// No description provided for @groupArrange.
  ///
  /// In pt, this message translates to:
  /// **'Disposição'**
  String get groupArrange;

  /// No description provided for @groupEditing.
  ///
  /// In pt, this message translates to:
  /// **'Edição'**
  String get groupEditing;

  /// No description provided for @groupSpacing.
  ///
  /// In pt, this message translates to:
  /// **'Espaçamento'**
  String get groupSpacing;

  /// No description provided for @fieldPageSize.
  ///
  /// In pt, this message translates to:
  /// **'Tamanho'**
  String get fieldPageSize;

  /// No description provided for @fieldMargins.
  ///
  /// In pt, this message translates to:
  /// **'Margens'**
  String get fieldMargins;

  /// No description provided for @pageSizeA4.
  ///
  /// In pt, this message translates to:
  /// **'A4'**
  String get pageSizeA4;

  /// No description provided for @pageSizeA5.
  ///
  /// In pt, this message translates to:
  /// **'A5'**
  String get pageSizeA5;

  /// No description provided for @pageSizeLetter.
  ///
  /// In pt, this message translates to:
  /// **'Carta'**
  String get pageSizeLetter;

  /// No description provided for @pageSizeBook6x9.
  ///
  /// In pt, this message translates to:
  /// **'Livro 6 × 9 pol.'**
  String get pageSizeBook6x9;

  /// No description provided for @pageSizeBook55x85.
  ///
  /// In pt, this message translates to:
  /// **'Livro 5,5 × 8,5 pol.'**
  String get pageSizeBook55x85;

  /// No description provided for @marginsNormal.
  ///
  /// In pt, this message translates to:
  /// **'Normal (2,5 cm)'**
  String get marginsNormal;

  /// No description provided for @marginsNarrow.
  ///
  /// In pt, this message translates to:
  /// **'Estreita (1,27 cm)'**
  String get marginsNarrow;

  /// No description provided for @marginsAbnt.
  ///
  /// In pt, this message translates to:
  /// **'ABNT (3 e 2 cm)'**
  String get marginsAbnt;

  /// No description provided for @marginsWide.
  ///
  /// In pt, this message translates to:
  /// **'Larga (5 cm dos lados)'**
  String get marginsWide;

  /// No description provided for @findField.
  ///
  /// In pt, this message translates to:
  /// **'Localizar'**
  String get findField;

  /// No description provided for @replaceField.
  ///
  /// In pt, this message translates to:
  /// **'Substituir por'**
  String get replaceField;

  /// No description provided for @findNext.
  ///
  /// In pt, this message translates to:
  /// **'Próxima'**
  String get findNext;

  /// No description provided for @findPrevious.
  ///
  /// In pt, this message translates to:
  /// **'Anterior'**
  String get findPrevious;

  /// No description provided for @findAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get findAll;

  /// No description provided for @replaceOne.
  ///
  /// In pt, this message translates to:
  /// **'Substituir'**
  String get replaceOne;

  /// No description provided for @replaceAll.
  ///
  /// In pt, this message translates to:
  /// **'Substituir todas'**
  String get replaceAll;

  /// No description provided for @findMatchCase.
  ///
  /// In pt, this message translates to:
  /// **'Diferenciar maiúsculas'**
  String get findMatchCase;

  /// No description provided for @findWholeWord.
  ///
  /// In pt, this message translates to:
  /// **'Palavra inteira'**
  String get findWholeWord;

  /// No description provided for @findRegex.
  ///
  /// In pt, this message translates to:
  /// **'Expressão regular'**
  String get findRegex;

  /// No description provided for @findClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar a busca'**
  String get findClose;

  /// No description provided for @findNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Nada encontrado'**
  String get findNotFound;

  /// No description provided for @paletteHint.
  ///
  /// In pt, this message translates to:
  /// **'Uma palavra do texto ou um comando'**
  String get paletteHint;

  /// No description provided for @paletteEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nada encontrado'**
  String get paletteEmpty;

  /// No description provided for @inspectorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Formatar'**
  String get inspectorTitle;

  /// No description provided for @sectionCharacter.
  ///
  /// In pt, this message translates to:
  /// **'Caractere'**
  String get sectionCharacter;

  /// No description provided for @sectionParagraph.
  ///
  /// In pt, this message translates to:
  /// **'Parágrafo'**
  String get sectionParagraph;

  /// No description provided for @sectionPage.
  ///
  /// In pt, this message translates to:
  /// **'Página'**
  String get sectionPage;

  /// No description provided for @sectionImage.
  ///
  /// In pt, this message translates to:
  /// **'Imagem'**
  String get sectionImage;

  /// No description provided for @sectionTable.
  ///
  /// In pt, this message translates to:
  /// **'Tabela'**
  String get sectionTable;

  /// No description provided for @sectionReveal.
  ///
  /// In pt, this message translates to:
  /// **'Revelar formatação'**
  String get sectionReveal;

  /// No description provided for @sectionStyles.
  ///
  /// In pt, this message translates to:
  /// **'Estilos'**
  String get sectionStyles;

  /// No description provided for @fieldFontColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor da fonte'**
  String get fieldFontColor;

  /// No description provided for @fieldHighlight.
  ///
  /// In pt, this message translates to:
  /// **'Realce'**
  String get fieldHighlight;

  /// No description provided for @colorAutomatic.
  ///
  /// In pt, this message translates to:
  /// **'Automática'**
  String get colorAutomatic;

  /// No description provided for @highlightNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem realce'**
  String get highlightNone;

  /// No description provided for @fieldIndentLeft.
  ///
  /// In pt, this message translates to:
  /// **'Recuo à esquerda'**
  String get fieldIndentLeft;

  /// No description provided for @fieldIndentRight.
  ///
  /// In pt, this message translates to:
  /// **'Recuo à direita'**
  String get fieldIndentRight;

  /// No description provided for @fieldIndentFirst.
  ///
  /// In pt, this message translates to:
  /// **'Primeira linha'**
  String get fieldIndentFirst;

  /// No description provided for @fieldSpacing.
  ///
  /// In pt, this message translates to:
  /// **'Espaço antes e depois'**
  String get fieldSpacing;

  /// No description provided for @fieldLineSpacing.
  ///
  /// In pt, this message translates to:
  /// **'Entrelinhas'**
  String get fieldLineSpacing;

  /// No description provided for @fieldOrientation.
  ///
  /// In pt, this message translates to:
  /// **'Orientação'**
  String get fieldOrientation;

  /// No description provided for @colorBlack.
  ///
  /// In pt, this message translates to:
  /// **'Preto'**
  String get colorBlack;

  /// No description provided for @colorGray.
  ///
  /// In pt, this message translates to:
  /// **'Cinza'**
  String get colorGray;

  /// No description provided for @colorRed.
  ///
  /// In pt, this message translates to:
  /// **'Vermelho'**
  String get colorRed;

  /// No description provided for @colorOrange.
  ///
  /// In pt, this message translates to:
  /// **'Laranja'**
  String get colorOrange;

  /// No description provided for @colorYellow.
  ///
  /// In pt, this message translates to:
  /// **'Amarelo'**
  String get colorYellow;

  /// No description provided for @colorGreen.
  ///
  /// In pt, this message translates to:
  /// **'Verde'**
  String get colorGreen;

  /// No description provided for @colorBlue.
  ///
  /// In pt, this message translates to:
  /// **'Azul'**
  String get colorBlue;

  /// No description provided for @colorPurple.
  ///
  /// In pt, this message translates to:
  /// **'Roxo'**
  String get colorPurple;

  /// No description provided for @revealParagraphStyle.
  ///
  /// In pt, this message translates to:
  /// **'Estilo de parágrafo'**
  String get revealParagraphStyle;

  /// No description provided for @revealFont.
  ///
  /// In pt, this message translates to:
  /// **'Fonte'**
  String get revealFont;

  /// No description provided for @revealEffects.
  ///
  /// In pt, this message translates to:
  /// **'Efeitos'**
  String get revealEffects;

  /// No description provided for @revealAlignment.
  ///
  /// In pt, this message translates to:
  /// **'Alinhamento'**
  String get revealAlignment;

  /// No description provided for @revealIndents.
  ///
  /// In pt, this message translates to:
  /// **'Recuos'**
  String get revealIndents;

  /// No description provided for @revealSpacing.
  ///
  /// In pt, this message translates to:
  /// **'Espaço antes e depois'**
  String get revealSpacing;

  /// No description provided for @revealLineSpacing.
  ///
  /// In pt, this message translates to:
  /// **'Entrelinhas'**
  String get revealLineSpacing;

  /// No description provided for @revealLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get revealLanguage;

  /// No description provided for @revealPageStyle.
  ///
  /// In pt, this message translates to:
  /// **'Estilo de página'**
  String get revealPageStyle;

  /// No description provided for @revealColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor'**
  String get revealColor;

  /// No description provided for @revealNone.
  ///
  /// In pt, this message translates to:
  /// **'nenhum'**
  String get revealNone;

  /// No description provided for @revealOther.
  ///
  /// In pt, this message translates to:
  /// **'outro'**
  String get revealOther;

  /// No description provided for @stylesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estilos'**
  String get stylesTitle;

  /// No description provided for @stylesParagraph.
  ///
  /// In pt, this message translates to:
  /// **'Parágrafo'**
  String get stylesParagraph;

  /// No description provided for @stylesCharacter.
  ///
  /// In pt, this message translates to:
  /// **'Caractere'**
  String get stylesCharacter;

  /// No description provided for @stylesMine.
  ///
  /// In pt, this message translates to:
  /// **'Meus estilos'**
  String get stylesMine;

  /// No description provided for @stylesBuiltIn.
  ///
  /// In pt, this message translates to:
  /// **'Estilos de fábrica'**
  String get stylesBuiltIn;

  /// No description provided for @stylesApply.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar'**
  String get stylesApply;

  /// No description provided for @stylesNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo estilo a partir da seleção'**
  String get stylesNewTitle;

  /// No description provided for @stylesName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do estilo'**
  String get stylesName;

  /// No description provided for @stylesCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar'**
  String get stylesCreate;

  /// No description provided for @stylesNameTaken.
  ///
  /// In pt, this message translates to:
  /// **'Já existe um estilo com esse nome'**
  String get stylesNameTaken;

  /// No description provided for @dialogCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get dialogCancel;

  /// No description provided for @dialogClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get dialogClose;

  /// No description provided for @stylePreformatted.
  ///
  /// In pt, this message translates to:
  /// **'Texto pré-formatado'**
  String get stylePreformatted;

  /// No description provided for @styleFootnote.
  ///
  /// In pt, this message translates to:
  /// **'Nota de rodapé'**
  String get styleFootnote;

  /// No description provided for @styleEndnote.
  ///
  /// In pt, this message translates to:
  /// **'Nota de fim'**
  String get styleEndnote;

  /// No description provided for @styleCaption.
  ///
  /// In pt, this message translates to:
  /// **'Legenda'**
  String get styleCaption;

  /// No description provided for @styleSignature.
  ///
  /// In pt, this message translates to:
  /// **'Assinatura'**
  String get styleSignature;

  /// No description provided for @styleFirstLineIndent.
  ///
  /// In pt, this message translates to:
  /// **'Primeira linha recuada'**
  String get styleFirstLineIndent;

  /// No description provided for @styleHangingIndent.
  ///
  /// In pt, this message translates to:
  /// **'Recuo deslocado'**
  String get styleHangingIndent;

  /// No description provided for @styleBodyIndent.
  ///
  /// In pt, this message translates to:
  /// **'Corpo de texto recuado'**
  String get styleBodyIndent;

  /// No description provided for @styleHeader.
  ///
  /// In pt, this message translates to:
  /// **'Cabeçalho'**
  String get styleHeader;

  /// No description provided for @styleFooter.
  ///
  /// In pt, this message translates to:
  /// **'Rodapé'**
  String get styleFooter;

  /// No description provided for @styleTableContents.
  ///
  /// In pt, this message translates to:
  /// **'Conteúdo da tabela'**
  String get styleTableContents;

  /// No description provided for @styleTableHeading.
  ///
  /// In pt, this message translates to:
  /// **'Título da tabela'**
  String get styleTableHeading;

  /// No description provided for @styleList.
  ///
  /// In pt, this message translates to:
  /// **'Lista'**
  String get styleList;

  /// No description provided for @styleListContents.
  ///
  /// In pt, this message translates to:
  /// **'Conteúdo da lista'**
  String get styleListContents;

  /// No description provided for @styleMarginalia.
  ///
  /// In pt, this message translates to:
  /// **'Nota na margem'**
  String get styleMarginalia;

  /// No description provided for @styleAppendix.
  ///
  /// In pt, this message translates to:
  /// **'Apêndice'**
  String get styleAppendix;

  /// No description provided for @styleHeadingBase.
  ///
  /// In pt, this message translates to:
  /// **'Título (base)'**
  String get styleHeadingBase;

  /// No description provided for @styleEmphasis.
  ///
  /// In pt, this message translates to:
  /// **'Ênfase'**
  String get styleEmphasis;

  /// No description provided for @styleStrongEmphasis.
  ///
  /// In pt, this message translates to:
  /// **'Ênfase forte'**
  String get styleStrongEmphasis;

  /// No description provided for @styleCitation.
  ///
  /// In pt, this message translates to:
  /// **'Citação'**
  String get styleCitation;

  /// No description provided for @contextIgnore.
  ///
  /// In pt, this message translates to:
  /// **'Ignorar'**
  String get contextIgnore;

  /// No description provided for @contextIgnoreAll.
  ///
  /// In pt, this message translates to:
  /// **'Ignorar sempre'**
  String get contextIgnoreAll;

  /// No description provided for @contextNoSuggestions.
  ///
  /// In pt, this message translates to:
  /// **'Sem sugestões'**
  String get contextNoSuggestions;

  /// No description provided for @themeClassico.
  ///
  /// In pt, this message translates to:
  /// **'Clássico 97'**
  String get themeClassico;

  /// No description provided for @menuFile.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo'**
  String get menuFile;

  /// No description provided for @menuEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get menuEdit;

  /// No description provided for @menuView.
  ///
  /// In pt, this message translates to:
  /// **'Exibir'**
  String get menuView;

  /// No description provided for @menuInsert.
  ///
  /// In pt, this message translates to:
  /// **'Inserir'**
  String get menuInsert;

  /// No description provided for @menuFormat.
  ///
  /// In pt, this message translates to:
  /// **'Formatar'**
  String get menuFormat;

  /// No description provided for @menuStyles.
  ///
  /// In pt, this message translates to:
  /// **'Estilos'**
  String get menuStyles;

  /// No description provided for @menuTools.
  ///
  /// In pt, this message translates to:
  /// **'Ferramentas'**
  String get menuTools;

  /// No description provided for @menuTable.
  ///
  /// In pt, this message translates to:
  /// **'Tabela'**
  String get menuTable;

  /// No description provided for @menuHelp.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda'**
  String get menuHelp;

  /// No description provided for @menuRecent.
  ///
  /// In pt, this message translates to:
  /// **'Recentes'**
  String get menuRecent;

  /// No description provided for @menuTheme.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get menuTheme;

  /// No description provided for @toolbarStandard.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get toolbarStandard;

  /// No description provided for @toolbarFormatting.
  ///
  /// In pt, this message translates to:
  /// **'Formatação'**
  String get toolbarFormatting;

  /// No description provided for @aboutText.
  ///
  /// In pt, this message translates to:
  /// **'Um editor de texto para livros longos, sobre o LibreOffice {version}.'**
  String aboutText(String version);

  /// No description provided for @findCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{nenhuma ocorrência} =1{1 ocorrência} other{{count} ocorrências}}'**
  String findCount(int count);

  /// No description provided for @findReplaced.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{nada trocado} =1{1 trocada} other{{count} trocadas}}'**
  String findReplaced(int count);

  /// No description provided for @tableSize.
  ///
  /// In pt, this message translates to:
  /// **'Tabela de {columns} × {rows}'**
  String tableSize(int columns, int rows);

  /// No description provided for @measureCm.
  ///
  /// In pt, this message translates to:
  /// **'{value} cm'**
  String measureCm(String value);

  /// No description provided for @imageSizeCm.
  ///
  /// In pt, this message translates to:
  /// **'{width} × {height} cm'**
  String imageSizeCm(String width, String height);

  /// No description provided for @percentValue.
  ///
  /// In pt, this message translates to:
  /// **'{value} %'**
  String percentValue(int value);

  /// No description provided for @unitCm.
  ///
  /// In pt, this message translates to:
  /// **'cm'**
  String get unitCm;

  /// No description provided for @fileTypeImages.
  ///
  /// In pt, this message translates to:
  /// **'Imagens'**
  String get fileTypeImages;

  /// No description provided for @commandFilePanel.
  ///
  /// In pt, this message translates to:
  /// **'Recentes e preferências…'**
  String get commandFilePanel;

  /// No description provided for @outlineTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estrutura'**
  String get outlineTitle;

  /// No description provided for @outlineClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar a estrutura'**
  String get outlineClose;

  /// No description provided for @outlineEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Os títulos do documento aparecem aqui (os estilos Título 1, 2 e 3).'**
  String get outlineEmpty;

  /// No description provided for @railLabel.
  ///
  /// In pt, this message translates to:
  /// **'Painéis'**
  String get railLabel;

  /// No description provided for @stylesPanelClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar os estilos'**
  String get stylesPanelClose;

  /// No description provided for @ribbonStyles.
  ///
  /// In pt, this message translates to:
  /// **'Estilos'**
  String get ribbonStyles;

  /// No description provided for @ribbonCollapse.
  ///
  /// In pt, this message translates to:
  /// **'Recolher'**
  String get ribbonCollapse;

  /// No description provided for @ribbonCollapseTip.
  ///
  /// In pt, this message translates to:
  /// **'Recolher a faixa'**
  String get ribbonCollapseTip;

  /// No description provided for @ribbonExpandTip.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar a faixa'**
  String get ribbonExpandTip;

  /// No description provided for @ribbonTabs.
  ///
  /// In pt, this message translates to:
  /// **'Abas da faixa'**
  String get ribbonTabs;

  /// No description provided for @searchCommands.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar no texto e nos comandos'**
  String get searchCommands;

  /// No description provided for @inspectorClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar o painel Formatar'**
  String get inspectorClose;

  /// No description provided for @inspectorSections.
  ///
  /// In pt, this message translates to:
  /// **'Seção do painel'**
  String get inspectorSections;

  /// No description provided for @sectionText.
  ///
  /// In pt, this message translates to:
  /// **'Texto'**
  String get sectionText;

  /// No description provided for @fontGrow.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar a fonte'**
  String get fontGrow;

  /// No description provided for @fontShrink.
  ///
  /// In pt, this message translates to:
  /// **'Diminuir a fonte'**
  String get fontShrink;

  /// No description provided for @moreStyles.
  ///
  /// In pt, this message translates to:
  /// **'Mais estilos'**
  String get moreStyles;

  /// No description provided for @commandLineSpacingMenu.
  ///
  /// In pt, this message translates to:
  /// **'Entrelinhas'**
  String get commandLineSpacingMenu;

  /// No description provided for @zoomSlider.
  ///
  /// In pt, this message translates to:
  /// **'Zoom'**
  String get zoomSlider;

  /// No description provided for @zoomPercent.
  ///
  /// In pt, this message translates to:
  /// **'{percent} %'**
  String zoomPercent(int percent);

  /// No description provided for @statusStyle.
  ///
  /// In pt, this message translates to:
  /// **'Estilo: {name}'**
  String statusStyle(Object name);

  /// No description provided for @commandCollapseRibbon.
  ///
  /// In pt, this message translates to:
  /// **'Recolher a faixa'**
  String get commandCollapseRibbon;

  /// No description provided for @commandOutline.
  ///
  /// In pt, this message translates to:
  /// **'Painel Estrutura'**
  String get commandOutline;

  /// No description provided for @commandStylesPanel.
  ///
  /// In pt, this message translates to:
  /// **'Painel Estilos'**
  String get commandStylesPanel;

  /// No description provided for @styleSampleBody.
  ///
  /// In pt, this message translates to:
  /// **'Era uma vez'**
  String get styleSampleBody;

  /// No description provided for @styleSampleHeading.
  ///
  /// In pt, this message translates to:
  /// **'Capítulo'**
  String get styleSampleHeading;

  /// No description provided for @styleSampleQuote.
  ///
  /// In pt, this message translates to:
  /// **'disse ela'**
  String get styleSampleQuote;

  /// No description provided for @styleSampleOther.
  ///
  /// In pt, this message translates to:
  /// **'Aa'**
  String get styleSampleOther;

  /// No description provided for @styleCardApplied.
  ///
  /// In pt, this message translates to:
  /// **'Estilo {name}, aplicado'**
  String styleCardApplied(Object name);

  /// No description provided for @styleCard.
  ///
  /// In pt, this message translates to:
  /// **'Estilo {name}'**
  String styleCard(Object name);

  /// No description provided for @colorMenuMore.
  ///
  /// In pt, this message translates to:
  /// **'{name}: {value}'**
  String colorMenuMore(Object name, Object value);

  /// No description provided for @fieldWidth.
  ///
  /// In pt, this message translates to:
  /// **'Largura'**
  String get fieldWidth;

  /// No description provided for @fieldHeight.
  ///
  /// In pt, this message translates to:
  /// **'Altura'**
  String get fieldHeight;

  /// No description provided for @keepRatio.
  ///
  /// In pt, this message translates to:
  /// **'Manter a proporção'**
  String get keepRatio;

  /// No description provided for @groupSize.
  ///
  /// In pt, this message translates to:
  /// **'Tamanho'**
  String get groupSize;

  /// No description provided for @fontSearch.
  ///
  /// In pt, this message translates to:
  /// **'Procurar uma fonte'**
  String get fontSearch;

  /// No description provided for @fontInDocument.
  ///
  /// In pt, this message translates to:
  /// **'Neste documento'**
  String get fontInDocument;

  /// No description provided for @fontRecent.
  ///
  /// In pt, this message translates to:
  /// **'Recentes'**
  String get fontRecent;

  /// No description provided for @fontAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get fontAll;

  /// No description provided for @fontSerif.
  ///
  /// In pt, this message translates to:
  /// **'Com serifa'**
  String get fontSerif;

  /// No description provided for @fontSans.
  ///
  /// In pt, this message translates to:
  /// **'Sem serifa'**
  String get fontSans;

  /// No description provided for @fontMono.
  ///
  /// In pt, this message translates to:
  /// **'Mono'**
  String get fontMono;

  /// No description provided for @fontNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma fonte com esse nome'**
  String get fontNone;

  /// No description provided for @fontFilters.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar as fontes'**
  String get fontFilters;

  /// No description provided for @stylesSearch.
  ///
  /// In pt, this message translates to:
  /// **'Procurar um estilo'**
  String get stylesSearch;

  /// No description provided for @stylesKind.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de estilo'**
  String get stylesKind;

  /// No description provided for @stylesFromBook.
  ///
  /// In pt, this message translates to:
  /// **'Do livro'**
  String get stylesFromBook;

  /// No description provided for @stylesFromLibreOffice.
  ///
  /// In pt, this message translates to:
  /// **'Do LibreOffice'**
  String get stylesFromLibreOffice;

  /// No description provided for @stylesNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum estilo com esse nome'**
  String get stylesNone;

  /// No description provided for @revealDirect.
  ///
  /// In pt, this message translates to:
  /// **'direto'**
  String get revealDirect;

  /// No description provided for @revealFromStyle.
  ///
  /// In pt, this message translates to:
  /// **'estilo'**
  String get revealFromStyle;

  /// No description provided for @revealClearDirect.
  ///
  /// In pt, this message translates to:
  /// **'Tirar o que é direto'**
  String get revealClearDirect;

  /// No description provided for @rulerFirstLine.
  ///
  /// In pt, this message translates to:
  /// **'Recuo da primeira linha'**
  String get rulerFirstLine;

  /// No description provided for @rulerLeftIndent.
  ///
  /// In pt, this message translates to:
  /// **'Recuo esquerdo'**
  String get rulerLeftIndent;

  /// No description provided for @rulerRightIndent.
  ///
  /// In pt, this message translates to:
  /// **'Recuo direito'**
  String get rulerRightIndent;

  /// No description provided for @rulerHorizontal.
  ///
  /// In pt, this message translates to:
  /// **'Régua'**
  String get rulerHorizontal;

  /// No description provided for @rulerVertical.
  ///
  /// In pt, this message translates to:
  /// **'Régua vertical'**
  String get rulerVertical;

  /// No description provided for @commandRuler.
  ///
  /// In pt, this message translates to:
  /// **'Régua'**
  String get commandRuler;

  /// No description provided for @prefRulerUnit.
  ///
  /// In pt, this message translates to:
  /// **'Unidade da régua'**
  String get prefRulerUnit;

  /// No description provided for @unitMm.
  ///
  /// In pt, this message translates to:
  /// **'mm'**
  String get unitMm;

  /// No description provided for @unitInch.
  ///
  /// In pt, this message translates to:
  /// **'pol'**
  String get unitInch;

  /// No description provided for @unitPt.
  ///
  /// In pt, this message translates to:
  /// **'pt'**
  String get unitPt;

  /// No description provided for @layoutLabel.
  ///
  /// In pt, this message translates to:
  /// **'Disposição das páginas'**
  String get layoutLabel;

  /// No description provided for @layoutSingle.
  ///
  /// In pt, this message translates to:
  /// **'Uma página'**
  String get layoutSingle;

  /// No description provided for @layoutMulti.
  ///
  /// In pt, this message translates to:
  /// **'Várias páginas'**
  String get layoutMulti;

  /// No description provided for @layoutBook.
  ///
  /// In pt, this message translates to:
  /// **'Livro (pares)'**
  String get layoutBook;

  /// No description provided for @themeSepia.
  ///
  /// In pt, this message translates to:
  /// **'Sépia'**
  String get themeSepia;

  /// No description provided for @commandZen.
  ///
  /// In pt, this message translates to:
  /// **'Modo zen'**
  String get commandZen;

  /// No description provided for @zenExitHint.
  ///
  /// In pt, this message translates to:
  /// **'Esc ou F11 sai'**
  String get zenExitHint;

  /// No description provided for @zenFocus.
  ///
  /// In pt, this message translates to:
  /// **'Foco no parágrafo'**
  String get zenFocus;

  /// No description provided for @zenTypewriter.
  ///
  /// In pt, this message translates to:
  /// **'Máquina de escrever'**
  String get zenTypewriter;

  /// No description provided for @zenPaper.
  ///
  /// In pt, this message translates to:
  /// **'Papel'**
  String get zenPaper;

  /// No description provided for @zenOptions.
  ///
  /// In pt, this message translates to:
  /// **'Opções do modo zen'**
  String get zenOptions;

  /// No description provided for @zenSession.
  ///
  /// In pt, this message translates to:
  /// **'{minutes, plural, =0{começou agora} =1{1 min nesta sessão} other{{minutes} min nesta sessão}}'**
  String zenSession(int minutes);

  /// No description provided for @ribbonMoreFont.
  ///
  /// In pt, this message translates to:
  /// **'Mais da fonte'**
  String get ribbonMoreFont;

  /// No description provided for @searchSectionDocument.
  ///
  /// In pt, this message translates to:
  /// **'No documento'**
  String get searchSectionDocument;

  /// No description provided for @searchSectionCommands.
  ///
  /// In pt, this message translates to:
  /// **'Comandos'**
  String get searchSectionCommands;

  /// No description provided for @searchSearching.
  ///
  /// In pt, this message translates to:
  /// **'Procurando no documento…'**
  String get searchSearching;

  /// No description provided for @searchNoHits.
  ///
  /// In pt, this message translates to:
  /// **'Nada no documento'**
  String get searchNoHits;

  /// No description provided for @searchPage.
  ///
  /// In pt, this message translates to:
  /// **'p. {page}'**
  String searchPage(int page);

  /// No description provided for @searchMoreHits.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{e mais 1 ocorrência} other{e mais {count} ocorrências}}'**
  String searchMoreHits(int count);

  /// No description provided for @searchFindOptions.
  ///
  /// In pt, this message translates to:
  /// **'Localizar e substituir, com opções…'**
  String get searchFindOptions;

  /// No description provided for @searchHitLabel.
  ///
  /// In pt, this message translates to:
  /// **'{text}, página {page}'**
  String searchHitLabel(String text, int page);

  /// No description provided for @searchHitsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 ocorrência} other{{count} ocorrências}}'**
  String searchHitsCount(int count);

  /// No description provided for @railFindReplace.
  ///
  /// In pt, this message translates to:
  /// **'Localizar e substituir'**
  String get railFindReplace;

  /// No description provided for @commandCloseTab.
  ///
  /// In pt, this message translates to:
  /// **'Fechar a aba'**
  String get commandCloseTab;

  /// No description provided for @commandNextTab.
  ///
  /// In pt, this message translates to:
  /// **'Próxima aba'**
  String get commandNextTab;

  /// No description provided for @commandPreviousTab.
  ///
  /// In pt, this message translates to:
  /// **'Aba anterior'**
  String get commandPreviousTab;

  /// No description provided for @tabsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Documentos abertos'**
  String get tabsLabel;

  /// No description provided for @tabCloseNamed.
  ///
  /// In pt, this message translates to:
  /// **'Fechar {name}'**
  String tabCloseNamed(String name);

  /// No description provided for @tabModifiedNamed.
  ///
  /// In pt, this message translates to:
  /// **'{name}, com alterações não salvas'**
  String tabModifiedNamed(String name);

  /// No description provided for @stylesMore.
  ///
  /// In pt, this message translates to:
  /// **'Mais estilos'**
  String get stylesMore;

  /// No description provided for @railFind.
  ///
  /// In pt, this message translates to:
  /// **'Localizar'**
  String get railFind;

  /// No description provided for @commandKeepWithNext.
  ///
  /// In pt, this message translates to:
  /// **'Manter com o próximo'**
  String get commandKeepWithNext;

  /// No description provided for @commandSeparateFromNext.
  ///
  /// In pt, this message translates to:
  /// **'Permitir separar do próximo'**
  String get commandSeparateFromNext;

  /// No description provided for @commandKeepLines.
  ///
  /// In pt, this message translates to:
  /// **'Manter as linhas juntas'**
  String get commandKeepLines;

  /// No description provided for @commandSplitLines.
  ///
  /// In pt, this message translates to:
  /// **'Permitir dividir as linhas'**
  String get commandSplitLines;

  /// No description provided for @contextStyle.
  ///
  /// In pt, this message translates to:
  /// **'Estilo'**
  String get contextStyle;

  /// No description provided for @contextParagraph.
  ///
  /// In pt, this message translates to:
  /// **'Parágrafo'**
  String get contextParagraph;

  /// No description provided for @fieldIndents.
  ///
  /// In pt, this message translates to:
  /// **'Recuos'**
  String get fieldIndents;

  /// No description provided for @fieldIndentLeftShort.
  ///
  /// In pt, this message translates to:
  /// **'Esquerda'**
  String get fieldIndentLeftShort;

  /// No description provided for @fieldIndentFirstShort.
  ///
  /// In pt, this message translates to:
  /// **'1ª linha'**
  String get fieldIndentFirstShort;

  /// No description provided for @fieldIndentRightShort.
  ///
  /// In pt, this message translates to:
  /// **'Direita'**
  String get fieldIndentRightShort;

  /// No description provided for @findPanelTitle.
  ///
  /// In pt, this message translates to:
  /// **'Localizar e substituir'**
  String get findPanelTitle;

  /// No description provided for @findHitsList.
  ///
  /// In pt, this message translates to:
  /// **'Ocorrências no documento'**
  String get findHitsList;

  /// No description provided for @commandFitWidth.
  ///
  /// In pt, this message translates to:
  /// **'Ajustar à largura'**
  String get commandFitWidth;

  /// No description provided for @commandFitPage.
  ///
  /// In pt, this message translates to:
  /// **'Ajustar à página'**
  String get commandFitPage;

  /// No description provided for @statusZoomTip.
  ///
  /// In pt, this message translates to:
  /// **'Zoom'**
  String get statusZoomTip;

  /// No description provided for @statusLanguageTip.
  ///
  /// In pt, this message translates to:
  /// **'Idioma e ortografia'**
  String get statusLanguageTip;

  /// No description provided for @statusWordsTip.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas do documento'**
  String get statusWordsTip;

  /// No description provided for @statusInfoPages.
  ///
  /// In pt, this message translates to:
  /// **'Páginas'**
  String get statusInfoPages;

  /// No description provided for @statusInfoWords.
  ///
  /// In pt, this message translates to:
  /// **'Palavras'**
  String get statusInfoWords;

  /// No description provided for @statusInfoCharacters.
  ///
  /// In pt, this message translates to:
  /// **'Caracteres'**
  String get statusInfoCharacters;

  /// No description provided for @statusInfoSelected.
  ///
  /// In pt, this message translates to:
  /// **'Palavras selecionadas'**
  String get statusInfoSelected;

  /// No description provided for @languageForSelection.
  ///
  /// In pt, this message translates to:
  /// **'Idioma da seleção'**
  String get languageForSelection;

  /// No description provided for @languageForParagraph.
  ///
  /// In pt, this message translates to:
  /// **'Idioma do parágrafo'**
  String get languageForParagraph;

  /// No description provided for @languageNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem verificação de ortografia'**
  String get languageNone;

  /// No description provided for @languageReset.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao idioma do estilo'**
  String get languageReset;

  /// No description provided for @recentHeading.
  ///
  /// In pt, this message translates to:
  /// **'Arquivos recentes'**
  String get recentHeading;

  /// No description provided for @recentName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get recentName;

  /// No description provided for @recentFolder.
  ///
  /// In pt, this message translates to:
  /// **'Pasta'**
  String get recentFolder;

  /// No description provided for @recentModified.
  ///
  /// In pt, this message translates to:
  /// **'Modificado'**
  String get recentModified;

  /// No description provided for @recentMissing.
  ///
  /// In pt, this message translates to:
  /// **'Não encontrado'**
  String get recentMissing;

  /// No description provided for @fileInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações'**
  String get fileInfo;

  /// No description provided for @infoFolder.
  ///
  /// In pt, this message translates to:
  /// **'Pasta'**
  String get infoFolder;

  /// No description provided for @infoSize.
  ///
  /// In pt, this message translates to:
  /// **'Tamanho'**
  String get infoSize;

  /// No description provided for @infoModified.
  ///
  /// In pt, this message translates to:
  /// **'Modificado em'**
  String get infoModified;

  /// No description provided for @infoNotSaved.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não foi salvo'**
  String get infoNotSaved;

  /// No description provided for @infoOpenFolder.
  ///
  /// In pt, this message translates to:
  /// **'Abrir a pasta do arquivo'**
  String get infoOpenFolder;

  /// No description provided for @sizeBytes.
  ///
  /// In pt, this message translates to:
  /// **'{n} bytes'**
  String sizeBytes(int n);

  /// No description provided for @sizeKb.
  ///
  /// In pt, this message translates to:
  /// **'{n} KB'**
  String sizeKb(int n);

  /// No description provided for @sizeMb.
  ///
  /// In pt, this message translates to:
  /// **'{n} MB'**
  String sizeMb(String n);

  /// No description provided for @decimalSeparator.
  ///
  /// In pt, this message translates to:
  /// **','**
  String get decimalSeparator;

  /// No description provided for @prefStart.
  ///
  /// In pt, this message translates to:
  /// **'Ao abrir o Quill sem um arquivo'**
  String get prefStart;

  /// No description provided for @prefStartScreen.
  ///
  /// In pt, this message translates to:
  /// **'Tela inicial'**
  String get prefStartScreen;

  /// No description provided for @prefStartBlank.
  ///
  /// In pt, this message translates to:
  /// **'Documento em branco'**
  String get prefStartBlank;

  /// No description provided for @startTitle.
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get startTitle;

  /// No description provided for @startBlank.
  ///
  /// In pt, this message translates to:
  /// **'Documento em branco'**
  String get startBlank;

  /// No description provided for @startOpen.
  ///
  /// In pt, this message translates to:
  /// **'Abrir um arquivo…'**
  String get startOpen;

  /// No description provided for @statusMoreInfo.
  ///
  /// In pt, this message translates to:
  /// **'Mais informações…'**
  String get statusMoreInfo;

  /// No description provided for @commandStatusBar.
  ///
  /// In pt, this message translates to:
  /// **'Barra de status'**
  String get commandStatusBar;

  /// No description provided for @groupPageLayout.
  ///
  /// In pt, this message translates to:
  /// **'Páginas'**
  String get groupPageLayout;

  /// No description provided for @groupWindow.
  ///
  /// In pt, this message translates to:
  /// **'Janela'**
  String get groupWindow;

  /// No description provided for @groupModes.
  ///
  /// In pt, this message translates to:
  /// **'Modos'**
  String get groupModes;

  /// No description provided for @busyOpening.
  ///
  /// In pt, this message translates to:
  /// **'Abrindo…'**
  String get busyOpening;

  /// No description provided for @busySaving.
  ///
  /// In pt, this message translates to:
  /// **'Salvando…'**
  String get busySaving;

  /// No description provided for @busyWorking.
  ///
  /// In pt, this message translates to:
  /// **'Trabalhando…'**
  String get busyWorking;

  /// No description provided for @themeHighContrastDark.
  ///
  /// In pt, this message translates to:
  /// **'Alto contraste escuro'**
  String get themeHighContrastDark;

  /// No description provided for @themeHighContrastLight.
  ///
  /// In pt, this message translates to:
  /// **'Alto contraste claro'**
  String get themeHighContrastLight;

  /// No description provided for @prefGeneral.
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get prefGeneral;

  /// No description provided for @prefAppearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get prefAppearance;

  /// No description provided for @prefAccessibility.
  ///
  /// In pt, this message translates to:
  /// **'Acessibilidade'**
  String get prefAccessibility;

  /// No description provided for @prefZoomOnOpen.
  ///
  /// In pt, this message translates to:
  /// **'Zoom ao abrir um documento'**
  String get prefZoomOnOpen;

  /// No description provided for @prefUiScale.
  ///
  /// In pt, this message translates to:
  /// **'Tamanho da interface'**
  String get prefUiScale;

  /// No description provided for @prefUiScaleNote.
  ///
  /// In pt, this message translates to:
  /// **'Tudo cresce junto: o texto, os botões, os ícones e a página. Vale por cima do tamanho do texto do sistema.'**
  String get prefUiScaleNote;

  /// No description provided for @prefComfortable.
  ///
  /// In pt, this message translates to:
  /// **'Botões maiores'**
  String get prefComfortable;

  /// No description provided for @prefCaretWidth.
  ///
  /// In pt, this message translates to:
  /// **'Espessura do cursor do texto'**
  String get prefCaretWidth;

  /// No description provided for @prefCaretPx.
  ///
  /// In pt, this message translates to:
  /// **'{n} px'**
  String prefCaretPx(int n);

  /// No description provided for @prefCaretBlink.
  ///
  /// In pt, this message translates to:
  /// **'O cursor do texto pisca'**
  String get prefCaretBlink;

  /// No description provided for @prefReduceMotion.
  ///
  /// In pt, this message translates to:
  /// **'Reduzir movimento'**
  String get prefReduceMotion;

  /// No description provided for @prefReduceMotionNote.
  ///
  /// In pt, this message translates to:
  /// **'Sem animações na interface. O Quill também segue o pedido do sistema.'**
  String get prefReduceMotionNote;

  /// No description provided for @prefSpellColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor da marca de ortografia'**
  String get prefSpellColor;

  /// No description provided for @prefSpellColorNote.
  ///
  /// In pt, this message translates to:
  /// **'Vale na próxima vez que o Quill abrir.'**
  String get prefSpellColorNote;

  /// No description provided for @prefScreenReaderDoc.
  ///
  /// In pt, this message translates to:
  /// **'Texto do documento para o leitor de tela'**
  String get prefScreenReaderDoc;

  /// No description provided for @prefScreenReaderDocNote.
  ///
  /// In pt, this message translates to:
  /// **'Liga sozinho quando um leitor de tela está ativo. Ligado, o motor trabalha um pouco mais a cada tecla.'**
  String get prefScreenReaderDocNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
