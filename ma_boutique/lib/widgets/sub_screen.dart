import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Écran secondaire avec en-tête (retour, titre, action) et contenu défilant.
class SubScreen extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  final Widget? action;
  final Widget enfant;

  const SubScreen({
    super.key,
    required this.titre,
    this.sousTitre,
    this.action,
    required this.enfant,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  Material(
                    color: c.surface2,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(Icons.chevron_left_rounded, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c.ink),
                        ),
                        if (sousTitre != null)
                          Text(
                            sousTitre!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: c.muted),
                          ),
                      ],
                    ),
                  ),
                  ?action,
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: enfant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}