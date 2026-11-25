import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/book/book.dart';
import 'package:psito_quill/src/document/comments.dart';
import 'package:psito_quill/src/kit/lok/lok_payloads.dart';
import 'package:psito_quill/src/kit/lok/lok_quill_kit.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';

// O que a 24.2 mandou na sonda (D-088).
const _added = '''
{
    "comment": {
        "action": "Add",
        "id": "1",
        "parentId": "0",
        "author": "Ana \\"Tal\\" Souza",
        "text": "Gato ou cão?",
        "resolved": "false",
        "dateTime": "2026-11-25T08:48:34,468242030",
        "anchorPos": "5610, 1418, 1, 276",
        "textRange": "5123, 1418, 487, 275"
    }
}''';

const _list = '{ "comments": [ { "id": 1, "parentId": 0, "author": "Autor desconhecido", "text": "Gato ou cachorro?", '
    '"resolved": "true", "dateTime": "2026-11-25T08:48:34,468242030", "anchorPos": "5610, 1418, 1, 276", '
    '"textRange": "5123, 1418, 487, 275"}, { "id": 2, "parentId": 1, "author": "Autor desconhecido", "text": "Gato.", '
    '"resolved": "false", "dateTime": "2026-11-25T08:48:35,633045755", "anchorPos": "5610, 1418, 1, 276", "textRange": ""}]}';

DocComment _c(String id, double y, double x, {String parent = '', bool resolved = false}) => DocComment(
      id: id,
      parentId: parent,
      resolved: resolved,
      range: parent.isEmpty ? [Rect.fromLTWH(x, y, 100, 275)] : const [],
    );

void main() {
  group('o callback 32', () {
    test('um comentário novo', () {
      final e = parseCommentChanged(_added)!;
      expect(e.action, CommentAction.add);
      final c = e.comment;
      expect(c.id, '1');
      expect(c.isReply, isFalse);
      expect(c.author, 'Ana "Tal" Souza');
      expect(c.text, 'Gato ou cão?');
      expect(c.resolved, isFalse);
      expect(c.date, DateTime(2026, 11, 25, 8, 48, 34, 468, 242));
      expect(c.anchor, const Rect.fromLTWH(5610, 1418, 1, 276));
      expect(c.range, [const Rect.fromLTWH(5123, 1418, 487, 275)]);
    });

    test('o apagado traz só o id', () {
      final e = parseCommentChanged('{"comment": {"action": "Remove", "id": "2"}}')!;
      expect(e.action, CommentAction.remove);
      expect(e.comment.id, '2');
    });

    test('a ação desconhecida e o texto estragado dão null', () {
      expect(parseCommentChanged('{"comment": {"action": "RedlinedDeletion", "id": "2"}}'), isNull);
      expect(parseCommentChanged('nada'), isNull);
    });

    test('o trecho em duas linhas', () {
      final e = parseCommentChanged('{"comment": {"action": "Modify", "id": "3", "textRange": "10, 20, 30, 40; 0, 60, 50, 40"}}')!;
      expect(e.comment.range, hasLength(2));
    });

    test('o tradutor do kit', () {
      expect(LokQuillKit.translate(32, _added), isA<CommentChanged>());
    });
  });

  test('a lista do ViewAnnotations, com os ids em número', () {
    final list = parseCommentList(_list);
    expect(list.map((c) => c.id), ['1', '2']);
    expect(list[0].resolved, isTrue);
    expect(list[1].parentId, '1');
    expect(list[1].range, isEmpty);
    expect(parseCommentList('{}'), isEmpty);
    expect(parseCommentList('estragado'), isEmpty);
  });

  group('as conversas', () {
    test('na ordem do texto, com as respostas embaixo', () {
      final threads = commentThreads([
        _c('1', 3000, 100),
        _c('2', 1418, 900),
        _c('3', 1418, 200),
        _c('4', 0, 0, parent: '2'),
        _c('5', 0, 0, parent: '4'), // resposta de uma resposta
      ]);
      expect(threads.map((t) => t.root.id), ['3', '2', '1']);
      expect(threads[1].replies.map((r) => r.id), ['4', '5']);
    });

    test('uma resposta sem o comentário de cima vira conversa', () {
      final threads = commentThreads([_c('9', 0, 0, parent: '7')]);
      expect(threads.single.root.id, '9');
    });

    test('o resolvido é o do comentário de cima', () {
      expect(commentThreads([_c('1', 0, 0, resolved: true)]).single.resolved, isTrue);
    });
  });

  test('aplicar o callback na lista', () {
    var list = <DocComment>[];
    list = applyCommentChange(list, CommentChanged(CommentAction.add, _c('1', 0, 0)));
    list = applyCommentChange(list, CommentChanged(CommentAction.add, _c('2', 10, 0)));
    list = applyCommentChange(list, CommentChanged(CommentAction.resolve, _c('1', 0, 0, resolved: true)));
    expect(list.map((c) => (c.id, c.resolved)), [('1', true), ('2', false)]);
    list = applyCommentChange(list, const CommentChanged(CommentAction.remove, DocComment(id: '1')));
    expect(list.map((c) => c.id), ['2']);
    expect(applyCommentChange(list, const CommentChanged(CommentAction.remove, DocComment(id: '8'))), same(list));
  });

  test('os argumentos dos comandos', () {
    expect(commentArgs(id: '3', text: 'a "b"'),
        '{"Id":{"type":"string","value":"3"},"Text":{"type":"string","value":"a \\"b\\""}}');
    expect(commentArgs(text: 'x'), '{"Text":{"type":"string","value":"x"}}');
  });

  test('os abertos de um content.xml fechado', () {
    const xml = '<text:p>Era <office:annotation office:name="a" loext:resolved="false"><dc:creator>A</dc:creator>'
        '</office:annotation>um<office:annotation-end office:name="a"/> '
        '<office:annotation loext:parent-name="a" loext:resolved="false"></office:annotation>'
        '<office:annotation office:name="b" loext:resolved="true"></office:annotation>'
        '<office:annotation office:name="c"></office:annotation>gato</text:p>';
    expect(openCommentsInContent(xml), 2);
    expect(openCommentsInContent('<text:p/>'), 0);
  });

  test('o livro.json guarda os comentários, e um livro antigo reconta', () {
    final node = BookNode(id: 'c1', kind: BookNodeKind.chapter, title: 'Um', words: 10, wordsStamp: 99, comments: 3);
    final back = BookNode.fromJson(node.toJson());
    expect(back.comments, 3);
    expect(back.wordsStamp, 99);
    final old = BookNode.fromJson({'id': 'c1', 'tipo': 'capitulo', 'titulo': 'Um', 'palavras': 10, 'palavrasEm': 99});
    expect(old.wordsStamp, 0);
  });
}
