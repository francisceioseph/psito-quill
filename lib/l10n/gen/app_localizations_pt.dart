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

  @override
  String get menuBook => 'Livro';

  @override
  String get railBinder => 'Fichário';

  @override
  String get binderTitle => 'Fichário';

  @override
  String get commandBinder => 'Fichário';

  @override
  String get commandNewBook => 'Novo livro…';

  @override
  String get commandOpenBook => 'Abrir livro…';

  @override
  String get commandImportManuscript => 'Importar um manuscrito…';

  @override
  String get commandCloseBook => 'Fechar o livro';

  @override
  String get commandNewChapter => 'Novo capítulo';

  @override
  String get commandNewPart => 'Nova parte';

  @override
  String get newChapterTitle => 'Capítulo novo';

  @override
  String get newPartTitle => 'Parte nova';

  @override
  String get firstChapterTitle => 'Capítulo 1';

  @override
  String get importUntitled => 'Abertura';

  @override
  String get chapterStatusDraft => 'Rascunho';

  @override
  String get chapterStatusRevision => 'Revisão';

  @override
  String get chapterStatusDone => 'Pronto';

  @override
  String get binderRename => 'Renomear';

  @override
  String get binderOpen => 'Abrir';

  @override
  String get binderDelete => 'Mandar para a lixeira';

  @override
  String get binderDeleteTitle => 'Mandar para a lixeira?';

  @override
  String binderDeleteChapter(String title) {
    return '“$title” sai do livro. O arquivo vai para a pasta lixeira, dentro do livro, e não é apagado.';
  }

  @override
  String binderDeletePart(String title) {
    return 'A parte “$title” sai do livro. Os capítulos dela continuam, no lugar dela.';
  }

  @override
  String get binderSynopsis => 'Sinopse';

  @override
  String get binderSynopsisHint => 'Do que trata este capítulo';

  @override
  String get binderStatus => 'Status';

  @override
  String get binderLabel => 'Rótulo';

  @override
  String get labelNone => 'Sem rótulo';

  @override
  String get labelRed => 'Vermelho';

  @override
  String get labelOrange => 'Laranja';

  @override
  String get labelGreen => 'Verde';

  @override
  String get labelBlue => 'Azul';

  @override
  String get labelPurple => 'Roxo';

  @override
  String binderWords(int count) {
    return '$count palavras';
  }

  @override
  String get binderKeysHint =>
      'Alt+setas move, F2 renomeia, Delete manda para a lixeira, → e ← mostram as cenas';

  @override
  String get binderEmpty => 'O livro não tem capítulos.';

  @override
  String statusBookWords(String count) {
    return 'livro $count';
  }

  @override
  String get statusBookWordsTip => 'Palavras no livro inteiro';

  @override
  String bookChapterName(String book, String chapter) {
    return '$book — $chapter';
  }

  @override
  String get newBookTitle => 'Novo livro';

  @override
  String get bookTitleLabel => 'Título do livro';

  @override
  String get bookLocationLabel => 'Onde guardar';

  @override
  String bookLocationNote(String folder) {
    return 'O livro vira a pasta “$folder”, com um arquivo por capítulo.';
  }

  @override
  String get chooseFolder => 'Escolher a pasta…';

  @override
  String get chooseFolderButton => 'Escolher';

  @override
  String get createButton => 'Criar';

  @override
  String get importTitle => 'Importar um manuscrito';

  @override
  String get importReading => 'Lendo o manuscrito…';

  @override
  String get importLevel => 'Os capítulos começam nos títulos de';

  @override
  String importLevelN(int level) {
    return 'Nível $level';
  }

  @override
  String importFound(int count) {
    return '$count capítulos';
  }

  @override
  String get importPartsNote => 'Os títulos de nível acima viram partes.';

  @override
  String get importButton => 'Importar';

  @override
  String importProgress(int done, int total) {
    return 'Importando o capítulo $done de $total…';
  }

  @override
  String importChapterWords(String title, int count) {
    return '$title · $count palavras';
  }

  @override
  String get fileTypeManuscripts => 'Manuscritos';

  @override
  String get bookErrorMissing => 'O livro não foi encontrado.';

  @override
  String get bookErrorInvalid => 'Esta pasta não tem um livro do Quill.';

  @override
  String get bookErrorExists => 'Já existe um livro nesta pasta.';

  @override
  String get bookErrorWrite => 'Não deu para gravar o livro.';

  @override
  String get importErrorUnreadable =>
      'O LibreOffice não conseguiu ler este manuscrito.';

  @override
  String get importErrorEmpty => 'O manuscrito não tem texto.';

  @override
  String get startNewBook => 'Novo livro';

  @override
  String get startImport => 'Importar um manuscrito';

  @override
  String get recentBook => 'Livro';

  @override
  String get binderClose => 'Fechar o fichário';

  @override
  String get prefAutosave => 'Salvamento automático';

  @override
  String get prefAutosaveNote =>
      'A cada minuto com alterações, uma cópia de recuperação fica no seu computador, na pasta do Quill. Se o Quill fechar sem querer, ela aparece na tela inicial.';

  @override
  String get recoverHeading => 'Recuperar arquivos';

  @override
  String get recoverNote =>
      'O Quill fechou sem salvar estes documentos. Recuperar abre a cópia como um documento novo; salve-o para ficar com ele.';

  @override
  String recoverRow(String name, String when) {
    return '$name, cópia de $when';
  }

  @override
  String get recoverOpen => 'Recuperar';

  @override
  String get recoverDiscard => 'Descartar';

  @override
  String get recoverDiscardTitle => 'Descartar a cópia?';

  @override
  String recoverDiscardBody(String name) {
    return 'A cópia de recuperação de “$name” será apagada. O arquivo salvo, se houver, não muda.';
  }

  @override
  String recoveredName(String name) {
    return '$name (recuperado)';
  }

  @override
  String get commandHeader => 'Cabeçalho';

  @override
  String get commandFooter => 'Rodapé';

  @override
  String get commandRemoveHeader => 'Remover o cabeçalho';

  @override
  String get commandRemoveFooter => 'Remover o rodapé';

  @override
  String get commandFirstPageDifferent => 'Primeira página diferente';

  @override
  String get commandLeftRightDifferent => 'Páginas pares diferentes';

  @override
  String get commandPageNumber => 'Número de página';

  @override
  String get commandPageCount => 'Total de páginas';

  @override
  String get commandDateField => 'Data';

  @override
  String get commandTimeField => 'Hora';

  @override
  String get commandHyphenation => 'Hifenização automática';

  @override
  String get commandHyphenateParagraph => 'Hifenizar este parágrafo';

  @override
  String get commandNoHyphenateParagraph => 'Não hifenizar este parágrafo';

  @override
  String commandDropCap(int n) {
    return 'Letra capitular ($n linhas)';
  }

  @override
  String get commandRemoveDropCap => 'Remover a capitular';

  @override
  String get commandColumnBreak => 'Quebra de coluna';

  @override
  String get commandBlankPage => 'Página em branco';

  @override
  String get commandExportPdf => 'Exportar como PDF…';

  @override
  String get commandPrint => 'Imprimir…';

  @override
  String get commandFootnote => 'Nota de rodapé';

  @override
  String get commandEndnote => 'Nota de fim';

  @override
  String get commandJumpFootnote => 'Ir para a nota e voltar';

  @override
  String get commandLink => 'Link…';

  @override
  String get commandOpenLink => 'Abrir o link';

  @override
  String get commandRemoveLink => 'Remover o link';

  @override
  String get commandSpecialCharacter => 'Caractere especial…';

  @override
  String get groupHeaderFooter => 'Cabeçalho e rodapé';

  @override
  String get groupNotes => 'Notas';

  @override
  String get groupLinks => 'Links';

  @override
  String get groupSymbols => 'Símbolos';

  @override
  String get groupBreaks => 'Quebras';

  @override
  String get groupHyphenation => 'Hifenização';

  @override
  String get groupFields => 'Campos';

  @override
  String get groupTypography => 'Tipografia';

  @override
  String get exportPdfFilter => 'Documento PDF';

  @override
  String noticeExported(String path) {
    return 'Exportado: $path';
  }

  @override
  String get noticeExportFailed => 'Não foi possível exportar o PDF.';

  @override
  String get noticePrinted => 'Enviado à impressora.';

  @override
  String noticePrintFailed(String detail) {
    return 'Não foi possível imprimir: $detail';
  }

  @override
  String get noticePrintNoPdf => 'A impressora escolhida não aceita PDF.';

  @override
  String get noticeStyleFailed => 'O motor não aplicou a mudança na página.';

  @override
  String get linkDialogTitle => 'Link';

  @override
  String get linkText => 'Texto';

  @override
  String get linkUrl => 'Endereço';

  @override
  String get linkApply => 'Aplicar';

  @override
  String get openLinkTitle => 'Abrir o link?';

  @override
  String openLinkBody(String url) {
    return 'O Quill vai pedir ao sistema para abrir este endereço. Se for um site, isso acessa a internet:\n$url';
  }

  @override
  String get noticeLinkScheme =>
      'O Quill só abre endereços da web (http, https) e de e-mail (mailto).';

  @override
  String get openLinkButton => 'Abrir';

  @override
  String get specialCharsTitle => 'Caracteres especiais';

  @override
  String get specialCharsSearch => 'Buscar pelo nome';

  @override
  String get specialCharsEmpty => 'Nenhum caractere com esse nome.';

  @override
  String specialCharInsert(String name, String char) {
    return '$name ($char)';
  }

  @override
  String get pageSectionHeaderFooter => 'Cabeçalho e rodapé';

  @override
  String get charEmDash => 'travessão';

  @override
  String get charEnDash => 'meia-risca';

  @override
  String get charEllipsis => 'reticências';

  @override
  String get charLeftDoubleQuote => 'aspas curvas de abrir';

  @override
  String get charRightDoubleQuote => 'aspas curvas de fechar';

  @override
  String get charLeftSingleQuote => 'aspa simples de abrir';

  @override
  String get charRightSingleQuote => 'aspa simples de fechar, apóstrofo';

  @override
  String get charLeftGuillemet => 'aspas angulares de abrir';

  @override
  String get charRightGuillemet => 'aspas angulares de fechar';

  @override
  String get charNoBreakSpace => 'espaço sem quebra';

  @override
  String get charNarrowNoBreakSpace => 'espaço fino sem quebra';

  @override
  String get charSoftHyphen => 'hífen opcional';

  @override
  String get charNoBreakHyphen => 'hífen sem quebra';

  @override
  String get charAsterism => 'asterismo (separador de cena)';

  @override
  String get charFleuron => 'florão';

  @override
  String get charSection => 'parágrafo (seção)';

  @override
  String get charPilcrow => 'pé-de-mosca';

  @override
  String get charDagger => 'adaga';

  @override
  String get charDoubleDagger => 'adaga dupla';

  @override
  String get charBullet => 'marcador';

  @override
  String get charMiddleDot => 'ponto médio';

  @override
  String get charDegree => 'grau';

  @override
  String get charOrdinalA => 'ordinal feminino';

  @override
  String get charOrdinalO => 'ordinal masculino';

  @override
  String get charCopyright => 'direitos autorais';

  @override
  String get charRegistered => 'marca registrada';

  @override
  String get charTrademark => 'marca';

  @override
  String get charTimes => 'vezes';

  @override
  String get charDivide => 'dividido';

  @override
  String get charPlusMinus => 'mais ou menos';

  @override
  String get charApprox => 'aproximadamente';

  @override
  String get charNotEqual => 'diferente';

  @override
  String get charLessEqual => 'menor ou igual';

  @override
  String get charGreaterEqual => 'maior ou igual';

  @override
  String get charHalf => 'meio';

  @override
  String get charQuarter => 'um quarto';

  @override
  String get charThreeQuarters => 'três quartos';

  @override
  String get charEuro => 'euro';

  @override
  String get charPound => 'libra';

  @override
  String get charYen => 'iene';

  @override
  String get charArrowRight => 'seta para a direita';

  @override
  String get charArrowLeft => 'seta para a esquerda';

  @override
  String get charStar => 'estrela';

  @override
  String get charPrime => 'linha (minuto, pé)';

  @override
  String get charDoublePrime => 'linha dupla (segundo, polegada)';

  @override
  String binderScenes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cenas',
      one: '1 cena',
    );
    return '$_temp0';
  }

  @override
  String binderScene(int number) {
    return 'Cena $number';
  }

  @override
  String get binderSceneHint =>
      'Enter leva à cena; seta para a esquerda volta ao capítulo';

  @override
  String get commandNewScene => 'Nova cena';

  @override
  String get commandSplitChapter => 'Dividir o capítulo aqui';

  @override
  String get commandJoinChapter => 'Juntar com o próximo capítulo';

  @override
  String get commandConvertScenes => 'Converter os separadores em cenas';

  @override
  String splitContinuationTitle(String title) {
    return '$title (continuação)';
  }

  @override
  String splitDone(String title) {
    return 'O resto do capítulo virou “$title”, logo depois dele';
  }

  @override
  String get splitNothing =>
      'Não há o que dividir: o cursor está no começo ou no fim do capítulo';

  @override
  String get splitFailed =>
      'Não deu para dividir o capítulo. O texto ficou como estava.';

  @override
  String get joinConfirmTitle => 'Juntar os capítulos?';

  @override
  String joinConfirmBody(String next, String current) {
    return 'O texto de “$next” vai para o fim de “$current”, que é salvo. O arquivo de “$next” vai para a lixeira do livro.';
  }

  @override
  String get joinConfirm => 'Juntar';

  @override
  String joinDone(String title) {
    return '“$title” foi juntado a este capítulo';
  }

  @override
  String get joinNoNext => 'Este é o último capítulo do livro';

  @override
  String joinNextModified(String title) {
    return 'Salve ou feche “$title” antes de juntar';
  }

  @override
  String get joinFailed => 'Não deu para juntar os capítulos';

  @override
  String scenesConverted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count separadores viraram cenas',
      one: '1 separador virou cena',
    );
    return '$_temp0';
  }

  @override
  String get scenesNone => 'Nenhum separador solto (* * *, #) neste documento';

  @override
  String get scenesFailed => 'Não deu para criar o estilo Cena';

  @override
  String importScenes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count separadores de cena (* * *) vão para o estilo Cena',
      one: '1 separador de cena (* * *) vai para o estilo Cena',
    );
    return '$_temp0';
  }

  @override
  String get busyWorkingChapters => 'Reorganizando os capítulos';

  @override
  String get findScope => 'Onde buscar';

  @override
  String get findScopeChapter => 'Neste capítulo';

  @override
  String get findScopeBook => 'No livro';

  @override
  String get findBadRegex => 'A expressão regular não vale';

  @override
  String get bookHitsList => 'Ocorrências no livro';

  @override
  String bookHitsCount(int count, int chapters) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ocorrências',
      one: '1 ocorrência',
    );
    String _temp1 = intl.Intl.pluralLogic(
      chapters,
      locale: localeName,
      other: '$chapters capítulos',
      one: '1 capítulo',
    );
    return '$_temp0 em $_temp1';
  }

  @override
  String bookChapterHits(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ocorrências',
      one: '1 ocorrência',
    );
    return '$title, $_temp0';
  }

  @override
  String bookMoreHits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mais $count neste capítulo: abra-o e busque nele',
      one: 'Mais 1 neste capítulo: abra-o e busque nele',
    );
    return '$_temp0';
  }

  @override
  String bookHitLabel(String text, String chapter, int page) {
    return '$text, $chapter, página $page';
  }

  @override
  String bookUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capítulos não puderam ser lidos',
      one: '1 capítulo não pôde ser lido',
    );
    return '$_temp0';
  }

  @override
  String get commandTakeSnapshot => 'Guardar um instantâneo do capítulo';

  @override
  String get commandSnapshots => 'Instantâneos do capítulo…';

  @override
  String get binderSnapshots => 'Instantâneos…';

  @override
  String snapshotsTitle(String chapter) {
    return 'Instantâneos de $chapter';
  }

  @override
  String get snapshotName => 'Nome do instantâneo (opcional)';

  @override
  String get snapshotTake => 'Guardar agora';

  @override
  String get snapshotsEmpty =>
      'Nenhum instantâneo ainda. Um instantâneo guarda o capítulo como está agora, para comparar ou voltar a ele depois.';

  @override
  String get snapshotAuto => 'Automático';

  @override
  String get snapshotUnnamed => 'Sem nome';

  @override
  String snapshotWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palavras',
      one: '1 palavra',
    );
    return '$_temp0';
  }

  @override
  String get snapshotCompare => 'Abrir ao lado, só para leitura';

  @override
  String get snapshotRestore => 'Restaurar';

  @override
  String get snapshotDelete => 'Apagar';

  @override
  String get snapshotRestoreTitle => 'Restaurar o instantâneo?';

  @override
  String snapshotRestoreBody(String when) {
    return 'O capítulo volta a como estava em $when. O texto de agora, com o que não foi salvo, fica guardado num instantâneo \"Antes de restaurar\".';
  }

  @override
  String get snapshotBeforeRestore => 'Antes de restaurar';

  @override
  String get snapshotDeleteTitle => 'Apagar o instantâneo?';

  @override
  String snapshotDeleteBody(String when) {
    return 'O instantâneo de $when vai para a lixeira do livro.';
  }

  @override
  String snapshotTaken(String chapter) {
    return 'Instantâneo de $chapter guardado';
  }

  @override
  String get snapshotFailed => 'Não deu para guardar o instantâneo';

  @override
  String snapshotRestored(String when) {
    return 'O capítulo voltou a $when';
  }

  @override
  String get snapshotRestoreFailed => 'Não deu para restaurar o instantâneo';

  @override
  String get snapshotCompareFailed => 'Não deu para abrir o instantâneo';

  @override
  String get prefAutoSnapshots => 'Instantâneo automático dos capítulos';

  @override
  String get prefAutoSnapshotsNote =>
      'No primeiro salvamento de cada dia, o Quill guarda como o capítulo estava antes, na pasta \"versoes\" do livro. Ficam os 30 últimos de cada capítulo.';

  @override
  String snapshotLabel(String chapter, String when) {
    return '$chapter, $when';
  }

  @override
  String snapshotTab(String label) {
    return 'Instantâneo: $label';
  }

  @override
  String snapshotViewingBanner(String label) {
    return 'Instantâneo de $label, só para leitura. Para comparar, passe para a aba do capítulo e volte.';
  }

  @override
  String get snapshotCloseView => 'Fechar o instantâneo';

  @override
  String get railNotes => 'Notas';

  @override
  String get commandNotes => 'Notas do livro';

  @override
  String get commandNewNote => 'Nova nota';

  @override
  String get notesTitle => 'Notas';

  @override
  String get notesClose => 'Fechar as notas';

  @override
  String get notesSearch => 'Buscar nas notas';

  @override
  String get notesAll => 'Todas';

  @override
  String get notesEmpty =>
      'Nenhuma nota ainda. Personagens, lugares, facções, termos e a linha do tempo ficam aqui, na pasta \"notas\" do livro.';

  @override
  String get notesNoMatch => 'Nenhuma nota com isso.';

  @override
  String get notesBack => 'Voltar às notas';

  @override
  String get noteNewName => 'Nova nota';

  @override
  String get noteDelete => 'Mandar a nota para a lixeira';

  @override
  String get noteDeleteTitle => 'Mandar a nota para a lixeira?';

  @override
  String noteDeleteBody(String name) {
    return 'A nota \"$name\" vai para a lixeira do livro.';
  }

  @override
  String get noteName => 'Nome';

  @override
  String get noteKind => 'Tipo';

  @override
  String get noteAliases => 'Apelidos';

  @override
  String get noteAliasesHint => 'Apelidos, separados por vírgula';

  @override
  String get noteText => 'Texto';

  @override
  String get noteTextHint =>
      'Escreva aqui. [[Nome]] liga a outra nota ou a um capítulo.';

  @override
  String get noteLinks => 'Ligações';

  @override
  String get noteMentions => 'Mencionada em';

  @override
  String noteCreateLink(String name) {
    return 'Criar $name';
  }

  @override
  String get noteTimelineEmpty =>
      'Nenhum evento ainda. Escreva um por linha, no Texto: \"- Ano 3: a Poeira chega\".';

  @override
  String get noteKindCharacter => 'Personagem';

  @override
  String get noteKindPlace => 'Lugar';

  @override
  String get noteKindFaction => 'Facção';

  @override
  String get noteKindTerm => 'Termo';

  @override
  String get noteKindTimeline => 'Linha do tempo';

  @override
  String get noteKindCharacters => 'Personagens';

  @override
  String get noteKindPlaces => 'Lugares';

  @override
  String get noteKindFactions => 'Facções';

  @override
  String get noteKindTerms => 'Termos';

  @override
  String get commandGoals => 'Metas…';

  @override
  String statusGoalToday(String done, String goal) {
    return 'meta hoje $done/$goal';
  }

  @override
  String get statusGoalTodayTip => 'A meta de palavras de hoje';

  @override
  String statusGoalSession(String done, String goal) {
    return 'sessão $done/$goal';
  }

  @override
  String zenGoal(String done, String goal) {
    return 'meta $done/$goal';
  }

  @override
  String goalsTitle(String book) {
    return 'Metas de $book';
  }

  @override
  String get goalsBook => 'Palavras do livro';

  @override
  String get goalsDaily => 'Palavras por dia';

  @override
  String get goalsSession => 'Palavras nesta sessão';

  @override
  String get goalsEmptyHint => 'Vazio: sem meta';

  @override
  String get goalsSessionHint => 'A meta da sessão vale até fechar o livro.';

  @override
  String get goalsDeadline => 'Prazo';

  @override
  String get goalsNoDeadline => 'Sem prazo';

  @override
  String get goalsPickDeadline => 'Escolher o prazo';

  @override
  String get goalsClearDeadline => 'Tirar o prazo';

  @override
  String goalsBookProgress(String words, String goal, int percent) {
    return 'Livro: $words de $goal palavras ($percent%)';
  }

  @override
  String goalsBookWords(String words) {
    return 'Livro: $words palavras';
  }

  @override
  String goalsPace(String words, String perDay) {
    return 'Faltam $words palavras: $perDay por dia';
  }

  @override
  String goalsDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'faltam $days dias',
      one: 'falta 1 dia',
      zero: 'o prazo passou',
    );
    return '$_temp0';
  }

  @override
  String get goalsReached => 'A meta do livro foi alcançada.';

  @override
  String goalsToday(String words, String goal) {
    return 'Hoje: $words de $goal';
  }

  @override
  String goalsTodayWords(String words) {
    return 'Hoje: $words palavras';
  }

  @override
  String goalsSessionProgress(String words, String goal) {
    return 'Sessão: $words de $goal';
  }

  @override
  String get goalsChartTitle => 'Os últimos 30 dias';

  @override
  String goalsChartLabel(String total, String best) {
    return 'Os últimos 30 dias: $total palavras, $best no melhor dia';
  }

  @override
  String get goalsSave => 'Salvar';

  @override
  String get commandCorkboard => 'Cortiça';

  @override
  String corkTitle(String book) {
    return 'Cortiça de $book';
  }

  @override
  String get corkScope => 'Os cartões de';

  @override
  String get corkAll => 'Todos os capítulos';

  @override
  String get corkBack => 'Voltar à página';

  @override
  String get corkEmpty => 'Nenhum capítulo aqui.';

  @override
  String corkWords(String count) {
    return '$count palavras';
  }

  @override
  String get corkSynopsis => 'Sinopse';

  @override
  String get corkNoSynopsis => 'Sem sinopse';

  @override
  String get corkEditSynopsis => 'Editar a sinopse';

  @override
  String get corkKeysHint =>
      'Setas andam, Alt+setas movem, Enter abre, F2 edita a sinopse, Esc volta à página';

  @override
  String get commandCompile => 'Compilar o livro…';

  @override
  String compileTitle(String book) {
    return 'Compilar $book';
  }

  @override
  String get compileChapters => 'Capítulos';

  @override
  String compileChapterCount(int count, int total, String words) {
    return '$count de $total capítulos · $words palavras';
  }

  @override
  String get compileSelectAll => 'Todos';

  @override
  String get compileSelectDone => 'Só os prontos';

  @override
  String get compileSelectNone => 'Nenhum';

  @override
  String get compileTitlePage => 'Folha de rosto';

  @override
  String get compileBookTitle => 'Título';

  @override
  String get compileSubtitle => 'Subtítulo';

  @override
  String get compileAuthor => 'Autor';

  @override
  String get compileToc => 'Sumário';

  @override
  String get compileTocTitle => 'Título do sumário';

  @override
  String get compileTocDefault => 'Sumário';

  @override
  String get compilePageBreaks => 'Cada capítulo começa numa página nova';

  @override
  String get compilePartTitles => 'O título de cada parte numa página própria';

  @override
  String get compileChapterTitles =>
      'O título do capítulo entra quando ele não começa por um título';

  @override
  String get compileScenes => 'Separador de cena';

  @override
  String get compileScenesKeep => 'Como está (estilo Cena)';

  @override
  String get compileScenesStars => '* * *';

  @override
  String get compileScenesHash => '#';

  @override
  String get compileFormat => 'Formato';

  @override
  String get compileFormatPdf => 'PDF, com marcadores';

  @override
  String get compileFormatEpub => 'EPUB, livro digital';

  @override
  String get compileFormatDocx => 'DOCX, Word';

  @override
  String get compileFormatOdt => 'ODT, LibreOffice';

  @override
  String compileFileFilter(String format) {
    return 'Livro em $format';
  }

  @override
  String get compileRun => 'Compilar…';

  @override
  String compileProgressChapters(int done, int total) {
    return 'Lendo o capítulo $done de $total';
  }

  @override
  String get compileProgressJoining => 'Juntando os capítulos';

  @override
  String get compileProgressWriting =>
      'Gravando o livro (o motor monta todas as páginas)';

  @override
  String compileDone(String path) {
    return 'Livro compilado em $path';
  }

  @override
  String compileFailedChapter(String chapter) {
    return 'Não deu para ler o capítulo \"$chapter\".';
  }

  @override
  String get compileFailed => 'Não deu para gravar o livro compilado.';

  @override
  String get compileNoChapters => 'Nenhum capítulo escolhido.';

  @override
  String get compileCancelled => 'Compilar cancelado.';

  @override
  String get compileModel => 'Modelo';

  @override
  String get compileModelNone => 'Sem modelo';

  @override
  String get compileModelManuscript => 'Manuscrito';

  @override
  String get compileModelSixByNine => 'Livro 6×9';

  @override
  String get compileModelEbook => 'E-book';

  @override
  String compileModelChanged(String name) {
    return '$name (alterado)';
  }

  @override
  String get compileModelSave => 'Salvar como modelo…';

  @override
  String get compileModelRename => 'Renomear…';

  @override
  String get compileModelDelete => 'Apagar o modelo';

  @override
  String get compileModelName => 'Nome do modelo';

  @override
  String get compileModelSaveTitle => 'Salvar como modelo';

  @override
  String get compileModelRenameTitle => 'Renomear o modelo';

  @override
  String get compileModelOk => 'Salvar';

  @override
  String compileModelSaved(String name) {
    return 'Modelo \"$name\" salvo no livro.';
  }

  @override
  String compileModelDeleted(String name) {
    return 'Modelo \"$name\" apagado.';
  }

  @override
  String get compileModelWriteFailed =>
      'Não deu para gravar o compilar.json do livro.';

  @override
  String get compileLook => 'Aparência';

  @override
  String get compileKeep => 'A do capítulo';

  @override
  String get compilePage => 'Página';

  @override
  String get compilePageA4 => 'A4';

  @override
  String get compilePageLetter => 'Carta';

  @override
  String get compilePageA5 => 'A5';

  @override
  String get compilePageSixByNine => '15,24 × 22,86 cm (6×9, espelhada)';

  @override
  String get compileFont => 'Fonte do corpo';

  @override
  String get compileFontSize => 'Tamanho do corpo';

  @override
  String compileFontSizePt(int size) {
    return '$size pt';
  }

  @override
  String get compileSpacing => 'Espaçamento';

  @override
  String get compileSpacingSingle => 'Simples';

  @override
  String get compileSpacingOneHalf => '1,5 linha';

  @override
  String get compileSpacingDouble => 'Duplo';

  @override
  String get compileIndent => 'Recuo da primeira linha';

  @override
  String get compileIndentOn => 'Com recuo';

  @override
  String get compileIndentOff => 'Sem recuo';

  @override
  String get compileHeaders => 'Cabeçalhos';

  @override
  String get compileHeadersNone => 'Nenhum';

  @override
  String get compileHeadersManuscript => 'Sobrenome / título / página';

  @override
  String get compileHeadersBook => 'Alternados: o livro e o capítulo';

  @override
  String get compileRightPage => 'Cada capítulo começa numa página ímpar';

  @override
  String get compileCover => 'Capa';

  @override
  String get compileCoverNone => 'Sem capa';

  @override
  String get compileCoverPick => 'Escolher a imagem…';

  @override
  String get compileCoverRemove => 'Tirar a capa';

  @override
  String get menuReview => 'Revisar';

  @override
  String get groupComments => 'Comentários';

  @override
  String get commandNewComment => 'Novo comentário';

  @override
  String get commandComments => 'Painel Comentários';

  @override
  String get railComments => 'Comentários';

  @override
  String get commentsTitle => 'Comentários';

  @override
  String get commentsClose => 'Fechar os comentários';

  @override
  String get commentsNew => 'Novo comentário';

  @override
  String get commentsNewHint => 'Selecione um trecho e escreva aqui';

  @override
  String get commentsAdd => 'Comentar';

  @override
  String commentsShowResolved(int count) {
    return 'Mostrar os resolvidos ($count)';
  }

  @override
  String get commentsEmpty =>
      'Nenhum comentário neste capítulo. Selecione um trecho, escreva acima e clique em Comentar (Ctrl+Alt+C).';

  @override
  String get commentsAllResolved => 'Todos os comentários estão resolvidos.';

  @override
  String get commentsReply => 'Responder';

  @override
  String get commentsReplyField => 'Resposta';

  @override
  String get commentsSend => 'Responder';

  @override
  String get commentsCancel => 'Cancelar';

  @override
  String get commentsResolve => 'Resolver';

  @override
  String get commentsReopen => 'Reabrir';

  @override
  String get commentsDelete => 'Excluir a conversa';

  @override
  String get commentsResolved => 'Resolvido';

  @override
  String get commentsNoAuthor => 'Sem autor';

  @override
  String commentsOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comentários abertos',
      one: '1 comentário aberto',
    );
    return '$_temp0';
  }

  @override
  String get prefAuthorName => 'Seu nome nos comentários';

  @override
  String prefAuthorNameNote(String name) {
    return 'Vazio: o nome da sua conta ($name). Vale para os capítulos abertos depois.';
  }

  @override
  String get modeEditing => 'Editando';

  @override
  String get modeReview => 'Revisão';

  @override
  String get modeReading => 'Leitura';

  @override
  String get modeLabel => 'Modo';

  @override
  String get modeReadingExit => 'Sair da leitura (Esc)';

  @override
  String get modeReadingHint => 'As setas e o Page Down folheiam.';

  @override
  String get groupTracking => 'Controle';

  @override
  String get groupChanges => 'Alterações';

  @override
  String get groupReading => 'Leitura';

  @override
  String get commandChanges => 'Painel Alterações';

  @override
  String get commandShowChanges => 'Mostrar as alterações';

  @override
  String get commandPreviousChange => 'Alteração anterior';

  @override
  String get commandNextChange => 'Próxima alteração';

  @override
  String get commandAcceptChange => 'Aceitar a alteração';

  @override
  String get commandRejectChange => 'Rejeitar a alteração';

  @override
  String get commandAcceptAll => 'Aceitar todas';

  @override
  String get commandRejectAll => 'Rejeitar todas';

  @override
  String get railChanges => 'Alterações';

  @override
  String get changesTitle => 'Alterações';

  @override
  String get changesClose => 'Fechar as alterações';

  @override
  String get changesTracking => 'Revisão: marcar o que eu mudar';

  @override
  String get changesShow => 'Mostrar na página';

  @override
  String get changesEmpty =>
      'Nenhuma alteração neste capítulo. Ligue a Revisão (Ctrl+Shift+E) para marcar o que você mudar.';

  @override
  String changesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alterações',
      one: '1 alteração',
    );
    return '$_temp0';
  }

  @override
  String get changesAccept => 'Aceitar';

  @override
  String get changesReject => 'Rejeitar';

  @override
  String get changeInsert => 'Inserção';

  @override
  String get changeDelete => 'Exclusão';

  @override
  String get changeFormat => 'Formatação';

  @override
  String get changeOther => 'Alteração';

  @override
  String get ribbonReferences => 'Referências';

  @override
  String get menuReferences => 'Referências';

  @override
  String get groupToc => 'Sumário';

  @override
  String get groupCaptions => 'Legendas';

  @override
  String get groupBookmarks => 'Marcadores';

  @override
  String get groupIndex => 'Índice remissivo';

  @override
  String get commandTocHere => 'Inserir o sumário';

  @override
  String get tocTitleDefault => 'Sumário';

  @override
  String get commandUpdateIndexes => 'Atualizar o sumário e os índices';

  @override
  String get commandCaption => 'Inserir a legenda';

  @override
  String get captionFigure => 'Figura';

  @override
  String get captionTable => 'Tabela';

  @override
  String get commandFigureTable => 'Índice de figuras';

  @override
  String get figureTableTitle => 'Índice de figuras';

  @override
  String get commandTableTable => 'Índice de tabelas';

  @override
  String get tableTableTitle => 'Índice de tabelas';

  @override
  String get commandBookmark => 'Marcador';

  @override
  String get commandCrossReference => 'Referência cruzada';

  @override
  String get commandMarkEntry => 'Marcar a entrada do índice';

  @override
  String get commandMarkAll => 'Marcar todas as ocorrências';

  @override
  String get commandIndex => 'Inserir o índice remissivo';

  @override
  String get indexTitle => 'Índice remissivo';

  @override
  String get bookmarkDialogTitle => 'Marcadores';

  @override
  String get bookmarkName => 'Nome do marcador novo';

  @override
  String get bookmarkBadName =>
      'O nome não pode começar por _ nem ter / \\ @ : * ? \" ; , . # |';

  @override
  String get bookmarkExists => 'Já existe um marcador com esse nome.';

  @override
  String get bookmarkListTitle => 'Neste capítulo';

  @override
  String get bookmarkNone => 'Nenhum marcador ainda.';

  @override
  String bookmarkGo(String name) {
    return 'Ir para $name';
  }

  @override
  String bookmarkDelete(String name) {
    return 'Excluir $name';
  }

  @override
  String get bookmarkInsert => 'Inserir';

  @override
  String get crossRefTitle => 'Referência cruzada';

  @override
  String get crossRefKind => 'Referência a';

  @override
  String get crossRefHeadings => 'Títulos';

  @override
  String get crossRefBookmarks => 'Marcadores';

  @override
  String get crossRefCaptions => 'Legendas';

  @override
  String get crossRefNoHeadings => 'Nenhum título neste capítulo.';

  @override
  String get crossRefNoCaptions =>
      'Nenhuma legenda neste capítulo. Selecione uma imagem ou entre numa tabela e use Inserir a legenda.';

  @override
  String get crossRefInsertAs => 'Inserir como';

  @override
  String get crossRefFormatText => 'O texto';

  @override
  String get crossRefFormatCaption => 'Figura e número';

  @override
  String get crossRefFormatPage => 'A página';

  @override
  String get crossRefFormatAboveBelow => 'Acima ou abaixo';

  @override
  String get crossRefInsert => 'Inserir';

  @override
  String crossRefOtherChapter(String bookmark, String chapter) {
    return '$bookmark (em $chapter)';
  }

  @override
  String get compileIndex => 'Índice remissivo no fim';

  @override
  String get compileFigures => 'Índice de figuras depois do sumário';

  @override
  String get compileReferencesNote =>
      'As entradas marcadas nos capítulos e as legendas das imagens entram aqui.';

  @override
  String get commandParagraph => 'Parágrafo…';

  @override
  String get paragraphDialogTitle => 'Parágrafo';

  @override
  String get paragraphDialogParts => 'Partes do parágrafo';

  @override
  String get paragraphPartBackground => 'Fundo';

  @override
  String get paragraphPartSpacing => 'Intervalo';

  @override
  String get paragraphPartBorders => 'Bordas';

  @override
  String get paragraphPartTabs => 'Tabulações';

  @override
  String get paragraphBackground => 'Cor de fundo do parágrafo';

  @override
  String get paragraphBackgroundNone => 'Sem cor de fundo';

  @override
  String get paragraphBackgroundNote =>
      'A cor vale para os parágrafos selecionados, de uma margem à outra.';

  @override
  String get paragraphNoSpaceSameStyle =>
      'Não adicionar intervalo entre parágrafos do mesmo estilo';

  @override
  String get paragraphNoSpaceNote =>
      'A caixa começa como o estilo do parágrafo está: o motor não diz o que foi mudado só neste parágrafo.';

  @override
  String get paragraphApply => 'Aplicar';

  @override
  String get borderSides => 'Onde';

  @override
  String get borderNone => 'Nenhuma';

  @override
  String get borderBox => 'Em volta';

  @override
  String get borderTop => 'Em cima';

  @override
  String get borderBottom => 'Embaixo';

  @override
  String get borderTopBottom => 'Em cima e embaixo';

  @override
  String get borderLeft => 'À esquerda';

  @override
  String get borderWeight => 'Espessura';

  @override
  String get borderThin => 'Fina';

  @override
  String get borderMedium => 'Média';

  @override
  String get borderThick => 'Grossa';

  @override
  String get borderColor => 'Cor da borda';

  @override
  String get tabsCurrent => 'As tabulações do parágrafo';

  @override
  String get tabsNone => 'Nenhuma tabulação, só as automáticas.';

  @override
  String tabsItem(String position, String align, String leader) {
    return '$position, $align, $leader';
  }

  @override
  String tabsRemove(String position) {
    return 'Remover a tabulação em $position';
  }

  @override
  String get tabsNew => 'Nova tabulação';

  @override
  String get tabsPosition => 'Posição em cm';

  @override
  String get tabsAlign => 'Alinhamento';

  @override
  String get tabsLeader => 'Preenchimento';

  @override
  String get tabAlignLeft => 'À esquerda';

  @override
  String get tabAlignCenter => 'Ao centro';

  @override
  String get tabAlignRight => 'À direita';

  @override
  String get tabAlignDecimal => 'Decimal';

  @override
  String get tabLeaderNone => 'Sem preenchimento';

  @override
  String get tabLeaderDots => 'Pontos';

  @override
  String get tabLeaderDashes => 'Traços';

  @override
  String get tabLeaderLine => 'Linha';

  @override
  String get tabsAdd => 'Adicionar';

  @override
  String get tabsClear => 'Remover todas';

  @override
  String get outlineStart => 'Início do documento';

  @override
  String get outlineLevels => 'Mostrar até o nível';

  @override
  String get outlineAllLevels => 'Todos os níveis';

  @override
  String outlineLevelN(int n) {
    return 'Até o nível $n';
  }

  @override
  String get outlineExpandAll => 'Expandir tudo';

  @override
  String get outlineCollapseAll => 'Recolher tudo';

  @override
  String outlineExpand(String title) {
    return 'Expandir $title';
  }

  @override
  String outlineCollapse(String title) {
    return 'Recolher $title';
  }

  @override
  String get infoCharactersWithSpaces => 'Caracteres (com espaços)';

  @override
  String get infoCharactersNoSpaces => 'Caracteres (sem espaços)';

  @override
  String get infoParagraphs => 'Parágrafos';

  @override
  String get infoProperties => 'Propriedades';

  @override
  String get infoTitle => 'Título';

  @override
  String get infoSubject => 'Assunto';

  @override
  String get infoAuthor => 'Autor';

  @override
  String get infoKeywords => 'Etiquetas, separadas por vírgula';

  @override
  String get infoComment => 'Comentário';

  @override
  String get infoApplyProperties => 'Aplicar as propriedades';

  @override
  String get infoUndoProperties => 'Desfazer as mudanças';

  @override
  String get commandPaintbrush => 'Copiar a formatação';

  @override
  String get commandChangeCase => 'Maiúsculas e minúsculas';

  @override
  String get commandCaseSentence => 'Como numa frase';

  @override
  String get commandCaseLower => 'minúsculas';

  @override
  String get commandCaseUpper => 'MAIÚSCULAS';

  @override
  String get commandCaseTitle => 'Cada Palavra Com Maiúscula';

  @override
  String get commandCaseToggle => 'iNVERTER mAIÚSCULAS';

  @override
  String get commandMultilevelList => 'Lista de vários níveis';

  @override
  String get commandListDecimal => 'Lista 1 · 1.1 · 1.1.1';

  @override
  String get commandListRoman => 'Lista I. · A. · 1.';

  @override
  String get commandListLetters => 'Lista A. · 1. · a.';

  @override
  String get commandListParenthesis => 'Lista 1) · a) · 1)';

  @override
  String get commandListBullets => 'Lista de marcadores em níveis';

  @override
  String get commandListLevelDown => 'Descer um nível na lista';

  @override
  String get commandListLevelUp => 'Subir um nível na lista';

  @override
  String commandColumns(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n colunas',
      one: 'Uma coluna',
    );
    return '$_temp0';
  }

  @override
  String get commandLineNumbers => 'Números de linha';

  @override
  String get commandWatermark => 'Marca d\'água…';

  @override
  String get commandRemoveWatermark => 'Tirar a marca d\'água';

  @override
  String get commandArrangeFront => 'Trazer para a frente';

  @override
  String get commandArrangeForward => 'Avançar um';

  @override
  String get commandArrangeBackward => 'Recuar um';

  @override
  String get commandArrangeBack => 'Enviar para trás';

  @override
  String get commandTextBox => 'Caixa de texto';

  @override
  String get commandDateTime => 'Data e hora';

  @override
  String get groupColumns => 'Colunas';

  @override
  String get groupPageBackground => 'Fundo da página';

  @override
  String get groupOrder => 'Ordem';

  @override
  String get groupText => 'Texto';

  @override
  String get pageColor => 'Cor da página';

  @override
  String get pageColorNone => 'Sem cor';

  @override
  String get pageColorCream => 'Creme';

  @override
  String get pageColorGray => 'Cinza-claro';

  @override
  String get pageColorBlue => 'Azul-claro';

  @override
  String get pageColorGreen => 'Verde-claro';

  @override
  String get pageColorYellow => 'Amarelo-claro';

  @override
  String get watermarkTitle => 'Marca d\'água';

  @override
  String get watermarkText => 'O texto';

  @override
  String get watermarkHint => 'RASCUNHO';

  @override
  String get watermarkColor => 'A cor';

  @override
  String watermarkColorN(int n) {
    return 'Cor $n';
  }

  @override
  String get watermarkLayout => 'A direção';

  @override
  String get watermarkDiagonal => 'Na diagonal';

  @override
  String get watermarkHorizontal => 'Na horizontal';

  @override
  String get watermarkNote =>
      'A marca d\'água vai no cabeçalho de cada página. Tirar o cabeçalho tira ela junto.';

  @override
  String get watermarkApply => 'Aplicar';

  @override
  String get prefSpellIgnoreUpper => 'Não verificar as palavras em MAIÚSCULAS';

  @override
  String get prefSpellIgnoreDigits => 'Não verificar as palavras com números';

  @override
  String get prefSpellRulesNote =>
      'As regras da ortografia valem na próxima vez que o Quill abrir: o LibreOffice só as lê ao ligar.';

  @override
  String get prefQuickAccess => 'Acesso rápido';

  @override
  String get prefQuickAccessNote =>
      'Os botões antes do Arquivo, na faixa. Até 12.';

  @override
  String prefQuickAccessUp(String name) {
    return 'Subir $name';
  }

  @override
  String prefQuickAccessDown(String name) {
    return 'Descer $name';
  }

  @override
  String prefQuickAccessRemove(String name) {
    return 'Tirar $name';
  }

  @override
  String get prefQuickAccessAdd => 'Adicionar um comando';

  @override
  String get prefQuickAccessDefault => 'Voltar ao padrão';

  @override
  String get prefShortcutsNote =>
      'Cada comando pode ter o seu atalho, por cima do jogo escolhido. Os em destaque são os seus.';

  @override
  String get prefShortcutsFilter => 'Procurar um comando ou atalho';

  @override
  String get prefShortcutsResetAll => 'Voltar todos ao jogo';

  @override
  String get prefShortcutChange => 'Mudar';

  @override
  String shortcutDialogTitle(String name) {
    return 'Atalho de $name';
  }

  @override
  String get shortcutNone => 'Sem atalho agora.';

  @override
  String shortcutCurrent(String keys) {
    return 'Agora: $keys';
  }

  @override
  String get shortcutPress => 'Pressione as teclas do atalho';

  @override
  String get shortcutUnusable =>
      'Use Ctrl ou Alt com uma tecla, ou uma tecla F: uma letra sozinha é texto.';

  @override
  String shortcutTaken(String name) {
    return 'Este já é o atalho de $name. Atribuir tira dele.';
  }

  @override
  String get shortcutRemove => 'Sem atalho';

  @override
  String get shortcutReset => 'O do jogo';

  @override
  String get shortcutAssign => 'Atribuir';

  @override
  String get commandNewFromTemplate => 'Novo a partir do modelo…';

  @override
  String get commandSaveAsTemplate => 'Salvar como modelo…';

  @override
  String get commandSaveBookTemplate =>
      'Salvar os estilos como modelo do livro';

  @override
  String get templatesNewTitle => 'Novo a partir do modelo';

  @override
  String templatesNone(String folder) {
    return 'Nenhum modelo ainda. \"Salvar como modelo\" grava os estilos de um documento em $folder.';
  }

  @override
  String get templatesOfBook => 'Os estilos do livro (estilos.ott)';

  @override
  String get templatesOpenFolder => 'Abrir a pasta dos modelos';

  @override
  String get templatesOpenFailed => 'O modelo não abriu.';

  @override
  String get templatesSaveTitle => 'Salvar como modelo';

  @override
  String get templatesSaveNote =>
      'O modelo guarda os estilos deste documento (a página, os parágrafos, os títulos), sem o texto.';

  @override
  String get templatesName => 'O nome do modelo';

  @override
  String get templatesExists => 'Já existe um modelo com esse nome.';

  @override
  String get templatesReplace => 'Substituir';

  @override
  String get templatesSave => 'Salvar';

  @override
  String templatesSaved(String name) {
    return 'O modelo $name foi salvo.';
  }

  @override
  String get templatesBookSaved =>
      'Os estilos viraram o modelo do livro: os capítulos novos nascem dele.';

  @override
  String get templatesSaveFailed => 'O modelo não foi salvo.';
}
