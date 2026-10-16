import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/product_image.dart';
import '../widgets/shared_helpers.dart';
import '../widgets/sheets.dart';
import '../widgets/ui/button.dart';

class ProduitDetailScreen extends StatefulWidget {
  final Produit produit;
  final String monnaie;

  const ProduitDetailScreen({
    super.key,
    required this.produit,
    required this.monnaie,
  });

  @override
  State<ProduitDetailScreen> createState() => _ProduitDetailScreenState();
}

class _ProduitDetailScreenState extends State<ProduitDetailScreen> {
  late final PageController _pageController;
  int _pageActuelle = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = widget.produit;
    final hasImages = p.images.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar avec galerie d'images
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: c.surface2,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_left_rounded, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: hasImages
                  ? Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: p.images.length,
                          onPageChanged: (i) =>
                              setState(() => _pageActuelle = i),
                          itemBuilder: (_, i) => ProductImage(
                            imagePath: p.images[i],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            categorie: p.categorie,
                          ),
                        ),
                        if (p.images.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                p.images.length,
                                (i) => Container(
                                  width: i == _pageActuelle ? 24 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: i == _pageActuelle
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : ProductImage(
                      imagePath: null,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      categorie: p.categorie,
                    ),
            ),
          ),
          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge catégorie + statut
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                       color: couleurCategorie(p.categorie)
                               .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p.categorieLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: couleurCategorie(p.categorie),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (p.estNouveau)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: c.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Nouveau',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.accent,
                            ),
                          ),
                        ),
                      const Spacer(),
                      _badgeStock(c, p),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Nom
                  Text(
                    p.nom,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Prix
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prix de vente',
                              style: TextStyle(
                                fontSize: 12,
                                color: c.muted,
                              ),
                            ),
                            Text(
                              formatMontant(p.prixVente, widget.monnaie),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: c.primary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Prix d\'achat',
                              style: TextStyle(
                                fontSize: 12,
                                color: c.muted,
                              ),
                            ),
                            Text(
                              formatMontant(p.prixAchat, widget.monnaie),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: c.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Marge
                  _infoLigne(
                    c,
                    'Marge bénéficiaire',
                    '${formatMontant(p.prixVente - p.prixAchat, widget.monnaie)} '
                    '(${(((p.prixVente - p.prixAchat) / p.prixAchat) * 100).toStringAsFixed(0)}%)',
                    Icons.trending_up_rounded,
                    c.success,
                  ),
                  const SizedBox(height: 12),
                  // Stock
                  _infoLigne(
                    c,
                    'Stock disponible',
                    '${p.quantite.toInt()} unités',
                    Icons.inventory_2_rounded,
                    p.quantite <= 0
                        ? c.danger
                        : p.quantite <= 5
                            ? const Color(0xFFF5A623)
                            : c.success,
                  ),
                  const SizedBox(height: 12),
                  // Date ajout
                  if (p.dateAjout != null)
                    _infoLigne(
                      c,
                      'Date d\'ajout',
                      '${p.dateAjout!.day}/${p.dateAjout!.month}/${p.dateAjout!.year}',
                      Icons.calendar_today_rounded,
                      c.muted,
                    ),
                  const SizedBox(height: 16),
                  // Bouton Vendre
                  if (p.quantite > 0)
                    Bouton(
                      taille: TailleBouton.lg,
                      pleineLargeur: true,
                      onPressed: () async {
                        await ouvrirVenteSheet(context, p);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('Vendre'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  // QR Code produit
                  if (p.qrCodeData != null && p.qrCodeData!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.line),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Code QR du produit',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                              ),
                              Icon(Icons.qr_code_rounded, color: c.primary),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: QrImageView(
                              data: p.qrCodeData!,
                              version: QrVersions.auto,
                              size: 180,
                              gapless: false,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scannez pour identifier le produit (ID: ${p.id})',
                            style: TextStyle(fontSize: 11, color: c.muted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeStock(AppColors c, Produit p) {
    final rupture = p.quantite <= 0;
    final faible = p.quantite > 0 && p.quantite <= 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (rupture ? c.danger : faible ? const Color(0xFFF5A623) : c.success)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        rupture ? 'Rupture' : faible ? 'Stock faible' : 'En stock',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: rupture ? c.danger : faible ? const Color(0xFFF5A623) : c.success,
        ),
      ),
    );
  }

  Widget _infoLigne(
    AppColors c,
    String label,
    String valeur,
    IconData icone,
    Color couleur,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: couleur.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icone, size: 18, color: couleur),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
            Text(
              valeur,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
          ],
        ),
      ],
    );
  }
}


