import 'package:flutter/material.dart';

import '../core/theme.dart';

enum Onglet { tableau, actions }

class BottomTabs extends StatelessWidget {
  final Onglet actif;
  final ValueChanged<Onglet> onChange;

  const BottomTabs({super.key, required this.actif, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = [
      (cle: Onglet.tableau, label: 'Tableau de bord', icone: Icons.dashboard_outlined),
      (cle: Onglet.actions, label: 'Actions & Stock', icone: Icons.inventory_2_outlined),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          for (final i in items) ...[
            Expanded(
              child: _OngletBouton(
                icone: i.icone,
                label: i.label,
                estActif: actif == i.cle,
                onTap: () => onChange(i.cle),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OngletBouton extends StatelessWidget {
  final IconData icone;
  final String label;
  final bool estActif;
  final VoidCallback onTap;

  const _OngletBouton({
    required this.icone,
    required this.label,
    required this.estActif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final couleur = estActif ? c.primary : c.muted;
    return Material(
      color: estActif ? c.primarySoft : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: 20, color: couleur),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: couleur),
              ),
            ],
          ),
        ),
      ),
    );
  }
}