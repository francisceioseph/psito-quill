// As metas do livro (Fase 3, Etapa 9, D-083): as palavras do livro com o
// prazo, as do dia e as da sessão, o progresso de cada uma, o ritmo que falta
// até o prazo e o gráfico dos últimos 30 dias. O progresso acompanha o que se
// digita nos campos; salvar grava as metas no `livro.json`.
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../book/book_controller.dart';
import '../../book/goals.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../atoms/w_text_field.dart';
import '../tokens/tokens.dart';
import 'goals_chart.dart';

/// Mostra as metas do livro aberto. [bookWords] e [today] são as palavras
/// do livro e as de hoje agora (com o capítulo da tela pelo motor).
Future<void> showGoalsDialog(BuildContext context, {required BookController books, required int bookWords, required int today}) =>
    showDialog<void>(context: context, builder: (_) => _GoalsDialog(books: books, bookWords: bookWords, today: today));

/// "12.000" ou "12 000" → 12000; vazio ou zero → null.
int? parseGoal(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  final v = int.tryParse(digits);
  return v == null || v <= 0 ? null : v;
}

class _GoalsDialog extends StatefulWidget {
  const _GoalsDialog({required this.books, required this.bookWords, required this.today});
  final BookController books;
  final int bookWords, today;

  @override
  State<_GoalsDialog> createState() => _GoalsDialogState();
}

class _GoalsDialogState extends State<_GoalsDialog> {
  late final BookGoals _start = widget.books.book!.goals;
  late final _book = TextEditingController(text: _start.book?.toString() ?? '');
  late final _daily = TextEditingController(text: _start.daily?.toString() ?? '');
  late final _session = TextEditingController(text: widget.books.sessionGoal?.toString() ?? '');
  late DateTime? _deadline = _start.deadline;

  @override
  void dispose() {
    _book.dispose();
    _daily.dispose();
    _session.dispose();
    super.dispose();
  }

  BookGoals get _goals => BookGoals(book: parseGoal(_book.text), deadline: _deadline, daily: parseGoal(_daily.text));

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline != null && !_deadline!.isBefore(today) ? _deadline! : today.add(const Duration(days: 30)),
      firstDate: today,
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null && mounted) setState(() => _deadline = picked);
  }

  void _save() {
    widget.books.setGoals(_goals, session: parseGoal(_session.text), today: widget.today);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final m = MaterialLocalizations.of(context);
    String n(int v) => m.formatDecimal(v);
    final books = widget.books;
    final goals = _goals;
    final session = parseGoal(_session.text);
    final pace = goalPace(widget.bookWords, goals, DateTime.now());
    final now = DateTime.now();
    final days = books.goalLog?.lastDays(now, 30, today: widget.today) ?? List.filled(30, 0);
    final total = days.fold(0, (s, v) => s + v), best = days.fold(0, (a, b) => a > b ? a : b);
    // As palavras da sessão: as de hoje menos as do começo dela (só se a
    // meta não mudou nesta janela; uma meta nova começa agora).
    final sessionDone = session != null && session == books.sessionGoal ? books.sessionWritten(widget.today) ?? 0 : 0;

    Widget field(String label, TextEditingController c, {bool autofocus = false}) => WTextField(
          label: label,
          hint: l10n.goalsEmptyHint,
          controller: c,
          width: 160,
          autofocus: autofocus,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _save(),
        );

    Widget row(String label, Widget child) => Padding(
          padding: EdgeInsets.only(bottom: t.space.md),
          child: Row(children: [
            SizedBox(width: 180, child: WLabel(label)),
            child,
          ]),
        );

    return AlertDialog(
      title: Text(l10n.goalsTitle(books.book!.title)),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              row(l10n.goalsBook, field(l10n.goalsBook, _book, autofocus: true)),
              row(
                l10n.goalsDeadline,
                Row(children: [
                  WTextButton(
                    label: _deadline == null ? l10n.goalsNoDeadline : m.formatMediumDate(_deadline!),
                    icon: Symbols.event_rounded,
                    onPressed: _pickDeadline,
                  ),
                  if (_deadline != null)
                    WButton(
                      icon: Symbols.close_rounded,
                      label: l10n.goalsClearDeadline,
                      onPressed: () => setState(() => _deadline = null),
                    ),
                ]),
              ),
              row(l10n.goalsDaily, field(l10n.goalsDaily, _daily)),
              row(l10n.goalsSession, field(l10n.goalsSession, _session)),
              WLabel(l10n.goalsSessionHint, small: true, tone: WLabelTone.muted, maxLines: 2),
              SizedBox(height: t.space.lg),
              const Divider(),
              SizedBox(height: t.space.md),
              WLabel(goals.book == null
                  ? l10n.goalsBookWords(n(widget.bookWords))
                  : l10n.goalsBookProgress(n(widget.bookWords), n(goals.book!), (100 * widget.bookWords / goals.book!).floor())),
              if (pace != null)
                WLabel(
                  pace.remaining == 0
                      ? l10n.goalsReached
                      : '${l10n.goalsPace(n(pace.remaining), n(pace.perDay))} · ${l10n.goalsDaysLeft(pace.days)}',
                  tone: WLabelTone.muted,
                  maxLines: 2,
                ),
              SizedBox(height: t.space.sm),
              WLabel(goals.daily == null ? l10n.goalsTodayWords(n(widget.today)) : l10n.goalsToday(n(widget.today), n(goals.daily!))),
              if (session != null) WLabel(l10n.goalsSessionProgress(n(sessionDone), n(session))),
              SizedBox(height: t.space.lg),
              WLabel(l10n.goalsChartTitle, small: true, tone: WLabelTone.muted),
              SizedBox(height: t.space.sm),
              GoalsChart(days: days, goal: goals.daily, semanticLabel: l10n.goalsChartLabel(n(total), n(best))),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dialogCancel)),
        FilledButton(onPressed: _save, child: Text(l10n.goalsSave)),
      ],
    );
  }
}
