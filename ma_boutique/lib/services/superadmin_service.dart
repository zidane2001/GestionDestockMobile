import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/permissions.dart';
import '../core/supabase_config.dart';
import '../models/models.dart';

/// Console superadmin : accès à toutes les boutiques via la clé
/// service_role (contourne la RLS). En production, remplacer par
/// une API administrateur sécurisée côté serveur.
class SuperadminService {
  SuperadminService._(this._client);

  final SupabaseClient _client;

  SupabaseClient get client => _client;

  static SuperadminService? _instance;

  static SuperadminService? get instance {
    if (supabaseServiceKey.startsWith('REMPLACEZ-MOI')) return null;
    _instance ??= SuperadminService._(SupabaseClient(supabaseUrl, supabaseServiceKey));
    return _instance;
  }

  Future<List<Map<String, dynamic>>> listerBoutiques() async {
    final rows = await _client.from('boutiques').select().order('nom');
    return rows;
  }

  Future<List<Map<String, dynamic>>> listerAdmins() async {
    final rows = await _client.from('admins').select().order('nom');
    return rows;
  }

  Future<Map<String, int>> compter(String boutiqueId) async {
    final r = <String, int>{};
    for (final table in ['employes', 'produits', 'ventes']) {
      final res = await _client
          .from(table)
          .select('id')
          .eq('boutique_id', boutiqueId)
          .count(CountOption.exact);
      r[table] = res.count;
    }
    return r;
  }

  /// Crée un compte admin (Supabase Auth) + sa fiche dans `admins` +
  /// une boutique rattachée (admin_id) + un tenant pour la RLS.
  Future<void> creerAdmin({
    required String nom,
    required String email,
    required String motDePasse,
    String telephone = '',
    String? nomBoutique,
  }) async {
    final user = await _client.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: motDePasse,
        emailConfirm: true,
      ),
    );
    final adminId = user.user!.id;

    try {
      await _client.from('admins').insert({
        'id': adminId,
        'nom': nom,
        'email': email,
        'telephone': telephone,
      });
    } catch (e) {
      await _client.auth.admin.deleteUser(adminId);
      rethrow;
    }

    // Créer la boutique rattachée à cet admin
    final boutiqueId = 'boutique_${adminId.substring(0, 8)}';
    final boutiqueNom = nomBoutique?.isNotEmpty == true ? nomBoutique! : 'Boutique de $nom';
    try {
      await _client.from('boutiques').insert({
        'id': boutiqueId,
        'nom': boutiqueNom,
        'style_commerce': '',
        'monnaie': 'FCFA',
        'email_patron': email,
        'admin_id': adminId,
        'statut': 'active',
        'abonnement_mode': 'achat_direct',
        'notification_abonnement': false,
        'methode_paiement': '',
        'solde_caisse': 0,
      });
    } catch (e) {
      rethrow;
    }

    // Créer le tenant pour la RLS
    await _client.from('boutique_tenants').insert({
      'user_id': adminId,
      'boutique_id': boutiqueId,
    });

    // Créer l'employé patron pour que le ConnexionScreen fonctionne
    final employeId = 'emp_${adminId.substring(0, 8)}';
    final permissionsStr = permissionsParDefaut(Role.patron).map((p) => p.name).join(',');
    await _client.from('employes').insert({
      'id': employeId,
      'boutique_id': boutiqueId,
      'nom': nom,
      'role': 'patron',
      'permissions': permissionsStr,
      'mot_de_passe': motDePasse,
      'statut': 'actif',
      'pin_actif': false,
      'pin': '',
      'biometrie': false,
      'date_creation': DateTime.now().toIso8601String(),
    });
  }

  /// Définit l'abonnement d'une boutique (réactive au passage).
  /// Direct : 30 j sans notification. Mensuel : 30 j. Trimestriel : 90 j.
  Future<void> definirAbonnement({
    required String boutiqueId,
    required String mode,
    required String methode,
  }) async {
    final duree = mode == 'trimestriel' ? 90 : 30;
    final debut = DateTime.now().toUtc();
    final fin = debut.add(Duration(days: duree));
    await _client.from('boutiques').update({
      'abonnement_mode': mode,
      'abonnement_debut': debut.toIso8601String(),
      'abonnement_fin': fin.toIso8601String(),
      'notification_abonnement': mode != 'achat_direct',
      'methode_paiement': methode,
      'statut': 'active',
    }).eq('id', boutiqueId);
  }

  /// Applique le même abonnement à toutes les boutiques d'un admin.
  Future<void> appliquerAbonnementToutAdmin({
    required String adminId,
    required String mode,
    required String methode,
  }) async {
    final boutiques = await _client.from('boutiques').select('id').eq('admin_id', adminId);
    for (final b in boutiques) {
      await definirAbonnement(boutiqueId: b['id'] as String, mode: mode, methode: methode);
    }
  }

  Future<void> activerBoutique(String id, bool actif) async {
    await _client
        .from('boutiques')
        .update({'statut': actif ? 'active' : 'desactivee'})
        .eq('id', id);
  }

  Future<void> reinitialiserMotDePassePatron(String boutiqueId, String motDePasse) async {
    await _client
        .from('employes')
        .update({'mot_de_passe': motDePasse})
        .eq('boutique_id', boutiqueId)
        .eq('role', 'patron');
  }

  Future<void> supprimerBoutique(String id) async {
    await _client.from('boutiques').delete().eq('id', id);
  }
}