import 'package:flutter/material.dart';

import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../tokens/tokens.dart';

/// Uma faixa de aviso acima do documento (só leitura, por exemplo), com uma
/// ação.
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.icon, required this.text, this.actionLabel, this.onAction});

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: t.space.lg, vertical: t.space.sm),
        decoration: BoxDecoration(
          color: t.colors.accentSoft,
          border: Border(bottom: BorderSide(color: t.colors.border)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: t.colors.onFrame),
          SizedBox(width: t.space.md),
          Expanded(child: WLabel(text, maxLines: 2)),
          if (actionLabel case final label?) ...[
            SizedBox(width: t.space.md),
            WTextButton(label: label, onPressed: onAction),
          ],
        ]),
      ),
    );
  }
}
