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

  @override
  String get commandFind => 'Localizar';

  @override
  String get commandReplace => 'Substituir';

  @override
  String get commandPalette => 'Paleta de comandos';

  @override
  String get commandInspector => 'Painel Formatar';

  @override
  String get commandRevealFormatting => 'Revelar formatação';

  @override
  String get commandFormattingMarks => 'Marcas de formatação';

  @override
  String get commandSpellOnline => 'Ortografia automática';

  @override
  String get commandInsertImage => 'Imagem…';

  @override
  String get commandInsertTable => 'Tabela…';

  @override
  String get commandPageBreak => 'Quebra de página';

  @override
  String get commandIndentMore => 'Aumentar recuo';

  @override
  String get commandIndentLess => 'Diminuir recuo';

  @override
  String get commandLineSpacing1 => 'Entrelinhas simples';

  @override
  String get commandLineSpacing15 => 'Entrelinhas 1,5';

  @override
  String get commandLineSpacing2 => 'Entrelinhas duplo';

  @override
  String get commandSpaceMore => 'Mais espaço entre parágrafos';

  @override
  String get commandSpaceLess => 'Menos espaço entre parágrafos';

  @override
  String get commandSuperscript => 'Sobrescrito';

  @override
  String get commandSubscript => 'Subscrito';

  @override
  String get commandClearFormatting => 'Limpar formatação direta';

  @override
  String get commandNewStyle => 'Novo estilo a partir da seleção…';

  @override
  String get commandUpdateStyle => 'Atualizar estilo pela seleção';

  @override
  String get commandManageStyles => 'Gerenciar estilos…';

  @override
  String get commandRowAbove => 'Inserir linha acima';

  @override
  String get commandRowBelow => 'Inserir linha abaixo';

  @override
  String get commandColumnLeft => 'Inserir coluna à esquerda';

  @override
  String get commandColumnRight => 'Inserir coluna à direita';

  @override
  String get commandDeleteRow => 'Excluir linha';

  @override
  String get commandDeleteColumn => 'Excluir coluna';

  @override
  String get commandDeleteTable => 'Excluir tabela';

  @override
  String get commandMergeCells => 'Mesclar células';

  @override
  String get commandPortrait => 'Retrato';

  @override
  String get commandLandscape => 'Paisagem';

  @override
  String get commandWrapOff => 'Acima e abaixo do texto';

  @override
  String get commandWrapIdeal => 'Texto em volta';

  @override
  String get commandWrapThrough => 'Atrás do texto';

  @override
  String get commandImageLeft => 'Imagem à esquerda';

  @override
  String get commandImageCenter => 'Imagem no centro';

  @override
  String get commandImageRight => 'Imagem à direita';

  @override
  String get commandAbout => 'Sobre o Psito Quill';

  @override
  String get ribbonInsert => 'Inserir';

  @override
  String get ribbonLayout => 'Layout';

  @override
  String get ribbonReview => 'Revisão';

  @override
  String get ribbonView => 'Exibir';

  @override
  String get ribbonTable => 'Tabela';

  @override
  String get ribbonImage => 'Imagem';

  @override
  String get groupPages => 'Páginas';

  @override
  String get groupTables => 'Tabelas';

  @override
  String get groupIllustrations => 'Ilustrações';

  @override
  String get groupPageSetup => 'Configurar página';

  @override
  String get groupProofing => 'Revisão de texto';

  @override
  String get groupShow => 'Mostrar';

  @override
  String get groupZoom => 'Zoom';

  @override
  String get groupRowsColumns => 'Linhas e colunas';

  @override
  String get groupMerge => 'Mesclar';

  @override
  String get groupArrange => 'Disposição';

  @override
  String get groupEditing => 'Edição';

  @override
  String get groupSpacing => 'Espaçamento';

  @override
  String get fieldPageSize => 'Tamanho';

  @override
  String get fieldMargins => 'Margens';

  @override
  String get pageSizeA4 => 'A4';

  @override
  String get pageSizeA5 => 'A5';

  @override
  String get pageSizeLetter => 'Carta';

  @override
  String get pageSizeBook6x9 => 'Livro 6 × 9 pol.';

  @override
  String get pageSizeBook55x85 => 'Livro 5,5 × 8,5 pol.';

  @override
  String get marginsNormal => 'Normal (2,5 cm)';

  @override
  String get marginsNarrow => 'Estreita (1,27 cm)';

  @override
  String get marginsAbnt => 'ABNT (3 e 2 cm)';

  @override
  String get marginsWide => 'Larga (5 cm dos lados)';

  @override
  String get findField => 'Localizar';

  @override
  String get replaceField => 'Substituir por';

  @override
  String get findNext => 'Próxima';

  @override
  String get findPrevious => 'Anterior';

  @override
  String get findAll => 'Todas';

  @override
  String get replaceOne => 'Substituir';

  @override
  String get replaceAll => 'Substituir todas';

  @override
  String get findMatchCase => 'Diferenciar maiúsculas';

  @override
  String get findWholeWord => 'Palavra inteira';

  @override
  String get findRegex => 'Expressão regular';

  @override
  String get findClose => 'Fechar a busca';

  @override
  String get findNotFound => 'Nada encontrado';

  @override
  String get paletteHint => 'Digite um comando';

  @override
  String get paletteEmpty => 'Nenhum comando com esse nome';

  @override
  String get inspectorTitle => 'Formatar';

  @override
  String get sectionCharacter => 'Caractere';

  @override
  String get sectionParagraph => 'Parágrafo';

  @override
  String get sectionPage => 'Página';

  @override
  String get sectionImage => 'Imagem';

  @override
  String get sectionTable => 'Tabela';

  @override
  String get sectionReveal => 'Revelar formatação';

  @override
  String get sectionStyles => 'Estilos';

  @override
  String get fieldFontColor => 'Cor da fonte';

  @override
  String get fieldHighlight => 'Realce';

  @override
  String get colorAutomatic => 'Automática';

  @override
  String get highlightNone => 'Sem realce';

  @override
  String get fieldIndentLeft => 'Recuo à esquerda';

  @override
  String get fieldIndentRight => 'Recuo à direita';

  @override
  String get fieldIndentFirst => 'Primeira linha';

  @override
  String get fieldSpacing => 'Espaço antes e depois';

  @override
  String get fieldLineSpacing => 'Entrelinhas';

  @override
  String get fieldOrientation => 'Orientação';

  @override
  String get colorBlack => 'Preto';

  @override
  String get colorGray => 'Cinza';

  @override
  String get colorRed => 'Vermelho';

  @override
  String get colorOrange => 'Laranja';

  @override
  String get colorYellow => 'Amarelo';

  @override
  String get colorGreen => 'Verde';

  @override
  String get colorBlue => 'Azul';

  @override
  String get colorPurple => 'Roxo';

  @override
  String get revealParagraphStyle => 'Estilo de parágrafo';

  @override
  String get revealFont => 'Fonte';

  @override
  String get revealEffects => 'Efeitos';

  @override
  String get revealAlignment => 'Alinhamento';

  @override
  String get revealIndents => 'Recuos';

  @override
  String get revealSpacing => 'Espaço antes e depois';

  @override
  String get revealLineSpacing => 'Entrelinhas';

  @override
  String get revealLanguage => 'Idioma';

  @override
  String get revealPageStyle => 'Estilo de página';

  @override
  String get revealColor => 'Cor';

  @override
  String get revealNone => 'nenhum';

  @override
  String get revealOther => 'outro';

  @override
  String get stylesTitle => 'Estilos';

  @override
  String get stylesParagraph => 'Parágrafo';

  @override
  String get stylesCharacter => 'Caractere';

  @override
  String get stylesMine => 'Meus estilos';

  @override
  String get stylesBuiltIn => 'Estilos de fábrica';

  @override
  String get stylesApply => 'Aplicar';

  @override
  String get stylesNewTitle => 'Novo estilo a partir da seleção';

  @override
  String get stylesName => 'Nome do estilo';

  @override
  String get stylesCreate => 'Criar';

  @override
  String get stylesNameTaken => 'Já existe um estilo com esse nome';

  @override
  String get dialogCancel => 'Cancelar';

  @override
  String get dialogClose => 'Fechar';

  @override
  String get stylePreformatted => 'Texto pré-formatado';

  @override
  String get styleFootnote => 'Nota de rodapé';

  @override
  String get styleEndnote => 'Nota de fim';

  @override
  String get styleCaption => 'Legenda';

  @override
  String get styleSignature => 'Assinatura';

  @override
  String get styleFirstLineIndent => 'Primeira linha recuada';

  @override
  String get styleHangingIndent => 'Recuo deslocado';

  @override
  String get styleBodyIndent => 'Corpo de texto recuado';

  @override
  String get styleHeader => 'Cabeçalho';

  @override
  String get styleFooter => 'Rodapé';

  @override
  String get styleTableContents => 'Conteúdo da tabela';

  @override
  String get styleTableHeading => 'Título da tabela';

  @override
  String get styleList => 'Lista';

  @override
  String get styleListContents => 'Conteúdo da lista';

  @override
  String get styleMarginalia => 'Nota na margem';

  @override
  String get styleAppendix => 'Apêndice';

  @override
  String get styleHeadingBase => 'Título (base)';

  @override
  String get styleEmphasis => 'Ênfase';

  @override
  String get styleStrongEmphasis => 'Ênfase forte';

  @override
  String get styleCitation => 'Citação';

  @override
  String get contextIgnore => 'Ignorar';

  @override
  String get contextIgnoreAll => 'Ignorar sempre';

  @override
  String get contextNoSuggestions => 'Sem sugestões';

  @override
  String get themeClassico => 'Clássico 97';

  @override
  String get menuFile => 'Arquivo';

  @override
  String get menuEdit => 'Editar';

  @override
  String get menuView => 'Exibir';

  @override
  String get menuInsert => 'Inserir';

  @override
  String get menuFormat => 'Formatar';

  @override
  String get menuStyles => 'Estilos';

  @override
  String get menuTools => 'Ferramentas';

  @override
  String get menuTable => 'Tabela';

  @override
  String get menuHelp => 'Ajuda';

  @override
  String get menuRecent => 'Recentes';

  @override
  String get menuTheme => 'Tema';

  @override
  String get toolbarStandard => 'Padrão';

  @override
  String get toolbarFormatting => 'Formatação';

  @override
  String aboutText(String version) {
    return 'Um editor de texto para livros longos, sobre o LibreOffice $version.';
  }

  @override
  String findCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ocorrências',
      one: '1 ocorrência',
      zero: 'nenhuma ocorrência',
    );
    return '$_temp0';
  }

  @override
  String findReplaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trocadas',
      one: '1 trocada',
      zero: 'nada trocado',
    );
    return '$_temp0';
  }

  @override
  String tableSize(int columns, int rows) {
    return 'Tabela de $columns × $rows';
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
    return '$value %';
  }

  @override
  String get unitCm => 'cm';

  @override
  String get fileTypeImages => 'Imagens';

  @override
  String get commandFilePanel => 'Recentes e preferências…';
}
