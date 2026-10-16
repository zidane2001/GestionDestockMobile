import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/shared_helpers.dart';
import '../widgets/sub_screen.dart';
import '../widgets/ui/empty_state.dart';

const _filtres = [
  (cle: 'tous', label: 'Tout'),
  (cle: 'vente', label: 'Ventes'),
  (cle: 'depense', label: 'Dépenses'),
  (cle: 'produit', label: 'Produits'),
  (cle: 'retour', label: 'Retours'),
  (cle: 'pointage', label: 'Pointages'),
  (cle: 'compte', label: 'Comptes'),
  (cle: 'connexion', label: 'Connexions'),
];

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String _type = 'tous';
  String _employe = 'tous';
  int _periode = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final c = context.colors;
    final limite = DateTime.now().millisecondsSinceEpoch - _periode * 86400000;
    final liste = provider.activites
        .where((a) =>
            (_type == 'tous' || a.type.name == _type) &&
            (_employe == 'tous' || a.employeNom == _employe) &&
            (_periode == 0 || DateTime.parse(a.date).millisecondsSinceEpoch >= limite))
        .toList();

    return SubScreen(
      titre: "Journal d'activité",
      sousTitre: '${liste.length} événement(s)',
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: c.canvas,
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in _filtres)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: PuceFiltre(
                            label: f.label,
                            actif: _type == f.cle,
                            surTap: () => setState(() => _type = f.cle),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      PuceFiltre(
                        label: 'Toute l’équipe',
                        actif: _employe == 'tous',
                        surTap: () => setState(() => _employe = 'tous'),
                      ),
                      for (final e in provider.employes)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: PuceFiltre(
                            label: e.nom,
                            actif: _employe == e.nom,
                            surTap: () => setState(() => _employe = e.nom),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (v, label) in [
                        (1, 'Aujourd’hui'),
                        (7, '7 derniers jours'),
                        (30, '30 derniers jours'),
                        (0, 'Toute la période'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: PuceFiltre(
                            label: label,
                            actif: _periode == v,
                            surTap: () => setState(() => _periode = v),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (liste.isEmpty)
            const EtatVide(
              icone: Icons.history_rounded,
              titre: 'Aucun événement',
              texte: 'Aucune action ne correspond à ces filtres.',
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, a) in liste.indexed)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: c.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (i < liste.length - 1)
                                Expanded(
                                  child: Container(width: 1, color: c.line),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: i < liste.length - 1 ? 20 : 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                      color: c.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${a.employeNom} (${a.employeRole.label}) · ${dateHeure(a.date)}',
                                    style: tnum(TextStyle(fontSize: 12, color: c.muted)),
                                  ),
                                ],
                              ),
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
    );
  }
}