const abonnementModes = <(String, String)>[
  ('achat_direct', 'Achat direct (30 j)'),
  ('mensuel', 'Mensuel (30 j)'),
  ('trimestriel', 'Trimestriel (90 j)'),
];

const methodesPaiement = <String>[
  'Mobile Money',
  'Carte bancaire',
  'Espèces',
  'Virement',
];

const categoriesProduit = <(String, String)>[
  ('vetement', 'Vêtement'),
  ('chaussure', 'Chaussure'),
  ('accessoire', 'Accessoire'),
  ('beaute', 'Beauté'),
  ('maison', 'Maison'),
  ('autre', 'Autre'),
];

enum Role {
  patron,
  manager,
  caissiere,
}

extension RoleX on Role {
  String get name {
    switch (this) {
      case Role.patron:
        return 'patron';
      case Role.manager:
        return 'manager';
      case Role.caissiere:
        return 'caissiere';
    }
  }

  String get label {
    switch (this) {
      case Role.patron:
        return 'Patron';
      case Role.manager:
        return 'Manager';
      case Role.caissiere:
        return 'Caissière';
    }
  }

  static Role fromName(String value) {
    return Role.values.firstWhere(
      (r) => r.name == value,
      orElse: () => Role.patron,
    );
  }
}

enum Permission {
  vendre,
  defectueux,
  retour,
  depense,
  sortieCaisse,
  gererProduits,
  voirPrixAchat,
  voirBenefices,
  voirCourbeVentes,
  historiqueComplet,
  exporter,
  journal,
  pointages,
  gererComptes,
  appareils,
  pointer,
  traiterRetours,
}

extension PermissionX on Permission {
  String get name => toString().split('.').last;
  static Permission fromName(String value) {
    return Permission.values.firstWhere(
      (p) => p.name == value,
      orElse: () => Permission.vendre,
    );
  }
}

enum Monnaie {
  fcfa,
  eur,
  usd,
}

extension MonnaieX on Monnaie {
  String get code {
    switch (this) {
      case Monnaie.fcfa:
        return 'FCFA';
      case Monnaie.eur:
        return 'EUR';
      case Monnaie.usd:
        return 'USD';
    }
  }

  String get label {
    switch (this) {
      case Monnaie.fcfa:
        return 'Franc CFA';
      case Monnaie.eur:
        return 'Euro';
      case Monnaie.usd:
        return 'Dollar US';
    }
  }

  static Monnaie fromCode(String value) {
    return Monnaie.values.firstWhere(
      (m) => m.code == value,
      orElse: () => Monnaie.fcfa,
    );
  }
}

enum StatutEmploye {
  actif,
  suspendu,
}

extension StatutEmployeX on StatutEmploye {
  String get name => toString().split('.').last;
  static StatutEmploye fromName(String value) {
    return StatutEmploye.values.firstWhere(
      (s) => s.name == value,
      orElse: () => StatutEmploye.actif,
    );
  }
}

enum TypeDepense {
  depense,
  sortieJustifiee,
}

extension TypeDepenseX on TypeDepense {
  String get name => toString().split('.').last;
  static TypeDepense fromName(String value) {
    return value == 'sortie_justifiee' ? TypeDepense.sortieJustifiee : TypeDepense.depense;
  }
}

enum MotifRetour {
  remboursement,
  echange,
  defectueux,
}

extension MotifRetourX on MotifRetour {
  String get name => toString().split('.').last;
  String get label {
    switch (this) {
      case MotifRetour.remboursement:
        return 'Remboursement';
      case MotifRetour.echange:
        return 'Échange';
      case MotifRetour.defectueux:
        return 'Défectueux';
    }
  }

  static MotifRetour fromName(String value) {
    return MotifRetour.values.firstWhere(
      (m) => m.name == value,
      orElse: () => MotifRetour.remboursement,
    );
  }
}

enum StatutRetour {
  enAttente,
  traite,
  refuse,
}

extension StatutRetourX on StatutRetour {
  String get name => toString().split('.').last;
  String get label {
    switch (this) {
      case StatutRetour.enAttente:
        return 'En attente';
      case StatutRetour.traite:
        return 'Traité';
      case StatutRetour.refuse:
        return 'Refusé';
    }
  }

  static StatutRetour fromName(String value) {
    return StatutRetour.values.firstWhere(
      (s) => s.name == value,
      orElse: () => StatutRetour.enAttente,
    );
  }
}

enum NotifType {
  vente,
  depense,
  stock,
  produit,
  retour,
  compte,
  pointage,
  connexion,
}

extension NotifTypeX on NotifType {
  String get name => toString().split('.').last;
  static NotifType fromName(String value) {
    return NotifType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => NotifType.vente,
    );
  }
}

enum TonToast {
  succes,
  erreur,
  info,
}

extension TonToastX on TonToast {
  String get name => toString().split('.').last;
  static TonToast fromName(String value) {
    return TonToast.values.firstWhere(
      (t) => t.name == value,
      orElse: () => TonToast.succes,
    );
  }
}

class Boutique {
  final String id;
  final String nom;
  final String styleCommerce;
  final Monnaie monnaie;
  final String emailPatron;
  final String? logoUrl;
  double soldeCaisse;
  final String statut;
  final String abonnementMode;
  final DateTime? abonnementDebut;
  final DateTime? abonnementFin;
  final bool notificationAbonnement;
  final String methodePaiement;

  Boutique({
    required this.id,
    required this.nom,
    required this.styleCommerce,
    required this.monnaie,
    required this.emailPatron,
    this.logoUrl,
    required this.soldeCaisse,
    this.statut = 'active',
    this.abonnementMode = 'achat_direct',
    this.abonnementDebut,
    this.abonnementFin,
    this.notificationAbonnement = false,
    this.methodePaiement = '',
  });

  bool get estDesactivee => statut == 'desactivee';

  bool get abonnementExpire =>
      abonnementFin != null && abonnementFin!.isBefore(DateTime.now());

  bool get abonnementProche =>
      abonnementFin != null &&
      !abonnementExpire &&
      abonnementFin!.difference(DateTime.now()).inDays <= 7;

  String get abonnementLabel =>
      abonnementModes.firstWhere(
        (m) => m.$1 == abonnementMode,
        orElse: () => const ('achat_direct', 'Achat direct (30 j)'),
      ).$2;

  Boutique copyWith({
    String? logoUrl,
    double? soldeCaisse,
    String? statut,
    String? abonnementMode,
    DateTime? abonnementDebut,
    DateTime? abonnementFin,
    bool? notificationAbonnement,
    String? methodePaiement,
  }) {
    return Boutique(
      id: id,
      nom: nom,
      styleCommerce: styleCommerce,
      monnaie: monnaie,
      emailPatron: emailPatron,
      logoUrl: logoUrl ?? this.logoUrl,
      soldeCaisse: soldeCaisse ?? this.soldeCaisse,
      statut: statut ?? this.statut,
      abonnementMode: abonnementMode ?? this.abonnementMode,
      abonnementDebut: abonnementDebut ?? this.abonnementDebut,
      abonnementFin: abonnementFin ?? this.abonnementFin,
      notificationAbonnement:
          notificationAbonnement ?? this.notificationAbonnement,
      methodePaiement: methodePaiement ?? this.methodePaiement,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'nom': nom,
        'styleCommerce': styleCommerce,
        'monnaie': monnaie.code,
        'emailPatron': emailPatron,
        'logoUrl': logoUrl,
        'soldeCaisse': soldeCaisse,
        'statut': statut,
        'abonnementMode': abonnementMode,
        'abonnementDebut': abonnementDebut?.toUtc().toIso8601String(),
        'abonnementFin': abonnementFin?.toUtc().toIso8601String(),
        'notificationAbonnement': notificationAbonnement ? 1 : 0,
        'methodePaiement': methodePaiement,
      };

  factory Boutique.fromMap(Map<String, Object?> map) => Boutique(
        id: map['id'] as String? ?? 'b1',
        nom: map['nom'] as String,
        styleCommerce: map['styleCommerce'] as String? ?? '',
        monnaie: MonnaieX.fromCode(map['monnaie'] as String? ?? 'FCFA'),
        emailPatron: map['emailPatron'] as String? ?? '',
        logoUrl: map['logoUrl'] as String?,
        soldeCaisse: (map['soldeCaisse'] as num? ?? 0).toDouble(),
        statut: map['statut'] as String? ?? 'active',
        abonnementMode: map['abonnementMode'] as String? ?? 'achat_direct',
        abonnementDebut:
            _parseIso(map['abonnementDebut'] as String?),
        abonnementFin: _parseIso(map['abonnementFin'] as String?),
        notificationAbonnement: (map['notificationAbonnement'] as num? ?? 0) == 1,
        methodePaiement: map['methodePaiement'] as String? ?? '',
      );
}

DateTime? _parseIso(String? s) {
  if (s == null || s.isEmpty) return null;
  return DateTime.tryParse(s)?.toLocal();
}

class Employe {
  final String id;
  final String nom;
  final Role role;
  List<Permission> permissions;
  String motDePasse;
  StatutEmploye statut;
  bool pinActif;
  String pin;
  bool biometrie;
  final String dateCreation;

  Employe({
    required this.id,
    required this.nom,
    required this.role,
    required this.permissions,
    required this.motDePasse,
    required this.statut,
    required this.pinActif,
    required this.pin,
    required this.biometrie,
    required this.dateCreation,
  });

  Employe copyWith({
    String? nom,
    Role? role,
    List<Permission>? permissions,
    String? motDePasse,
    StatutEmploye? statut,
    bool? pinActif,
    String? pin,
    bool? biometrie,
  }) {
    return Employe(
      id: id,
      nom: nom ?? this.nom,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      motDePasse: motDePasse ?? this.motDePasse,
      statut: statut ?? this.statut,
      pinActif: pinActif ?? this.pinActif,
      pin: pin ?? this.pin,
      biometrie: biometrie ?? this.biometrie,
      dateCreation: dateCreation,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'nom': nom,
        'role': role.name,
        'permissions': permissions.map((p) => p.name).join(','),
        'motDePasse': motDePasse,
        'statut': statut.name,
        'pinActif': pinActif ? 1 : 0,
        'pin': pin,
        'biometrie': biometrie ? 1 : 0,
        'dateCreation': dateCreation,
      };

  factory Employe.fromMap(Map<String, Object?> map) => Employe(
        id: map['id'] as String,
        nom: map['nom'] as String,
        role: RoleX.fromName(map['role'] as String? ?? 'caissiere'),
        permissions: (map['permissions'] as String? ?? '')
            .split(',')
            .where((p) => p.isNotEmpty)
            .map(PermissionX.fromName)
            .toList(),
        motDePasse: map['motDePasse'] as String? ?? '',
        statut: StatutEmployeX.fromName(map['statut'] as String? ?? 'actif'),
        pinActif: (map['pinActif'] as num? ?? 0) == 1,
        pin: map['pin'] as String? ?? '',
        biometrie: (map['biometrie'] as num? ?? 0) == 1,
        dateCreation: map['dateCreation'] as String? ?? '',
      );
}

class Produit {
  final String id;
  final String nom;
  final double prixAchat;
  final double prixVente;
  double quantite;
  bool actif;
  final List<String> images;
  final String categorie;
  final DateTime? dateAjout;
  final String? qrCodeData;

  Produit({
    required this.id,
    required this.nom,
    required this.prixAchat,
    required this.prixVente,
    required this.quantite,
    this.actif = true,
    this.images = const [],
    this.categorie = 'autre',
    this.dateAjout,
    this.qrCodeData,
  });

  bool get estNouveau =>
      dateAjout != null &&
      DateTime.now().difference(dateAjout!).inDays <= 7;

  String get categorieLabel =>
      categoriesProduit
          .firstWhere((c) => c.$1 == categorie,
              orElse: () => const ('autre', 'Autre'))
          .$2;

  Produit copyWith({
    String? nom,
    double? prixAchat,
    double? prixVente,
    double? quantite,
    bool? actif,
    List<String>? images,
    String? categorie,
    DateTime? dateAjout,
    String? qrCodeData,
  }) {
    return Produit(
      id: id,
      nom: nom ?? this.nom,
      prixAchat: prixAchat ?? this.prixAchat,
      prixVente: prixVente ?? this.prixVente,
      quantite: quantite ?? this.quantite,
      actif: actif ?? this.actif,
      images: images ?? this.images,
      categorie: categorie ?? this.categorie,
      dateAjout: dateAjout ?? this.dateAjout,
      qrCodeData: qrCodeData ?? this.qrCodeData,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'nom': nom,
        'prixAchat': prixAchat,
        'prixVente': prixVente,
        'quantite': quantite,
        'actif': actif ? 1 : 0,
        'images': images.join(','),
        'categorie': categorie,
        'dateAjout': dateAjout?.toUtc().toIso8601String(),
        'qrCodeData': qrCodeData,
      };

  factory Produit.fromMap(Map<String, Object?> map) => Produit(
        id: map['id'] as String,
        nom: map['nom'] as String,
        prixAchat: (map['prixAchat'] as num? ?? 0).toDouble(),
        prixVente: (map['prixVente'] as num? ?? 0).toDouble(),
        quantite: (map['quantite'] as num? ?? 0).toDouble(),
        actif: (map['actif'] as num? ?? 1) == 1,
        images: (map['images'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
        categorie: map['categorie'] as String? ?? 'autre',
        dateAjout: _parseIso(map['dateAjout'] as String?),
        qrCodeData: map['qrCodeData'] as String?,
      );
}

class Vente {
  final String id;
  final String produitId;
  final String produitNom;
  final double quantite;
  final double prixUnitaireReel;
  final double prixAchatUnitaire;
  final double total;
  final String vendeurId;
  final String vendeurNom;
  final Role vendeurRole;
  final String date;

  Vente({
    required this.id,
    required this.produitId,
    required this.produitNom,
    required this.quantite,
    required this.prixUnitaireReel,
    required this.prixAchatUnitaire,
    required this.total,
    required this.vendeurId,
    required this.vendeurNom,
    required this.vendeurRole,
    required this.date,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'produitId': produitId,
        'produitNom': produitNom,
        'quantite': quantite,
        'prixUnitaireReel': prixUnitaireReel,
        'prixAchatUnitaire': prixAchatUnitaire,
        'total': total,
        'vendeurId': vendeurId,
        'vendeurNom': vendeurNom,
        'vendeurRole': vendeurRole.name,
        'date': date,
      };

  factory Vente.fromMap(Map<String, Object?> map) => Vente(
        id: map['id'] as String,
        produitId: map['produitId'] as String? ?? '',
        produitNom: map['produitNom'] as String? ?? '',
        quantite: (map['quantite'] as num? ?? 0).toDouble(),
        prixUnitaireReel: (map['prixUnitaireReel'] as num? ?? 0).toDouble(),
        prixAchatUnitaire: (map['prixAchatUnitaire'] as num? ?? 0).toDouble(),
        total: (map['total'] as num? ?? 0).toDouble(),
        vendeurId: map['vendeurId'] as String? ?? '',
        vendeurNom: map['vendeurNom'] as String? ?? '',
        vendeurRole: RoleX.fromName(map['vendeurRole'] as String? ?? 'caissiere'),
        date: map['date'] as String? ?? '',
      );
}

class Depense {
  final String id;
  final String description;
  final double montant;
  final String auteurNom;
  final Role auteurRole;
  final TypeDepense type;
  final String date;

  Depense({
    required this.id,
    required this.description,
    required this.montant,
    required this.auteurNom,
    required this.auteurRole,
    required this.type,
    required this.date,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'description': description,
        'montant': montant,
        'auteurNom': auteurNom,
        'auteurRole': auteurRole.name,
        'type': type.name,
        'date': date,
      };

  factory Depense.fromMap(Map<String, Object?> map) => Depense(
        id: map['id'] as String,
        description: map['description'] as String? ?? '',
        montant: (map['montant'] as num? ?? 0).toDouble(),
        auteurNom: map['auteurNom'] as String? ?? '',
        auteurRole: RoleX.fromName(map['auteurRole'] as String? ?? 'caissiere'),
        type: TypeDepenseX.fromName(map['type'] as String? ?? 'depense'),
        date: map['date'] as String? ?? '',
      );
}

class Retour {
  final String id;
  final String produitId;
  final String produitNom;
  final MotifRetour motif;
  final String description;
  final double montant;
  final String auteurNom;
  StatutRetour statut;
  final String date;

  Retour({
    required this.id,
    required this.produitId,
    required this.produitNom,
    required this.motif,
    required this.description,
    required this.montant,
    required this.auteurNom,
    required this.statut,
    required this.date,
  });

  Retour copyWith({StatutRetour? statut}) {
    return Retour(
      id: id,
      produitId: produitId,
      produitNom: produitNom,
      motif: motif,
      description: description,
      montant: montant,
      auteurNom: auteurNom,
      statut: statut ?? this.statut,
      date: date,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'produitId': produitId,
        'produitNom': produitNom,
        'motif': motif.name,
        'description': description,
        'montant': montant,
        'auteurNom': auteurNom,
        'statut': statut.name,
        'date': date,
      };

  factory Retour.fromMap(Map<String, Object?> map) => Retour(
        id: map['id'] as String,
        produitId: map['produitId'] as String? ?? '',
        produitNom: map['produitNom'] as String? ?? '',
        motif: MotifRetourX.fromName(map['motif'] as String? ?? 'remboursement'),
        description: map['description'] as String? ?? '',
        montant: (map['montant'] as num? ?? 0).toDouble(),
        auteurNom: map['auteurNom'] as String? ?? '',
        statut: StatutRetourX.fromName(map['statut'] as String? ?? 'en_attente'),
        date: map['date'] as String? ?? '',
      );
}

class NotificationItem {
  final String id;
  final List<Role> destinataires;
  final String titre;
  final String message;
  final NotifType type;
  bool estLu;
  final String date;

  NotificationItem({
    required this.id,
    required this.destinataires,
    required this.titre,
    required this.message,
    required this.type,
    required this.estLu,
    required this.date,
  });

  NotificationItem copyWith({bool? estLu}) {
    return NotificationItem(
      id: id,
      destinataires: destinataires,
      titre: titre,
      message: message,
      type: type,
      estLu: estLu ?? this.estLu,
      date: date,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'destinataires': destinataires.map((r) => r.name).join(','),
        'titre': titre,
        'message': message,
        'type': type.name,
        'estLu': estLu ? 1 : 0,
        'date': date,
      };

  factory NotificationItem.fromMap(Map<String, Object?> map) => NotificationItem(
        id: map['id'] as String,
        destinataires: (map['destinataires'] as String? ?? '')
            .split(',')
            .where((r) => r.isNotEmpty)
            .map(RoleX.fromName)
            .toList(),
        titre: map['titre'] as String? ?? '',
        message: map['message'] as String? ?? '',
        type: NotifTypeX.fromName(map['type'] as String? ?? 'vente'),
        estLu: (map['estLu'] as num? ?? 0) == 1,
        date: map['date'] as String? ?? '',
      );
}

class Pointage {
  final String id;
  final String employeId;
  final String employeNom;
  final Role role;
  final String date;
  final String heureArrivee;
  String? heureDepart;

  Pointage({
    required this.id,
    required this.employeId,
    required this.employeNom,
    required this.role,
    required this.date,
    required this.heureArrivee,
    this.heureDepart,
  });

  Pointage copyWith({String? heureDepart}) {
    return Pointage(
      id: id,
      employeId: employeId,
      employeNom: employeNom,
      role: role,
      date: date,
      heureArrivee: heureArrivee,
      heureDepart: heureDepart ?? this.heureDepart,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'employeId': employeId,
        'employeNom': employeNom,
        'role': role.name,
        'date': date,
        'heureArrivee': heureArrivee,
        'heureDepart': heureDepart,
      };

  factory Pointage.fromMap(Map<String, Object?> map) => Pointage(
        id: map['id'] as String,
        employeId: map['employeId'] as String? ?? '',
        employeNom: map['employeNom'] as String? ?? '',
        role: RoleX.fromName(map['role'] as String? ?? 'caissiere'),
        date: map['date'] as String? ?? '',
        heureArrivee: map['heureArrivee'] as String? ?? '',
        heureDepart: map['heureDepart'] as String?,
      );
}

class Activite {
  final String id;
  final String employeNom;
  final Role employeRole;
  final NotifType type;
  final String description;
  final String date;

  Activite({
    required this.id,
    required this.employeNom,
    required this.employeRole,
    required this.type,
    required this.description,
    required this.date,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'employeNom': employeNom,
        'employeRole': employeRole.name,
        'type': type.name,
        'description': description,
        'date': date,
      };

  factory Activite.fromMap(Map<String, Object?> map) => Activite(
        id: map['id'] as String,
        employeNom: map['employeNom'] as String? ?? '',
        employeRole: RoleX.fromName(map['employeRole'] as String? ?? 'caissiere'),
        type: NotifTypeX.fromName(map['type'] as String? ?? 'vente'),
        description: map['description'] as String? ?? '',
        date: map['date'] as String? ?? '',
      );
}

class Appareil {
  final String id;
  final String employeNom;
  final Role role;
  final String nomAppareil;
  final String derniereConnexion;
  bool actif;

  Appareil({
    required this.id,
    required this.employeNom,
    required this.role,
    required this.nomAppareil,
    required this.derniereConnexion,
    required this.actif,
  });

  Appareil copyWith({bool? actif}) {
    return Appareil(
      id: id,
      employeNom: employeNom,
      role: role,
      nomAppareil: nomAppareil,
      derniereConnexion: derniereConnexion,
      actif: actif ?? this.actif,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'employeNom': employeNom,
        'role': role.name,
        'nomAppareil': nomAppareil,
        'derniereConnexion': derniereConnexion,
        'actif': actif ? 1 : 0,
      };

  factory Appareil.fromMap(Map<String, Object?> map) => Appareil(
        id: map['id'] as String,
        employeNom: map['employeNom'] as String? ?? '',
        role: RoleX.fromName(map['role'] as String? ?? 'caissiere'),
        nomAppareil: map['nomAppareil'] as String? ?? '',
        derniereConnexion: map['derniereConnexion'] as String? ?? '',
        actif: (map['actif'] as num? ?? 1) == 1,
      );
}

class ToastMessage {
  final String id;
  final String message;
  final TonToast ton;

  ToastMessage({required this.id, required this.message, required this.ton});
}