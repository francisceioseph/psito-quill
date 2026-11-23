// Os átomos da Etapa 1 da Fase 2B (D-042): o ligado tonal, o ícone
// preenchido, e os átomos novos (WSegmented, WSwitch, WSlider, WChip), nos
// três temas, pelo mouse, pelo teclado e pelo leitor de tela.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/ui/atoms/w_button.dart';
import 'package:psito_quill/src/ui/atoms/w_chip.dart';
import 'package:psito_quill/src/ui/atoms/w_segmented.dart';
import 'package:psito_quill/src/ui/atoms/w_slider.dart';
import 'package:psito_quill/src/ui/atoms/w_switch.dart';
import 'package:psito_quill/src/ui/tokens/themes/themes.dart';
import 'package:psito_quill/src/ui/tokens/tokens.dart';

import 'helpers.dart';

void main() {
  for (final t in builtInThemes) {
    final name = t.id;

    testWidgets('WToggle ligado: tonal e com o ícone preenchido ($name)', (tester) async {
      await tester.pumpWidget(themed(Center(child: WToggle(icon: Icons.format_bold, label: 'N', value: true, onPressed: () {})), t));
      final icon = tester.widget<Icon>(find.byType(Icon));
      if (t.component == ComponentStyle.modern) {
        expect(icon.fill, 1);
        expect(icon.color, t.colors.onAccentSoft);
        final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration! as BoxDecoration;
        expect(box.color, t.colors.accentSoft);
      }
      expect(tester.getSize(find.byType(AnimatedContainer)).height, t.density.control);
    });

    testWidgets('WSegmented escolhe pelo clique e pelo teclado ($name)', (tester) async {
      final handle = tester.ensureSemantics();
      var value = 'texto';
      await tester.pumpWidget(themed(
        StatefulBuilder(
          builder: (context, setState) => Center(
            child: WSegmented<String>(
              label: 'Seção',
              segments: const [WSegment('texto', 'Texto'), WSegment('paragrafo', 'Parágrafo'), WSegment('pagina', 'Página')],
              selected: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
        t,
      ));
      expect(tester.getSemantics(find.bySemanticsLabel('Texto')), isSemantics(isSelected: true, isInMutuallyExclusiveGroup: true));
      await tester.tap(find.text('Página'));
      await tester.pump();
      expect(value, 'pagina');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(value, 'paragrafo');
      expect(tester.getSemantics(find.bySemanticsLabel('Parágrafo')), isSemantics(isSelected: true));
      handle.dispose();
    });

    testWidgets('WSwitch liga pelo clique e pelo Espaço, e diz o estado ($name)', (tester) async {
      final handle = tester.ensureSemantics();
      var value = false;
      await tester.pumpWidget(themed(
        StatefulBuilder(
          builder: (context, setState) =>
              Center(child: WSwitch(label: 'Reduzir movimento', value: value, onChanged: (v) => setState(() => value = v))),
        ),
        t,
      ));
      expect(tester.getSemantics(find.byType(WSwitch)), isSemantics(label: 'Reduzir movimento', hasToggledState: true, isToggled: false));
      await tester.tap(find.byType(WSwitch));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(value, isFalse);
      handle.dispose();
    });

    testWidgets('WSlider muda pelas setas e só avisa o fim ao soltar ($name)', (tester) async {
      var value = 100.0;
      double? end;
      await tester.pumpWidget(themed(
        StatefulBuilder(
          builder: (context, setState) => Center(
            child: WSlider(
              label: 'Zoom',
              value: value,
              min: 20,
              max: 500,
              divisions: 48,
              valueLabel: '${value.round()} %',
              onChanged: (v) => setState(() => value = v),
              onChangeEnd: (v) => end = v,
            ),
          ),
        ),
        t,
      ));
      await tester.drag(find.byType(Slider), const Offset(30, 0));
      await tester.pumpAndSettle();
      expect(value, greaterThan(100));
      expect(end, value);
    });

    testWidgets('WChip é um botão com estado de escolhido ($name)', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(themed(Center(child: WChip(label: 'Com serifa', selected: true, onPressed: () => taps++)), t));
      await tester.tap(find.byType(WChip));
      expect(taps, 1);
      expect(tester.getSemantics(find.byType(WChip)), isSemantics(label: 'Com serifa', isButton: true, isSelected: true));
      expect(tester.getSize(find.byType(AnimatedContainer)).height, 28);
      handle.dispose();
    });
  }

  testWidgets('a densidade confortável aumenta os botões para 44 px', (tester) async {
    final big = claro.copyWith(density: QuillDensity.comfortable);
    await tester.pumpWidget(themed(Center(child: WButton(icon: Icons.save, label: 'Salvar', onPressed: () {})), big));
    expect(tester.getSize(find.byType(AnimatedContainer)), const Size(44, 44));
    expect(tester.widget<Icon>(find.byType(Icon)).size, 24);
  });
}
