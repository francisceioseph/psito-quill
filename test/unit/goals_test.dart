// As metas do livro (Fase 3, Etapa 9, D-083): o `livro.json`, o histórico
// em `metas.json`, as palavras de hoje (sem contar o que se cortou) e o ritmo
// até o prazo.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/book/book.dart';
import 'package:psito_quill/src/book/goals.dart';

void main() {
  BookNode chapter(String id, int words) => BookNode(id: id, kind: BookNodeKind.chapter, title: id, words: words);

  test('as metas vão e voltam no livro.json; sem metas, nada fica lá', () {
    final book = Book(title: 'D', goals: BookGoals(book: 90000, deadline: DateTime(2027, 3, 1), daily: 1000));
    final back = Book.fromJson(book.toJson());
    expect(back.goals.book, 90000);
    expect(back.goals.deadline, DateTime(2027, 3, 1));
    expect(back.goals.daily, 1000);
    expect(Book(title: 'D').toJson().containsKey('metas'), isFalse);
    expect(BookGoals.fromJson({'livro': 0, 'dia': -3, 'prazo': 'ontem'}).isEmpty, isTrue);
  });

  test('as palavras de hoje: o que cresceu desde a base, cortar não desconta', () {
    final a = chapter('a', 1000), b = chapter('b', 500);
    final book = Book(title: 'D', nodes: [a, b]);
    final log = GoalLog();
    expect(log.roll(book, DateTime(2026, 11, 24, 9)), isTrue);
    expect(log.roll(book, DateTime(2026, 11, 24, 23)), isFalse, reason: 'o mesmo dia');
    a.words = 1300;
    b.words = 200; // cortou 300 no b
    expect(log.written(book), 300);
    // O da tela pelo motor.
    expect(log.written(book, liveId: 'b', liveWords: 650), 450);
    // Um capítulo que aparece no meio do dia entra com o que tem.
    final c = chapter('c', 800);
    book.nodes.add(c);
    expect(log.written(book), 300);
    expect(log.adopt(book), isTrue);
    c.words = 850;
    expect(log.written(book), 350);
    // Outro dia: a base vira o de agora.
    log.days['2026-11-24'] = 350;
    expect(log.roll(book, DateTime(2026, 11, 25, 0, 1)), isTrue);
    expect(log.written(book), 0);
  });

  test('o metas.json vai e volta; os últimos dias, com o de hoje ao vivo', () {
    final dir = Directory.systemTemp.createTempSync('pq-metas');
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(GoalLog.read(dir.path).days, isEmpty, reason: 'sem arquivo');
    final log = GoalLog(days: {'2026-11-22': 400, '2026-11-24': 640}, baseDay: '2026-11-24', base: {'a': 12});
    log.write(dir.path);
    final back = GoalLog.read(dir.path);
    expect(back.days, {'2026-11-22': 400, '2026-11-24': 640});
    expect(back.baseDay, '2026-11-24');
    expect(back.base, {'a': 12});
    expect(back.lastDays(DateTime(2026, 11, 24, 15), 4, today: 700), [0, 400, 0, 700]);
    // Na virada do mês.
    expect(GoalLog(days: {'2026-11-30': 5}).lastDays(DateTime(2026, 12, 1), 2), [5, 0]);
    File('${dir.path}/metas.json').writeAsStringSync('{quebrado');
    expect(GoalLog.read(dir.path).days, isEmpty);
  });

  test('o ritmo até o prazo conta hoje e os dias do calendário', () {
    final goals = BookGoals(book: 10000, deadline: DateTime(2026, 11, 28));
    final p = goalPace(6000, goals, DateTime(2026, 11, 24, 22))!;
    expect(p.days, 5);
    expect(p.remaining, 4000);
    expect(p.perDay, 800);
    expect(goalPace(12000, goals, DateTime(2026, 11, 24))!.remaining, 0);
    expect(goalPace(6000, goals, DateTime(2026, 11, 30))!.days, 0, reason: 'o prazo passou');
    expect(goalPace(6000, const BookGoals(book: 1), DateTime(2026, 11, 24)), isNull);
  });
}
