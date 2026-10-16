import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/permissions.dart';
import '../core/stats.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/sales_chart.dart';
import '../widgets/shared_helpers.dart';
import '../widgets/ui/badge.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/segmented_control.dart';
import 'journal_screen.dart';
import 'pointages_screen.dart';
import 'rapports_screen.dart';
import 'retours_screen.dart';

class TableauDeBordView extends StatefulWidget {
  final VoidCallback onOuvrirActions;

  const TableauDeBordView({super.key, required this.onOuvrirActions});

  @override
  State<TableauDeBordView> createState() => _TableauDeBordViewState();
}

class _TableauDeBordViewState extends State<TableauDeBordView> {
  int _periode = 7;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final c = context.colors;
    final monnaie = provider.monnaie;
    final acteur = provider.session;
    final historiqueComplet = peut(acteur, Permission.historiqueComplet);
    final jours = _periode;

    final mesVentes = historiqueComplet
        ? provider.ventes
        : provider.ventes.where((v) => v.vendeurId == acteur?.id).toList();
    final periodeVentes = ventesRecentes(mesVentes, jours);
    final serieCA = serieJournaliere(mesVentes, jours, 'ca');
    final serieMarge = serieJournaliere(provider.ventes, jours, 'marge');
    final aujourdhui = ventesRecentes(mesVentes, 1);
    final top = classementProduits(periodeVentes).take(4).toList();
    final variation = tendance(mesVentes, jours);
    final marge = margeTotale(ventesRecentes(provider.ventes, jours));
    final ca = chiffreAffaires(periodeVentes);
    final tauxMarge = ca > 0 ? (marge / ca * 100).round() : 0;
    final retoursEnAttente = provider.retours.where((r) => r.statut == StatutRetour.enAttente).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        if (provider.boutique?.notificationAbonnement == true &&
            (provider.boutique?.abonnementProche ?? false))
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.accent.withValues(alpha: 0.30)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.event_repeat_rounded, size: 16, color: c.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Abonnement ${provider.boutique!.abonnementLabel.toLowerCase()} — '
                    'renouvellement avant le ${dateCourt(provider.boutique!.abonnementFin!)}. '
                    'Paiement par ${provider.boutique!.methodePaiement.isEmpty ? 'la méthode choisie' : provider.boutique!.methodePaiement}.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      color: c.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (provider.boutique?.notificationAbonnement == true &&
            (provider.boutique?.abonnementExpire ?? false))
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: c.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.danger.withValues(alpha: 0.30)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: c.danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Abonnement expiré le ${dateCourt(provider.boutique!.abonnementFin!)}. '
                    'Régularisez-le auprès de votre administrateur pour continuer à utiliser la boutique.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      color: c.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (!provider.enLigne)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.accent.withValues(alpha: 0.30)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cloud_off_rounded, size: 16, color: c.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hors-ligne — ${provider.enAttenteSync} opération${provider.enAttenteSync > 1 ? 's' : ''} en attente. Tout sera envoyé à l\'équipe dès le retour du réseau.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      color: c.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 15, color: c.onPrimary.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  Text(
                    'Solde de la caisse',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatMontant(provider.boutique?.soldeCaisse ?? 0, monnaie),
                style: tnum(TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -0.5,
                  color: c.onPrimary,
                )),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.onPrimary.withValues(alpha: 0.20))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ventes du jour',
                            style: TextStyle(fontSize: 13, color: c.onPrimary.withValues(alpha: 0.75)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatMontant(chiffreAffaires(aujourdhui), monnaie),
                            style: tnum(TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c.onPrimary)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pièces vendues',
                            style: TextStyle(fontSize: 13, color: c.onPrimary.withValues(alpha: 0.75)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            piecesVendues(aujourdhui).round().toString(),
                            style: tnum(TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c.onPrimary)),
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

        const SizedBox(height: 16),

        if (peut(acteur, Permission.voirCourbeVentes))
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
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Évolution des ventes',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.ink),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                formatMontant(ca, monnaie),
                                style: tnum(TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.ink)),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'sur $jours jours',
                                style: TextStyle(fontSize: 12, color: c.muted),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                variation >= 0
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                size: 11,
                                color: variation >= 0 ? c.success : c.danger,
                              ),
                              Text(
                                '${variation.abs()} %',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: variation >= 0 ? c.success : c.danger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ControleSegmente<int>(
                      options: const [
                        OptionSegmente(7, '7 j'),
                        OptionSegmente(30, '30 j'),
                      ],
                      valeur: _periode,
                      onChange: (v) => setState(() => _periode = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SalesChart(points: serieCA, monnaie: monnaie),
              ],
            ),
          )
        else
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
                Text('Mes ventes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.ink)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Aujourd'hui", style: TextStyle(fontSize: 12, color: c.muted)),
                            const SizedBox(height: 2),
                            Text(
                              formatMontant(chiffreAffaires(aujourdhui), monnaie),
                              style: tnum(TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c.ink)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('7 derniers jours', style: TextStyle(fontSize: 12, color: c.muted)),
                            const SizedBox(height: 2),
                            Text(
                              formatMontant(chiffreAffaires(ventesRecentes(mesVentes, 7)), monnaie),
                              style: tnum(TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c.ink)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        if (peut(acteur, Permission.voirBenefices)) ...[
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bénéfices', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.ink)),
                          const SizedBox(height: 2),
                          Text(
                            'Marges des produits vendus − dépenses',
                            style: TextStyle(fontSize: 12, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    Badge(
                      ton: TonBadge.accent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up_rounded, size: 11),
                          const SizedBox(width: 2),
                          Text('marge $tauxMarge %'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Marge sur $jours j', style: TextStyle(fontSize: 12, color: c.muted)),
                            const SizedBox(height: 2),
                            Text(
                              formatMontant(marge, monnaie),
                              style: tnum(TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c.ink)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bénéfice net', style: TextStyle(fontSize: 12, color: c.muted)),
                            const SizedBox(height: 2),
                            Text(
                              formatMontant(
                                beneficeNet(
                                  ventesRecentes(provider.ventes, jours),
                                  provider.depenses
                                      .where((d) => DateTime.parse(d.date).millisecondsSinceEpoch >=
                                          DateTime.now().millisecondsSinceEpoch - jours * 86400000)
                                      .toList(),
                                ),
                                monnaie,
                              ),
                              style: tnum(TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c.ink)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SalesChart(points: serieMarge, monnaie: monnaie, hauteur: 104, accent: true),
              ],
            ),
          ),
        ],

        if (peut(acteur, Permission.voirCourbeVentes)) ...[
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
                Text(
                  'Produits les plus vendus',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.ink),
                ),
                const SizedBox(height: 12),
                if (top.isEmpty)
                  Text('Aucune vente sur la période.', style: TextStyle(fontSize: 13, color: c.muted))
                else
                  for (final (i, l) in top.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Expanded(
                                child: Text(
                                  '${i + 1}. ${l.nom}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink),
                                ),
                              ),
                              Text(
                                '${l.pieces.round()} pc · ${formatMontant(l.ca, monnaie)}',
                                style: tnum(TextStyle(fontSize: 13, color: c.muted)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: (l.pieces / (top.first.pieces > 0 ? top.first.pieces : 1)).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: c.surface2,
                              valueColor: AlwaysStoppedAnimation(c.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],

        if (peut(acteur, Permission.exporter) || peut(acteur, Permission.journal)) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              if (peut(acteur, Permission.exporter))
                Expanded(
                  child: _Raccourci(
                    icone: Icons.download_rounded,
                    label: peut(acteur, Permission.voirPrixAchat) ? 'Rapports & export' : 'Rapport hebdo',
                    surTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RapportsScreen()),
                    ),
                  ),
                ),
              if (peut(acteur, Permission.journal)) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _Raccourci(
                    icone: Icons.history_rounded,
                    label: "Journal d'activité",
                    surTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JournalScreen()),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
        if (peut(acteur, Permission.pointages) || peut(acteur, Permission.traiterRetours)) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (peut(acteur, Permission.pointages))
                Expanded(
                  child: _Raccourci(
                    icone: Icons.schedule_rounded,
                    label: 'Pointages',
                    surTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PointagesScreen()),
                    ),
                  ),
                ),
              if (peut(acteur, Permission.traiterRetours)) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _Raccourci(
                    icone: Icons.fact_check_outlined,
                    label: 'Retours',
                    badge: retoursEnAttente,
                    surTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RetoursScreen()),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],

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
                    Expanded(
                      child: Text(
                        historiqueComplet ? 'Historique des ventes' : 'Mes ventes',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.ink),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onOuvrirActions,
                      style: TextButton.styleFrom(
                        foregroundColor: c.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Enregistrer une vente'),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, size: 13),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (mesVentes.isEmpty)
                EtatVide(
                  icone: Icons.receipt_long_outlined,
                  titre: "Aucune vente pour l'instant",
                  texte: "Les ventes enregistrées par l'équipe apparaîtront ici, avec le nom du vendeur.",
                )
              else
                for (final v in mesVentes.take(12).toList())
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
                                v.produitNom,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${v.quantite.round()} × ${formatMontant(v.prixUnitaireReel, monnaie)} · '
                                '${historiqueComplet ? '${v.vendeurNom} (${v.vendeurRole.label})' : ilYA(v.date)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: c.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatMontant(v.total, monnaie),
                              style: tnum(TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: c.ink)),
                            ),
                            Text(
                              dateHeure(v.date),
                              style: tnum(TextStyle(fontSize: 12, color: c.muted)),
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
    );
  }
}

class _Raccourci extends StatelessWidget {
  final IconData icone;
  final String label;
  final int badge;
  final VoidCallback surTap;

  const _Raccourci({required this.icone, required this.label, this.badge = 0, required this.surTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: surTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              Icon(icone, size: 17, color: c.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink),
                ),
              ),
              if (badge > 0)
                Badge(
                  ton: TonBadge.danger,
                  child: Text('$badge'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}