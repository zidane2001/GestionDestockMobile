import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/permissions.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/sub_screen.dart';
import '../widgets/ui/badge.dart';
import '../widgets/ui/button.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/field.dart';
import '../widgets/ui/segmented_control.dart';
import '../widgets/ui/sheet.dart';

class EmployesScreen extends StatefulWidget {
  const EmployesScreen({super.key});

  @override
  State<EmployesScreen> createState() => _EmployesScreenState();
}

class _EmployesScreenState extends State<EmployesScreen> {
  Employe? _edition;
  String _nom = '';
  Role _role = Role.manager;
  String _mdp = '';
  List<Permission> _droits = permissionsParDefaut(Role.manager);
  String? _erreur;
  String? _reinitId;
  String _nouveauMdp = '';
  final _nomCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();

  @override
  void dispose() {
    _nomCtrl.dispose();
    _mdpCtrl.dispose();
    super.dispose();
  }

  void _ouvrirCreation() {
    setState(() {
      _edition = null;
      _nom = '';
      _role = Role.manager;
      _mdp = '';
      _droits = permissionsParDefaut(Role.manager);
      _erreur = null;
      _nomCtrl.clear();
      _mdpCtrl.clear();
    });
    _afficherFeuille();
  }

  void _ouvrirEdition(Employe e) {
    setState(() {
      _edition = e;
      _nom = e.nom;
      _role = e.role;
      _mdp = '';
      _droits = [...e.permissions];
      _erreur = null;
      _nomCtrl.text = e.nom;
      _mdpCtrl.clear();
    });
    _afficherFeuille();
  }

  void _afficherFeuille() {
    ouvrirFeuille(
      context: context,
      titre: _edition != null ? 'Droits de ${_edition!.nom}' : 'Créer un compte',
      sousTitre: _edition != null
          ? "Les droits s'appliquent dès la prochaine ouverture de son application"
          : "L'employé se connecte avec le nom de la boutique et ce mot de passe",
      enfant: StatefulBuilder(
        builder: (ctx, setSheetState) => _contenuFeuille(setSheetState),
      ),
    );
  }

  void _basculerDroit(Permission p, [StateSetter? setSheetState]) {
    final update = (setSheetState ?? setState);
    update(() {
      _droits = _droits.contains(p)
          ? _droits.where((d) => d != p).toList()
          : [..._droits, p];
      _erreur = null;
    });
  }

  void _valider([StateSetter? setSheetState]) {
    final update = setSheetState ?? setState;
    final provider = context.read<AppProvider>();
    // Sync _nom from controller
    _nom = _nomCtrl.text.trim();
    if (_nom.length < 2) {
      update(() => _erreur = "Indiquez le nom de l'employé (min. 2 caractères).");
      return;
    }
    if (_edition == null && _mdpCtrl.text.length < 6) {
      update(() => _erreur = 'Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }
    if (_edition == null) {
      _mdp = _mdpCtrl.text;
    }
    if (_droits.isEmpty) {
      update(() => _erreur = 'Attribuez au moins un droit à cet employé.');
      return;
    }
    if (_edition != null) {
      provider.modifierEmploye(_edition!.id, nom: _nom, role: _role, permissions: _droits);
    } else {
      provider.creerEmploye(_nom, _role, _mdp, _droits);
    }
    Navigator.pop(context);
  }

  Widget _contenuFeuille(StateSetter setSheetState) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Error banner at the top
        if (_erreur != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.danger.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 18, color: c.danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _erreur!,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.danger),
                  ),
                ),
                GestureDetector(
                  onTap: () => setSheetState(() => _erreur = null),
                  child: Icon(Icons.close_rounded, size: 16, color: c.danger),
                ),
              ],
            ),
          ),
        Champ(
          label: "Nom de l'employé",
          enfant: Saisie(
            controller: _nomCtrl,
            hint: 'Ex. Ibrahim Sow',
            onChanged: (v) => setSheetState(() { _nom = v; _erreur = null; }),
          ),
        ),
        const SizedBox(height: 16),
        Champ(
          label: 'Rôle',
          aide: 'Change les droits attribués par défaut',
          enfant: ControleSegmente<Role>(
            options: const [
              OptionSegmente(Role.manager, 'Manager'),
              OptionSegmente(Role.caissiere, 'Caissière'),
            ],
            valeur: _role,
            onChange: (r) => setSheetState(() {
              _role = r;
              _droits = permissionsParDefaut(r);
            }),
          ),
        ),
        if (_edition == null) ...[
          const SizedBox(height: 16),
          Champ(
            label: 'Mot de passe',
            aide: 'Minimum 6 caractères',
            enfant: Saisie(
              controller: _mdpCtrl,
              masque: true,
              hint: '••••••',
              onChanged: (v) {
                setSheetState(() {
                  _mdp = v;
                  _erreur = null;
                });
              },
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permissions',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink),
                  ),
                  Text(
                    '${_droits.length} droit${_droits.length > 1 ? 's' : ''} attribué${_droits.length > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setSheetState(() => _droits = permissionsParDefaut(_role)),
              style: TextButton.styleFrom(
                foregroundColor: c.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: const Text('Droits par défaut du rôle'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final g in groupesPermissions) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                g.titre.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: c.muted,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.line),
            ),
            child: Column(
              children: [
                for (final (i, item) in g.items.indexed)
                  _LigneDroit(
                    item: item,
                    actif: _droits.contains(item.cle),
                    avecBordure: i > 0,
                    surTap: () => _basculerDroit(item.cle, setSheetState),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Bouton(
          taille: TailleBouton.lg,
          pleineLargeur: true,
          onPressed: () => _valider(setSheetState),
          child: Text(_edition != null ? 'Enregistrer les droits' : 'Créer le compte'),
        ),
        const SizedBox(height: 8),
        Text(
          'La gestion des comptes, des appareils et le traitement des retours restent réservés au patron.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, height: 1.4, color: c.muted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final employes = provider.employes;

    return SubScreen(
      titre: 'Comptes employés',
      sousTitre: '${employes.length} compte${employes.length > 1 ? 's' : ''}',
      action: Bouton(
        taille: TailleBouton.sm,
        onPressed: _ouvrirCreation,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_alt_1_rounded, size: 15),
            SizedBox(width: 6),
            Text('Créer'),
          ],
        ),
      ),
      enfant: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (employes.isEmpty)
              const EtatVide(
                icone: Icons.group_outlined,
                titre: 'Aucun employé',
                texte: 'Créez le premier compte employé pour commencer.',
              ),
            for (final e in employes)
              _CarteEmploye(
                employe: e,
                surEdition: () => _ouvrirEdition(e),
                surReinit: () => setState(() => _reinitId = _reinitId == e.id ? null : e.id),
                surStatut: () => provider.basculerStatutEmploye(e.id),
                surSuppression: () => provider.supprimerEmploye(e.id),
                reinitOuvert: _reinitId == e.id,
                nouveauMdp: _nouveauMdp,
                onNouveauMdp: (v) => setState(() => _nouveauMdp = v),
                surAttribuer: () {
                  if (_nouveauMdp.length < 6) return;
                  provider.reinitialiserMotDePasse(e.id, _nouveauMdp);
                  setState(() {
                    _nouveauMdp = '';
                    _reinitId = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CarteEmploye extends StatelessWidget {
  final Employe employe;
  final VoidCallback surEdition;
  final VoidCallback surReinit;
  final VoidCallback surStatut;
  final VoidCallback surSuppression;
  final bool reinitOuvert;
  final String nouveauMdp;
  final ValueChanged<String> onNouveauMdp;
  final VoidCallback surAttribuer;

  const _CarteEmploye({
    required this.employe,
    required this.surEdition,
    required this.surReinit,
    required this.surStatut,
    required this.surSuppression,
    required this.reinitOuvert,
    required this.nouveauMdp,
    required this.onNouveauMdp,
    required this.surAttribuer,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final e = employe;
    final defaut = permissionsParDefaut(e.role);
    final personnalise = e.permissions.length != defaut.length ||
        e.permissions.any((p) => !defaut.contains(p));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  String.fromCharCode(e.nom.runes.first).toUpperCase(),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: c.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                    ),
                    Text(
                      '${e.role.label} · ${e.permissions.length} droits'
                      '${personnalise ? ' (personnalisés)' : ''}',
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ),
              ),
              Badge(
                ton: e.statut == StatutEmploye.actif ? TonBadge.succes : TonBadge.danger,
                child: Text(e.statut == StatutEmploye.actif ? 'Actif' : 'Suspendu'),
              ),
            ],
          ),
          if (e.role != Role.patron) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Bouton(
                  taille: TailleBouton.sm,
                  onPressed: surEdition,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 14),
                      SizedBox(width: 6),
                      Text('Rôle & droits'),
                    ],
                  ),
                ),
                Bouton(
                  taille: TailleBouton.sm,
                  variante: VarianteBouton.secondaire,
                  onPressed: surReinit,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restart_alt_rounded, size: 14),
                      SizedBox(width: 6),
                      Text('Mot de passe'),
                    ],
                  ),
                ),
                Bouton(
                  taille: TailleBouton.sm,
                  variante: VarianteBouton.secondaire,
                  onPressed: surStatut,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        e.statut == StatutEmploye.actif
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(e.statut == StatutEmploye.actif ? 'Suspendre' : 'Réactiver'),
                    ],
                  ),
                ),
                Material(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: surSuppression,
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(Icons.delete_outline_rounded, size: 15, color: c.muted),
                    ),
                  ),
                ),
              ],
            ),
            if (reinitOuvert)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Saisie(
                      hint: 'Nouveau mot de passe (min. 6)',
                      masque: true,
                      onChanged: onNouveauMdp,
                    ),
                    const SizedBox(height: 8),
                    Bouton(
                      taille: TailleBouton.sm,
                      onPressed: surAttribuer,
                      child: const Text('Attribuer'),
                    ),
                  ],
                ),
              ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 13, color: c.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Accès complet',
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                  const Spacer(),
                  Bouton(
                    taille: TailleBouton.sm,
                    variante: VarianteBouton.secondaire,
                    onPressed: surReinit,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restart_alt_rounded, size: 14),
                        SizedBox(width: 6),
                        Text('Mot de passe'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (reinitOuvert)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Saisie(
                      hint: 'Nouveau mot de passe (min. 6)',
                      masque: true,
                      onChanged: onNouveauMdp,
                    ),
                    const SizedBox(height: 8),
                    Bouton(
                      taille: TailleBouton.sm,
                      onPressed: surAttribuer,
                      child: const Text('Attribuer'),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _LigneDroit extends StatelessWidget {
  final ItemPermission item;
  final bool actif;
  final bool avecBordure;
  final VoidCallback surTap;

  const _LigneDroit({
    required this.item,
    required this.actif,
    required this.avecBordure,
    required this.surTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: actif ? c.primarySoft : c.surface2,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        onTap: surTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: avecBordure ? Border(top: BorderSide(color: c.line)) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: actif ? c.primary : c.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: actif ? c.primary : c.line),
                ),
                child: actif ? Icon(Icons.check_rounded, size: 13, color: c.onPrimary) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: actif ? c.primary : c.ink,
                      ),
                    ),
                    Text(item.description, style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
