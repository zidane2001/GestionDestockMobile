import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../data/database.dart';
import '../providers/app_provider.dart';

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

class SyncService {
  final DatabaseHelper _db;
  bool _enCours = false;

  RealtimeChannel? _canal;
  String? _canalBoutiqueId;
  String? _sessionBoutiqueId;
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

  Future<SupabaseClient?> _client(String boutiqueId, String nomBoutique) async {
    if (!configure) return null;
    final client = Supabase.instance.client;
    if (_sessionBoutiqueId == boutiqueId &&
        client.auth.currentSession != null) {
      return client;
    }
    final email =
        'boutique-${boutiqueId.replaceAll(RegExp(r'[^a-z0-9]'), '')}@ma-boutique.app';
    final mdpDerive = 'mb-${boutiqueId.replaceAll(RegExp(r'[^a-z0-9]'), '')}';
    var mdp = await _db.getSetting('serveur_mdp');
    if (mdp == null || mdp.isEmpty) {
      mdp = mdpDerive;
      await _db.setSetting('serveur_mdp', mdp);
    }
    Future<bool> essaie(String m) async {
      try {
        await client.auth.signInWithPassword(email: email, password: m);
        return true;
      } on AuthException {
        return false;
      }
    }

    if (!await essaie(mdp)) {
      if (mdp != mdpDerive && await essaie(mdpDerive)) {
        mdp = mdpDerive;
        await _db.setSetting('serveur_mdp', mdp);
      } else {
        try {
          await client.auth.signUp(email: email, password: mdpDerive);
          mdp = mdpDerive;
          await _db.setSetting('serveur_mdp', mdp);
        } on AuthException {
          return null;
        }
      }
    }
    try {
      await client.rpc(
        'initier_boutique',
        params: {'p_id': boutiqueId, 'p_nom': nomBoutique},
      );
    } catch (_) {
      // Déjà initialisée : rien à faire.
    }
    _sessionBoutiqueId = boutiqueId;
    return client;
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
      final client = await _client(boutiqueId, provider.boutique?.nom ?? '');
      if (client == null) return false;
      final canal = client.channel('boutique:$boutiqueId');
      for (final table in tablesSynchronisees) {
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
      final client = await _client(boutiqueId, provider.boutique?.nom ?? '');
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
      await _db.inserer('boutiques', ligneDistante);
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
      await _db.inserer(table, decision.ligne!, boutiqueId: boutiqueId);
    }
    _programmerRafraichissement(provider);
    provider.signalerMajDistante(table);
  }

  /// Envoie le catalogue local vers un serveur encore vierge pour cette
  /// boutique. Les horodatages renvoyés par le serveur alimentent le journal
  /// afin que l'écho de ces écritures ne soit pas réappliqué.
  Future<int> _amorcerServeur(SupabaseClient client, String boutiqueId) async {
    var envoyees = 0;
    final localesBoutiques = await _db.toutes('boutiques');
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
          final renvoye = await client
              .from(table)
              .upsert(
                versSupabase(table, ligne, boutiqueId),
                onConflict: 'id',
                ignoreDuplicates: false,
              )
              .select('id, maj_ts');
          final maj = renvoye.isNotEmpty
              ? renvoye.first['maj_ts']?.toString()
              : null;
          journal.noter(table, id, maj);
          envoyees++;
        } catch (_) {
          // Colonne absente ou table non publiée : nouvel essai au cycle suivant.
        }
      }
    }
    return envoyees;
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
      final client = await _client(boutiqueId, b.nom);
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
            // La ligne renvoyée porte l'horodatage réellement stocké : elle
            // permet de reconnaître l'écho de nos propres écritures.
            final renvoye = await client
                .from(table)
                .upsert(ligne, onConflict: 'id', ignoreDuplicates: false)
                .select('id, maj_ts');
            final majServeur = renvoye.isNotEmpty
                ? renvoye.first['maj_ts']?.toString()
                : ligne['maj_ts']?.toString();
            journal.noter(table, rowId, majServeur);
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
        final rows = table == 'boutiques'
            ? await client.from(table).select().eq('id', boutiqueId)
            : await client.from(table).select().eq('boutique_id', boutiqueId);
        if (table != 'boutiques') lignesMetier += rows.length;
        for (final row in rows) {
          final id = row['id']?.toString();
          if (id == null) continue;
          if (_operationEnAttente(restantes, table, id)) continue;
          final maj = row['maj_ts']?.toString();
          if (!journal.distantPlusRecent(table, id, maj)) continue;
          final locale = versLocal(table, row);
          if (locale.isEmpty) continue;
          await _db.inserer(table, locale, boutiqueId: boutiqueId);
          recues++;
        }
      }
      // Serveur vide pour cette boutique (nouvelle installation, projet
      // restauré ou recréé) : la file ne contient que les modifications
      // récentes, on y pousse donc le catalogue local une fois pour que tous
      // les appareils repartent du même état.
      var amorcees = 0;
      if (serveurSansDonneesMetier(lignesMetier)) {
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
