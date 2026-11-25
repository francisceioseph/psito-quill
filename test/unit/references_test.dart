// As referências (Fase 4, Etapa 5, D-090): as macros do perfil, o que a cópia
// diz dos marcadores e das legendas, e o livro juntado com os índices.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/book/compile.dart';
import 'package:psito_quill/src/book/fodt_join.dart';
import 'package:psito_quill/src/document/fodt.dart';
import 'package:psito_quill/src/document/references.dart';
import 'package:psito_quill/src/kit/lok/lo_profile.dart';
import 'package:psito_quill/src/kit/lok/quill_macros.dart';

// O corpo como a 24.2 gravou na sonda (D-090), resumido.
const _body = '<office:text>'
    '<text:h text:outline-level="1"><text:bookmark-start text:name="__RefHeading__quill_t1"/>Capítulo um'
    '<text:bookmark-end text:name="__RefHeading__quill_t1"/></text:h>'
    '<text:p><text:bookmark text:name="mapa &amp; ç"/>O gato.<text:bookmark text:name="_GoBack"/></text:p>'
    '<text:p text:style-name="Caption"><draw:frame draw:name="Figura1"><draw:image/></draw:frame>Figura '
    '<text:sequence text:ref-name="refFigure0" text:name="Figure" text:formula="ooow:Figure+1" style:num-format="1">1</text:sequence>: Mapa</text:p>'
    '<text:p text:style-name="Caption">Figura <text:sequence text:ref-name="refFigure1" text:name="Figure" '
    'text:formula="ooow:Figure+1" style:num-format="1"/>: Rio<text:note><text:note-body><text:p>nota</text:p></text:note-body></text:note></text:p>'
    '<text:p text:style-name="Caption">Tabela <text:sequence text:ref-name="refTable0" text:name="Table" '
    'text:formula="ooow:Table+1" style:num-format="1">1</text:sequence>: Números</text:p>'
    '<text:p><text:bookmark-start text:name="trecho"/>longo<text:bookmark-end text:name="trecho"/></text:p>'
    '</office:text>';

void main() {
  group('as macros', () {
    test('o endereço: tudo entre aspas, o texto em hexadecimal', () {
      expect(quillMacro('Atualizar'), 'macro:///PsitoQuill.Referencias.Atualizar()');
      expect(quillMacro('Sumario', [const MacroText('Sumário'), 3]),
          'macro:///PsitoQuill.Referencias.Sumario("00530075006d00e100720069006f","3")');
      expect(quillMacro('MarcarEntrada', [true]), endsWith('MarcarEntrada("1")'));
      expect(quillMacro('Legenda', [const MacroText('"),x'), MacroName('Figura')]),
          endsWith('Legenda("00220029002c0078","Figura")'));
      // Um emoji são duas unidades UTF-16 (o Chr do Basic junta).
      expect(basicHex('😀'), 'd83dde00');
      expect(() => MacroName('com aspas"'), throwsArgumentError);
      expect(() => MacroName('acentuação'), throwsArgumentError);
      expect(() => quillMacro('X', [1.5]), throwsArgumentError);
    });

    test('o módulo escapa o Basic no XML e não usa o ChrW', () {
      final xml = quillMacroModuleXml();
      expect(xml, contains('script:name="Referencias"'));
      expect(xml, contains('Sub Sumario(titulo As String, niveis As Integer)'));
      expect(xml, contains('s = s &amp; Chr(CLng(&quot;&amp;H&quot;'));
      expect(xml, isNot(contains('ChrW')));
      expect(xml.split('<script:module').length, 2);
    });

    test('o Basic não abre arquivo, rede nem programa (a privacidade)', () {
      final xml = quillMacroModuleXml();
      final basic = xml.substring(xml.indexOf('StarBasic">'));
      for (final banned in ['Shell', 'Open ', 'Kill', 'FileCopy', 'MkDir', 'ucb', 'http', 'SimpleFileAccess', 'storeToURL']) {
        expect(basic, isNot(contains(banned)), reason: banned);
      }
      // O único serviço criado é o que despacha o campo da legenda.
      expect(RegExp(r'createUnoService\(&quot;([^&]*)&quot;\)').allMatches(basic).map((m) => m[1]).toSet(),
          {'com.sun.star.frame.DispatchHelper'});
    });

    test('o perfil: a biblioteca, e a lista com ela uma vez só', () {
      final dir = Directory.systemTemp.createTempSync('quill-macros-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final p = LoProfile(dir)..ensureSettings(const []);
      final basic = '${dir.path}/user/basic';
      expect(File('$basic/PsitoQuill/Referencias.xba').readAsStringSync(), quillMacroModuleXml());
      expect(File('$basic/PsitoQuill/script.xlb').readAsStringSync(), contains('library:name="Referencias"'));
      expect(File('$basic/Standard/script.xlb').existsSync(), isTrue);
      final list = File('$basic/script.xlc');
      expect(list.readAsStringSync(), contains('library:name="Standard"'));
      // O LibreOffice regravou a lista sem a nossa (o perfil novo, D-090).
      list.writeAsStringSync(list.readAsStringSync().replaceAll(RegExp(r' <library:library library:name="PsitoQuill"[^\n]*\n'), ''));
      p.ensureMacros();
      p.ensureMacros();
      expect('library:name="PsitoQuill"'.allMatches(list.readAsStringSync()).length, 1);
    });
  });

  group('a cópia', () {
    test('os marcadores da pessoa, sem os escondidos', () {
      expect(odfBookmarks(_body), ['mapa & ç', 'trecho']);
    });

    test('as legendas: o texto com o número, e o número interno', () {
      final c = odfCaptions(_body);
      expect(c.map((e) => e.text), ['Figura 1: Mapa', 'Figura 2: Rio', 'Tabela 1: Números']);
      expect(c.map((e) => (e.sequence, e.number)), [('Figure', 0), ('Figure', 1), ('Table', 0)]);
    });

    test('a cópia inteira traz os dois', () {
      final s = parseFodt('<office:document><office:body>$_body</office:body></office:document>');
      expect(s.bookmarks, ['mapa & ç', 'trecho']);
      expect(s.captions, hasLength(3));
      expect(s.outline.single.text, 'Capítulo um');
    });
  });

  test('os argumentos da referência cruzada', () {
    expect(bookmarkRefArgs('a"b', RefFormat.page),
        '{"Type":{"type":"short","value":13},"SubType":{"type":"short","value":2},'
        '"Name":{"type":"string","value":"a\\"b"},"Content":{"type":"string","value":""},"Format":{"type":"long","value":0}}');
    final cap = captionRefArgs(const CaptionEntry(sequence: 'Figure', number: 4, text: ''), RefFormat.text);
    expect(cap, contains('"SubType":{"type":"short","value":1}'));
    expect(cap, contains('"Name":{"type":"string","value":"Figura"}'));
    expect(cap, contains('"Content":{"type":"string","value":"4"}'));
    expect(cap, contains('"Format":{"type":"long","value":5}'));
    expect(headingRefMacro(2, 'Um', '__RefHeading__quill_x_1', RefFormat.aboveBelow),
        'macro:///PsitoQuill.Referencias.RefTitulo("2","0055006d","__RefHeading__quill_x_1","3")');
    expect(newHeadingMark(DateTime(2026), 7), matches(RegExp(r'^__RefHeading__quill_[a-z0-9]+_7$')));
    expect(engineSequenceName('Illustration'), 'Ilustração');
    expect(engineSequenceName('Minha'), 'Minha');
  });

  test('o nome do marcador', () {
    expect(bookmarkNameProblem(' ', const []), BookmarkNameProblem.empty);
    expect(bookmarkNameProblem('_x', const []), BookmarkNameProblem.characters);
    expect(bookmarkNameProblem('a.b', const []), BookmarkNameProblem.characters);
    expect(bookmarkNameProblem('mapa', const ['mapa']), BookmarkNameProblem.exists);
    expect(bookmarkNameProblem('mapa do rio', const ['mapa']), isNull);
  });

  group('o livro juntado', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('quill-ref-'));
    tearDown(() => tmp.deleteSync(recursive: true));

    String chapter(String name, String body) =>
        (File('${tmp.path}/$name.fodt')..writeAsStringSync('<?xml version="1.0"?><office:document office:version="1.3">'
                '<office:automatic-styles/><office:body><office:text>$body</office:text></office:body></office:document>'))
            .path;

    String join(JoinOptions o) {
      final a = chapter('a', '<text:table-of-content text:name="S1"><text:index-body/></text:table-of-content>'
          '<text:h text:outline-level="1">Um</text:h>'
          '<text:p><text:bookmark text:name="mapa"/>Figura <text:sequence text:ref-name="refFigure0" text:name="Figure">1</text:sequence></text:p>');
      final b = chapter('b', '<text:h text:outline-level="1">Dois</text:h>'
          '<text:p>Ver <text:bookmark-ref text:ref-name="mapa" text:reference-format="page">1</text:bookmark-ref>, '
          '<text:sequence-ref text:ref-name="refFigure0" text:reference-format="category-and-value">1</text:sequence-ref> e '
          '<text:sequence text:ref-name="refFigure0" text:name="Figure">1</text:sequence>.'
          '<text:alphabetical-index-mark-start text:id="IMark1"/>gato<text:alphabetical-index-mark-end text:id="IMark1"/></text:p>'
          '<text:alphabetical-index text:name="I1"><text:index-body/></text:alphabetical-index>');
      final out = '${tmp.path}/livro.fodt';
      joinFodt([JoinChapter(a, 'Um'), JoinChapter(b, 'Dois')], o, out);
      return File(out).readAsStringSync();
    }

    test('os índices dos capítulos saem; os do compilar entram', () {
      final xml = join(const JoinOptions(figures: true, figuresTitle: 'Figuras', index: true, indexTitle: 'Índice'));
      expect('<text:table-of-content '.allMatches(xml).length, 1);
      expect(xml, contains('text:name="QuillSumario"'));
      expect(xml, isNot(contains('text:name="S1"')));
      expect(xml, isNot(contains('text:name="I1"')));
      expect(xml, contains('<text:illustration-index text:name="QuillFiguras"'));
      expect(xml, contains('text:caption-sequence-name="Figure"'));
      expect(xml, contains('<text:p text:style-name="QuillFigurasQuebra">Figuras</text:p>'));
      // O remissivo no fim, depois do último capítulo.
      expect(xml.indexOf('<text:alphabetical-index text:name="QuillIndice"'), greaterThan(xml.indexOf('Dois')));
      expect(xml, contains('<text:p text:style-name="QuillIndiceQuebra">Índice</text:p>'));
      expect(xml, contains('style:name="QuillIndiceQuebra"'));
      expect(xml, contains('<text:index-entry-page-number/>'));
    });

    test('a referência a um marcador fica sem prefixo; a da legenda ganha', () {
      final xml = join(const JoinOptions());
      expect(xml, contains('<text:bookmark text:name="mapa"/>'));
      expect(xml, contains('<text:bookmark-ref text:ref-name="mapa"'));
      // A legenda do segundo capítulo e a referência a ela, com o prefixo.
      expect(xml, contains('<text:sequence-ref text:ref-name="q1_refFigure0"'));
      expect(xml, contains('<text:sequence text:ref-name="q1_refFigure0"'));
      expect(xml, contains('<text:sequence text:ref-name="refFigure0"'));
      expect(xml, contains('text:id="q1_IMark1"'));
      expect(xml, isNot(contains('<text:illustration-index')));
      expect(xml, isNot(contains('<text:alphabetical-index ')));
    });

    test('sem páginas (o EPUB): as entradas sem o número', () {
      final xml = join(const JoinOptions(figures: true, tocPageNumbers: false));
      expect(xml, contains('<text:illustration-index text:name="QuillFiguras"'));
      expect(xml, isNot(contains('<text:index-entry-page-number/>')));
    });

    test('as opções no compilar.json, e o EPUB sem o remissivo', () {
      const s = CompileSettings(figures: true, index: true, indexTitle: 'Remissivo', format: CompileFormat.epub);
      final back = CompileSettings.fromJson(s.toJson());
      expect((back.figures, back.index, back.indexTitle), (true, true, 'Remissivo'));
      expect(s.join.index, isFalse);
      expect(s.copyWith(format: CompileFormat.pdf).join.index, isTrue);
      expect(const CompileSettings().join.figures, isFalse);
    });
  });
}
