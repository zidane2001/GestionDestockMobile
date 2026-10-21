import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/image_service.dart';
import '../widgets/logo_boutique.dart';
import '../widgets/sub_screen.dart';
import '../widgets/ui/button.dart';
import '../widgets/ui/field.dart';
import 'appareils_screen.dart';
import 'employes_screen.dart';
import 'accueil_screen.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  bool _editionPin = false;
  String _pin = '';
  String? _erreur;
  final _pinCtrl = TextEditingController();

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  void _enregistrerPin() {
    final provider = context.read<AppProvider>();
    if (!RegExp(r'^\d{4}$').hasMatch(_pin)) {
      setState(() => _erreur = 'Le code PIN doit contenir exactement 4 chiffres.');
      return;
    }
    provider.definirPin(_pin);
    setState(() {
      _pin = '';
      _pinCtrl.clear();
      _editionPin = false;
      _erreur = null;
    });
    if (provider.session?.biometrie != true) {
      provider.notifier('Activez la biométrie pour déverrouiller plus vite.', TonToast.info);
    }
  }

  Future<void> _confirmerSuppression(BuildContext context) async {
    final c = context.colors;
    final provider = context.read<AppProvider>();
    final boutique = provider.boutique;
    final session = provider.session;

    // Étape 1 : Confirmation initiale
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer « ${boutique?.nom ?? ''} » ?'),
        content: const Text(
          'Toute la boutique sera supprimée définitivement : employés, produits, ventes, dépenses, pointages, journal et appareils. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: TextStyle(color: c.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    // Étape 2 : Vérification du mot de passe
    final mdpCtrl = TextEditingController();
    final mdpValide = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = ctx.colors;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: c.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Vérification du mot de passe'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Saisissez votre mot de passe pour supprimer « ${boutique?.nom ?? ''} ».',
                  style: TextStyle(color: c.muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: mdpCtrl,
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                  ),
                  onSubmitted: (_) => Navigator.pop(ctx, mdpCtrl.text.isNotEmpty),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, mdpCtrl.text.isNotEmpty),
                style: FilledButton.styleFrom(backgroundColor: c.danger),
                child: const Text('Vérifier'),
              ),
            ],
          ),
        );
      },
    );

    if (mdpValide != true || !context.mounted) return;

    if (mdpCtrl.text != session?.motDePasse) {
      provider.notifier('Mot de passe incorrect.', TonToast.erreur);
      return;
    }

    // Étape 3 : Vérification du code PIN
    if (session?.pinActif == true && (session?.pin ?? '').isNotEmpty) {
      final pinCtrl = TextEditingController();
      final pinValide = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final c = ctx.colors;
          return StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              backgroundColor: c.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Code PIN requis'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Saisissez votre code PIN pour confirmer.',
                    style: TextStyle(color: c.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Code PIN',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.pin_outlined),
                    ),
                    onSubmitted: (_) => Navigator.pop(ctx, pinCtrl.text),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null as String?),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, pinCtrl.text),
                  style: FilledButton.styleFrom(backgroundColor: c.danger),
                  child: const Text('Confirmer'),
                ),
              ],
            ),
          );
        },
      );

      if (pinValide == null || pinValide != session?.pin) {
        provider.notifier(pinValide == null ? 'Annulé.' : 'Code PIN incorrect.', TonToast.erreur);
        return;
      }
    }

    // Étape 4 : Suppression totale
    await provider.supprimerBoutique();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AccueilScreen()),
      (route) => false,
    );
    provider.notifier('Boutique supprimée avec succès.', TonToast.succes);
  }

  void _montrerChangementMdp(BuildContext context) {
    final c = context.colors;
    final provider = context.read<AppProvider>();
    final ancienCtrl = TextEditingController();
    final nouveauCtrl = TextEditingController();
    final confirmerCtrl = TextEditingController();
    String? erreur;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Icon(Icons.password_rounded, size: 40, color: c.primary),
              const SizedBox(height: 12),
              Text(
                'Changer mon mot de passe',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c.ink),
              ),
              const SizedBox(height: 24),
              Champ(
                label: 'Mot de passe actuel',
                enfant: Saisie(
                  controller: ancienCtrl,
                  masque: true,
                  hint: '••••••',
                ),
              ),
              const SizedBox(height: 16),
              Champ(
                label: 'Nouveau mot de passe',
                enfant: Saisie(
                  controller: nouveauCtrl,
                  masque: true,
                  hint: 'Min. 6 caractères',
                ),
              ),
              const SizedBox(height: 16),
              Champ(
                label: 'Confirmer le mot de passe',
                enfant: Saisie(
                  controller: confirmerCtrl,
                  masque: true,
                  hint: '••••••',
                ),
              ),
              if (erreur != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    erreur!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.danger, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Bouton(
                taille: TailleBouton.lg,
                pleineLargeur: true,
                onPressed: () {
                  final ancien = ancienCtrl.text;
                  final nouveau = nouveauCtrl.text;
                  final confirmer = confirmerCtrl.text;
                  if (ancien != provider.session?.motDePasse) {
                    setSheetState(() => erreur = 'Le mot de passe actuel est incorrect.');
                    return;
                  }
                  if (nouveau.length < 6) {
                    setSheetState(() => erreur = 'Le nouveau mot de passe doit contenir au moins 6 caractères.');
                    return;
                  }
                  if (nouveau != confirmer) {
                    setSheetState(() => erreur = 'Les mots de passe ne correspondent pas.');
                    return;
                  }
                  provider.reinitialiserMotDePasse(provider.session!.id, nouveau);
                  Navigator.pop(ctx);
                  provider.notifier('Mot de passe changé avec succès.', TonToast.succes);
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final c = context.colors;
    final session = provider.session;
    final boutique = provider.boutique;

    return SubScreen(
      titre: 'Paramètres',
      sousTitre: session != null ? '${session.role.label} · ${session.nom}' : '',
      enfant: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (session?.role == Role.patron)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LogoBoutique(logoUrl: boutique?.logoUrl, nom: boutique?.nom, taille: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            boutique?.nom ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                          ),
                          Text(
                            boutique?.logoUrl != null
                                ? 'Logo affiché sur tous les téléphones'
                                : 'Aucun logo',
                            style: TextStyle(fontSize: 12, color: c.muted),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Bouton(
                                taille: TailleBouton.sm,
                                variante: VarianteBouton.secondaire,
                                onPressed: () async {
                                  final chemin = await ImageService.instance.ajouterImage();
                                  if (chemin != null) provider.definirLogo(chemin);
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_photo_alternate_outlined, size: 15),
                                    const SizedBox(width: 6),
                                    Text(boutique?.logoUrl != null ? 'Changer le logo' : 'Ajouter un logo'),
                                  ],
                                ),
                              ),
                              if (boutique?.logoUrl != null) ...[
                                const SizedBox(width: 8),
                                Bouton(
                                  taille: TailleBouton.sm,
                                  variante: VarianteBouton.fantome,
                                  onPressed: () => provider.definirLogo(null),
                                  child: const Text('Retirer'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.line),
              ),
              child: Column(
                children: [
                  _LigneParametre(
                    icone: Icons.password_rounded,
                    titre: 'Code PIN à 4 chiffres',
                    sousTitre: session?.pinActif == true ? 'Demandé à chaque ouverture' : 'Désactivé',
                    avecBordure: false,
                    enfant: Switch(
                      value: session?.pinActif == true,
                      onChanged: (v) {
                        final prov = context.read<AppProvider>();
                        if (session?.pinActif == true) {
                          prov.definirPin(null);
                          setState(() => _editionPin = false);
                        } else {
                          setState(() => _editionPin = true);
                        }
                      },
                      activeTrackColor: c.primary,
                    ),
                  ),
                  if (_editionPin || session?.pinActif == true)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: c.line)),
                      ),
                      child: _editionPin
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Champ(
                                  label: 'Nouveau code PIN',
                                  erreur: _erreur,
                                  enfant: Saisie(
                                    controller: _pinCtrl,
                                    clavier: TextInputType.number,
                                    maxLongueur: 4,
                                    filtre: (v) => v.replaceAll(RegExp(r'\D'), ''),
                                    alignement: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 8,
                                    ),
                                    hint: '••••',
                                    onChanged: (v) => setState(() {
                                      _pin = v;
                                      _erreur = null;
                                    }),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Bouton(
                                      taille: TailleBouton.sm,
                                      onPressed: _enregistrerPin,
                                      child: const Text('Enregistrer'),
                                    ),
                                    const SizedBox(width: 8),
                                    Bouton(
                                      taille: TailleBouton.sm,
                                      variante: VarianteBouton.fantome,
                                      onPressed: () => setState(() => _editionPin = false),
                                      child: const Text('Annuler'),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : TextButton(
                              onPressed: () => setState(() => _editionPin = true),
                              style: TextButton.styleFrom(
                                foregroundColor: c.primary,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 32),
                                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              child: const Text('Modifier le code PIN'),
                            ),
                    ),
                  _LigneParametre(
                    icone: Icons.fingerprint_rounded,
                    titre: 'Biométrie',
                    sousTitre: session?.pinActif == true
                        ? 'Empreinte ou visage pour déverrouiller'
                        : "Activez d'abord le code PIN",
                    enfant: Switch(
                      value: session?.biometrie == true,
onChanged: (v) {
                        final prov = context.read<AppProvider>();
                        if (session?.pinActif == true) {
                          prov.basculerBiometrie();
                        } else {
                          prov.notifier('Activez d\'abord le code PIN.', TonToast.erreur);
                        }
                      },
                      activeTrackColor: c.primary,
                    ),
                  ),
                  _LigneParametre(
                    icone: Icons.password_rounded,
                    titre: 'Mot de passe',
                    sousTitre: session?.role == Role.patron
                        ? 'Changer le mot de passe du patron'
                        : 'Changer mon mot de passe',
                    avecBordure: false,
                    enfant: Bouton(
                      taille: TailleBouton.sm,
                      variante: VarianteBouton.secondaire,
                      onPressed: () => _montrerChangementMdp(context),
                      child: const Text('Changer'),
                    ),
                  ),
                  _LigneParametre(
                    icone: provider.sombre ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    titre: 'Thème sombre',
                    sousTitre: 'Confort de lecture en boutique',
                    enfant: Switch(
                      value: provider.sombre,
                      onChanged: (_) => context.read<AppProvider>().basculerTheme(),
                      activeTrackColor: c.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            if (session?.role == Role.patron)
              Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.line),
                ),
                child: Column(
                  children: [
                    _LienParametre(
                      icone: Icons.group_outlined,
                      label: 'Gestion des comptes employés',
                      description: 'Créer, suspendre, supprimer',
                      surTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EmployesScreen()),
                      ),
                    ),
                    _LienParametre(
                      icone: Icons.smartphone_rounded,
                      label: 'Appareils connectés',
                      description: 'Voir et révoquer les téléphones',
                      surTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AppareilsScreen()),
                      ),
                      avecBordure: true,
                    ),
                  ],
                ),
              ),

            if (session?.role == Role.patron) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: c.danger.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.danger.withValues(alpha: 0.3)),
                ),
                child: _LigneParametre(
                  icone: Icons.delete_forever_outlined,
                  titre: 'Supprimer la boutique',
                  sousTitre: 'Action irréversible — toutes les données seront perdues',
                  avecBordure: false,
                  enfant: Bouton(
                    taille: TailleBouton.sm,
                    variante: VarianteBouton.secondaire,
                    onPressed: () => _confirmerSuppression(context),
                    child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Bouton(
              taille: TailleBouton.lg,
              pleineLargeur: true,
              variante: VarianteBouton.secondaire,
              onPressed: () {
                provider.deconnexion();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AccueilScreen()),
                  (route) => false,
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout_rounded, size: 17),
                  SizedBox(width: 8),
                  Text('Se déconnecter'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ma Boutique · ${boutique?.nom ?? ''}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _LigneParametre extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String sousTitre;
  final Widget enfant;
  final bool avecBordure;

  const _LigneParametre({
    required this.icone,
    required this.titre,
    required this.sousTitre,
    required this.enfant,
    this.avecBordure = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: avecBordure ? Border(top: BorderSide(color: c.line)) : null,
      ),
      child: Row(
        children: [
          Icon(icone, size: 18, color: c.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                ),
                Text(sousTitre, style: TextStyle(fontSize: 12, color: c.muted)),
              ],
            ),
          ),
          enfant,
        ],
      ),
    );
  }
}

class _LienParametre extends StatelessWidget {
  final IconData icone;
  final String label;
  final String description;
  final VoidCallback surTap;
  final bool avecBordure;

  const _LienParametre({
    required this.icone,
    required this.label,
    required this.description,
    required this.surTap,
    this.avecBordure = false,
  });

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: avecBordure ? Border(top: BorderSide(color: c.line)) : null,
          ),
          child: Row(
            children: [
              Icon(icone, size: 18, color: c.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                    ),
                    Text(description, style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: c.muted),
            ],
          ),
        ),
      ),
    );
  }
}