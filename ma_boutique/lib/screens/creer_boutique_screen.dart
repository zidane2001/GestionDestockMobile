import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/image_service.dart';
import '../widgets/logo_boutique.dart';
import '../widgets/ui/button.dart';
import '../widgets/ui/field.dart';
import 'home_screen.dart';

const _monnaies = [
  (Monnaie.fcfa, 'Franc CFA'),
  (Monnaie.eur, 'Euro'),
  (Monnaie.usd, 'Dollar US'),
];

class CreerBoutiqueScreen extends StatefulWidget {
  const CreerBoutiqueScreen({super.key});

  @override
  State<CreerBoutiqueScreen> createState() => _CreerBoutiqueScreenState();
}

class _CreerBoutiqueScreenState extends State<CreerBoutiqueScreen> {
  final _nomCtrl = TextEditingController();
  final _styleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  final _confCtrl = TextEditingController();

  Monnaie _monnaie = Monnaie.fcfa;
  String? _logo;
  final Map<String, String> _erreurs = {};

  @override
  void dispose() {
    _nomCtrl.dispose();
    _styleCtrl.dispose();
    _emailCtrl.dispose();
    _mdpCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  void _valider() {
    final provider = context.read<AppProvider>();
    final nom = _nomCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final mdp = _mdpCtrl.text;
    final erreurs = <String, String>{};
    if (nom.length < 3 || nom.length > 40) {
      erreurs['nom'] = 'Le nom doit contenir entre 3 et 40 caractères.';
    }
    if (provider.boutique != null &&
        provider.boutique!.nom.toLowerCase() == nom.toLowerCase()) {
      erreurs['nom'] = 'Ce nom de boutique existe déjà.';
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      erreurs['email'] = 'Adresse email invalide.';
    }
    if (mdp.length < 6) erreurs['mdp'] = 'Minimum 6 caractères.';
    if (mdp != _confCtrl.text) erreurs['confirmation'] = 'Les mots de passe ne correspondent pas.';
    setState(() => _erreurs.clear());
    if (erreurs.isNotEmpty) {
      setState(() => _erreurs.addAll(erreurs));
      return;
    }
    provider.creerBoutique(
      nom: nom,
      styleCommerce: _styleCtrl.text.trim(),
      monnaie: _monnaie,
      emailPatron: email,
      motDePasse: mdp,
      logoUrl: _logo,
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Material(
                    color: c.surface2,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(Icons.chevron_left_rounded, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Créer ma boutique',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c.ink),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Le nom de la boutique servira d'identifiant de connexion à toute l'équipe. Votre compte patron est créé automatiquement.",
                      style: TextStyle(fontSize: 13, height: 1.5, color: c.muted),
                    ),
                    const SizedBox(height: 16),
                    Champ(
                      label: 'Nom de la boutique',
                      erreur: _erreurs['nom'],
                      aide: '3 à 40 caractères, unique',
                      enfant: Saisie(
                        controller: _nomCtrl,
                        hint: 'Ex. Boutique Kadi',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Champ(
                      label: 'Style de commerce (facultatif)',
                      enfant: Saisie(
                        controller: _styleCtrl,
                        hint: 'Vêtements, électronique, alimentation…',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Champ(
                      label: 'Logo de la boutique (facultatif)',
                      erreur: _erreurs['logo'],
                      aide: "Affiché en haut de l'application sur tous les téléphones",
                      enfant: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.line),
                        ),
                        child: Row(
                          children: [
                            LogoBoutique(logoUrl: _logo, nom: _nomCtrl.text, taille: 56),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Bouton(
                                        taille: TailleBouton.sm,
                                        variante: VarianteBouton.secondaire,
                                        onPressed: () => _choisirLogo(),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.add_photo_alternate_outlined, size: 15),
                                            const SizedBox(width: 6),
                                            Text(_logo != null ? 'Changer' : 'Choisir une image'),
                                          ],
                                        ),
                                      ),
                                      if (_logo != null)
                                        Bouton(
                                          taille: TailleBouton.sm,
                                          variante: VarianteBouton.fantome,
                                          onPressed: () => setState(() => _logo = null),
                                          child: const Text('Retirer'),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'PNG ou JPG carré, 2 Mo maximum.',
                                    style: TextStyle(fontSize: 12, color: c.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Champ(
                      label: 'Monnaie',
                      enfant: Row(
                        children: [
                          for (final (m, label) in _monnaies) ...[
                            Expanded(
                              child: _PuceMonnaie(
                                label: label,
                                actif: _monnaie == m,
                                surTap: () => setState(() => _monnaie = m),
                              ),
                            ),
                            if (m != _monnaies.last.$1) const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Champ(
                      label: 'Email du patron',
                      erreur: _erreurs['email'],
                      aide: 'Utilisé pour récupérer un compte ou un code PIN',
                      enfant: Saisie(
                        controller: _emailCtrl,
                        hint: 'vous@exemple.com',
                        clavier: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Champ(
                      label: 'Mot de passe',
                      erreur: _erreurs['mdp'],
                      aide: 'Minimum 6 caractères',
                      enfant: Saisie(controller: _mdpCtrl, masque: true, hint: '••••••'),
                    ),
                    const SizedBox(height: 16),
                    Champ(
                      label: 'Confirmer le mot de passe',
                      erreur: _erreurs['confirmation'],
                      enfant: Saisie(controller: _confCtrl, masque: true, hint: '••••••'),
                    ),
                    const SizedBox(height: 20),
                    Bouton(
                      taille: TailleBouton.lg,
                      pleineLargeur: true,
                      onPressed: _valider,
                      child: const Text('Créer la boutique'),
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

  void _choisirLogo() async {
    final chemin = await ImageService.instance.ajouterImage();
    if (chemin != null) {
      setState(() => _logo = chemin);
    }
  }
}

class _PuceMonnaie extends StatelessWidget {
  final String label;
  final bool actif;
  final VoidCallback surTap;

  const _PuceMonnaie({required this.label, required this.actif, required this.surTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: actif ? c.primarySoft : c.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: surTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: actif ? c.primary : c.line),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: actif ? c.primary : c.muted,
            ),
          ),
        ),
      ),
    );
  }
}