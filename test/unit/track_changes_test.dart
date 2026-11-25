import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/kit/lok/lok_payloads.dart';
import 'package:psito_quill/src/kit/lok/lok_quill_kit.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/organisms/changes_panel.dart';

// O que a 24.2 mandou na sonda (D-089), na ordem do motor.
const _list = '{ "redlines": [ { "index": 2, "author": "Ana Teste", "type": "Delete", "comment": "", '
    '"description": "Excluir “Era ”", "dateTime": "2026-11-25T10:09:48", "textRange": "1418, 1418, 393, 275"}, '
    '{ "index": 1, "author": "Ana Teste", "type": "Insert", "comment": "", "description": "Inserir “Ele miava.”", '
    '"dateTime": "2026-11-25T10:09:48", "textRange": "3517, 1418, 1026, 275"}, '
    '{ "index": 7, "author": "", "type": "ParagraphFormat", "description": "Atributos", "textRange": ""}]}';

void main() {
  test('a lista do AcceptTrackedChanges', () {
    final list = parseTrackedChanges(_list);
    expect(list.map((c) => c.index), [2, 1, 7]);
    expect(list[0].kind, TrackedChangeKind.delete);
    expect(list[0].author, 'Ana Teste');
    expect(list[0].description, 'Excluir “Era ”');
    expect(list[0].date, DateTime(2026, 11, 25, 10, 9, 48));
    expect(list[0].range, [const Rect.fromLTWH(1418, 1418, 393, 275)]);
    expect(list[1].kind, TrackedChangeKind.insert);
    expect(list[2].kind, TrackedChangeKind.format);
    expect(list[2].range, isEmpty);
    expect(parseTrackedChanges('{ "redlines": [ ]}'), isEmpty);
    expect(parseTrackedChanges('estragado'), isEmpty);
  });

  test('os callbacks 30 e 31 viram um aviso só', () {
    expect(LokQuillKit.translate(30, '{"redline": {"action": "Add"}}'), isA<TrackedChangesChanged>());
    expect(LokQuillKit.translate(31, '{"redline": {"action": "Modify"}}'), isA<TrackedChangesChanged>());
  });

  test('na ordem do texto, e as sem trecho no fim', () {
    final ordered = changesInTextOrder(parseTrackedChanges(_list));
    expect(ordered.map((c) => c.index), [2, 1, 7]);
    final other = changesInTextOrder([
      const TrackedChange(index: 1, range: [Rect.fromLTWH(900, 3000, 10, 10)]),
      const TrackedChange(index: 2, range: [Rect.fromLTWH(2000, 1418, 10, 10)]),
      const TrackedChange(index: 3, range: [Rect.fromLTWH(100, 1420, 10, 10)]),
    ]);
    expect(other.map((c) => c.index), [3, 2, 1]);
  });
}
