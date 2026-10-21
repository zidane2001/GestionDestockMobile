import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../data/database.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import 'image_service.dart';

/// Tables synchronisées entre les appareils d'une même boutique.
const List<String> tablesSynchronisees = [
  'boutiques',
  'employes',
  'produits',
  'ventes',
  'depenses',
  'retours',
  'pointages',
  'activites',
  'appareils',
  'notifications',
];

/// Correspondance colonnes locales (SQLite, camelCase) -> Supabase (snake_case).
const Map<String, Map<String, String>> _colonnes = {
  'boutiques': {
    'id': 'id',
    'nom': 'nom',
    'styleCommerce': 'style_commerce',
    'monnaie': 'monnaie',
    'emailPatron': 'email_patron',
    'logoUrl': 'logo_url',
    'soldeCaisse': 'solde_caisse',
    'statut': 'statut',
    'abonnementMode': 'abonnement_mode',
    'abonnementDebut': 'abonnement_debut',
    'abonnementFin': 'abonnement_fin',
    'notificationAbonnement': 'notification_abonnement',
    'methodePaiement': 'methode_paiement',
  },
  'employes': {
    'id': 'id',
    'nom': 'nom',
    'role': 'role',
    'permissions': 'permissions',
    'motDePasse': 'mot_de_passe',
    'statut': 'statut',
    'pinActif': 'pin_actif',
    'pin': 'pin',
    'biometrie': 'biometrie',
    'dateCreation': 'date_creation',
  },
  'produits': {
    'id': 'id',
    'nom': 'nom',
    'prixAchat': 'prix_achat',
    'prixVente': 'prix_vente',
    'quantite': 'quantite',
    'actif': 'actif',
    'images': 'images',
    'categorie': 'categorie',
    'dateAjout': 'date_ajout',
    'qrCodeData': 'qr_code_data',
  },
  'ventes': {
    'id': 'id',
    'produitId': 'produit_id',
    'produitNom': 'produit_nom',
    'quantite': 'quantite',
    'prixUnitaireReel': 'prix_unitaire_reel',
    'prixAchatUnitaire': 'prix_achat_unitaire',
    'total': 'total',
    'vendeurId': 'vendeur_id',
    'vendeurNom': 'vendeur_nom',
    'vendeurRole': 'vendeur_role',
    'date': 'date',
  },
  'depenses': {
    'id': 'id',
    'description': 'description',
    'montant': 'montant',
    'auteurNom': 'auteur_nom',
    'auteurRole': 'auteur_role',
    'type': 'type',
    'date': 'date',
  },
  'retours': {
    'id': 'id',
    'produitId': 'produit_id',
    'produitNom': 'produit_nom',
    'motif': 'motif',
    'description': 'description',
    'montant': 'montant',
    'auteurNom': 'auteur_nom',
    'statut': 'statut',
    'date': 'date',
  },
  'pointages': {
    'id': 'id',
    'employeId': 'employe_id',
    'employeNom': 'employe_nom',
    'role': 'role',
    'date': 'date',
    'heureArrivee': 'heure_arrivee',
    'heureDepart': 'heure_depart',
  },
  'activites': {
    'id': 'id',
    'employeNom': 'employe_nom',
    'employeRole': 'employe_role',
    'type': 'type',
    'description': 'description',
    'date': 'date',
  },
  'appareils': {
    'id': 'id',
    'employeNom': 'employe_nom',
    'role': 'role',
    'nomAppareil': 'nom_appareil',
    'derniereConnexion': 'derniere_connexion',
    'actif': 'actif',
  },
  'notifications': {
    'id': 'id',
    'destinataires': 'destinataires',
    'titre': 'titre',
    'message': 'message',
    'type': 'type',
    'estLu': 'est_lu',
    'date': 'date',
  },
};

/// Colonnes booléennes locales (SQLite : 0/1, Supabase : true/false).
const Map<String, List<String>> _booleens = {
  'boutiques': ['notificationAbonnement'],
  'employes': ['pinActif', 'biometrie'],
  'produits': ['actif'],
  'appareils': ['actif'],
  'notifications': ['estLu'],
};

/// Message lisible annonçant une modification reçue d'un autre appareil.
String libelleMajDistante(String table) {
  switch (table) {
    case 'produits':
      return 'Stock mis à jour par un autre appareil.';
    case 'ventes':
      return 'Nouvelle vente enregistrée sur un autre appareil.';
    case 'depenses':
      return 'Nouvelle dépense enregistrée sur un autre appareil.';
    case 'retours':
      return 'Retour produit mis à jour sur un autre appareil.';
    case 'employes':
      return 'Équipe mise à jour par un autre appareil.';
    case 'pointages':
      return 'Pointage mis à jour sur un autre appareil.';
    case 'notifications':
      return 'Nouvelle notification reçue.';
    case 'boutiques':
      return 'Informations de la boutique mises à jour.';
    default:
      return 'Mise à jour reçue d\'un autre appareil.';
  }
}

/// Journal des écritures locales : évite de réappliquer l'écho des
/// modifications que cet appareil vient lui-même d'envoyer.
class JournalEcritures {
  final Map<String, DateTime> _maj = {};
  final Duration validite;

  JournalEcritures({this.validite = const Duration(seconds: 45)});

  static String cle(String table, String id) => '$table/$id';

  void noter(String table, String id, String? majIso) {
    final date = _date(majIso) ?? DateTime.now().toUtc();
    _maj[cle(table, id)] = date;
  }

  /// Vrai si la modification distante est plus récente que notre écriture.
  bool distantPlusRecent(String table, String id, String? majIso) {
    final locale = _maj[cle(table, id)];
    if (locale == null) return true;
    final distante = _date(majIso);
    if (distante == null) return false;
    return distante.isAfter(locale);
  }

  void oublier(String table, String id) => _maj.remove(cle(table, id));

  /// Purge les entrées anciennes : au-delà de [validite] la réconciliation
  /// périodique doit pouvoir réappliquer l'état du serveur.
  void purger() {
    final limite = DateTime.now().toUtc().subtract(validite);
    _maj.removeWhere((_, date) => date.isBefore(limite));
  }

  void vider() => _maj.clear();

  static DateTime? _date(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso)?.toUtc();
  }
}

/// Résultat d'un cycle de synchronisation.
class SyncResultat {
  /// Opérations locales envoyées au serveur.
  final int envoyees;

  /// Lignes distantes appliquées localement.
  final int recues;

  /// Opérations encore en file d'attente après le cycle.
  final int enAttente;

  /// Vrai si le cycle a pu se dérouler (configuration + réseau + auth).
  final bool ok;

  const SyncResultat({
    this.envoyees = 0,
    this.recues = 0,
    this.enAttente = 0,
    this.ok = false,
  });
}

/// Décision à prendre face à un événement temps réel.
typedef DecisionChangement = ({
  String type,
  String id,
  Map<String, Object?>? ligne,
});

const String decisionIgnorer = 'ignorer';
const String decisionEcrire = 'ecrire';
const String decisionSupprimer = 'supprimer';

/// Interprète un événement `postgres_changes` : isole le locataire, ignore les
/// lignes étrangères et convertit la ligne distante au format local.
@visibleForTesting
DecisionChangement interpreterChangement({
  required String table,
  required String boutiqueId,
  required String evenement,
  required Map<String, Object?> nouveau,
  required Map<String, Object?> ancien,
}) {
  final id = (nouveau['id'] ?? ancien['id'])?.toString();
  if (id == null || id.isEmpty) {
    return (type: decisionIgnorer, id: '', ligne: null);
  }
  if (evenement == 'DELETE') {
    final portee = table == 'boutiques'
        ? ancien['id']?.toString()
        : ancien['boutique_id']?.toString();
    if (portee != boutiqueId) {
      return (type: decisionIgnorer, id: id, ligne: null);
    }
    return (type: decisionSupprimer, id: id, ligne: null);
  }
  final portee = table == 'boutiques'
      ? nouveau['id']?.toString()
      : nouveau['boutique_id']?.toString();
  if (portee != null && portee != boutiqueId) {
    return (type: decisionIgnorer, id: id, ligne: null);
  }
  final ligne = versLocal(table, nouveau);
  if (ligne.isEmpty) {
    return (type: decisionIgnorer, id: id, ligne: null);
  }
  return (type: decisionEcrire, id: id, ligne: ligne);
}

/// Vrai si le serveur ne contient encore aucune donnée métier pour la
/// boutique : il faut alors y envoyer le catalogue local (amorçage).
@visibleForTesting
bool serveurSansDonneesMetier(int lignesDistantesMetier) =>
    lignesDistantesMetier == 0;

/// Lignes locales à envoyer pour amorcer le serveur.
@visibleForTesting
List<Map<String, Object?>> lignesAAmorcer(
  String table,
  String boutiqueId,
  List<Map<String, Object?>> localesBoutiques,
  List<Map<String, Object?>> localesTable,
) {
  if (table == 'boutiques') {
    return localesBoutiques.where((l) => l['id'] == boutiqueId).toList();
  }
  return localesTable;
}

String _nomEvenement(PostgresChangeEvent evenement) {
  switch (evenement) {
    case PostgresChangeEvent.insert:
      return 'INSERT';
    case PostgresChangeEvent.update:
      return 'UPDATE';
    case PostgresChangeEvent.delete:
      return 'DELETE';
    default:
      return 'ALL';
  }
}

/// Évite d'appliquer une ligne distante lorsqu'une écriture locale est en file.
/// La lecture de la file et l'écriture ne sont pas atomiques.
@visibleForTesting
Future<bool> appliquerSiAucuneOperationEnAttente({
  required Future<List<Map<String, Object?>>> Function() lireFile,
  required String table,
  required String id,
  required Future<void> Function() appliquer,
}) async {
  final file = await lireFile();
  if (file.any((op) => op['tableName'] == table && op['rowId'] == id)) {
    return false;
  }
  await appliquer();
  return true;
}

class SyncService {
  final DatabaseHelper _db;
  bool _enCours = false;

  RealtimeChannel? _canal;
  String? _canalBoutiqueId;
  bool _tempsReelConnecte = false;
  Timer? _minuteurReconcile;
  Timer? _minuteurCompte;
  bool _compteEnCours = false;
  Timer? _rafraichissement;

  final JournalEcritures journal = JournalEcritures();

  SyncService(this._db);

  bool get enCours => _enCours;

  /// Vrai si une URL et une clé Supabase ont été renseignées.
  bool get configure => supabaseConfigure;

  /// Vrai quand l'écoute temps réel est établie.
  bool get tempsReelActif => _canal != null && _tempsReelConnecte;

  /// Vrai quand la réconciliation périodique est programmée.
  bool get surveillanceActive => _minuteurReconcile != null;

  String? _employeLie;
  String? _boutiqueLie;

  /// Chaque appareil possède son propre compte Supabase, créé une fois et
  /// conservé dans les réglages locaux. Ce compte ne voit rien tant que la
  /// RPC `rattacher_employe` ne l'a pas relié à une fiche employé.
  Future<SupabaseClient?> _compteAppareil() async {
    if (!configure) return null;
    final client = Supabase.instance.client;
    if (client.auth.currentSession != null) return client;
    var email = await _db.getSetting('appareil_email');
    var mdp = await _db.getSetting('appareil_mdp');
    if (email == null || email.isEmpty || mdp == null || mdp.isEmpty) {
      final rnd = Random.secure();
      String hex(int n) =>
          List.generate(n, (_) => rnd.nextInt(16).toRadixString(16)).join();
      email = 'appareil-${hex(24)}@ma-boutique.app';
      mdp = hex(48);
      await _db.setSetting('appareil_email', email);
      await _db.setSetting('appareil_mdp', mdp);
    }
    try {
      await client.auth.signInWithPassword(email: email, password: mdp);
      return client;
    } on AuthException {
      try {
        final res = await client.auth.signUp(email: email, password: mdp);
        return res.session == null ? null : client;
      } on AuthException {
        return null;
      }
    }
  }

  Future<bool> _lierEmploye(
    SupabaseClient client,
    String boutiqueId,
    String role,
    String motDePasse,
  ) async {
    try {
      final rows = await client.rpc(
        'rattacher_employe',
        params: {
          'p_boutique': boutiqueId,
          'p_role': role,
          'p_mot_de_passe': motDePasse,
        },
      );
      if (rows is List && rows.isNotEmpty) {
        final row = rows.first as Map;
        _employeLie = row['employe_id']?.toString();
        _boutiqueLie = boutiqueId;
        return true;
      }
    } catch (_) {
      // Mot de passe refusé ou serveur injoignable.
    }
    return false;
  }

  /// Ouvre (ou rouvre) la session de l'employé courant sur cet appareil.
  Future<SupabaseClient?> _client(AppProvider provider) async {
    final s = provider.session;
    final b = provider.boutique;
    if (s == null || b == null) return null;
    final client = await _compteAppareil();
    if (client == null) return null;
    if (_employeLie == s.id && _boutiqueLie == b.id) return client;
    final lie = await _lierEmploye(client, b.id, s.role.name, s.motDePasse);
    return lie ? client : null;
  }

  /// Vérifie les identifiants d'un employé côté serveur et renvoie
  /// l'identifiant de sa boutique. La RPC `rejoindre_boutique` est ouverte
  /// aux clients anonymes : elle ne divulgue rien tant que le mot de passe
  /// est faux, ce qui rend inutile toute clé privilégiée dans l'application.
  Future<String?> identifierBoutique({
    required String nom,
    required String role,
    required String motDePasse,
  }) async {
    if (!configure) return null;
    final rows = await Supabase.instance.client.rpc(
      'rejoindre_boutique',
      params: {
        'p_nom': nom,
        'p_role': role,
        'p_mot_de_passe': motDePasse,
      },
    );
    if (rows is List && rows.isNotEmpty) {
      return (rows.first as Map)['boutique_id'] as String?;
    }
    return null;
  }

  /// Relie l'appareil à l'employé (le serveur revérifie le mot de passe),
  /// puis renvoie la boutique et la fiche employé à importer localement.
  Future<({Map<String, dynamic>? boutique, Map<String, dynamic>? employe})?>
      rejoindreBoutique(
    String boutiqueId,
    String nom,
    String role,
    String motDePasse,
  ) async {
    if (!configure) return null;
    final client = await _compteAppareil();
    if (client == null) return null;
    if (!await _lierEmploye(client, boutiqueId, role, motDePasse)) return null;
    final employeId = _employeLie;
    if (employeId == null) return null;
    final boutique =
        await client.from('boutiques').select().eq('id', boutiqueId).maybeSingle();
    final employe = await client
        .from('employes')
        .select()
        .eq('id', employeId)
        .maybeSingle();
    return (boutique: boutique, employe: employe);
  }

  /// Première synchronisation d'une boutique créée localement : crée la
  /// fiche patron côté serveur et lie l'appareil à elle.
  Future<void> demarrerBoutique(AppProvider provider) async {
    final s = provider.session;
    final b = provider.boutique;
    if (s == null || b == null) return;
    final client = await _compteAppareil();
    if (client == null) return;
    try {
      await client.rpc('demarrer_boutique', params: {
        'p_boutique': b.id,
        'p_nom': b.nom,
        'p_employe': s.id,
        'p_nom_employe': s.nom,
        'p_mot_de_passe': s.motDePasse,
      });
      _employeLie = s.id;
      _boutiqueLie = b.id;
    } catch (_) {
      // Boutique déjà initialisée : on retombe sur le rattachement normal.
      await _lierEmploye(client, b.id, s.role.name, s.motDePasse);
    }
  }

  // ---------- Temps réel ----------

  /// Écoute les modifications de la boutique : chaque changement fait sur un
  /// autre appareil est écrit localement dès réception.
  Future<bool> demarrerTempsReel(
    AppProvider provider,
    String boutiqueId,
  ) async {
    if (!configure || !provider.enLigne) return false;
    if (_canal != null) {
      if (_canalBoutiqueId == boutiqueId && _tempsReelConnecte) return true;
      await arreterTempsReel();
    }
    try {
      final client = await _client(provider);
      if (client == null) return false;
      final canal = client.channel('boutique:$boutiqueId');
      // Les charges utiles temps réel contiennent toutes les colonnes : un
      // rôle sans droit sur les prix d'achat reste en réconciliation
      // périodique, qui passe par les vues masquées.
      final tables = tablesSynchronisees.where(
        (t) => provider.session?.role == Role.patron ||
            (t != 'produits' && t != 'ventes'),
      );
      for (final table in tables) {
        canal.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: table == 'boutiques' ? 'id' : 'boutique_id',
            value: boutiqueId,
          ),
          callback: (payload) => unawaited(
            _appliquerEvenement(provider, boutiqueId, table, payload),
          ),
        );
      }
      _canal = canal;
      _canalBoutiqueId = boutiqueId;
      _tempsReelConnecte = false;

      final confirmation = Completer<bool>();
      canal.subscribe((statut, _) {
        if (!identical(_canal, canal)) return;
        final connecte = statut == RealtimeSubscribeStatus.subscribed;
        _tempsReelConnecte = connecte;
        provider.definirEtatTempsReel(connecte);

        if (connecte) {
          demarrerSurveillance(
            provider,
            boutiqueId,
            intervalle: const Duration(seconds: 45),
          );
          if (!confirmation.isCompleted) confirmation.complete(true);
          return;
        }

        demarrerSurveillance(
          provider,
          boutiqueId,
          intervalle: const Duration(seconds: 15),
        );
        if (!confirmation.isCompleted &&
            (statut == RealtimeSubscribeStatus.channelError ||
                statut == RealtimeSubscribeStatus.timedOut ||
                statut == RealtimeSubscribeStatus.closed)) {
          confirmation.complete(false);
        }
      });

      final connecte = await confirmation.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => false,
      );
      if (!connecte && identical(_canal, canal)) {
        await arreterTempsReel();
      }
      return connecte;
    } catch (_) {
      // Serveur injoignable ou non configuré : la réconciliation périodique
      // de secours prend le relais, l'application reste utilisable hors ligne.
      return false;
    }
  }

  Future<void> arreterTempsReel() async {
    final canal = _canal;
    _canal = null;
    _canalBoutiqueId = null;
    _tempsReelConnecte = false;
    if (canal == null) return;
    try {
      await Supabase.instance.client.removeChannel(canal);
    } catch (_) {
      // Canal déjà fermé.
    }
  }

  /// Réconciliation de secours, utile si le temps réel est indisponible
  /// (réseau filtré, publication absente) : rapatrie l'état du serveur
  /// régulièrement, sans message intempestif.
  void demarrerSurveillance(
    AppProvider provider,
    String boutiqueId, {
    Duration intervalle = const Duration(seconds: 20),
  }) {
    arreterSurveillance();
    _minuteurReconcile = Timer.periodic(
      intervalle,
      (_) => unawaited(synchroniser(provider, boutiqueId, silencieux: true)),
    );
    // Certaines installations Supabase historiques n'ont pas encore publié
    // `boutiques` dans Realtime. Ce contrôle léger garantit que le nom, le
    // logo et les réglages du compte arrivent tout de même en quelques secondes
    // sans relire les dix tables métier.
    _minuteurCompte = Timer.periodic(
      const Duration(seconds: 4),
      (_) => unawaited(_reconcilierCompte(provider, boutiqueId)),
    );
  }

  void arreterSurveillance() {
    _minuteurReconcile?.cancel();
    _minuteurReconcile = null;
    _minuteurCompte?.cancel();
    _minuteurCompte = null;
  }

  Future<void> _reconcilierCompte(
    AppProvider provider,
    String boutiqueId,
  ) async {
    if (_compteEnCours || !provider.enLigne) return;
    _compteEnCours = true;
    try {
      final client = await _client(provider);
      if (client == null) return;
      final distante = await client
          .from('boutiques')
          .select()
          .eq('id', boutiqueId)
          .maybeSingle();
      if (distante == null) return;
      final ligneDistante = versLocal(
        'boutiques',
        Map<String, Object?>.from(distante),
      );
      final locales = await _db.toutes('boutiques');
      Map<String, Object?>? ligneLocale;
      for (final ligne in locales) {
        if (ligne['id'] == boutiqueId) {
          ligneLocale = ligne;
          break;
        }
      }
      if (ligneLocale != null && mapEquals(ligneLocale, ligneDistante)) return;
      // Ne pas remplacer une modification locale qui attend son envoi.
      // Une transaction regroupant l'écriture locale et la file reste
      // nécessaire pour éliminer complètement les courses concurrentes.
      final appliquee = await appliquerSiAucuneOperationEnAttente(
        lireFile: () => _db.listeSyncQueue(boutiqueId: boutiqueId),
        table: 'boutiques',
        id: boutiqueId,
        appliquer: () => _db.inserer('boutiques', ligneDistante),
      );
      if (!appliquee) return;
      await provider.chargerDepuisBase();
      provider.signalerMajDistante('boutiques');
    } catch (_) {
      // Le prochain tick ou le canal Realtime reprendra automatiquement.
    } finally {
      _compteEnCours = false;
    }
  }

  Future<void> liberer() async {
    arreterSurveillance();
    _rafraichissement?.cancel();
    _rafraichissement = null;
    await arreterTempsReel();
  }

  /// Déconnexion : l'appareil n'est plus rattaché à l'employé côté
  /// serveur, l'accès à la boutique est immediately coupé.
  Future<void> deconnexion() async {
    _employeLie = null;
    _boutiqueLie = null;
    if (!configure) return;
    try {
      final client = await _compteAppareil();
      if (client == null) return;
      await client.rpc('detacher_employe');
    } catch (_) {
      // Serveur injoignable : le lien expirera de lui-même.
    }
  }

  /// Regroupe les rafraîchissements d'interface (une rafale d'événements
  /// ne provoque qu'un seul rechargement).
  void _programmerRafraichissement(AppProvider provider) {
    _rafraichissement?.cancel();
    _rafraichissement = Timer(const Duration(milliseconds: 120), () {
      unawaited(provider.chargerDepuisBase());
    });
  }

  Future<void> _appliquerEvenement(
    AppProvider provider,
    String boutiqueId,
    String table,
    PostgresChangePayload payload,
  ) async {
    final decision = interpreterChangement(
      table: table,
      boutiqueId: boutiqueId,
      evenement: _nomEvenement(payload.eventType),
      nouveau: payload.newRecord,
      ancien: payload.oldRecord,
    );
    if (decision.type == decisionIgnorer) return;
    final file = await _db.listeSyncQueue(boutiqueId: boutiqueId);
    if (_operationEnAttente(file, table, decision.id)) return;
    if (decision.type == decisionSupprimer) {
      await _db.supprimer(table, decision.id, boutiqueId: boutiqueId);
    } else {
      final maj = payload.newRecord['maj_ts']?.toString();
      if (!journal.distantPlusRecent(table, decision.id, maj)) return;
      await _db.inserer(
        table,
        await _completerLigne(table, decision.id, decision.ligne!, boutiqueId),
        boutiqueId: boutiqueId,
      );
    }
    _programmerRafraichissement(provider);
    provider.signalerMajDistante(table);
  }

  /// Une charge utile temps réel peut être partielle : les colonnes
  /// sensibles (prix d'achat) ne sont jamais diffusées. On conserve
  /// alors la valeur locale pour les colonnes absentes.
  Future<Map<String, Object?>> _completerLigne(
    String table,
    String id,
    Map<String, Object?> ligne,
    String boutiqueId,
  ) async {
    final locales = table == 'boutiques'
        ? await _db.toutes('boutiques')
        : await _db.toutes(table, boutiqueId: boutiqueId);
    for (final locale in locales) {
      if (locale['id'] != id) continue;
      return {...locale, ...ligne};
    }
    return ligne;
  }

  /// Envoie le catalogue local vers un serveur encore vierge pour cette
  /// boutique. Les horodatages renvoyés par le serveur alimentent le journal
  /// afin que l'écho de ces écritures ne soit pas réappliqué.
  Future<int> _amorcerServeur(SupabaseClient client, String boutiqueId) async {
    var envoyees = 0;
    final localesBoutiques = await _db.toutes('boutiques');
    // Le serveur déduit les ventes et les retours du stock : on lui
    // envoie le stock de départ, pas celui affiché après les opérations.
    final ajustements = await _stockAvantOperations(boutiqueId);
    for (final table in tablesSynchronisees) {
      final localesTable = table == 'boutiques'
          ? const <Map<String, Object?>>[]
          : await _db.toutes(table, boutiqueId: boutiqueId);
      final lignes = lignesAAmorcer(
        table,
        boutiqueId,
        localesBoutiques,
        localesTable,
      );
      for (final ligne in lignes) {
        final id = ligne['id']?.toString();
        if (id == null) continue;
        try {
          final ligneDistante = versSupabase(table, ligne, boutiqueId);
          if (table == 'produits') {
            final ajustement = ajustements[id] ?? 0;
            if (ajustement != 0) {
              final qte = (ligneDistante['quantite'] as num?)?.toDouble() ?? 0;
              ligneDistante['quantite'] = qte + ajustement;
            }
          }
          await _pousser(client, table, ligneDistante);
          journal.noter(table, id, ligneDistante['maj_ts']?.toString());
          envoyees++;
        } catch (_) {
          // Colonne absente ou table non publiée : nouvel essai au cycle suivant.
        }
      }
    }
    return envoyees;
  }

  /// Stock tel qu'il était AVANT les ventes et les retours déjà
  /// enregistrés localement : le serveur les déduira lui-même.
  Future<Map<String, double>> _stockAvantOperations(String boutiqueId) async {
    final ajustements = <String, double>{};
    final ventes = await _db.toutes('ventes', boutiqueId: boutiqueId);
    for (final v in ventes) {
      final id = v['produitId']?.toString();
      if (id == null || id.isEmpty) continue;
      final qte = (v['quantite'] as num?)?.toDouble() ?? 0;
      ajustements[id] = (ajustements[id] ?? 0) + qte;
    }
    final retours = await _db.toutes('retours', boutiqueId: boutiqueId);
    for (final r in retours) {
      final id = r['produitId']?.toString();
      if (id == null || id.isEmpty) continue;
      final motif = r['motif']?.toString() ?? '';
      // Un défaut retire une pièce (+1 à renvoyer au serveur), un échange
      // ou un remboursement en rend une (-1).
      ajustements[id] = (ajustements[id] ?? 0) + (motif == 'defectueux' ? 1 : -1);
    }
    return ajustements;
  }

  /// Vrai si le serveur ne contient encore aucune donnée métier pour la
  /// boutique. Le contrôle est fait par le serveur : la lecture des
  /// tables est filtrée par le rôle, elle ne conviendrait pas.
  Future<bool> _serveurVide(SupabaseClient client, String boutiqueId) async {
    try {
      final reponse = await client.rpc(
        'compte_metier',
        params: {'p_boutique': boutiqueId},
      );
      final nombre = reponse is List && reponse.isNotEmpty
          ? (reponse.first as Map)['compte_metier']
          : null;
      if (nombre is num) return nombre == 0;
    } catch (_) {
      // Sans réponse du serveur, on n'amorce pas : mieux vaut un serveur
      // vide qu'un stock décalé.
    }
    return false;
  }

  /// Le serveur distingue la création de la modification : `upsert` envoie
  /// `ON CONFLICT DO UPDATE`, qui exige les droits de modification. Un
  /// caissier peut créer une vente ou une sortie de caisse sans pouvoir
  /// réécrire une ligne existante : son envoi échouait donc entièrement.
  /// On insère d'abord, et on ne bascule sur une mise à jour que si la ligne
  /// existe déjà (c'est alors une modification locale à répercuter).
  Future<void> _pousser(
    SupabaseClient client,
    String table,
    Map<String, Object?> ligne,
  ) async {
    if (table == 'produits') {
      // Les images partent d'abord vers Storage : la colonne ne transporte
      // que des chemins d'objets, lisibles par tous les appareils.
      ligne['images'] = await _imagesDistantes(client, ligne);
      await client.rpc('enregistrer_produit', params: {'p_data': ligne});
    } else if (table == 'ventes') {
      await client.rpc('enregistrer_vente', params: {'p_data': ligne});
    } else if (table == 'activites') {
      // Journal en ajout seul : un doublon signifie que la ligne est déjà
      // arrivée et peut être considérée comme envoyée.
      try {
        await client.from(table).insert(ligne);
      } on PostgrestException catch (e) {
        if (e.code != '23505') rethrow;
      }
    } else {
      try {
        await client.from(table).insert(ligne);
      } on PostgrestException catch (e) {
        if (e.code != '23505') rethrow;
        await client.from(table).update(ligne).eq('id', ligne['id']!);
      }
    }
  }

  /// Envoie les images locales du produit vers Storage et renvoie la valeur
  /// à stocker côté serveur. Un envoi impossible laisse le chemin local :
  /// il sera réessayé au cycle suivant, sans bloquer le reste du produit.
  Future<String> _imagesDistantes(
    SupabaseClient client,
    Map<String, Object?> ligne,
  ) async {
    final brut = (ligne['images'] as String? ?? '').trim();
    final produitId = ligne['id']?.toString() ?? '';
    final boutiqueId = ligne['boutique_id']?.toString() ?? '';
    if (brut.isEmpty || produitId.isEmpty || boutiqueId.isEmpty) return brut;
    final sortie = <String>[];
    for (final entree in brut.split(',')) {
      final chemin = entree.trim();
      if (chemin.isEmpty) continue;
      if (!ImageService.estCheminLocal(chemin)) {
        sortie.add(chemin);
        continue;
      }
      try {
        sortie.add(await ImageService.instance
            .televerser(client, chemin, boutiqueId, produitId));
      } catch (_) {
        sortie.add(chemin);
      }
    }
    return sortie.join(',');
  }

  /// Rapatrie les images d'un produit reçu du serveur : l'appareil stocke et
  /// affiche des fichiers locaux, le serveur des chemins d'objets.
  Future<String> _imagesLocales(
    SupabaseClient client,
    Object? valeur,
  ) async {
    final brut = (valeur?.toString() ?? '').trim();
    if (brut.isEmpty) return '';
    final sortie = <String>[];
    for (final entree in brut.split(',')) {
      final objet = entree.trim();
      if (objet.isEmpty) continue;
      if (ImageService.estCheminLocal(objet)) {
        // Chemin absolu : le nôtre (envoi encore en attente) ou celui d'un
        // autre appareil, alors sans fichier ici.
        if (await ImageService.instance.existe(objet)) sortie.add(objet);
        continue;
      }
      try {
        final local = await ImageService.instance.telecharger(client, objet);
        if (local != null) sortie.add(local);
      } catch (_) {
        // Réessai au prochain cycle de synchronisation.
      }
    }
    return sortie.join(',');
  }

  static bool _operationEnAttente(
    List<Map<String, Object?>> file,
    String table,
    String id,
  ) {
    for (final op in file) {
      if (op['tableName'] == table && op['rowId'] == id) return true;
    }
    return false;
  }

  // ---------- Envoi / réception ----------

  /// Pousse la file locale vers le serveur puis rapatrie l'état du tenant.
  ///
  /// [silencieux] évite les messages lors des cycles automatiques.
  Future<SyncResultat> synchroniser(
    AppProvider provider,
    String boutiqueId, {
    bool silencieux = false,
  }) async {
    if (!configure || !provider.enLigne || _enCours) {
      return const SyncResultat();
    }
    final b = provider.boutique;
    if (b == null) return const SyncResultat();
    _enCours = true;
    journal.purger();
    try {
      final client = await _client(provider);
      if (client == null) return const SyncResultat();
      final operations = await _db.listeSyncQueue(boutiqueId: boutiqueId);
      var poussees = 0;
      for (final op in operations) {
        final table = op['tableName'] as String;
        final action = op['action'] as String;
        final rowId = op['rowId'] as String;
        try {
          if (action == 'delete') {
            await client.from(table).delete().eq('id', rowId);
          } else {
            final data =
                jsonDecode(op['data'] as String) as Map<String, Object?>;
            final ligne = versSupabase(table, data, boutiqueId);
            await _pousser(client, table, ligne);
            journal.noter(table, rowId, ligne['maj_ts']?.toString());
          }
          await _db.supprimerSyncQueue(
            op['id'] as String,
            boutiqueId: boutiqueId,
          );
          poussees++;
        } catch (_) {
          // L'opération reste en file et sera retentée à la prochaine sync.
        }
      }
      var recues = 0;
      var lignesMetier = 0;
      final restantes = await _db.listeSyncQueue(boutiqueId: boutiqueId);
      for (final table in tablesSynchronisees) {
        // `produits` et `ventes` ont des colonnes sensibles : les lectures
        // passent par des vues qui masquent les coûts selon les droits.
        final source = switch (table) {
          'produits' => 'produits_employe',
          'ventes' => 'ventes_employe',
          _ => table,
        };
        final rows = table == 'boutiques'
            ? await client.from(source).select().eq('id', boutiqueId)
            : await client.from(source).select().eq('boutique_id', boutiqueId);
        if (table != 'boutiques') lignesMetier += rows.length;
        for (final row in rows) {
          final id = row['id']?.toString();
          if (id == null) continue;
          if (_operationEnAttente(restantes, table, id)) continue;
          final maj = row['maj_ts']?.toString();
          if (!journal.distantPlusRecent(table, id, maj)) continue;
          final locale = versLocal(table, row);
          if (locale.isEmpty) continue;
          if (table == 'produits') {
            locale['images'] =
                await _imagesLocales(client, row['images']);
          }
          // `boutiques` n'a pas de colonne de tenant : son `id` est celui de
          // la boutique. Ajouter `boutique_id` y ferait échouer l'insertion
          // SQLite et interromprait toute la réconciliation.
          await _db.inserer(
            table,
            locale,
            boutiqueId: table == 'boutiques' ? null : boutiqueId,
          );
          recues++;
        }
      }
      // Serveur vide pour cette boutique (nouvelle installation, projet
      // restauré ou recréé) : la file ne contient que les modifications
      // récentes, on y pousse donc le catalogue local une fois pour que tous
      // les appareils repartent du même état.
      var amorcees = 0;
      if (serveurSansDonneesMetier(lignesMetier) &&
          await _serveurVide(client, boutiqueId)) {
        amorcees = await _amorcerServeur(client, boutiqueId);
      }
      await provider.chargerDepuisBase();
      return SyncResultat(
        envoyees: poussees + amorcees,
        recues: recues,
        enAttente: restantes.length,
        ok: true,
      );
    } catch (_) {
      return const SyncResultat();
    } finally {
      _enCours = false;
    }
  }
}

@visibleForTesting
Map<String, Object?> versSupabase(
  String table,
  Map<String, Object?> locale,
  String boutiqueId,
) {
  final colonnes = _colonnes[table]!;
  final booleens = _booleens[table] ?? const <String>[];
  final out = <String, Object?>{
    if (table != 'boutiques') 'boutique_id': boutiqueId,
    'maj_ts': DateTime.now().toUtc().toIso8601String(),
  };
  locale.forEach((cle, valeur) {
    if (cle == 'boutique_id') return;
    final cible = colonnes[cle];
    if (cible == null) return;
    // La caisse est tenue par les triggers serveur : le client ne l'écrit plus.
    if (table == 'boutiques' && cible == 'solde_caisse') return;
    out[cible] = booleens.contains(cle) && valeur is num ? valeur == 1 : valeur;
  });
  return out;
}

@visibleForTesting
Map<String, Object?> versLocal(String table, Map<String, Object?> supabase) {
  final colonnes = _colonnes[table]!;
  final booleens = _booleens[table] ?? const <String>[];
  final inverses = <String, String>{
    for (final e in colonnes.entries) e.value: e.key,
  };
  final out = <String, Object?>{};
  supabase.forEach((cle, valeur) {
    final locale = inverses[cle];
    if (locale == null) return;
    out[locale] = booleens.contains(locale) && valeur is bool
        ? (valeur ? 1 : 0)
        : valeur;
  });
  return out;
}
