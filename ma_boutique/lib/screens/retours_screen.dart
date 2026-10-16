import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/shared_helpers.dart';
import '../widgets/sub_screen.dart';
import '../widgets/ui/badge.dart';
import '../widgets/ui/button.dart';
import '../widgets/ui/empty_state.dart';

class RetoursScreen extends StatefulWidget {
  const RetoursScreen({super.key});

  @override
  State<RetoursScreen> createState() => _RetoursScreenState();
}

class _RetoursScreenState extends State<RetoursScreen> {
  StatutRetour? _filtre = StatutRetour.enAttente;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final c = context.colors;
    final monnaie = provider.monnaie;
    final enAttente = provider.retours.where((r) => r.statut == StatutRetour.enAttente).length;
    final liste = provider.retours
        .where((r) => _filtre == null || r.statut == _filtre)
        .toList();

    return SubScreen(
      titre: 'Retours & défectueux',
      sousTitre: '$enAttente en attente de traitement',
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: c.canvas,
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (f, label) in [
                    (StatutRetour.enAttente, 'En attente'),
                    (StatutRetour.traite, 'Traité'),
                    (StatutRetour.refuse, 'Refusé'),
                    (null, 'Tous'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: PuceFiltre(
                        label: label,
                        actif: _filtre == f,
                        surTap: () => setState(() => _filtre = f),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (liste.isEmpty)
            const EtatVide(
              icone: Icons.swap_horiz_rounded,
              titre: 'Aucun retour',
              texte: "Les retours et articles défectueux signalés par l'équipe s'afficheront ici.",
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final r in liste)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.produitNom,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: c.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${r.motif.label}'
                                      '${r.montant > 0 ? ' · ${formatMontant(r.montant, monnaie)}' : ''}'
                                      ' · ${r.auteurNom}',
                                      style: TextStyle(fontSize: 12, color: c.muted),
                                    ),
                                  ],
                                ),
                              ),
                              Badge(
                                ton: r.statut == StatutRetour.traite
                                    ? TonBadge.succes
                                    : r.statut == StatutRetour.refuse
                                        ? TonBadge.danger
                                        : TonBadge.accent,
                                child: Text(r.statut.label),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: c.surface2,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              r.description,
                              style: TextStyle(fontSize: 13, height: 1.3, color: c.ink),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dateHeure(r.date),
                            style: tnum(TextStyle(fontSize: 12, color: c.muted)),
                          ),
                          if (r.statut == StatutRetour.enAttente) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Bouton(
                                  taille: TailleBouton.sm,
                                  onPressed: () => provider.traiterRetour(r.id, StatutRetour.traite),
                                  child: const Text('Marquer traité'),
                                ),
                                const SizedBox(width: 8),
                                Bouton(
                                  taille: TailleBouton.sm,
                                  variante: VarianteBouton.secondaire,
                                  onPressed: () => provider.traiterRetour(r.id, StatutRetour.refuse),
                                  child: const Text('Refuser'),
                                ),
                              ],
                            ),
                          ],
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