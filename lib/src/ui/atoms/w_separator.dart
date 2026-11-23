import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Um traço vertical entre grupos de controles.
class WSeparator extends StatelessWidget {
  const WSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return Container(
      width: 1,
      height: t.density.control,
      margin: EdgeInsets.symmetric(horizontal: t.space.md),
      color: t.colors.border,
    );
  }
}
