// As metas do livro (Fase 3, Etapa 9, D-083).
//
// As metas ficam no `livro.json` (as palavras do livro, o prazo e as do
// dia); a da sessão, só na memória (o `BookController`). O histórico fica em
// `metas.json`, ao lado:
//
//   {
//     "versao": 1,
//     "dias": {"2026-11-24": 640, ...},   as palavras escritas em cada dia
//     "base": {"dia": "2026-11-24", "capitulos": {"a": 1200, ...}}
//   }
//
// As palavras de hoje são a soma, por capítulo, do que ele cresceu desde a
// base do dia (as palavras dele no primeiro momento do dia em que o livro
// estava aberto). Um capítulo que encolheu conta zero, não negativo: cortar
// texto não é escrever ao contrário. Um capítulo que aparece no meio do dia
// (dividido, importado) entra na base com o que já tem; um capítulo novo e
// vazio entra com zero.
import 'dart:convert';
import 'dart:io';

import 'book.dart';

const goalsFileName = 'metas.json';

/// As metas do livro, no `livro.json`. Null: sem meta.
class BookGoals {
  const BookGoals({this.book, this.deadline, this.daily});

  /// As palavras do livro inteiro.
  final int? book;

  /// O dia do prazo da meta do livro (só a data).
  final DateTime? deadline;

  /// As palavras por dia.
  final int? daily;

  bool get isEmpty => book == null && deadline == null && daily == null;

  Map<String, Object?> toJson() => {
        if (book != null) 'livro': book,
        if (deadline != null) 'prazo': dayKey(deadline!),
        if (daily != null) 'dia': daily,
      };

  static BookGoals fromJson(Object? j) {
    if (j is! Map) return const BookGoals();
    int? positive(Object? v) => v is num && v > 0 ? v.toInt() : null;
    return BookGoals(
      book: positive(j['livro']),
      deadline: j['prazo'] is String ? DateTime.tryParse(j['prazo'] as String) : null,
      daily: positive(j['dia']),
    );
  }
}

/// "2026-11-24", na hora local.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// O histórico de `metas.json`.
class GoalLog {
  GoalLog({Map<String, int>? days, this.baseDay, Map<String, int>? base})
      : days = days ?? {},
        base = base ?? {};

  /// As palavras escritas por dia ("2026-11-24" → 640).
  final Map<String, int> days;

  /// O dia da [base]; null antes da primeira contagem.
  String? baseDay;

  /// As palavras de cada capítulo (pelo id) no começo do dia.
  final Map<String, int> base;

  static Map<String, int> _ints(Object? j) => {
        if (j is Map)
          for (final MapEntry(:key, :value) in j.entries)
            if (key is String && value is num) key: value.toInt(),
      };

  /// Lê o `metas.json` de [dir]; um arquivo que falta ou não se entende é um
  /// histórico vazio.
  static GoalLog read(String dir) {
    try {
      final j = jsonDecode(File('$dir/$goalsFileName').readAsStringSync());
      if (j is! Map) return GoalLog();
      final b = j['base'];
      return GoalLog(
        days: _ints(j['dias']),
        baseDay: b is Map && b['dia'] is String ? b['dia'] as String : null,
        base: b is Map ? _ints(b['capitulos']) : null,
      );
    } on FileSystemException {
      return GoalLog();
    } on FormatException {
      return GoalLog();
    }
  }

  Map<String, Object?> toJson() => {
        'versao': 1,
        'dias': days,
        if (baseDay != null) 'base': {'dia': baseDay, 'capitulos': base},
      };

  /// Grava de forma atômica, como o `livro.json`.
  void write(String dir) {
    final tmp = File('$dir/.$goalsFileName.tmp');
    tmp.writeAsStringSync(jsonEncode(toJson()), flush: true);
    tmp.renameSync('$dir/$goalsFileName');
  }

  /// Começa um dia novo, se [now] não é o dia da base: a base vira as
  /// palavras de agora. Devolve se mudou.
  bool roll(Book book, DateTime now) {
    final key = dayKey(now);
    if (baseDay == key) return false;
    baseDay = key;
    base
      ..clear()
      ..addAll({for (final c in book.chapters) c.id: c.words});
    return true;
  }

  /// Os capítulos que ainda não estão na base entram com as palavras que
  /// têm. Devolve se mudou.
  bool adopt(Book book) {
    var changed = false;
    for (final c in book.chapters) {
      if (!base.containsKey(c.id)) {
        base[c.id] = c.words;
        changed = true;
      }
    }
    return changed;
  }

  /// As palavras escritas desde a base: o capítulo [liveId] pelas
  /// [liveWords] (o que o motor conta agora), os outros pelo `livro.json`.
  int written(Book book, {String? liveId, int? liveWords}) {
    var sum = 0;
    for (final c in book.chapters) {
      final now = c.id == liveId && liveWords != null ? liveWords : c.words;
      final grew = now - (base[c.id] ?? now);
      if (grew > 0) sum += grew;
    }
    return sum;
  }

  /// As palavras dos [count] dias até [now] (o mais antigo primeiro), com
  /// [today] no lugar do de hoje.
  List<int> lastDays(DateTime now, int count, {int? today}) {
    final day = DateTime(now.year, now.month, now.day);
    return [
      for (var i = count - 1; i >= 0; i--)
        if (i == 0 && today != null) today else days[dayKey(DateTime(day.year, day.month, day.day - i))] ?? 0,
    ];
  }
}

/// O ritmo até o prazo: as palavras que faltam, os dias (contando hoje) e
/// quantas por dia. Null sem meta do livro ou sem prazo.
({int remaining, int days, int perDay})? goalPace(int words, BookGoals goals, DateTime now) {
  final target = goals.book, deadline = goals.deadline;
  if (target == null || deadline == null) return null;
  final remaining = target - words < 0 ? 0 : target - words;
  // Pelos dias do calendário (em UTC, sem o horário de verão), contando hoje.
  final days = DateTime.utc(deadline.year, deadline.month, deadline.day)
          .difference(DateTime.utc(now.year, now.month, now.day))
          .inDays +
      1;
  if (days <= 0) return (remaining: remaining, days: 0, perDay: remaining);
  return (remaining: remaining, days: days, perDay: (remaining / days).ceil());
}
