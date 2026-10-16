import 'dart:io';

import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../core/format.dart';
import '../core/permissions.dart';
import '../core/stats.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/sales_chart.dart';
import '../widgets/sub_screen.dart';
import '../widgets/ui/badge.dart';
import '../widgets/ui/button.dart';
import '../widgets/ui/segmented_control.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  int _periode = 7;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final c = context.colors;
    final monnaie = provider.monnaie;
    final complet = peut(provider.session, Permission.voirPrixAchat);
    final jours = _periode;

    final periodeVentes = ventesRecentes(provider.ventes, jours);
    final serie = serieJournaliere(provider.ventes, jours, 'ca');
    final classement = classementProduits(periodeVentes);
    final ca = chiffreAffaires(periodeVentes);
    final marge = margeTotale(periodeVentes);
    final depensesPeriode = provider.depenses.where((d) =>
        DateTime.parse(d.date).millisecondsSinceEpoch >=
        DateTime.now().millisecondsSinceEpoch - jours * 86400000).toList();
    final tendanceV = tendance(provider.ventes, jours);

    final archives = <(String, double)>[];
    for (var s = 1; s <= 3; s++) {
      final fin = DateTime.now().millisecondsSinceEpoch - (s - 1) * 7 * 86400000;
      final debut = fin - 7 * 86400000;
      final lot = provider.ventes.where((v) {
        final t = DateTime.parse(v.date).millisecondsSinceEpoch;
        return t >= debut && t < fin;
      }).toList();
      archives.add((jourCourtDate(DateTime.fromMillisecondsSinceEpoch(debut)), chiffreAffaires(lot)));
    }

    Future<void> exporter() async {
      final entete = complet
          ? ['Date', 'Produit', 'Quantité', 'Prix de vente', "Prix d'achat", 'Marge', 'Total', 'Vendeur']
          : ['Date', 'Produit', 'Quantité', 'Prix de vente', 'Total', 'Vendeur'];
      final lignes = periodeVentes.map((v) => complet
          ? [
              dateHeure(v.date),
              v.produitNom,
              v.quantite,
              v.prixUnitaireReel,
              v.prixAchatUnitaire,
              (v.prixUnitaireReel - v.prixAchatUnitaire) * v.quantite,
              v.total,
              v.vendeurNom,
            ]
          : [
              dateHeure(v.date),
              v.produitNom,
              v.quantite,
              v.prixUnitaireReel,
              v.total,
              v.vendeurNom,
            ]).toList();
      final csv = exporterCsvContent([entete, ...lignes]);
      
      // Sauvegarder et partager
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/rapport_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Rapport de ventes');
    }

    return SubScreen(
      titre: complet ? 'Rapports & export' : 'Rapport hebdomadaire',
      sousTitre: complet ? 'Données complètes, marges incluses' : 'Sans données de prix d’achat',
      enfant: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (complet)
              Align(
                alignment: Alignment.centerLeft,
                child: ControleSegmente<int>(
                  libelle: 'Période du rapport',
                  options: const [
                    OptionSegmente(7, '7 jours'),
                    OptionSegmente(30, '30 jours'),
                  ],
                  valeur: _periode,
                  onChange: (v) => setState(() => _periode = v),
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Chiffre d'affaires · $jours j",
                              style: TextStyle(fontSize: 12, color: c.muted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatMontant(ca, monnaie),
                              style: tnum(TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                color: c.ink,
                              )),
                            ),
                          ],
                        ),
                      ),
                      Badge(
                        ton: tendanceV >= 0 ? TonBadge.succes : TonBadge.danger,
                        child: Text('${tendanceV >= 0 ? '+' : ''}$tendanceV %'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SalesChart(points: serie, monnaie: monnaie, hauteur: 116),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: c.line)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pièces vendues', style: TextStyle(fontSize: 12, color: c.muted)),
                              Text(
                                piecesVendues(periodeVentes).round().toString(),
                                style: tnum(TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c.ink)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nombre de ventes', style: TextStyle(fontSize: 12, color: c.muted)),
                              Text(
                                '${periodeVentes.length}',
                                style: tnum(TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c.ink)),
                              ),
                            ],
                          ),
                        ),
                        if (complet) ...[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Marge brute', style: TextStyle(fontSize: 12, color: c.muted)),
                                Text(
                                  formatMontant(marge, monnaie),
                                  style: tnum(TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c.ink)),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bénéfice net', style: TextStyle(fontSize: 12, color: c.muted)),
                                Text(
                                  formatMontant(marge - depensesPeriode.fold(0.0, (s, d) => s + d.montant), monnaie),
                                  style: tnum(TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c.ink)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.line)),
                    ),
                    child: Text(
                      'Par produit',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.ink),
                    ),
                  ),
                  if (classement.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Aucune vente sur la période.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                    )
                  else
                    for (final l in classement)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: c.line)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.nom,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                                  ),
                                  Text(
                                    '${l.pieces.round()} pièce${l.pieces > 1 ? 's' : ''} · ${formatMontant(l.ca, monnaie)}',
                                    style: tnum(TextStyle(fontSize: 12, color: c.muted)),
                                  ),
                                ],
                              ),
                            ),
                            if (complet)
                              Text(
                                '+${formatMontant(l.marge, monnaie)}',
                                style: tnum(TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: c.accent,
                                )),
                              ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
            if (complet) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: c.line)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_outlined, size: 16, color: c.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Archives hebdomadaires',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.ink),
                          ),
                        ],
                      ),
                    ),
                    for (final (i, a) in archives.indexed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: c.line)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.description_outlined, size: 16, color: c.muted),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Semaine du ${a.$1}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                                  ),
                                  Text(
                                    formatMontant(a.$2, monnaie),
                                    style: tnum(TextStyle(fontSize: 12, color: c.muted)),
                                  ),
                                ],
                              ),
                            ),
                            if (i == 0)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Badge(
                                  ton: TonBadge.primaire,
                                  child: Text('Dernier'),
                                ),
                              ),
                            Material(
                              color: c.surface2,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () =>
                                    provider.notifier('Rapport archivé prêt au partage.', TonToast.info),
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Icon(Icons.share_outlined, size: 15, color: c.muted),
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
            const SizedBox(height: 16),
            Bouton(
              taille: TailleBouton.lg,
              pleineLargeur: true,
              onPressed: exporter,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_rounded, size: 17),
                  SizedBox(width: 8),
                  Text('Exporter en CSV'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Le fichier s'ouvre dans Excel et se partage via WhatsApp, email ou fichiers."
              '${complet ? '' : ' Les prix d’achat ne sont jamais inclus.'}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.5, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}