import 'package:flutter/material.dart';

import '../../core/theme.dart';

class EtatVide extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String texte;
  final Widget? action;

  const EtatVide({
    super.key,
    required this.icone,
    required this.titre,
    required this.texte,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icone, size: 20, color: c.muted),
          ),
          const SizedBox(height: 12),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.ink),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              texte,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5, color: c.muted),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}