import '../models/models.dart';

const Map<Role, List<Permission>> _parDefaut = {
  Role.patron: [
    Permission.vendre,
    Permission.defectueux,
    Permission.retour,
    Permission.depense,
    Permission.sortieCaisse,
    Permission.gererProduits,
    Permission.voirPrixAchat,
    Permission.voirBenefices,
    Permission.voirCourbeVentes,
    Permission.historiqueComplet,
    Permission.exporter,
    Permission.journal,
    Permission.pointages,
    Permission.gererComptes,
    Permission.appareils,
    Permission.traiterRetours,
  ],
  Role.manager: [
    Permission.vendre,
    Permission.defectueux,
    Permission.retour,
    Permission.depense,
    Permission.sortieCaisse,
    Permission.voirCourbeVentes,
    Permission.historiqueComplet,
    Permission.exporter,
    Permission.pointer,
  ],
  Role.caissiere: [
    Permission.vendre,
    Permission.defectueux,
    Permission.retour,
    Permission.sortieCaisse,
    Permission.pointer,
  ],
};

List<Permission> permissionsParDefaut(Role role) => [..._parDefaut[role]!];

bool peut(Employe? sujet, Permission permission) {
  if (sujet == null) return false;
  final liste = sujet.permissions.isNotEmpty ? sujet.permissions : _parDefaut[sujet.role]!;
  return liste.contains(permission);
}

/// Droits réservés au patron : non attribuables à un employé.
const permissionsReservees = [
  Permission.gererComptes,
  Permission.appareils,
  Permission.traiterRetours,
];

class ItemPermission {
  final Permission cle;
  final String label;
  final String description;

  const ItemPermission({
    required this.cle,
    required this.label,
    required this.description,
  });
}

class GroupePermissions {
  final String titre;
  final List<ItemPermission> items;

  const GroupePermissions({required this.titre, required this.items});
}

/// Droits que le patron peut cocher / décocher pour un employé.
const groupesPermissions = [
  GroupePermissions(
    titre: 'Opérations de caisse',
    items: [
      ItemPermission(cle: Permission.vendre, label: 'Enregistrer une vente', description: 'Stock et caisse mis à jour'),
      ItemPermission(cle: Permission.defectueux, label: 'Signaler un défectueux', description: 'Retire une pièce du stock'),
      ItemPermission(cle: Permission.retour, label: 'Signaler un retour', description: 'Remboursement ou échange'),
      ItemPermission(cle: Permission.depense, label: 'Signaler une dépense', description: 'Loyer, factures…'),
      ItemPermission(cle: Permission.sortieCaisse, label: 'Justifier une sortie de caisse', description: 'Motif obligatoire'),
    ],
  ),
  GroupePermissions(
    titre: 'Stock',
    items: [
      ItemPermission(cle: Permission.gererProduits, label: 'Gérer les produits', description: 'Ajouter, modifier, supprimer'),
      ItemPermission(cle: Permission.voirPrixAchat, label: "Voir les prix d'achat", description: 'Donnée sensible — patron par défaut'),
    ],
  ),
  GroupePermissions(
    titre: 'Chiffres & rapports',
    items: [
      ItemPermission(cle: Permission.voirCourbeVentes, label: 'Voir les courbes de ventes', description: '7 et 30 jours'),
      ItemPermission(cle: Permission.historiqueComplet, label: "Voir l'historique de toute l'équipe", description: 'Sinon, ses ventes uniquement'),
      ItemPermission(cle: Permission.voirBenefices, label: 'Voir les bénéfices et marges', description: 'Donnée sensible — patron par défaut'),
      ItemPermission(cle: Permission.exporter, label: 'Exporter des rapports', description: 'Fichier CSV partageable'),
      ItemPermission(cle: Permission.journal, label: "Consulter le journal d'activité", description: 'Toutes les actions'),
      ItemPermission(cle: Permission.pointages, label: 'Consulter les pointages', description: "Arrivées et départs de l'équipe"),
    ],
  ),
  GroupePermissions(
    titre: 'Présence',
    items: [
      ItemPermission(cle: Permission.pointer, label: 'Pointer arrivée / départ', description: 'Un pointage par jour'),
    ],
  ),
];