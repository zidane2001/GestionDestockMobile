import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Feuille modale reproduisant le composant Sheet du design React :
/// coin supérieur arrondi, poignée, en-tête collant (titre + fermeture).
Future<T?> ouvrirFeuille<T>({
  required BuildContext context,
  required String titre,
  String? sousTitre,
  required Widget enfant,
  bool barrable = true,
}) {
  final c = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      final hauteurMax = MediaQuery.of(ctx).size.height * 0.86;
      return Container(
        height: hauteurMax,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 12, bottom: 12, left: 20, right: 12),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: c.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titre,
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c.ink),
                            ),
                            if (sousTitre != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(sousTitre, style: TextStyle(fontSize: 13, color: c.muted)),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: barrable ? () => Navigator.pop(ctx) : null,
                        tooltip: 'Fermer',
                        icon: Icon(Icons.close_rounded, size: 18, color: c.muted),
                        style: IconButton.styleFrom(
                          backgroundColor: c.surface2,
                          fixedSize: const Size(36, 36),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: enfant,
              ),
            ),
          ],
        ),
      );
    },
  );
}