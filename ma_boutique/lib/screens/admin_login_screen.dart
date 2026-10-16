import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../services/superadmin_service.dart';
import '../widgets/sub_screen.dart';
import '../widgets/ui/button.dart';
import '../widgets/ui/field.dart';
import 'admin_screen.dart';
import 'superadmin_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  bool _chargement = false;
  String? _erreur;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _mdpCtrl.dispose();
    super.dispose();
  }

  Future<void> _soumettre() async {
    final input = _emailCtrl.text.trim();
    final mdp = _mdpCtrl.text;
    if (input.isEmpty || mdp.isEmpty) {
      setState(() => _erreur = 'Renseignez votre identifiant et votre mot de passe.');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    // Détection superadmin
    if (input.toLowerCase() == superadminNomBoutique && mdp == superadminMotDePasse) {
      final service = SuperadminService.instance;
      if (service == null) {
        if (mounted) setState(() { _erreur = 'Clé service_role non renseignée.'; _chargement = false; });
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SuperadminScreen()),
        (route) => false,
      );
      return;
    }

    try {
      // Résoudre le nom en email si pas de @
      String email = input;
      if (!input.contains('@')) {
        final service = SuperadminService.instance;
        if (service != null) {
          final admins = await service.listerAdmins();
          final match = admins.cast<Map<String, dynamic>?>().firstWhere(
            (a) => (a?['nom'] as String? ?? '').toLowerCase() == input.toLowerCase(),
            orElse: () => null,
          );
          if (match == null) {
            if (mounted) setState(() { _erreur = 'Aucun administrateur nommé "$input".'; _chargement = false; });
            return;
          }
          email = match['email'] as String;
        }
      }

      await Supabase.instance.client.auth.signInWithPassword(email: email, password: mdp);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erreur = 'Impossible de se connecter au serveur.');
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SubScreen(
      titre: 'Espace administrateur',
      sousTitre: 'Gérez vos boutiques',
      enfant: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.badge_rounded, size: 56, color: c.primary),
            const SizedBox(height: 24),
            Champ(
              label: 'Nom ou email',
              enfant: Saisie(
                controller: _emailCtrl,
                hint: 'Nom de l\'admin ou email',
              ),
            ),
            Champ(
              label: 'Mot de passe',
              enfant: Saisie(
                controller: _mdpCtrl,
                masque: true,
                hint: '••••••••',
              ),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 8),
              Text(
                _erreur!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.danger, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            Bouton(
              onPressed: _chargement ? null : _soumettre,
              child: _chargement
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Se connecter'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}