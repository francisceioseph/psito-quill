// A página do livro, as notas, os links e o PDF (Fase 3, Etapas 3 e 4,
// D-075 e D-076). Parte do DocumentController: usa a fila do motor e as
// cópias dele.
part of 'document_controller.dart';

/// Os campos que o Inserir põe no texto (sondados na 24.2).
enum DocField { pageNumber, pageCount, date, time }

extension PageFormat on DocumentController {
  /// Mostra [text] na barra de status (a página traduz).
  void notice(String text) {
    message = NoticeMessage(text);
    notifyListeners();
  }

  // ------------------------------------------------- a cópia com espera --

  /// Grava uma cópia do documento em [path] no [format] ("fodt", "pdf") e
  /// espera o motor. true: gravou.
  Future<bool> exportTo(String path, String format) {
    if (!isOpen) return Future.value(false);
    final done = Completer<bool>();
    _copyWaiters[path] = done;
    kit.exportCopy(path, format);
    return done.future.timeout(const Duration(seconds: 120), onTimeout: () {
      _copyWaiters.remove(path);
      return false;
    });
  }

  String _tempCopy(String what, String ext) => '${DocumentController.copyDir}/'
      '${DocumentController.copyPrefixOfThisProcess}$what-${_copies++}.$ext';

  // -------------------------------------- mudar estilos pela cópia (D-075) --

  /// Muda estilos pela cópia (style_patch.dart): o motor grava a cópia, o
  /// Quill a muda ([patch], num isolate), o motor a converte para ODT, e o
  /// `.uno:LoadStyles` carrega os estilos [flags] de volta, por cima.
  /// true: carregou. Nada disso passa pelo desfazer do motor.
  Future<bool> patchStyles(String Function(String fodt) patch, {required int flags}) async {
    if (!canEdit || _patching) return false;
    _patching = true;
    final tab = _current;
    final copy = _tempCopy('estilos', 'fodt');
    final changed = _tempCopy('estilos', 'fodt');
    final odt = changed.replaceFirst(RegExp(r'\.fodt$'), '.odt');
    try {
      if (!await exportTo(copy, 'fodt')) return false;
      try {
        await Isolate.run(() {
          final xml = File(copy).readAsStringSync();
          File(changed).writeAsStringSync(patch(stylesOnly(xml)));
        });
      } on Object {
        return false;
      }
      if (!await KitConverter(kit).convert(changed, odt, 'odt')) return false;
      if (_disposed || tab != _current || !isOpen) return false;
      kit.uno(
        '.uno:LoadStyles',
        jsonEncode({
          'FileName': {'type': 'string', 'value': Uri.file(odt).toString()},
          'Flags': {'type': 'long', 'value': flags | StyleFlags.overwrite},
        }),
      );
      _edited();
      // A cópia nova vem depois do LoadStyles na fila: quando ela chega, o
      // ODT já foi lido (e a Estrutura, os estilos e a página se refazem).
      refreshSnapshot();
      final fence = _tempCopy('estilos-fim', 'fodt');
      await exportTo(fence, 'fodt');
      DocumentController._deleteCopy(fence);
      return true;
    } finally {
      for (final p in [copy, changed, odt]) {
        DocumentController._deleteCopy(p);
      }
      _patching = false;
    }
  }

  // ------------------------------------------- o cabeçalho e o rodapé --

  /// Liga o cabeçalho ([footer] falso) ou o rodapé em todos os estilos de
  /// página, e o cursor vai para ele (sondado: com `On` e sem o estilo).
  void insertHeaderFooter({required bool footer}) {
    uno(footer ? '.uno:InsertPageFooter' : '.uno:InsertPageHeader', '{"On":{"type":"boolean","value":true}}');
    refreshSnapshot();
  }

  /// Desliga pela cópia: o comando do motor abre uma janela que trava o LOK.
  Future<bool> removeHeaderFooter({required bool footer}) =>
      patchStyles((x) => xmlRemoveHeaderFooter(x, footer: footer), flags: StyleFlags.page);

  /// O cursor vai ao cabeçalho (ou ao rodapé) da página dele, para editar.
  void editHeaderFooter({required bool footer}) => uno(footer ? '.uno:JumpToFooter' : '.uno:JumpToHeader');

  Future<bool> setFirstPageDifferent(bool on) =>
      patchStyles((x) => xmlFirstDifferent(x, on), flags: StyleFlags.page);

  Future<bool> setLeftRightDifferent(bool on) =>
      patchStyles((x) => xmlLeftDifferent(x, on), flags: StyleFlags.page);

  void insertField(DocField f) => uno(switch (f) {
        DocField.pageNumber => '.uno:InsertPageNumberField',
        DocField.pageCount => '.uno:InsertPageCountField',
        DocField.date => '.uno:InsertDateField',
        DocField.time => '.uno:InsertTimeField',
      });

  // ------------------------------------------- hifenização e capitular --

  /// A hifenização automática do documento (o estilo padrão de parágrafo).
  Future<bool> setDocumentHyphenation(bool on) =>
      patchStyles((x) => xmlDocumentHyphenation(x, on), flags: StyleFlags.paragraph);

  /// Só no parágrafo do cursor (ou nos da seleção): formatação direta.
  void setParagraphHyphenation(bool on) =>
      uno('.uno:SetHyphenZone', '{"SetHyphenZone.Hyphen":{"type":"boolean","value":$on}}');

  /// A letra capitular de [lines] linhas no parágrafo do cursor: um estilo
  /// filho do estilo dele, com a capitular (D-075). 0 tira.
  Future<bool> setDropCap(int lines) async {
    final current = paragraphStyle;
    if (current == null) return false;
    final base = dropCapBase(current);
    if (lines == 0) {
      if (base != null) applyParagraphStyle(base);
      return base != null;
    }
    final label = base ?? current;
    final id = base == null ? (paragraphStyleId ?? current) : (styleIdFromState(base));
    final ok = await patchStyles((x) {
      final (out, _) = addDropCapStyle(x, base: id, label: label, lines: lines);
      return out;
    }, flags: StyleFlags.paragraph);
    if (!ok) return false;
    applyParagraphStyle('$label$dropCapSuffix $lines');
    refreshStyles();
    return true;
  }

  // ------------------------------------------------------------ quebras --

  void insertColumnBreak() => uno('.uno:InsertColumnBreak');

  /// Uma página em branco: duas quebras de página (a 24.2 não tem o
  /// `.uno:InsertBlankPage`).
  void insertBlankPage() {
    uno('.uno:InsertPagebreak');
    uno('.uno:InsertPagebreak');
  }

  // ------------------------------------------------- as notas (D-076) --

  void insertFootnote() => uno('.uno:InsertFootnote');
  void insertEndnote() => uno('.uno:InsertEndnote');

  /// Do número da nota ao texto dela, e de volta.
  void jumpFootnote() {
    if (isOpen) kit.uno('.uno:JumpToFootnoteOrAnchor');
  }

  // ------------------------------------------------- os links (D-076) --

  /// Insere um link [text] → [url] (ou, com o cursor num link, troca-o).
  void insertLink(String text, String url) => uno(
        '.uno:SetHyperlink',
        jsonEncode({
          'Hyperlink.Text': {'type': 'string', 'value': text},
          'Hyperlink.URL': {'type': 'string', 'value': url},
        }),
      );

  void removeLink() => uno('.uno:RemoveHyperlink');

  /// Um Ctrl+clique: se o cursor parar num link, [onLinkClicked] é chamado
  /// (a página pergunta antes de abrir: o Quill não abre nada sozinho);
  /// senão, [otherwise] (a seleção da frase).
  void expectLinkClick({void Function()? otherwise}) {
    _linkClick = true;
    _linkOtherwise = otherwise;
    _linkClickTimer?.cancel();
    // O motor não manda o cursor se ele não saiu do lugar: decide pelo link
    // que já se sabe.
    _linkClickTimer = Timer(const Duration(milliseconds: 300), () => _settleLinkClick(link));
  }

  void _settleLinkClick(DocLink? l) {
    if (!_linkClick) return;
    _linkClick = false;
    _linkClickTimer?.cancel();
    final otherwise = _linkOtherwise;
    _linkOtherwise = null;
    if (l != null) {
      onLinkClicked?.call(l);
    } else {
      otherwise?.call();
    }
  }

  // ------------------------------------------- o PDF e a impressão (D-076) --

  /// Exporta o documento para PDF em [path] (os títulos viram marcadores).
  Future<bool> exportPdf(String path) => exportTo(path, 'pdf');

  /// A janela de impressão do sistema: o PDF vai para uma pasta temporária e
  /// é apagado depois. O resultado vem pelo [Printed].
  Future<Printed> printDocument(String title) async {
    final pdf = _tempCopy('impressao', 'pdf');
    if (!await exportTo(pdf, 'pdf')) {
      DocumentController._deleteCopy(pdf);
      return const Printed(PrintOutcome.failed);
    }
    final result = kit.events.firstWhere((e) => e is Printed).then((e) => e as Printed);
    kit.printPdf(pdf, title);
    return result;
  }
}
