import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/sub_screen.dart';
import '../widgets/ui/badge.dart';
import '../widgets/ui/button.dart';
import '../widgets/ui/empty_state.dart';

class AppareilsScreen extends StatelessWidget {
  const AppareilsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final c = context.colors;
    final appareils = provider.appareils;
    final actifs = appareils.where((a) => a.actif).length;

    return SubScreen(
      titre: 'Appareils connectés',
      sousTitre: '$actifs appareil(s) autorisé(s)',
      enfant: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Chaque téléphone est enregistré au premier lancement. Révoquez un appareil inconnu : il est déconnecté immédiatement et ne peut plus se reconnecter.',
              style: TextStyle(fontSize: 13, height: 1.5, color: c.muted),
            ),
            const SizedBox(height: 16),
            if (appareils.isEmpty)
              const EtatVide(
                icone: Icons.smartphone_rounded,
                titre: 'Aucun appareil',
                texte: 'Les téléphones apparaîtront ici au premier lancement.',
              ),
            for (final a in appareils)
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
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: a.actif ? c.primarySoft : c.surface2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.smartphone_rounded,
                            size: 18,
                            color: a.actif ? c.primary : c.muted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.nomAppareil,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                              ),
                              Text(
                                '${a.role.label} · ${a.employeNom} · ${ilYA(a.derniereConnexion)}',
                                style: TextStyle(fontSize: 12, color: c.muted),
                              ),
                            ],
                          ),
                        ),
                        Badge(
                          ton: a.actif ? TonBadge.succes : TonBadge.danger,
                          child: Text(a.actif ? 'Autorisé' : 'Révoqué'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Bouton(
                      taille: TailleBouton.sm,
                      variante: a.actif ? VarianteBouton.danger : VarianteBouton.secondaire,
                      onPressed: () => provider.revoquerAppareil(a.id),
                      child: Text(a.actif ? 'Révoquer cet appareil' : 'Autoriser à nouveau'),
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