import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/sub_screen.dart';
import '../widgets/ui/badge.dart';
import '../widgets/ui/empty_state.dart';

class PointagesScreen extends StatelessWidget {
  const PointagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final c = context.colors;
    final pointages = [...provider.pointages]..sort((a, b) => b.date.compareTo(a.date));

    final parJour = <String, List<Pointage>>{};
    for (final p in pointages) {
      parJour.putIfAbsent(p.date, () => []).add(p);
    }

    final aujourdhui = cleJour(DateTime.now());

    return SubScreen(
      titre: 'Pointages',
      sousTitre: "Arrivées et départs de l'équipe",
      enfant: parJour.isEmpty
          ? const EtatVide(
              icone: Icons.schedule_rounded,
              titre: 'Aucun pointage',
              texte: "Les arrivées et départs pointés par vos employés apparaîtront ici.",
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final e in parJour.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key == aujourdhui ? "Aujourd'hui" : jourLongDate(DateTime.parse(e.key)),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: c.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: c.line),
                            ),
                            child: Column(
                              children: [
                                for (final (i, p) in e.value.indexed)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: i > 0 ? Border(top: BorderSide(color: c.line)) : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: c.primarySoft,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            String.fromCharCode(p.employeNom.runes.first).toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: c.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p.employeNom,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: c.ink,
                                                ),
                                              ),
                                              Text(
                                                p.role.label,
                                                style: TextStyle(fontSize: 12, color: c.muted),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${p.heureArrivee} → ${p.heureDepart ?? '—'}',
                                              style: tnum(TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: c.ink,
                                              )),
                                            ),
                                            if (p.heureDepart == null)
                                              const Padding(
                                                padding: EdgeInsets.only(top: 4),
                                                child: Badge(
                                                  ton: TonBadge.primaire,
                                                  child: Text('En poste'),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}