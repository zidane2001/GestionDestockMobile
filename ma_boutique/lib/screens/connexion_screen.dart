import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/superadmin_service.dart';
import '../widgets/ui/button.dart';
import '../widgets/ui/field.dart';
import 'home_screen.dart';
import 'superadmin_screen.dart';

class ConnexionScreen extends StatefulWidget {
  const ConnexionScreen({super.key});

  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen> {
  final _nomCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  Role _role = Role.patron;
  String? _erreur;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _mdpCtrl.dispose();
    super.dispose();
  }

  bool _chargement = false;

  Future<void> _soumettre() async {
    // Détection superadmin depuis le formulaire principal
    if (_nomCtrl.text.trim().toLowerCase() == superadminNomBoutique) {
      if (_mdpCtrl.text == superadminMotDePasse) {
        final service = SuperadminService.instance;
        if (service == null) {
          setState(() => _erreur = 'Clé service_role non renseignée.');
          return;
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SuperadminScreen()),
          (route) => false,
        );
        return;
      }
      setState(() => _erreur = 'Mot de passe superadmin incorrect.');
      return;
    }

    // 1) Tentative de connexion locale
    final provider = context.read<AppProvider>();
    var message = await provider.connexion(
      _nomCtrl.text,
      _role,
      _mdpCtrl.text,
    );

    // 2) Si échec local + Supabase configuré → résoudre depuis Supabase
    if (message != null && supabaseConfigure) {
      setState(() {
        _chargement = true;
        _erreur = null;
      });
      try {
        final imported = await _importerDepuisSupabase(
          _nomCtrl.text.trim(),
          _mdpCtrl.text,
        );
        if (imported) {
          message = await provider.connexion(
            _nomCtrl.text,
            _role,
            _mdpCtrl.text,
          );
          if (message != null) {
            message = 'Données synchronisées mais $message';
          }
        }
      } catch (_) {
        // Erreur silencieuse
      } finally {
        if (mounted) setState(() => _chargement = false);
      }
    }

    if (message != null) {
      setState(() => _erreur = message);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  /// Cherche la boutique dans Supabase par son nom, puis copie
  /// la boutique + les employés dans la base locale.
  Future<bool> _importerDepuisSupabase(String nomBoutique, String motDePasse) async {
    final service = SuperadminService.instance;
    if (service == null) return false;

    final db = context.read<AppProvider>();
    final boutiques = await service.listerBoutiques();
    final b = boutiques.cast<Map<String, dynamic>?>().firstWhere(
      (row) => (row?['nom'] as String? ?? '').toLowerCase() == nomBoutique.toLowerCase(),
      orElse: () => null,
    );
    if (b == null) return false;

    await db.importerBoutiqueDepuisSupabase(b);

    final boutiqueId = b['id'] as String;
    final employes = await service.client.from('employes').select().eq('boutique_id', boutiqueId);

    for (final emp in employes) {
      await db.importerEmployeDepuisSupabase(emp);
    }

    return true;
  }

  void _montrerRecuperationCompte() {
    final c = context.colors;
    final emailCtrl = TextEditingController();
    String? erreur;
    bool chargement = false;

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
              Icon(Icons.lock_reset_rounded, size: 40, color: c.primary),
              const SizedBox(height: 12),
              Text(
                'Récupérer mon compte',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c.ink),
              ),
              const SizedBox(height: 4),
              Text(
                'Entrez l\'email associé à votre compte patron.\nUn lien de réinitialisation vous sera envoyé.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: c.muted),
              ),
              const SizedBox(height: 24),
              Champ(
                label: 'Email du patron',
                enfant: Saisie(
                  controller: emailCtrl,
                  hint: 'patron@boutique.com',
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
                onPressed: chargement
                    ? null
                    : () async {
                        final email = emailCtrl.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          setSheetState(() => erreur = 'Entrez un email valide.');
                          return;
                        }
                        setSheetState(() { chargement = true; erreur = null; });
                        try {
                          await Supabase.instance.client.auth.resetPasswordForEmail(email);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Lien de réinitialisation envoyé à $email'),
                                backgroundColor: c.success,
                              ),
                            );
                            Navigator.pop(ctx);
                          }
                        } catch (e) {
                          setSheetState(() {
                            erreur = 'Erreur : ${e.toString()}';
                            chargement = false;
                          });
                        }
                      },
                child: chargement
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Envoyer le lien'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  void _ouvrirSuperadmin() {
    final c = context.colors;
    final nomCtrl = TextEditingController();
    final mdpCtrl = TextEditingController();
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
              Icon(Icons.shield_rounded, size: 40, color: c.primary),
              const SizedBox(height: 12),
              Text(
                'Espace superadmin',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c.ink),
              ),
              const SizedBox(height: 4),
              Text(
                'Gestion des abonnements et des boutiques.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: c.muted),
              ),
              const SizedBox(height: 24),
              Champ(
                label: 'Nom de la boutique',
                enfant: Saisie(
                  controller: nomCtrl,
                  hint: '« superadmin »',
                ),
              ),
              const SizedBox(height: 16),
              Champ(
                label: 'Mot de passe',
                erreur: erreur,
                enfant: Saisie(
                  controller: mdpCtrl,
                  masque: true,
                  hint: '••••••••',
                ),
              ),
              const SizedBox(height: 20),
              Bouton(
                taille: TailleBouton.lg,
                pleineLargeur: true,
                onPressed: () {
                  if (nomCtrl.text.trim().toLowerCase() == superadminNomBoutique &&
                      mdpCtrl.text == superadminMotDePasse) {
                    Navigator.pop(ctx);
                    final service = SuperadminService.instance;
                    if (service == null) {
                      setState(() => _erreur =
                          'Clé service_role non renseignée.');
                      return;
                    }
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const SuperadminScreen()),
                      (route) => false,
                    );
                  } else {
                    setSheetState(() => erreur = 'Identifiants incorrects.');
                  }
                },
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final roles = [
      (role: Role.patron, label: 'Patron', description: 'Accès complet', icone: Icons.workspace_premium_outlined),
      (role: Role.manager, label: 'Manager', description: 'Ventes & dépenses', icone: Icons.business_center_outlined),
      (role: Role.caissiere, label: 'Caissière', description: 'Caisse & ventes', icone: Icons.account_balance_wallet_outlined),
    ];

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
                    'Se connecter',
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
                    Champ(
                      label: 'Nom de la boutique',
                      enfant: Saisie(
                        controller: _nomCtrl,
                        hint: 'Nom exact de la boutique',
                        onChanged: (_) => setState(() => _erreur = null),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Champ(
                      label: 'Je me connecte en tant que',
                      enfant: Column(
                        children: [
                          for (final r in roles)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _CarteRole(
                                icone: r.icone,
                                label: r.label,
                                description: r.description,
                                actif: _role == r.role,
                                surTap: () => setState(() {
                                  _role = r.role;
                                  _erreur = null;
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Champ(
                      label: 'Mot de passe',
                      erreur: _erreur,
                      enfant: Saisie(
                        controller: _mdpCtrl,
                        masque: true,
                        hint: '••••••',
                        onChanged: (_) => setState(() => _erreur = null),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Bouton(
                      taille: TailleBouton.lg,
                      pleineLargeur: true,
                      onPressed: _chargement ? null : _soumettre,
                      child: _chargement
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Se connecter'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Mot de passe oublié ? Le patron peut le réinitialiser depuis les paramètres.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, height: 1.5, color: c.muted),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _montrerRecuperationCompte(),
                      child: Text(
                        'Récupérer mon compte',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.primary),
                      ),
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

class _CarteRole extends StatelessWidget {
  final IconData icone;
  final String label;
  final String description;
  final bool actif;
  final VoidCallback surTap;

  const _CarteRole({
    required this.icone,
    required this.label,
    required this.description,
    required this.actif,
    required this.surTap,
  });

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: actif ? c.primary : c.line),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: actif ? c.primary : c.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, size: 17, color: actif ? c.onPrimary : c.muted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: actif ? c.primary : c.ink,
                      ),
                    ),
                    Text(description, style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: actif ? c.primary : Colors.transparent,
                  border: Border.all(color: actif ? c.primary : c.line, width: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
