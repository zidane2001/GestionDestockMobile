import 'package:flutter/material.dart' hide Badge;

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/superadmin_service.dart';
import '../widgets/shared_helpers.dart';
import '../widgets/sub_screen.dart';
import '../widgets/ui/badge.dart';
import '../widgets/ui/button.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/field.dart';
import 'accueil_screen.dart';

class _Donnees {
  final List<Map<String, dynamic>> boutiques;
  final List<Map<String, dynamic>> admins;

  const _Donnees(this.boutiques, this.admins);
}

class SuperadminScreen extends StatefulWidget {
  const SuperadminScreen({super.key});

  @override
  State<SuperadminScreen> createState() => _SuperadminScreenState();
}

class _SuperadminScreenState extends State<SuperadminScreen> {
  Future<_Donnees>? _futur;

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  Future<_Donnees> _charger() async {
    final service = SuperadminService.instance!;
    final boutiques = await service.listerBoutiques();
    final admins = await service.listerAdmins();
    return _Donnees(boutiques, admins);
  }

  void _recharger() {
    final futur = _charger();
    setState(() { _futur = futur; });
  }

  Future<void> _creerAdmin() async {
    final nomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final mdpCtrl = TextEditingController();
    final boutiqueCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvel administrateur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Champ(
                label: 'Nom complet',
                enfant: Saisie(controller: nomCtrl, hint: 'Ex : Awa Diallo'),
              ),
              Champ(
                label: 'Email (identifiant de connexion)',
                enfant: Saisie(controller: emailCtrl, hint: 'awa@exemple.com'),
              ),
              Champ(
                label: 'Téléphone (facultatif)',
                enfant: Saisie(controller: telCtrl, hint: '+225 07 00 00 00 00'),
              ),
              Champ(
                label: 'Mot de passe',
                enfant: Saisie(controller: mdpCtrl, masque: true, hint: '••••••••'),
              ),
              Champ(
                label: 'Nom de la boutique (facultatif)',
                enfant: Saisie(controller: boutiqueCtrl, hint: 'Ex : Boutique Awa'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (nomCtrl.text.trim().isEmpty ||
                  emailCtrl.text.trim().isEmpty ||
                  mdpCtrl.text.isEmpty) {
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await SuperadminService.instance!.creerAdmin(
        nom: nomCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        motDePasse: mdpCtrl.text,
        telephone: telCtrl.text.trim(),
        nomBoutique: boutiqueCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Administrateur et boutique créés.')),
      );
      _recharger();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e'), duration: const Duration(seconds: 5)),
      );
    }
  }

  Future<void> _definirAbonnement(Map<String, dynamic> b) async {
    final id = b['id'] as String;
    var mode = b['abonnement_mode'] as String? ?? 'achat_direct';
    var methode = b['methode_paiement'] as String? ?? methodesPaiement.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('Abonnement — ${b['nom']}'),
          content: RadioGroup<String>(
            groupValue: mode,
            onChanged: (v) => setDialog(() => mode = v ?? mode),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mode d\'abonnement', style: TextStyle(fontWeight: FontWeight.w600)),
                for (final m in abonnementModes)
                  RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(m.$2),
                    value: m.$1,
                  ),
                const SizedBox(height: 8),
                Text('Méthode de paiement', style: TextStyle(fontWeight: FontWeight.w600)),
                DropdownButtonFormField<String>(
                  initialValue: methodesPaiement.contains(methode) ? methode : methodesPaiement.first,
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    for (final m in methodesPaiement)
                      DropdownMenuItem(value: m, child: Text(m)),
                  ],
                  onChanged: (v) => setDialog(() => methode = v ?? methode),
                ),
                const SizedBox(height: 12),
                Text(
                  mode == 'achat_direct'
                      ? 'Achat direct : 30 jours, aucune notification de renouvellement.'
                      : 'Renouvellement ${mode == 'mensuel' ? 'mensuel (30 j)' : 'trimestriel (90 j)'} '
                          'avec notification au boutique.',
                  style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.outline),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await SuperadminService.instance!.definirAbonnement(
        boutiqueId: id,
        mode: mode,
        methode: methode,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abonnement enregistré, boutique réactivée.')),
      );
      _recharger();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec : $e')));
    }
  }

  Future<void> _appliquerTout(String adminId, String adminNom) async {
    var mode = 'mensuel';
    var methode = methodesPaiement.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('Payer tout pour $adminNom'),
          content: RadioGroup<String>(
            groupValue: mode,
            onChanged: (v) => setDialog(() => mode = v ?? mode),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appliquer le même abonnement et la même méthode de paiement à TOUTES ses boutiques.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                for (final m in abonnementModes)
                  RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(m.$2),
                    value: m.$1,
                  ),
                DropdownButtonFormField<String>(
                  initialValue: methodesPaiement.first,
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    for (final m in methodesPaiement)
                      DropdownMenuItem(value: m, child: Text(m)),
                  ],
                  onChanged: (v) => setDialog(() => methode = v ?? methode),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Payer tout'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await SuperadminService.instance!.appliquerAbonnementToutAdmin(
        adminId: adminId,
        mode: mode,
        methode: methode,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abonnement appliqué à toutes ses boutiques.')),
      );
      _recharger();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec : $e')));
    }
  }

  Future<void> _basculerStatut(String id, bool actif, String nom) async {
    await SuperadminService.instance!.activerBoutique(id, actif);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(actif ? '$nom réactivée.' : '$nom désactivée.')),
    );
    _recharger();
  }

  Future<void> _reinitialiserPatron(String boutiqueId, String nom) async {
    final ctrl = TextEditingController();
    final mdp = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Réinitialiser $nom'),
        content: Champ(
          label: 'Nouveau mot de passe du patron',
          enfant: Saisie(
            controller: ctrl,
            masque: true,
            hint: '••••••',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (mdp == null || mdp.trim().isEmpty) return;
    await SuperadminService.instance!.reinitialiserMotDePassePatron(boutiqueId, mdp.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mot de passe du patron de $nom réinitialisé.')),
    );
  }

  Future<void> _supprimer(String id, String nom) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer « $nom » ?'),
        content: const Text(
          'Toute la boutique sera supprimée définitivement : employés, produits, ventes, dépenses, pointages, journal et appareils.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: TextStyle(color: ctx.colors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await SuperadminService.instance!.supprimerBoutique(id);
    if (!mounted) return;
    _recharger();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final service = SuperadminService.instance;
    if (service == null) {
      return SubScreen(
        titre: 'Superadmin',
        sousTitre: 'Non configuré',
        enfant: const EtatVide(
          icone: Icons.admin_panel_settings_outlined,
          titre: 'Clé service_role manquante',
          texte: 'Renseignez SUPABASE_SERVICE_KEY dans lib/core/supabase_config.dart.',
        ),
      );
    }

    return SubScreen(
      titre: 'Superadmin',
      sousTitre: 'Boutiques & abonnements du SaaS',
      action: TextButton(
        onPressed: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AccueilScreen()),
          (route) => false,
        ),
        style: TextButton.styleFrom(
          foregroundColor: c.muted,
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 32),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: const Text('Se déconnecter'),
      ),
      enfant: FutureBuilder(
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
              titre: 'Impossible de charger les données',
              texte: 'Le schéma Supabase est-il appliqué ? (${snap.error})',
            );
          }
          final donnees = snap.data as _Donnees;
          if (donnees.boutiques.isEmpty && donnees.admins.isEmpty) {
            return const EtatVide(
              icone: Icons.storefront_rounded,
              titre: 'Rien pour le moment',
              texte:
                  'Créez un administrateur puis définissez les abonnements de ses boutiques.',
            );
          }
          final sansAdmin =
              donnees.boutiques.where((b) => b['admin_id'] == null).toList();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Administrateurs',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: c.ink,
                        ),
                      ),
                    ),
                    Bouton(
                      taille: TailleBouton.sm,
                      onPressed: _creerAdmin,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add_alt_1_rounded, size: 15),
                          SizedBox(width: 6),
                          Text('Créer un admin'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (donnees.admins.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Aucun administrateur. Créez-en un pour y rattacher des boutiques.',
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ),
                for (final a in donnees.admins)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.line),
                    ),
                    child: _CarteAdmin(
                      admin: a,
                      nbBoutiques:
                          donnees.boutiques.where((b) => b['admin_id'] == a['id']).length,
                      surTout: () =>
                          _appliquerTout(a['id'] as String, a['nom'] as String? ?? ''),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Boutiques',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 8),
                for (final a in donnees.admins)
                  ..._sectionAdmin(donnees, a, c),
                if (sansAdmin.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Sans administrateur',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.muted),
                    ),
                  ),
                  for (final b in sansAdmin)
                    _carteBoutique(context, b),
                ],
                const SizedBox(height: 8),
                Text(
                  'Achat direct : 30 j sans notification. Mensuel 30 j et trimestriel 90 j : '
                  'notification de renouvellement à la boutique.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _sectionAdmin(_Donnees donnees, Map<String, dynamic> a, AppColors c) {
    final mes = donnees.boutiques.where((b) => b['admin_id'] == a['id']).toList();
    if (mes.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Boutiques de ${a['nom']}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.muted),
        ),
      ),
      for (final b in mes) _carteBoutique(context, b),
    ];
  }

  Widget _carteBoutique(BuildContext context, Map<String, dynamic> b) {
    final id = b['id'] as String;
    final nom = b['nom'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.line),
      ),
      child: _CarteBoutique(
        boutique: b,
        surAbonnement: () => _definirAbonnement(b),
        surStatut: () =>
            _basculerStatut(id, (b['statut'] as String? ?? 'active') == 'desactivee', nom),
        surReset: () => _reinitialiserPatron(id, nom),
        surSupprimer: () => _supprimer(id, nom),
      ),
    );
  }
}

class _CarteAdmin extends StatelessWidget {
  final Map<String, dynamic> admin;
  final int nbBoutiques;
  final VoidCallback surTout;

  const _CarteAdmin({
    required this.admin,
    required this.nbBoutiques,
    required this.surTout,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: c.primary,
          child: Text(
            (admin['nom'] as String? ?? '?').characters.first.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                admin['nom'] as String? ?? '',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: c.ink),
              ),
              Text(
                '${admin['email']} · $nbBoutiques boutique${nbBoutiques > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
            ],
          ),
        ),
        Bouton(
          taille: TailleBouton.sm,
          variante: VarianteBouton.secondaire,
          onPressed: surTout,
          child: const Text('Payer tout'),
        ),
      ],
    );
  }
}

class _CarteBoutique extends StatelessWidget {
  final Map<String, dynamic> boutique;
  final VoidCallback surAbonnement;
  final VoidCallback surStatut;
  final VoidCallback surReset;
  final VoidCallback surSupprimer;

  const _CarteBoutique({
    required this.boutique,
    required this.surAbonnement,
    required this.surStatut,
    required this.surReset,
    required this.surSupprimer,
  });

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    boutique['nom'] as String? ?? '',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${boutique['email_patron'] as String? ?? '—'} · '
                    '${formatMontant(solde, monnaie)} en caisse',
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ],
              ),
            ),
            Badge(
              ton: actif ? TonBadge.succes : TonBadge.danger,
              child: Text(actif ? 'Active' : 'Désactivée'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$modeLabel · $methode'
          '${notification ? ' · notification ON' : ''}'
          '${fin != null ? ' · fin le ${dateCourt(fin)}' : ''}',
          style: TextStyle(fontSize: 12, color: c.muted),
        ),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, int>>(
          future: SuperadminService.instance!.compter(boutique['id'] as String),
          builder: (context, snap) {
            final counts = snap.data ?? const <String, int>{};
            return Row(
              children: [
                Compteur(label: 'Employés', valeur: counts['employes'] ?? 0),
                Compteur(label: 'Produits', valeur: counts['produits'] ?? 0),
                Compteur(label: 'Ventes', valeur: counts['ventes'] ?? 0),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Bouton(
              taille: TailleBouton.sm,
              onPressed: surAbonnement,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_repeat_rounded, size: 15),
                  SizedBox(width: 6),
                  Text('Abonnement'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Bouton(
              taille: TailleBouton.sm,
              variante: VarianteBouton.secondaire,
              onPressed: surStatut,
              child: Text(actif ? 'Désactiver' : 'Réactiver'),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Mot de passe patron',
              icon: const Icon(Icons.password_rounded, size: 18),
              onPressed: surReset,
            ),
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              color: c.danger,
              onPressed: surSupprimer,
            ),
          ],
        ),
      ],
    );
  }
}