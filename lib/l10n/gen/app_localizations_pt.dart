// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Psito Quill';

  @override
  String get commandBold => 'Negrito';

  @override
  String get commandSave => 'Salvar';

  @override
  String get commandDarkPaper => 'Tema escuro';

  @override
  String get documentArea => 'Documento';

  @override
  String get statusStarting => 'Ligando o motor…';

  @override
  String statusEngineFailed(String detail) {
    return 'O motor não ligou: $detail';
  }

  @override
  String get statusOpening => 'Abrindo…';

  @override
  String get statusNoDocument => 'Nenhum documento';

  @override
  String statusSaved(String path) {
    return 'Salvo em $path';
  }

  @override
  String statusError(String detail) {
    return 'Erro: $detail';
  }

  @override
  String statusPlugin(String text) {
    return 'Plugin: $text';
  }

  @override
  String get statusModified => 'modificado';

  @override
  String statusMemory(int mb) {
    return '$mb MB';
  }

  @override
  String get commandNew => 'Novo';

  @override
  String get commandOpen => 'Abrir…';

  @override
  String get commandSaveAs => 'Salvar como…';

  @override
  String get commandUndo => 'Desfazer';

  @override
  String get commandRedo => 'Refazer';

  @override
  String get commandCut => 'Recortar';

  @override
  String get commandCopy => 'Copiar';

  @override
  String get commandPaste => 'Colar';

  @override
  String get commandSelectAll => 'Selecionar tudo';

  @override
  String get commandItalic => 'Itálico';

  @override
  String get commandUnderline => 'Sublinhado';

  @override
  String get commandStrikeout => 'Tachado';

  @override
  String get commandAlignLeft => 'Alinhar à esquerda';

  @override
  String get commandAlignCenter => 'Centralizar';

  @override
  String get commandAlignRight => 'Alinhar à direita';

  @override
  String get commandJustify => 'Justificar';

  @override
  String get commandBullets => 'Marcadores';

  @override
  String get commandNumbering => 'Numeração';

  @override
  String get commandZoomIn => 'Aumentar o zoom';

  @override
  String get commandZoomOut => 'Diminuir o zoom';

  @override
  String get commandZoomReset => 'Zoom em 100%';

  @override
  String get styleDefault => 'Padrão';

  @override
  String get styleBody => 'Corpo de texto';

  @override
  String get styleTitle => 'Título do livro';

  @override
  String get styleSubtitle => 'Subtítulo';

  @override
  String styleHeading(int level) {
    return 'Título $level';
  }

  @override
  String get styleQuote => 'Citação';

  @override
  String get ribbonFile => 'Arquivo';

  @override
  String get ribbonHome => 'Início';

  @override
  String get groupClipboard => 'Área de transferência';

  @override
  String get groupStyles => 'Estilos';

  @override
  String get groupFont => 'Fonte';

  @override
  String get groupParagraph => 'Parágrafo';

  @override
  String get fieldStyle => 'Estilo de parágrafo';

  @override
  String get fieldFont => 'Fonte';

  @override
  String get fieldFontSize => 'Tamanho da fonte';

  @override
  String get fileBack => 'Voltar ao documento';

  @override
  String get recentTitle => 'Recentes';

  @override
  String get recentEmpty => 'Nenhum arquivo recente.';

  @override
  String get preferencesTitle => 'Preferências';

  @override
  String get prefTheme => 'Tema';

  @override
  String get prefShortcuts => 'Atalhos de teclado';

  @override
  String get schemeWordPt =>
      'Word em português (Ctrl+N negrito, Ctrl+B salvar)';

  @override
  String get schemeWordEn => 'Word em inglês (Ctrl+B negrito, Ctrl+S salvar)';

  @override
  String get themeClaro => 'Claro';

  @override
  String get themeEscuro => 'Escuro';

  @override
  String readOnlyBanner(String owner) {
    return 'Só leitura: $owner está com este arquivo aberto. Para editar, salve uma cópia.';
  }

  @override
  String get readOnlySaveCopy => 'Salvar uma cópia…';

  @override
  String get unsavedTitle => 'Salvar as alterações?';

  @override
  String unsavedBody(String name) {
    return '“$name” tem alterações que ainda não foram salvas.';
  }

  @override
  String get unsavedSave => 'Salvar';

  @override
  String get unsavedDiscard => 'Não salvar';

  @override
  String get unsavedCancel => 'Cancelar';

  @override
  String get untitled => 'Documento sem título';

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
    return '$name (só leitura) — Psito Quill';
  }

  @override
  String get fileTypeDocuments => 'Documentos (ODT, DOCX)';

  @override
  String get formatOdt => 'Documento ODF (.odt)';

  @override
  String get formatDocx => 'Documento do Word (.docx)';

  @override
  String statusPage(int page, int pages) {
    return 'Página $page de $pages';
  }

  @override
  String statusWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palavras',
      one: '1 palavra',
    );
    return '$_temp0';
  }

  @override
  String statusWordsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palavras selecionadas',
      one: '1 palavra selecionada',
    );
    return '$_temp0';
  }

  @override
  String statusZoom(int percent) {
    return '$percent %';
  }

  @override
  String get statusReadOnly => 'só leitura';

  @override
  String statusOpenFailed(String name, String detail) {
    return 'Não foi possível abrir $name: $detail';
  }
}
