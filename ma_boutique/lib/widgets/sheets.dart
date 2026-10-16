import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/qr_code_service.dart';
import '../widgets/product_image.dart';
import 'produit_picker.dart';
import 'ui/button.dart';
import 'ui/field.dart';
import 'ui/segmented_control.dart';
import 'ui/sheet.dart';

// ===================== VENTE =====================

Future<void> ouvrirVenteSheet(BuildContext context, Produit? produitInitial) {
  return ouvrirFeuille(
    context: context,
    titre: 'Enregistrer une vente',
    sousTitre: produitInitial?.nom ?? 'Choisissez le produit vendu',
    enfant: _VenteContenu(produitInitial: produitInitial),
  );
}

class _VenteContenu extends StatefulWidget {
  final Produit? produitInitial;
  const _VenteContenu({this.produitInitial});

  @override
  State<_VenteContenu> createState() => _VenteContenuState();
}

class _VenteContenuState extends State<_VenteContenu> {
  late Produit? _produit;
  late int _quantite;
  late String _prix;
  String? _erreur;
  late final TextEditingController _prixCtrl;
  late final TextEditingController _qteCtrl;

  @override
  void initState() {
    super.initState();
    _produit = widget.produitInitial;
    _quantite = 1;
    _prix = widget.produitInitial != null
        ? widget.produitInitial!.prixVente.toStringAsFixed(0)
        : '';
    _prixCtrl = TextEditingController(text: _prix);
    _qteCtrl = TextEditingController(text: '$_quantite');
  }

  @override
  void dispose() {
    _prixCtrl.dispose();
    _qteCtrl.dispose();
    super.dispose();
  }

  void _choisir(Produit p) {
    setState(() {
      _produit = p;
      _prix = p.prixVente.toStringAsFixed(0);
      _prixCtrl.text = _prix;
      _quantite = 1;
      _qteCtrl.text = '1';
      _erreur = null;
    });
  }

  void _fixerQuantite(int q) {
    setState(() {
      _quantite = q;
      _qteCtrl.text = '$q';
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final c = context.colors;
    final monnaie = provider.monnaie;
    final produit = _produit;
    final total = (double.tryParse(_prix) ?? 0) * _quantite;

    if (produit == null) {
      return ProduitPicker(
        produits: provider.produits,
        monnaie: monnaie,
        onSelect: _choisir,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produit.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                    ),
                    Text(
                      '${produit.quantite.toStringAsFixed(0)} en stock',
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _produit = null;
                  _erreur = null;
                }),
                style: TextButton.styleFrom(
                  foregroundColor: c.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                child: const Text('Changer'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Champ(
          label: 'Quantité',
          aide: 'Maximum ${produit.quantite.toStringAsFixed(0)}',
          enfant: Row(
            children: [
              _BoutonQuantite(
                icone: Icons.remove_rounded,
                surTap: () => _fixerQuantite((_quantite - 1).clamp(1, 999999)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: Saisie(
                    clavier: TextInputType.number,
                    alignement: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    filtre: (v) => v.replaceAll(RegExp(r'\D'), ''),
                    onChanged: (v) {
                      // L'état suit strictement le champ : aucune valeur fantôme
                      // (0 affiché → 1 enregistré).
                      final n = int.tryParse(v.replaceAll(RegExp(r'\D'), '')) ?? 0;
                      setState(() {
                        _quantite = n;
                        _erreur = null;
                      });
                    },
                    controller: _qteCtrl,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _BoutonQuantite(
                icone: Icons.add_rounded,
                surTap: () => _fixerQuantite((_quantite + 1).clamp(1, produit.quantite.toInt())),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Champ(
          label: 'Prix de vente réel (unitaire)',
          aide: 'Modifiable pour appliquer une remise',
          enfant: Saisie(
            clavier: const TextInputType.numberWithOptions(decimal: true),
            filtre: (v) => v.replaceAll(RegExp(r'[^\d.]'), ''),
            onChanged: (v) => setState(() {
              _prix = v;
              _erreur = null;
            }),
            controller: _prixCtrl,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.primarySoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total encaissé',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.primary),
              ),
              Text(
                formatMontant(total, monnaie),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.primary),
              ),
            ],
          ),
        ),
        if (_erreur != null) ...[
          const SizedBox(height: 12),
          Text(
            _erreur!,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.danger),
          ),
        ],
        const SizedBox(height: 16),
        Bouton(
          taille: TailleBouton.lg,
          pleineLargeur: true,
          onPressed: () {
            final message = provider.enregistrerVente(
              produit.id,
              _quantite.toDouble(),
              double.tryParse(_prix) ?? 0,
            );
            if (message != null) {
              setState(() => _erreur = message);
              return;
            }
            Navigator.pop(context);
          },
          child: const Text('Signaler vendu'),
        ),
        const SizedBox(height: 12),
        Text(
          "Le stock diminue, la caisse augmente et l'équipe est notifiée avec votre nom.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: c.muted),
        ),
      ],
    );
  }
}

class _BoutonQuantite extends StatelessWidget {
  final IconData icone;
  final VoidCallback surTap;

  const _BoutonQuantite({required this.icone, required this.surTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: surTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icone, size: 18, color: c.ink),
        ),
      ),
    );
  }
}

// ===================== DÉFECTUEUX =====================

Future<void> ouvrirDefectueuxSheet(BuildContext context, Produit? produitInitial) {
  return ouvrirFeuille(
    context: context,
    titre: 'Article défectueux',
    sousTitre: "Une pièce est retirée du stock et le patron est prévenu",
    enfant: _DefectueuxContenu(produitInitial: produitInitial),
  );
}

class _DefectueuxContenu extends StatefulWidget {
  final Produit? produitInitial;
  const _DefectueuxContenu({this.produitInitial});

  @override
  State<_DefectueuxContenu> createState() => _DefectueuxContenuState();
}

class _DefectueuxContenuState extends State<_DefectueuxContenu> {
  late Produit? _produit;
  String _description = '';
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _produit = widget.produitInitial;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final c = context.colors;
    final produit = _produit;

    if (produit == null) {
      return ProduitPicker(
        produits: provider.produits,
        monnaie: provider.monnaie,
        onSelect: (p) => setState(() => _produit = p),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produit.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                    ),
                    Text(
                      '${produit.quantite.toStringAsFixed(0)} en stock',
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _produit = null),
                style: TextButton.styleFrom(
                  foregroundColor: c.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                child: const Text('Changer'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Champ(
          label: 'Description du problème',
          erreur: _erreur,
          aide: 'Obligatoire',
          enfant: ZoneTexte(
            hint: 'Ex. couture déchirée sur la manche droite',
            onChanged: (v) => setState(() {
              _description = v;
              _erreur = null;
            }),
          ),
        ),
        const SizedBox(height: 16),
        Bouton(
          taille: TailleBouton.lg,
          pleineLargeur: true,
          variante: VarianteBouton.danger,
          onPressed: () {
            final message = provider.signalerDefectueux(produit.id, _description);
            if (message != null) {
              setState(() => _erreur = message);
              return;
            }
            Navigator.pop(context);
          },
          child: const Text("Signaler l'article défectueux"),
        ),
      ],
    );
  }
}

// ===================== RETOUR =====================

Future<void> ouvrirRetourSheet(BuildContext context, Produit? produitInitial) {
  return ouvrirFeuille(
    context: context,
    titre: 'Retour produit',
    sousTitre: 'Le produit revient en stock ; le patron traite le retour',
    enfant: _RetourContenu(produitInitial: produitInitial),
  );
}

class _RetourContenu extends StatefulWidget {
  final Produit? produitInitial;
  const _RetourContenu({this.produitInitial});

  @override
  State<_RetourContenu> createState() => _RetourContenuState();
}

class _RetourContenuState extends State<_RetourContenu> {
  late Produit? _produit;
  MotifRetour _motif = MotifRetour.remboursement;
  late String _montant;
  String _description = '';
  String? _erreur;
  late final TextEditingController _montantCtrl;

  @override
  void initState() {
    super.initState();
    _produit = widget.produitInitial;
    _montant = widget.produitInitial != null
        ? widget.produitInitial!.prixVente.toStringAsFixed(0)
        : '';
    _montantCtrl = TextEditingController(text: _montant);
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    super.dispose();
  }

  void _choisir(Produit p) {
    setState(() {
      _produit = p;
      _montant = p.prixVente.toStringAsFixed(0);
      _montantCtrl.text = _montant;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final c = context.colors;
    final produit = _produit;

    if (produit == null) {
      return ProduitPicker(
        produits: provider.produits,
        monnaie: provider.monnaie,
        autoriserRuptures: true,
        onSelect: _choisir,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produit.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                    ),
                    Text(
                      'Prix catalogue ${formatMontant(produit.prixVente, provider.monnaie)}',
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _produit = null),
                style: TextButton.styleFrom(
                  foregroundColor: c.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                child: const Text('Changer'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Champ(
          label: 'Motif du retour',
          enfant: ControleSegmente<MotifRetour>(
            options: const [
              OptionSegmente(MotifRetour.remboursement, 'Remboursement'),
              OptionSegmente(MotifRetour.echange, 'Échange'),
            ],
            valeur: _motif,
            onChange: (v) => setState(() {
              _motif = v;
              _erreur = null;
            }),
          ),
        ),
        if (_motif == MotifRetour.remboursement) ...[
          const SizedBox(height: 16),
          Champ(
            label: 'Montant remboursé',
            aide: 'Retiré de la caisse',
            enfant: Saisie(
              clavier: const TextInputType.numberWithOptions(decimal: true),
              filtre: (v) => v.replaceAll(RegExp(r'[^\d.]'), ''),
              onChanged: (v) => setState(() => _montant = v),
              controller: _montantCtrl,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Champ(
          label: 'Description',
          erreur: _erreur,
          aide: 'Obligatoire',
          enfant: ZoneTexte(
            hint: _motif == MotifRetour.remboursement
                ? 'Ex. cliente non satisfaite de la taille'
                : 'Ex. échange contre la pointure 41',
            onChanged: (v) => setState(() {
              _description = v;
              _erreur = null;
            }),
          ),
        ),
        const SizedBox(height: 16),
        Bouton(
          taille: TailleBouton.lg,
          pleineLargeur: true,
          onPressed: () {
            final message = provider.signalerRetour(
              produit.id,
              _motif,
              _description,
              double.tryParse(_montant) ?? 0,
            );
            if (message != null) {
              setState(() => _erreur = message);
              return;
            }
            Navigator.pop(context);
          },
          child: const Text('Enregistrer le retour'),
        ),
      ],
    );
  }
}

// ===================== DÉPENSE / SORTIE =====================

const _motifsRapides = ['Loyer', 'Électricité', 'Eau', 'Impôts', 'Transport', 'Réassort'];

Future<void> ouvrirDepenseSheet(BuildContext context, TypeDepense type) {
  final solde = context.read<AppProvider>().boutique?.soldeCaisse ?? 0;
  final monnaie = context.read<AppProvider>().monnaie;
  return ouvrirFeuille(
    context: context,
    titre: type == TypeDepense.depense
        ? 'Signaler une dépense'
        : 'Justifier une sortie de caisse',
    sousTitre: 'Caisse actuelle : ${formatMontant(solde, monnaie)}',
    enfant: _DepenseContenu(type: type),
  );
}

class _DepenseContenu extends StatefulWidget {
  final TypeDepense type;
  const _DepenseContenu({required this.type});

  @override
  State<_DepenseContenu> createState() => _DepenseContenuState();
}

class _DepenseContenuState extends State<_DepenseContenu> {
  String _description = '';
  String _montant = '';
  String? _erreur;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final c = context.colors;
    final monnaie = provider.monnaie;
    final solde = provider.boutique?.soldeCaisse ?? 0;
    final restant = solde - (double.tryParse(_montant) ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Champ(
          label: 'Motif',
          aide: 'Obligatoire',
          enfant: Saisie(
            hint: widget.type == TypeDepense.depense
                ? 'Ex. loyer du mois'
                : 'Ex. transport marchandise',
            onChanged: (v) => setState(() {
              _description = v;
              _erreur = null;
            }),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in _motifsRapides)
              Material(
                color: c.surface2,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: () => setState(() => _description = m),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: c.line),
                    ),
                    child: Text(
                      m,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.muted),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Champ(
          label: 'Montant',
          erreur: _erreur,
          enfant: Saisie(
            hint: '0',
            clavier: const TextInputType.numberWithOptions(decimal: true),
            filtre: (v) => v.replaceAll(RegExp(r'[^\d.]'), ''),
            onChanged: (v) => setState(() {
              _montant = v;
              _erreur = null;
            }),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Caisse après opération',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.muted),
              ),
              Text(
                formatMontant(restant, monnaie),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: restant < 0 ? c.danger : c.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Bouton(
          taille: TailleBouton.lg,
          pleineLargeur: true,
          onPressed: () {
            final message = provider.enregistrerDepense(
              _description,
              double.tryParse(_montant) ?? 0,
              widget.type,
            );
            if (message != null) {
              setState(() => _erreur = message);
              return;
            }
            Navigator.pop(context);
          },
          child: Text(
            widget.type == TypeDepense.depense
                ? 'Enregistrer la dépense'
                : 'Justifier la sortie',
          ),
        ),
      ],
    );
  }
}

// ===================== PRODUIT =====================

Future<void> ouvrirProduitSheet(BuildContext context, Produit? produitInitial) {
  return ouvrirFeuille(
    context: context,
    titre: produitInitial != null ? 'Modifier le produit' : 'Ajouter un produit',
    sousTitre: "Le prix d'achat reste visible par vous seul",
    enfant: _ProduitContenu(produitInitial: produitInitial),
  );
}

class _ProduitContenu extends StatefulWidget {
  final Produit? produitInitial;
  const _ProduitContenu({this.produitInitial});

  @override
  State<_ProduitContenu> createState() => _ProduitContenuState();
}

class _ProduitContenuState extends State<_ProduitContenu> {
  late String _nom;
  late String _prixAchat;
  late String _prixVente;
  late String _quantite;
  late String _categorie;
  late List<String> _images;
  String? _qrCodeData;
  String? _erreur;
  late final TextEditingController _nomCtrl;
  late final TextEditingController _achatCtrl;
  late final TextEditingController _venteCtrl;
  late final TextEditingController _qteCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.produitInitial;
    _nom = p?.nom ?? '';
    _prixAchat = p != null ? p.prixAchat.toStringAsFixed(0) : '';
    _prixVente = p != null ? p.prixVente.toStringAsFixed(0) : '';
    _quantite = p != null ? p.quantite.toStringAsFixed(0) : '';
    _categorie = p?.categorie ?? 'autre';
    _images = List<String>.from(p?.images ?? []);
    _qrCodeData = p?.qrCodeData;
    _nomCtrl = TextEditingController(text: _nom);
    _achatCtrl = TextEditingController(text: _prixAchat);
    _venteCtrl = TextEditingController(text: _prixVente);
    _qteCtrl = TextEditingController(text: _quantite);
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _achatCtrl.dispose();
    _venteCtrl.dispose();
    _qteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final c = context.colors;
    final monnaie = provider.monnaie;
    final marge = (double.tryParse(_prixVente) ?? 0) - (double.tryParse(_prixAchat) ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Champ(
          label: 'Nom du produit',
          enfant: Saisie(
            hint: 'Ex. Chemise coton homme',
            onChanged: (v) => setState(() => _nom = v),
            controller: _nomCtrl,
          ),
        ),
        const SizedBox(height: 16),

        // Sélection catégorie
        Champ(
          label: 'Catégorie',
          enfant: DropdownButtonFormField<String>(
            initialValue: _categorie,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: categoriesProduit
                .map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                .toList(),
            onChanged: (v) => setState(() => _categorie = v ?? 'autre'),
          ),
        ),
        const SizedBox(height: 16),

        // Images produit
        Champ(
          label: 'Images du produit',
          enfant: ProductImagePicker(
            images: _images,
            onChanged: (newImages) => setState(() => _images = newImages),
            maxImages: 5,
            categorie: _categorie,
          ),
        ),
        const SizedBox(height: 16),

        // QR Code (généré automatiquement à la création)
        if (widget.produitInitial == null || _qrCodeData != null)
          Champ(
            label: 'Code QR produit',
            enfant: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.line),
                  ),
                  child: Center(
                    child: QrImageView(
                      // Aperçu aligné sur ce qui sera enregistré : l'id réel du
                      // produit et les valeurs actuelles du formulaire (jamais
                      // l'ancien QR éventuellement fautif stocké en base).
                      data: QrCodeService.genererDataProduit(
                        produitId: widget.produitInitial?.id ?? 'nouveau',
                        nom: _nom,
                        prixVente: double.tryParse(_prixVente) ?? 0,
                        categorie: _categorie,
                      ),
                      version: QrVersions.auto,
                      size: 160,
                      gapless: false,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.produitInitial == null
                      ? 'Le QR code sera généré automatiquement à la création'
                      : 'Scannez pour identifier le produit (ID: ${widget.produitInitial!.id})',
                  style: TextStyle(fontSize: 12, color: c.muted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Champ(
                label: "Prix d'achat",
                enfant: Saisie(
                  clavier: const TextInputType.numberWithOptions(decimal: true),
                  filtre: (v) => v.replaceAll(RegExp(r'[^\d.]'), ''),
                  onChanged: (v) => setState(() => _prixAchat = v),
                  controller: _achatCtrl,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Champ(
                label: 'Prix de vente',
                enfant: Saisie(
                  clavier: const TextInputType.numberWithOptions(decimal: true),
                  filtre: (v) => v.replaceAll(RegExp(r'[^\d.]'), ''),
                  onChanged: (v) => setState(() => _prixVente = v),
                  controller: _venteCtrl,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Champ(
          label: widget.produitInitial != null ? 'Quantité en stock' : 'Quantité initiale',
          enfant: Saisie(
            clavier: TextInputType.number,
            filtre: (v) => v.replaceAll(RegExp(r'\D'), ''),
            onChanged: (v) => setState(() => _quantite = v),
            controller: _qteCtrl,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Marge par pièce',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.muted),
              ),
              Text(
                formatMontant(marge, monnaie),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: marge <= 0 ? c.danger : c.ink,
                ),
              ),
            ],
          ),
        ),
        if (_erreur != null) ...[
          const SizedBox(height: 12),
          Text(
            _erreur!,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.danger),
          ),
        ],
        const SizedBox(height: 16),
        Bouton(
          taille: TailleBouton.lg,
          pleineLargeur: true,
          onPressed: () {
            if (_nom.trim().length < 2) {
              setState(() => _erreur = 'Le nom du produit est obligatoire.');
              return;
            }
            if ((double.tryParse(_prixAchat) ?? 0) <= 0) {
              setState(() => _erreur = "Le prix d'achat doit être supérieur à 0.");
              return;
            }
            if ((double.tryParse(_prixVente) ?? 0) <= 0) {
              setState(() => _erreur = 'Le prix de vente doit être supérieur à 0.');
              return;
            }
            if (double.tryParse(_quantite) == null || (double.tryParse(_quantite) ?? 0) < 0) {
              setState(() => _erreur = 'Indiquez la quantité en stock.');
              return;
            }
            final p = widget.produitInitial;
            final nom = _nom.trim();
            final prixAchat = double.tryParse(_prixAchat) ?? 0;
            final prixVente = double.tryParse(_prixVente) ?? 0;
            final quantite = double.tryParse(_quantite) ?? 0;
            if (p != null) {
              provider.modifierProduit(
                p.id,
                nom: nom,
                prixAchat: prixAchat,
                prixVente: prixVente,
                quantite: quantite,
                images: _images,
                categorie: _categorie,
              );
            } else {
              provider.ajouterProduit(
                nom: nom,
                prixAchat: prixAchat,
                prixVente: prixVente,
                quantite: quantite,
                images: _images,
                categorie: _categorie,
              );
            }
            Navigator.pop(context);
          },
          child: Text(widget.produitInitial != null
              ? 'Enregistrer les modifications'
              : 'Ajouter au stock'),
        ),
      ],
    );
  }
}