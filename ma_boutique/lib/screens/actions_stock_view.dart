import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/permissions.dart';
import '../core/stats.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/ui/badge.dart';
import '../widgets/ui/button.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/field.dart';
import 'home_screen.dart';
import 'produit_detail_screen.dart';

class ActionsStockView extends StatefulWidget {
  final Future<void> Function(TypeSheet type, {Produit? produit}) onOuvrirSheet;

  const ActionsStockView({super.key, required this.onOuvrirSheet});

  @override
  State<ActionsStockView> createState() => _ActionsStockViewState();
}

class _ActionsStockViewState extends State<ActionsStockView> {
  String _requete = '';
  String? _aSupprimerId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final c = context.colors;
    final monnaie = provider.monnaie;
    final acteur = provider.session;

    final actifs = provider.produits.where((p) => p.actif).toList();
    final liste = rechercheProduits(actifs, _requete);
    final ruptures = actifs.where((p) => p.quantite == 0).length;

    final nouveautes = actifs
        .where((p) => p.estNouveau)
        .toList()
      ..sort((a, b) => (b.dateAjout ?? DateTime(0)).compareTo(a.dateAjout ?? DateTime(0)));

    final jour = cleJour(DateTime.now());
    Pointage? monPointage;
    for (final p in provider.pointages) {
      if (p.employeId == acteur?.id && p.date == jour) monPointage = p;
    }

    final actions = <(TypeSheet, String, String, IconData, bool)>[
      if (peut(acteur, Permission.vendre))
        (TypeSheet.vente, 'Enregistrer une vente', 'Article vendu', Icons.shopping_cart_outlined, true),
      if (peut(acteur, Permission.defectueux))
        (TypeSheet.defectueux, 'Article défectueux', 'Retirer du stock', Icons.warning_amber_rounded, false),
      if (peut(acteur, Permission.retour))
        (TypeSheet.retour, 'Retour produit', 'Remboursement / échange', Icons.swap_horiz_rounded, false),
      if (peut(acteur, Permission.depense))
        (TypeSheet.depense, 'Dépense', 'Loyer, factures…', Icons.receipt_long_outlined, false),
      if (peut(acteur, Permission.sortieCaisse))
        (TypeSheet.sortie, 'Sortie de caisse', 'Justifier une diminution', Icons.account_balance_outlined, false),
      if (peut(acteur, Permission.gererProduits))
        (TypeSheet.produit, 'Ajouter un produit', 'Nouvel article en stock', Icons.add_box_outlined, false),
    ];
    (TypeSheet, String, String, IconData, bool)? principale;
    for (final a in actions) {
      if (a.$5) principale = a;
    }
    final p = principale;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // Pointage
        if (peut(acteur, Permission.pointer))
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ma journée',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        monPointage == null
                            ? "Pas encore pointé aujourd'hui"
                            : 'Arrivée ${monPointage.heureArrivee}'
                                '${monPointage.heureDepart != null ? ' · Départ ${monPointage.heureDepart}' : ' · en poste'}',
                        style: tnum(TextStyle(fontSize: 12, color: c.muted)),
                      ),
                    ],
                  ),
                ),
                if (monPointage == null)
                  Bouton(
                    taille: TailleBouton.sm,
                    onPressed: () {
                      final err = provider.pointer('arrivee');
                      if (err != null) provider.notifier(err, TonToast.erreur);
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.login_rounded, size: 15),
                        SizedBox(width: 6),
                        Text('Arrivée'),
                      ],
                    ),
                  )
                else if (monPointage.heureDepart == null)
                  Bouton(
                    taille: TailleBouton.sm,
                    variante: VarianteBouton.secondaire,
                    onPressed: () {
                      final err = provider.pointer('depart');
                      if (err != null) provider.notifier(err, TonToast.erreur);
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout_rounded, size: 15),
                        SizedBox(width: 6),
                        Text('Départ'),
                      ],
                    ),
                  )
                else
                  const Badge(
                    ton: TonBadge.succes,
                    child: Text('Journée terminée'),
                  ),
              ],
            ),
          ),

        // Bouton vente rapide
        if (p != null)
          Material(
            color: c.primary,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => widget.onOuvrirSheet(p.$1),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.onPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.shopping_cart_outlined, size: 21, color: c.onPrimary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enregistrer une vente',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c.onPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Stock et caisse mis à jour, équipe notifiée',
                            style: TextStyle(fontSize: 13, color: c.onPrimary.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Actions secondaires
        if (actions.any((a) => !a.$5))
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = 2;
                final spacing = 10.0;
                final cardWidth = (constraints.maxWidth - spacing) / crossAxisCount;
                // Calculate needed height based on content (icon + title + description with wrapping)
                final cardHeight = 110.0; // min height, will expand if needed
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: cardWidth / cardHeight,
                  children: [
                    for (final a in actions.where((a) => !a.$5))
                      Material(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () => widget.onOuvrirSheet(a.$1),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: c.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(a.$4, size: 19, color: c.primary),
                                const SizedBox(height: 8),
                                Flexible(
                                  child: Text(
                                    a.$2,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink, height: 1.2),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Flexible(
                                  child: Text(
                                    a.$3,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, color: c.muted, height: 1.25),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

        // ===== Section Nouveautés =====
        if (nouveautes.isNotEmpty && _requete.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 12),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 18, color: c.accent),
                const SizedBox(width: 8),
                Text(
                  'Nouveautés',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.ink),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${nouveautes.length}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.accent),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: nouveautes.length,
              separatorBuilder: (_, b) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(
                width: 160,
                child: ProductCard(
                  produit: nouveautes[i],
                  monnaie: monnaie,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProduitDetailScreen(produit: nouveautes[i], monnaie: monnaie),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],

        // ===== Section Stock =====
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${actifs.length} produits · valeur ${formatMontant(valeurStock(actifs), monnaie)}'
                      '${ruptures > 0 ? ' · $ruptures en rupture' : ''}',
                      style: tnum(TextStyle(fontSize: 12, color: c.muted)),
                    ),
                  ],
                ),
              ),
              if (peut(acteur, Permission.gererProduits))
                Bouton(
                  taille: TailleBouton.sm,
                  variante: VarianteBouton.secondaire,
                  onPressed: () => widget.onOuvrirSheet(TypeSheet.produit),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 15),
                      SizedBox(width: 6),
                      Text('Produit'),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        Saisie(
          icone: const Icon(Icons.search_rounded, size: 16),
          hint: 'Rechercher un produit…',
          onChanged: (v) => setState(() => _requete = v),
        ),

        const SizedBox(height: 12),
        if (liste.isEmpty)
          EtatVide(
            icone: Icons.search_rounded,
            titre: 'Aucun résultat',
            texte: 'Aucun produit ne correspond à « $_requete ». Vérifiez l\'orthographe.',
          )
        else
          // Grille 2 colonnes
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: liste.length,
            itemBuilder: (_, i) {
              final prod = liste[i];
              return Stack(
                children: [
                  ProductCard(
                    produit: prod,
                    monnaie: monnaie,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProduitDetailScreen(produit: prod, monnaie: monnaie),
                      ),
                    ),
                  ),
                  // Boutons admin (éditer/supprimer)
                  if (peut(acteur, Permission.gererProduits))
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          _PetitIcone(
                            icone: Icons.edit_outlined,
                            surTap: () => widget.onOuvrirSheet(TypeSheet.produit, produit: prod),
                          ),
                          const SizedBox(width: 4),
                          _PetitIcone(
                            icone: Icons.delete_outline_rounded,
                            couleurSurvol: c.danger,
                            surTap: () => setState(() => _aSupprimerId = prod.id),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),

        // Confirmation suppression
        if (_aSupprimerId != null)
          Builder(
            builder: (ctx) {
              final prod = actifs.firstWhere((p) => p.id == _aSupprimerId);
              return Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.danger.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.danger.withValues(alpha: 0.30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supprimer « ${prod.nom} » du stock actif ? L\'historique des ventes est conservé.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.ink),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Bouton(
                          taille: TailleBouton.sm,
                          variante: VarianteBouton.danger,
                          onPressed: () {
                            provider.supprimerProduit(prod.id);
                            setState(() => _aSupprimerId = null);
                          },
                          child: const Text('Supprimer'),
                        ),
                        const SizedBox(width: 8),
                        Bouton(
                          taille: TailleBouton.sm,
                          variante: VarianteBouton.fantome,
                          onPressed: () => setState(() => _aSupprimerId = null),
                          child: const Text('Annuler'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _PetitIcone extends StatelessWidget {
  final IconData icone;
  final VoidCallback surTap;
  final Color? couleurSurvol;

  const _PetitIcone({required this.icone, required this.surTap, this.couleurSurvol});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: surTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icone, size: 14, color: couleurSurvol ?? c.muted),
        ),
      ),
    );
  }
}
