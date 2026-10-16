import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import 'product_image.dart';
import '../models/models.dart';

/// Carte produit pour la grille 2 colonnes.
class ProductCard extends StatelessWidget {
  final Produit produit;
  final String monnaie;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.produit,
    required this.monnaie,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasImage = produit.images.isNotEmpty;
    final rupture = produit.quantite <= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zone image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: ProductImage(
                      imagePath: hasImage ? produit.images.first : null,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      categorie: produit.categorie,
                    ),
                  ),
                  if (produit.estNouveau)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: c.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Nouveau',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: c.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  if (rupture)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: c.danger,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Rupture',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: c.onPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Infos produit
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produit.nom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatMontant(produit.prixVente, monnaie),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: c.primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: rupture
                                ? c.danger.withValues(alpha: 0.1)
                                : c.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${produit.quantite.toInt()}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: rupture ? c.danger : c.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
