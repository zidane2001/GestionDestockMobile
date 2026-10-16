import 'package:flutter/material.dart';

import '../../core/theme.dart';

enum TonBadge { neutre, primaire, succes, danger, accent }

class Badge extends StatelessWidget {
  final TonBadge ton;
  final Widget child;

  const Badge({super.key, this.ton = TonBadge.neutre, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (fond, texte, bordure) = switch (ton) {
      TonBadge.neutre => (c.surface2, c.muted, c.line),
      TonBadge.primaire => (c.primarySoft, c.primary, c.primary.withValues(alpha: 0.25)),
      TonBadge.succes => (c.success.withValues(alpha: 0.10), c.success, c.success.withValues(alpha: 0.25)),
      TonBadge.danger => (c.danger.withValues(alpha: 0.10), c.danger, c.danger.withValues(alpha: 0.25)),
      TonBadge.accent => (c.accent.withValues(alpha: 0.10), c.accent, c.accent.withValues(alpha: 0.25)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bordure),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: texte,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [child],
        ),
      ),
    );
  }
}