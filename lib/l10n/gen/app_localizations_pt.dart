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
  String get prefPrivacy => 'Privacidade';

  @override
  String get prefKeepRecents => 'Guardar a lista de arquivos recentes';

  @override
  String get prefPrivacyNote =>
      'Nada sai deste computador: sem rede, sem telemetria, sem arquivo de log.';

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
  String get commandPalette => 'Pesquisar';

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
  String get paletteHint => 'Uma palavra do texto ou um comando';

  @override
  String get paletteEmpty => 'Nada encontrado';

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

  @override
  String get outlineTitle => 'Estrutura';

  @override
  String get outlineClose => 'Fechar a estrutura';

  @override
  String get outlineEmpty =>
      'Os títulos do documento aparecem aqui (os estilos Título 1, 2 e 3).';

  @override
  String get railLabel => 'Painéis';

  @override
  String get stylesPanelClose => 'Fechar os estilos';

  @override
  String get ribbonStyles => 'Estilos';

  @override
  String get ribbonCollapse => 'Recolher';

  @override
  String get ribbonCollapseTip => 'Recolher a faixa';

  @override
  String get ribbonExpandTip => 'Mostrar a faixa';

  @override
  String get ribbonTabs => 'Abas da faixa';

  @override
  String get searchCommands => 'Pesquisar no texto e nos comandos';

  @override
  String get inspectorClose => 'Fechar o painel Formatar';

  @override
  String get inspectorSections => 'Seção do painel';

  @override
  String get sectionText => 'Texto';

  @override
  String get fontGrow => 'Aumentar a fonte';

  @override
  String get fontShrink => 'Diminuir a fonte';

  @override
  String get moreStyles => 'Mais estilos';

  @override
  String get commandLineSpacingMenu => 'Entrelinhas';

  @override
  String get zoomSlider => 'Zoom';

  @override
  String zoomPercent(int percent) {
    return '$percent %';
  }

  @override
  String statusStyle(Object name) {
    return 'Estilo: $name';
  }

  @override
  String get commandCollapseRibbon => 'Recolher a faixa';

  @override
  String get commandOutline => 'Painel Estrutura';

  @override
  String get commandStylesPanel => 'Painel Estilos';

  @override
  String get styleSampleBody => 'Era uma vez';

  @override
  String get styleSampleHeading => 'Capítulo';

  @override
  String get styleSampleQuote => 'disse ela';

  @override
  String get styleSampleOther => 'Aa';

  @override
  String styleCardApplied(Object name) {
    return 'Estilo $name, aplicado';
  }

  @override
  String styleCard(Object name) {
    return 'Estilo $name';
  }

  @override
  String colorMenuMore(Object name, Object value) {
    return '$name: $value';
  }

  @override
  String get fieldWidth => 'Largura';

  @override
  String get fieldHeight => 'Altura';

  @override
  String get keepRatio => 'Manter a proporção';

  @override
  String get groupSize => 'Tamanho';

  @override
  String get fontSearch => 'Procurar uma fonte';

  @override
  String get fontInDocument => 'Neste documento';

  @override
  String get fontRecent => 'Recentes';

  @override
  String get fontAll => 'Todas';

  @override
  String get fontSerif => 'Com serifa';

  @override
  String get fontSans => 'Sem serifa';

  @override
  String get fontMono => 'Mono';

  @override
  String get fontNone => 'Nenhuma fonte com esse nome';

  @override
  String get fontFilters => 'Filtrar as fontes';

  @override
  String get stylesSearch => 'Procurar um estilo';

  @override
  String get stylesKind => 'Tipo de estilo';

  @override
  String get stylesFromBook => 'Do livro';

  @override
  String get stylesFromLibreOffice => 'Do LibreOffice';

  @override
  String get stylesNone => 'Nenhum estilo com esse nome';

  @override
  String get revealDirect => 'direto';

  @override
  String get revealFromStyle => 'estilo';

  @override
  String get revealClearDirect => 'Tirar o que é direto';

  @override
  String get rulerFirstLine => 'Recuo da primeira linha';

  @override
  String get rulerLeftIndent => 'Recuo esquerdo';

  @override
  String get rulerRightIndent => 'Recuo direito';

  @override
  String get rulerHorizontal => 'Régua';

  @override
  String get rulerVertical => 'Régua vertical';

  @override
  String get commandRuler => 'Régua';

  @override
  String get prefRulerUnit => 'Unidade da régua';

  @override
  String get unitMm => 'mm';

  @override
  String get unitInch => 'pol';

  @override
  String get unitPt => 'pt';

  @override
  String get layoutLabel => 'Disposição das páginas';

  @override
  String get layoutSingle => 'Uma página';

  @override
  String get layoutMulti => 'Várias páginas';

  @override
  String get layoutBook => 'Livro (pares)';

  @override
  String get themeSepia => 'Sépia';

  @override
  String get commandZen => 'Modo zen';

  @override
  String get zenExitHint => 'Esc ou F11 sai';

  @override
  String get zenFocus => 'Foco no parágrafo';

  @override
  String get zenTypewriter => 'Máquina de escrever';

  @override
  String get zenPaper => 'Papel';

  @override
  String get zenOptions => 'Opções do modo zen';

  @override
  String zenSession(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min nesta sessão',
      one: '1 min nesta sessão',
      zero: 'começou agora',
    );
    return '$_temp0';
  }

  @override
  String get ribbonMoreFont => 'Mais da fonte';

  @override
  String get searchSectionDocument => 'No documento';

  @override
  String get searchSectionCommands => 'Comandos';

  @override
  String get searchSearching => 'Procurando no documento…';

  @override
  String get searchNoHits => 'Nada no documento';

  @override
  String searchPage(int page) {
    return 'p. $page';
  }

  @override
  String searchMoreHits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'e mais $count ocorrências',
      one: 'e mais 1 ocorrência',
    );
    return '$_temp0';
  }

  @override
  String get searchFindOptions => 'Localizar e substituir, com opções…';

  @override
  String searchHitLabel(String text, int page) {
    return '$text, página $page';
  }

  @override
  String searchHitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ocorrências',
      one: '1 ocorrência',
    );
    return '$_temp0';
  }

  @override
  String get railFindReplace => 'Localizar e substituir';

  @override
  String get commandCloseTab => 'Fechar a aba';

  @override
  String get commandNextTab => 'Próxima aba';

  @override
  String get commandPreviousTab => 'Aba anterior';

  @override
  String get tabsLabel => 'Documentos abertos';

  @override
  String tabCloseNamed(String name) {
    return 'Fechar $name';
  }

  @override
  String tabModifiedNamed(String name) {
    return '$name, com alterações não salvas';
  }

  @override
  String get stylesMore => 'Mais estilos';

  @override
  String get railFind => 'Localizar';

  @override
  String get commandKeepWithNext => 'Manter com o próximo';

  @override
  String get commandSeparateFromNext => 'Permitir separar do próximo';

  @override
  String get commandKeepLines => 'Manter as linhas juntas';

  @override
  String get commandSplitLines => 'Permitir dividir as linhas';

  @override
  String get contextStyle => 'Estilo';

  @override
  String get contextParagraph => 'Parágrafo';

  @override
  String get fieldIndents => 'Recuos';

  @override
  String get fieldIndentLeftShort => 'Esquerda';

  @override
  String get fieldIndentFirstShort => '1ª linha';

  @override
  String get fieldIndentRightShort => 'Direita';

  @override
  String get findPanelTitle => 'Localizar e substituir';

  @override
  String get findHitsList => 'Ocorrências no documento';

  @override
  String get commandFitWidth => 'Ajustar à largura';

  @override
  String get commandFitPage => 'Ajustar à página';

  @override
  String get statusZoomTip => 'Zoom';

  @override
  String get statusLanguageTip => 'Idioma e ortografia';

  @override
  String get statusWordsTip => 'Estatísticas do documento';

  @override
  String get statusInfoPages => 'Páginas';

  @override
  String get statusInfoWords => 'Palavras';

  @override
  String get statusInfoCharacters => 'Caracteres';

  @override
  String get statusInfoSelected => 'Palavras selecionadas';

  @override
  String get languageForSelection => 'Idioma da seleção';

  @override
  String get languageForParagraph => 'Idioma do parágrafo';

  @override
  String get languageNone => 'Sem verificação de ortografia';

  @override
  String get languageReset => 'Voltar ao idioma do estilo';

  @override
  String get recentHeading => 'Arquivos recentes';

  @override
  String get recentName => 'Nome';

  @override
  String get recentFolder => 'Pasta';

  @override
  String get recentModified => 'Modificado';

  @override
  String get recentMissing => 'Não encontrado';

  @override
  String get fileInfo => 'Informações';

  @override
  String get infoFolder => 'Pasta';

  @override
  String get infoSize => 'Tamanho';

  @override
  String get infoModified => 'Modificado em';

  @override
  String get infoNotSaved => 'Ainda não foi salvo';

  @override
  String get infoOpenFolder => 'Abrir a pasta do arquivo';

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
  String get decimalSeparator => ',';

  @override
  String get prefStart => 'Ao abrir o Quill sem um arquivo';

  @override
  String get prefStartScreen => 'Tela inicial';

  @override
  String get prefStartBlank => 'Documento em branco';

  @override
  String get startTitle => 'Começar';

  @override
  String get startBlank => 'Documento em branco';

  @override
  String get startOpen => 'Abrir um arquivo…';

  @override
  String get statusMoreInfo => 'Mais informações…';

  @override
  String get commandStatusBar => 'Barra de status';

  @override
  String get groupPageLayout => 'Páginas';

  @override
  String get groupWindow => 'Janela';

  @override
  String get groupModes => 'Modos';

  @override
  String get busyOpening => 'Abrindo…';

  @override
  String get busySaving => 'Salvando…';

  @override
  String get busyWorking => 'Trabalhando…';

  @override
  String get themeHighContrastDark => 'Alto contraste escuro';

  @override
  String get themeHighContrastLight => 'Alto contraste claro';

  @override
  String get prefGeneral => 'Geral';

  @override
  String get prefAppearance => 'Aparência';

  @override
  String get prefAccessibility => 'Acessibilidade';

  @override
  String get prefZoomOnOpen => 'Zoom ao abrir um documento';

  @override
  String get prefUiScale => 'Tamanho da interface';

  @override
  String get prefUiScaleNote =>
      'Tudo cresce junto: o texto, os botões, os ícones e a página. Vale por cima do tamanho do texto do sistema.';

  @override
  String get prefComfortable => 'Botões maiores';

  @override
  String get prefCaretWidth => 'Espessura do cursor do texto';

  @override
  String prefCaretPx(int n) {
    return '$n px';
  }

  @override
  String get prefCaretBlink => 'O cursor do texto pisca';

  @override
  String get prefReduceMotion => 'Reduzir movimento';

  @override
  String get prefReduceMotionNote =>
      'Sem animações na interface. O Quill também segue o pedido do sistema.';

  @override
  String get prefSpellColor => 'Cor da marca de ortografia';

  @override
  String get prefSpellColorNote => 'Vale na próxima vez que o Quill abrir.';

  @override
  String get prefScreenReaderDoc => 'Texto do documento para o leitor de tela';

  @override
  String get prefScreenReaderDocNote =>
      'Liga sozinho quando um leitor de tela está ativo. Ligado, o motor trabalha um pouco mais a cada tecla.';
}
