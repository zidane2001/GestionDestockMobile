import 'package:flutter/material.dart' hide Badge;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/shared_helpers.dart';
import '../widgets/sub_screen.dart';
import '../widgets/ui/badge.dart';
import '../widgets/ui/empty_state.dart';
import 'accueil_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late Future<List<Map<String, dynamic>>> _futur;

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  Future<List<Map<String, dynamic>>> _charger() async {
    final client = Supabase.instance.client;
    final rows = await client.from('boutiques').select().order('nom');
    return rows;
  }

  Future<Map<String, dynamic>> _stats(String id) async {
    final res = await Supabase.instance.client.rpc('stats_boutique', params: {
      'p_boutique_id': id,
    });
    return res.first as Map<String, dynamic>;
  }

  Future<void> _deconnexion() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AccueilScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SubScreen(
      titre: 'Mes boutiques',
      sousTitre: 'Espace administrateur',
      action: TextButton(
        onPressed: _deconnexion,
        style: TextButton.styleFrom(
          foregroundColor: c.muted,
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 32),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: const Text('Se déconnecter'),
      ),
      enfant: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futur,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError) {
            return EtatVide(
              icone: Icons.error_outline_rounded,
              titre: 'Impossible de charger vos boutiques',
              texte: '${snap.error}',
            );
          }
          final boutiques = snap.data ?? const <Map<String, dynamic>>[];
          if (boutiques.isEmpty) {
            return const EtatVide(
              icone: Icons.storefront_rounded,
              titre: 'Aucune boutique',
              texte:
                  'Le superadmin doit rattacher des boutiques à votre compte administrateur.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final b in boutiques)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.line),
                  ),
                  child: _CarteAdminBoutique(
                    boutique: b,
                    stats: _stats(b['id'] as String),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Vous visualisez et pilotez uniquement vos boutiques.\n'
                'Opérations internes (ventes, stock, pointages) : dans chaque boutique, '
                'avec un compte employé (patron/manager/caissière).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, height: 1.5, color: c.muted),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CarteAdminBoutique extends StatelessWidget {
  final Map<String, dynamic> boutique;
  final Future<Map<String, dynamic>> stats;

  const _CarteAdminBoutique({required this.boutique, required this.stats});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final monnaie = boutique['monnaie'] as String? ?? 'FCFA';
    final solde = (boutique['solde_caisse'] as num? ?? 0).toDouble();
    final actif = (boutique['statut'] as String? ?? 'active') == 'active';
    final mode = boutique['abonnement_mode'] as String? ?? 'achat_direct';
    final fin = DateTime.tryParse(boutique['abonnement_fin'] as String? ?? '');
    final notification = boutique['notification_abonnement'] == true;
    final methode = boutique['methode_paiement'] as String? ?? '';
    final modeLabel = abonnementModes
        .firstWhere((m) => m.$1 == mode, orElse: () => const ('achat_direct', 'Achat direct (30 j)'))
        .$2;
    final expire = fin != null && fin.isBefore(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                boutique['nom'] as String? ?? '',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.ink),
              ),
            ),
            Badge(
              ton: actif ? TonBadge.succes : TonBadge.danger,
              child: Text(actif ? 'Active' : 'Désactivée'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.event_repeat_rounded, size: 14, color: c.muted),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '$modeLabel · $methode'
                '${fin != null ? ' · ${dateCourt(fin)}' : ''}'
                '${expire ? ' · ABONNEMENT EXPIRÉ' : ''}'
                '${notification ? ' · notification de renouvellement' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: expire ? c.danger : c.muted,
                  fontWeight: expire ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${boutique['email_patron'] as String? ?? '—'} · '
          '${formatMontant(solde, monnaie)} en caisse',
          style: TextStyle(fontSize: 12, color: c.muted),
        ),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, dynamic>>(
          future: stats,
          builder: (context, snap) {
            final s = snap.data ?? const <String, dynamic>{};
            return Row(
              children: [
                Compteur(label: 'Employés', valeur: (s['employes'] as num? ?? 0).toInt()),
                Compteur(label: 'Produits', valeur: (s['produits'] as num? ?? 0).toInt()),
                Compteur(label: 'Ventes', valeur: (s['ventes'] as num? ?? 0).toInt()),
              ],
            );
          },
        ),
      ],
    );
  }
}