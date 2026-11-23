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
