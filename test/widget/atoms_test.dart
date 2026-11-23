import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/ui/atoms/w_button.dart';
import 'package:psito_quill/src/ui/atoms/w_dropdown.dart';
import 'package:psito_quill/src/ui/atoms/w_label.dart';
import 'package:psito_quill/src/ui/tokens/themes/themes.dart';
import 'package:psito_quill/src/ui/tokens/tokens.dart';

import 'helpers.dart';

/// Os temas de verdade e um com o estilo bisel (o do 97, que entra na Fase 2),
/// para a Strategy do ComponentStyle ser exercitada desde já.
final themes = [...builtInThemes, claro.copyWith(component: ComponentStyle.bevel)];

void main() {
  for (final t in themes) {
    final name = '${t.id}/${t.component.name}';

    testWidgets('WButton aperta pelo mouse e pelo teclado ($name)', (tester) async {
      var taps = 0;
      await tester.pumpWidget(themed(
          Center(child: WButton(icon: Icons.save_outlined, label: 'Salvar', onPressed: () => taps++)), t));
      await tester.tap(find.byType(WButton));
      expect(taps, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 2);
    });

    testWidgets('WToggle diz ao leitor de tela se está ligado ($name)', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(themed(
          Center(child: WToggle(icon: Icons.format_bold, label: 'Negrito', value: true, onPressed: () {})), t));
      expect(
          tester.getSemantics(find.byType(WToggle)),
          matchesSemantics(
              label: 'Negrito', isButton: true, hasToggledState: true, isToggled: true, hasEnabledState: true,
              isEnabled: true, isFocusable: true, hasTapAction: true, hasFocusAction: true));
      handle.dispose();
    });

    testWidgets('botão desligado não responde ($name)', (tester) async {
      await tester.pumpWidget(themed(const Center(child: WButton(icon: Icons.save_outlined, label: 'Salvar')), t));
      await tester.tap(find.byType(WButton));
      expect(tester.getSemantics(find.byType(WButton)).flagsCollection.isEnabled.toBoolOrNull(), isFalse);
    });

    testWidgets('as cores vêm dos tokens ($name)', (tester) async {
      await tester.pumpWidget(themed(const WLabel('oi', tone: WLabelTone.danger), t));
      final text = tester.widget<Text>(find.text('oi'));
      expect(text.style!.color, t.colors.danger);
    });
  }

  testWidgets('bisel ligado inverte as bordas (afundado)', (tester) async {
    final bevel = claro.copyWith(component: ComponentStyle.bevel);
    Border borderOf() => (tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .decoration! as BoxDecoration)
        .border! as Border;
    await tester.pumpWidget(themed(
        Center(child: WToggle(icon: Icons.format_bold, label: 'N', value: false, onPressed: () {})), bevel));
    expect(borderOf().top.color, bevel.colors.bevelLight);
    await tester.pumpWidget(themed(
        Center(child: WToggle(icon: Icons.format_bold, label: 'N', value: true, onPressed: () {})), bevel));
    expect(borderOf().top.color, bevel.colors.bevelDark);
  });

  testWidgets('WDropdown mostra o valor atual, abre e escolhe; o menu fecha', (tester) async {
    double? chosen;
    var closed = 0;
    await tester.pumpWidget(themed(
      Center(
        child: WDropdown<double>(
          label: 'Tamanho',
          text: '12',
          items: const [WDropdownItem(10, '10'), WDropdownItem(14, '14')],
          onSelected: (v) => chosen = v,
          onClosed: () => closed++,
        ),
      ),
      claro,
    ));
    expect(find.text('12'), findsOneWidget);
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('14'));
    await tester.pumpAndSettle();
    expect(chosen, 14);
    expect(closed, 1);
    expect(find.text('10'), findsNothing);
  });

  testWidgets('WDropdown desligado não abre', (tester) async {
    await tester.pumpWidget(themed(
      const Center(child: WDropdown<int>(label: 'Fonte', text: 'Serif', items: [WDropdownItem(1, 'Um')], onSelected: null)),
      claro,
    ));
    await tester.tap(find.text('Serif'));
    await tester.pumpAndSettle();
    expect(find.text('Um'), findsNothing);
  });

  testWidgets('WTextButton: a aba atual é "selecionada" para o leitor de tela', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(themed(
      Row(children: [
        WTextButton(label: 'Arquivo', onPressed: () {}),
        WTextButton(label: 'Início', selected: true, onPressed: () {}),
      ]),
      claro,
    ));
    expect(tester.getSemantics(find.bySemanticsLabel('Início')), isSemantics(label: 'Início', isButton: true, isSelected: true));
    expect(tester.getSemantics(find.bySemanticsLabel('Arquivo')), isSemantics(isSelected: false));
    handle.dispose();
  });
}
