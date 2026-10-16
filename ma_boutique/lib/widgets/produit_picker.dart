import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/stats.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/product_image.dart';
import 'ui/field.dart';

/// Sélecteur de produit : suggestions mises à jour à chaque frappe,
/// classées par pertinence puis par disponibilité en stock.
///
/// Le sélecteur est présenté dans une feuille modale défilante : il ne
/// contraint donc jamais la hauteur (pas de `Flexible`/`ListView` imbriqué),
/// c'est la feuille qui fait défiler les suggestions.
class ProduitPicker extends StatefulWidget {
  final List<Produit> produits;
  final ValueChanged<Produit> onSelect;
  final String monnaie;
  final bool autoriserRuptures;

  /// Nombre maximum de suggestions affichées.
  final int limite;

  const ProduitPicker({
    super.key,
    required this.produits,
    required this.onSelect,
    this.monnaie = 'FCFA',
    this.autoriserRuptures = false,
    this.limite = 60,
  });

  @override
  State<ProduitPicker> createState() => _ProduitPickerState();
}

class _ProduitPickerState extends State<ProduitPicker> {
  final TextEditingController _ctrl = TextEditingController();
  String _requete = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _effacer() {
    _ctrl.clear();
    setState(() => _requete = '');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final actifs = widget.produits.where((p) => p.actif).toList();
    final disponibles = widget.autoriserRuptures
        ? actifs
        : actifs.where((p) => p.quantite > 0).toList();
    final enStock = actifs.where((p) => p.quantite > 0).length;
    final liste = rechercheProduits(disponibles, _requete, limite: widget.limite);
    final rechercheEnCours = _requete.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Saisie(
          controller: _ctrl,
          hint: 'Rechercher un produit…',
          icone: Icon(Icons.search_rounded, size: 16, color: c.muted),
          suffixe: rechercheEnCours
              ? IconButton(
                  tooltip: 'Effacer la recherche',
                  icon: Icon(Icons.clear_rounded, size: 18, color: c.muted),
                  onPressed: _effacer,
                )
              : null,
          onChanged: (v) => setState(() => _requete = v),
        ),
        const SizedBox(height: 8),
        Text(
          rechercheEnCours
              ? '${liste.length} suggestion${liste.length > 1 ? 's' : ''} · $enStock en stock'
              : '$enStock produit${enStock > 1 ? 's' : ''} en stock',
          style: TextStyle(fontSize: 12, color: c.muted),
        ),
        const SizedBox(height: 12),
        if (liste.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              rechercheEnCours
                  ? 'Aucun produit en stock ne correspond à « ${_requete.trim()} ».'
                  : 'Aucun produit en stock pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.muted),
            ),
          )
        else
          for (var i = 0; i < liste.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _LigneSuggestion(
              produit: liste[i],
              monnaie: widget.monnaie,
              onTap: () => widget.onSelect(liste[i]),
            ),
          ],
      ],
    );
  }
}

class _LigneSuggestion extends StatelessWidget {
  final Produit produit;
  final String monnaie;
  final VoidCallback onTap;

  const _LigneSuggestion({
    required this.produit,
    required this.monnaie,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enRupture = produit.quantite == 0;
    return Material(
      color: c.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              ProductImage(
                imagePath: produit.images.isNotEmpty ? produit.images.first : null,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
                categorie: produit.categorie,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produit.nom,
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
                      '${produit.categorieLabel} · ${formatMontant(produit.prixVente, monnaie)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    produit.quantite.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: enRupture ? c.danger : c.ink,
                    ),
                  ),
                  Text(
                    enRupture ? 'rupture' : 'en stock',
                    style: TextStyle(
                      fontSize: 10,
                      color: enRupture ? c.danger : c.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
