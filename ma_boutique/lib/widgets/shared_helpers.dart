import 'package:flutter/material.dart';
import '../core/theme.dart';

IconData iconeCategorie(String cat) {
  switch (cat) {
    case 'vetement':
      return Icons.checkroom_rounded;
    case 'chaussure':
      return Icons.sports_football_rounded;
    case 'accessoire':
      return Icons.watch_rounded;
    case 'beaute':
      return Icons.face_rounded;
    case 'maison':
      return Icons.home_rounded;
    default:
      return Icons.inventory_2_rounded;
  }
}

Color couleurCategorie(String cat) {
  switch (cat) {
    case 'vetement':
      return const Color(0xFF4A90D9);
    case 'chaussure':
      return const Color(0xFFD4A76A);
    case 'accessoire':
      return const Color(0xFF9B59B6);
    case 'beaute':
      return const Color(0xFFE91E8C);
    case 'maison':
      return const Color(0xFF2ECC71);
    default:
      return const Color(0xFF95A5A6);
  }
}

String dateCourt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class Compteur extends StatelessWidget {
  final String label;
  final int valeur;

  const Compteur({super.key, required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$valeur',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c.ink),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
          ],
        ),
      ),
    );
  }
}

class PuceFiltre extends StatelessWidget {
  final String label;
  final bool actif;
  final VoidCallback surTap;

  const PuceFiltre({super.key, required this.label, required this.actif, required this.surTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: actif ? c.primarySoft : c.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: surTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: actif ? c.primary : c.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: actif ? c.primary : c.muted,
            ),
          ),
        ),
      ),
    );
  }
}
