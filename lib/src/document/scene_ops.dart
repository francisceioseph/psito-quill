// As cenas no documento (Fase 3, Etapa 5, D-079). Parte do
// DocumentController: usa a fila do motor, as cópias e o estilo pela cópia.
//
// Sondado na 24.2: o `.uno:LoadStyles` traz o estilo "Cena" e o `StyleApply`
// o aplica; a busca por expressão regular com "Selecionar tudo" seleciona
// todos os separadores soltos, e um `StyleApply` vale para todos; o
// `.uno:InsertBookmark` com o nome não abre janela, e o `.uno:DeleteBookmark`
// o tira; o `.uno:InsertDoc` com o arquivo insere outro documento no
// cursor, sem janela, e entra no Ctrl+Z.
//
// Tudo vai por comandos, nunca por teclas: o LOK põe a tecla numa fila do
// motor e o comando roda na hora, então um Enter mandado antes de um
// `.uno:GoUp` chegava depois dele (visto na integração; o `lok_script`,
// que espera entre os passos, não mostrava). O `.uno:InsertPara`, o
// `.uno:InsertText` e o `.uno:SwBackspace` fazem o mesmo na ordem.
part of 'document_controller.dart';

/// O que o motor insere como separador de uma cena nova.
const sceneSeparatorText = '* * *';

/// A expressão regular (do ICU) de um separador solto, a mesma regra do
/// `isSceneSeparatorText`.
const _separatorRegex = r'^\s*[*#⁂](\s*[*#⁂])*\s*$';

extension SceneOps on DocumentController {
  /// O documento já tem o estilo "Cena".
  bool get hasSceneStyle => snapshot.styles.containsKey(sceneStyleName);

  /// Cria o estilo "Cena" pela cópia (D-075), se ainda não existe.
  Future<bool> ensureSceneStyle() async {
    if (hasSceneStyle) return true;
    return patchStyles(addSceneStyle, flags: StyleFlags.paragraph);
  }

  /// Uma cena nova depois do parágrafo do cursor: um separador "* * *" no
  /// estilo "Cena" e um parágrafo vazio embaixo, com o cursor nele.
  Future<bool> insertScene() async {
    if (!canEdit || busy != null) return false;
    if (!await ensureSceneStyle() || !canEdit) return false;
    kit.uno('.uno:GoToEndOfPara');
    kit.uno('.uno:InsertPara');
    kit.uno('.uno:InsertPara');
    kit.uno('.uno:GoUp');
    kit.uno('.uno:InsertText', jsonEncode({'Text': {'type': 'string', 'value': sceneSeparatorText}}));
    applyParagraphStyle(sceneStyleName);
    kit.uno('.uno:GoDown');
    _edited();
    refreshSnapshot();
    return true;
  }

  /// Os separadores soltos ("* * *", "#") do documento passam para o estilo
  /// "Cena". Devolve quantos eram (pela cópia); 0 sem nenhum, -1 se falhou.
  Future<int> convertSceneSeparators() async {
    if (!canEdit || busy != null) return -1;
    final copy = _tempCopy('cenas', 'fodt');
    var loose = 0;
    try {
      if (!await exportTo(copy, 'fodt')) return -1;
      loose = await Isolate.run(() => odfLooseSeparators(File(copy).readAsStringSync()));
    } on Object {
      return -1;
    } finally {
      DocumentController._deleteCopy(copy);
    }
    if (loose == 0) return 0;
    if (!await ensureSceneStyle() || !canEdit) return -1;
    // A resposta da busca não é do Localizar.
    _headingSearches++;
    kit.uno('.uno:ExecuteSearch', searchArgs(const SearchQuery(_separatorRegex, regex: true), SearchCommand.all));
    applyParagraphStyle(sceneStyleName);
    _edited();
    refreshSnapshot();
    return loose;
  }

  /// Leva o cursor à cena [e]: ao separador dela, pela busca (como a
  /// Estrutura, D-072), ou ao começo do documento, a primeira.
  void goToScene(SceneEntry e) {
    if (!isOpen) return;
    final key = e.searchKey;
    if (key == null) {
      kit.uno('.uno:GoToStartOfDoc');
      return;
    }
    _jumpToText(key, e.occurrence);
  }

  /// Leva à cena [index] quando a cópia do documento [path] chegar (um
  /// capítulo que ainda vai abrir).
  void goToSceneWhenOpen(String path, int index) => _pendingScene = (path: path, index: index, hit: null);

  /// Leva à ocorrência [hit] da busca no livro quando o documento [path]
  /// abrir (Fase 3, Etapa 6).
  void goToHitWhenOpen(String path, TextHit hit) => _pendingScene = (path: path, index: null, hit: hit);

  /// O salto pendente, se é deste documento (um capítulo que já estava
  /// aberto numa aba).
  void takePendingScene() => _takePendingScene();

  void _takePendingScene() {
    final p = _pendingScene;
    if (p == null || p.path != path) return;
    _pendingScene = null;
    if (p.hit case final hit?) {
      goToHit(hit);
    } else if (p.index case final i? when i < snapshot.scenes.length) {
      goToScene(snapshot.scenes[i]);
    }
  }

  // ------------------------------------------ dividir e juntar (D-079) --

  /// Põe um marcador [name] no cursor e grava a cópia em [copy]. false: o
  /// motor não gravou (o marcador já foi tirado). Quem chama trava a tela
  /// antes ([whileWorking]).
  Future<bool> markAndCopy(String name, String copy) async {
    if (!canEdit) return false;
    kit.uno('.uno:InsertBookmark', jsonEncode({'Bookmark': {'type': 'string', 'value': name}}));
    if (await exportTo(copy, 'fodt')) return true;
    removeBookmark(name);
    return false;
  }

  void removeBookmark(String name) {
    if (isOpen) kit.uno('.uno:DeleteBookmark', jsonEncode({'Bookmark': {'type': 'string', 'value': name}}));
  }

  /// Apaga do cursor (o marcador [name]) ao fim do documento, e tira o
  /// marcador. Com [joinEmpty], o parágrafo que fica vazio sai também.
  void deleteToEnd(String name, {required bool joinEmpty}) {
    if (!canEdit) return;
    kit.uno('.uno:EndOfDocumentSel');
    kit.uno('.uno:Delete');
    if (joinEmpty) kit.uno('.uno:SwBackspace');
    removeBookmark(name);
    _edited();
    refreshSnapshot();
  }

  /// Insere o documento [file] no fim deste, num parágrafo novo.
  void appendDocument(String file) {
    if (!canEdit) return;
    kit.uno('.uno:GoToEndOfDoc');
    kit.uno('.uno:InsertPara');
    kit.uno('.uno:InsertDoc', jsonEncode({'Name': {'type': 'string', 'value': Uri.file(file).toString()}}));
    _edited();
    refreshSnapshot();
  }

  /// Uma cópia temporária com o nome deste processo (apagada pelo
  /// [deleteTempCopy]).
  String tempCopy(String what, String ext) => _tempCopy(what, ext);
  static void deleteTempCopy(String path) => DocumentController._deleteCopy(path);
}
