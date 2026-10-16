import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/format.dart';
import '../core/permissions.dart';
import '../data/database.dart';
import '../models/models.dart';
import '../services/biometric_service.dart';
import '../services/qr_code_service.dart';
import '../services/sync_service.dart';
import '../services/superadmin_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final SyncService? _sync;

  AppProvider({this._sync});

  Boutique? _boutique;
  List<Employe> _employes = [];
  List<Produit> _produits = [];
  List<Vente> _ventes = [];
  List<Depense> _depenses = [];
  List<Retour> _retours = [];
  List<NotificationItem> _notifications = [];
  List<Pointage> _pointages = [];
  List<Activite> _activites = [];
  List<Appareil> _appareils = [];

  String? _sessionId;
  bool _verrouille = false;
  bool _sombre = false;
  bool _enLigne = true;
  int _enAttenteSync = 0;
  bool _tempsReelActif = false;
  DateTime? _derniereMajDistante;
  DateTime? _derniereNotificationDistante;
  List<ToastMessage> _toasts = [];

  final List<Timer> _timers = [];

  // ---------- Getters ----------

  Boutique? get boutique => _boutique;
  List<Employe> get employes => List.unmodifiable(_employes);
  List<Produit> get produits => List.unmodifiable(_produits);
  List<Vente> get ventes => List.unmodifiable(_ventes);
  List<Depense> get depenses => List.unmodifiable(_depenses);
  List<Retour> get retours => List.unmodifiable(_retours);
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  List<Pointage> get pointages => List.unmodifiable(_pointages);
  List<Activite> get activites => List.unmodifiable(_activites);
  List<Appareil> get appareils => List.unmodifiable(_appareils);

  Employe? get session {
    if (_sessionId == null) return null;
    for (final e in _employes) {
      if (e.id == _sessionId) return e;
    }
    return null;
  }

  bool get verrouille => _verrouille;
  bool get sombre => _sombre;
  bool get enLigne => _enLigne;
  int get enAttenteSync => _enAttenteSync;

  /// Vrai quand l'écoute temps réel est établie avec le serveur.
  bool get tempsReel => _tempsReelActif;

  /// Horodatage de la dernière modification reçue d'un autre appareil.
  DateTime? get derniereMajDistante => _derniereMajDistante;
  List<ToastMessage> get toasts => List.unmodifiable(_toasts);
  String get monnaie => _boutique?.monnaie.code ?? 'FCFA';

  List<NotificationItem> get notificationsRole {
    final s = session;
    if (s == null) return [];
    return _notifications.where((n) => n.destinataires.contains(s.role)).toList();
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    unawaited(_sync?.liberer());
    super.dispose();
  }

  // ---------- Initialisation ----------

  Future<void> initialize() async {
    final rowsBoutique = await _db.toutes('boutiques');
    if (rowsBoutique.isNotEmpty) {
      _boutique = Boutique.fromMap(rowsBoutique.first);
    }
    final boutiqueId = _boutique?.id;
    if (boutiqueId != null) {
      await _chargerDonneesBoutique(boutiqueId);
    }
    final theme = await _db.getSetting('theme');
    _sombre = theme == 'sombre';
    final sid = await _db.getSetting('session_id');
    if (sid != null && sid.isNotEmpty) {
      for (final e in _employes) {
        if (e.id == sid) {
          _sessionId = sid;
          _verrouille = e.pinActif;
          break;
        }
      }
    }
    notifyListeners();
    unawaited(_synchroniser());
    unawaited(_activerTempsReel());
  }

  Future<void> _chargerDonneesBoutique(String boutiqueId) async {
    _employes = (await _db.toutes('employes', boutiqueId: boutiqueId)).map(Employe.fromMap).toList();
    _produits = (await _db.toutes('produits', boutiqueId: boutiqueId)).map(Produit.fromMap).toList();
    _ventes = (await _db.toutes('ventes', ordre: 'date DESC', boutiqueId: boutiqueId)).map(Vente.fromMap).toList();
    _depenses = (await _db.toutes('depenses', ordre: 'date DESC', boutiqueId: boutiqueId)).map(Depense.fromMap).toList();
    _retours = (await _db.toutes('retours', ordre: 'date DESC', boutiqueId: boutiqueId)).map(Retour.fromMap).toList();
    _notifications =
        (await _db.toutes('notifications', ordre: 'date DESC', boutiqueId: boutiqueId)).map(NotificationItem.fromMap).toList();
    _pointages = (await _db.toutes('pointages', boutiqueId: boutiqueId)).map(Pointage.fromMap).toList();
    _activites = (await _db.toutes('activites', ordre: 'date DESC', boutiqueId: boutiqueId)).map(Activite.fromMap).toList();
    _appareils = (await _db.toutes('appareils', boutiqueId: boutiqueId)).map(Appareil.fromMap).toList();
  }

  Future<void> _persistTout() async {
    final boutiqueId = _boutique?.id;
    if (boutiqueId == null) return;
    if (_boutique != null) {
      await _db.inserer('boutiques', _boutique!.toMap());
    }
    for (final e in _employes) {
      await _db.inserer('employes', e.toMap(), boutiqueId: boutiqueId);
    }
    for (final p in _produits) {
      await _db.inserer('produits', p.toMap(), boutiqueId: boutiqueId);
    }
    for (final v in _ventes) {
      await _db.inserer('ventes', v.toMap(), boutiqueId: boutiqueId);
    }
    for (final d in _depenses) {
      await _db.inserer('depenses', d.toMap(), boutiqueId: boutiqueId);
    }
    for (final r in _retours) {
      await _db.inserer('retours', r.toMap(), boutiqueId: boutiqueId);
    }
    for (final n in _notifications) {
      await _db.inserer('notifications', n.toMap(), boutiqueId: boutiqueId);
    }
    for (final p in _pointages) {
      await _db.inserer('pointages', p.toMap(), boutiqueId: boutiqueId);
    }
    for (final a in _activites) {
      await _db.inserer('activites', a.toMap(), boutiqueId: boutiqueId);
    }
    for (final a in _appareils) {
      await _db.inserer('appareils', a.toMap(), boutiqueId: boutiqueId);
    }
  }

  Future<void> _persistBoutique() async {
    if (_boutique != null) {
      await _db.inserer('boutiques', _boutique!.toMap());
    }
  }

  Future<void> _persistEmployes() async {
    final boutiqueId = _boutique?.id;
    if (boutiqueId == null) return;
    for (final e in _employes) {
      await _db.inserer('employes', e.toMap(), boutiqueId: boutiqueId);
    }
  }

  Future<void> _persistProduits() async {
    final boutiqueId = _boutique?.id;
    if (boutiqueId == null) return;
    for (final p in _produits) {
      await _db.inserer('produits', p.toMap(), boutiqueId: boutiqueId);
    }
  }

  Future<void> _persistVentes() async {
    final boutiqueId = _boutique?.id;
    if (boutiqueId == null) return;
    for (final v in _ventes) {
      await _db.inserer('ventes', v.toMap(), boutiqueId: boutiqueId);
    }
  }

  Future<void> _persistDepenses() async {
    final boutiqueId = _boutique?.id;
    if (boutiqueId == null) return;
    for (final d in _depenses) {
      await _db.inserer('depenses', d.toMap(), boutiqueId: boutiqueId);
    }
  }

  Future<void> _persistRetours() async {
    final boutiqueId = _boutique?.id;
    if (boutiqueId == null) return;
    for (final r in _retours) {
      await _db.inserer('retours', r.toMap(), boutiqueId: boutiqueId);
    }
  }

  Future<void> _persistNotifications() async {
    final boutiqueId = _boutique?.id;
    if (boutiqueId == null) return;
    for (final n in _notifications) {
      await _db.inserer('notifications', n.toMap(), boutiqueId: boutiqueId);
    }
  }

  Future<void> _persistPointages() async {
    final boutiqueId = _boutique?.id;
    if (boutiqueId == null) return;
    for (final p in _pointages) {
      await _db.inserer('pointages', p.toMap(), boutiqueId: boutiqueId);
    }
  }

  Future<void> _persistActivites() async {
    final boutiqueId = _boutique?.id;
    if (boutiqueId == null) return;
    for (final a in _activites) {
      await _db.inserer('activites', a.toMap(), boutiqueId: boutiqueId);
    }
  }

  Future<void> _persistAppareils() async {
    final boutiqueId = _boutique?.id;
    if (boutiqueId == null) return;
    for (final a in _appareils) {
      await _db.inserer('appareils', a.toMap(), boutiqueId: boutiqueId);
    }
  }

  // ---------- Utilitaires ----------

  String _uid() {
    final rand = Random();
    var s = '';
    for (var i = 0; i < 8; i++) {
      s += rand.nextInt(36).toRadixString(36);
    }
    return s;
  }

  String _maintenantIso() => DateTime.now().toUtc().toIso8601String();

  void notifier(String message, [TonToast ton = TonToast.succes]) {
    final id = _uid();
    _toasts = [..._toasts, ToastMessage(id: id, message: message, ton: ton)];
    notifyListeners();
    _timers.add(Timer(const Duration(milliseconds: 3200), () {
      fermerToast(id);
    }));
  }

  void fermerToast(String id) {
    _toasts = _toasts.where((t) => t.id != id).toList();
    notifyListeners();
  }

  void _pousserNotification(
    String titre,
    String message,
    NotifType type,
    List<Role> destinataires,
  ) {
    _notifications = [
      NotificationItem(
        id: _uid(),
        destinataires: destinataires,
        titre: titre,
        message: message,
        type: type,
        estLu: false,
        date: _maintenantIso(),
      ),
      ..._notifications,
    ];
    _persistNotifications();
    _enregistrerSync('notifications', 'upsert', _notifications.first.id,
        _notifications.first.toMap());
  }

  void _journaliser(NotifType type, String description) {
    final auteur = session;
    if (auteur == null) return;
    _activites = [
      Activite(
        id: _uid(),
        employeNom: auteur.nom,
        employeRole: auteur.role,
        type: type,
        description: description,
        date: _maintenantIso(),
      ),
      ..._activites,
    ];
    _persistActivites();
    _enregistrerSync('activites', 'upsert', _activites.first.id, _activites.first.toMap());
  }

  void _majCaisse(double delta) {
    final b = _boutique;
    if (b == null) return;
    _boutique = b.copyWith(soldeCaisse: b.soldeCaisse + delta);
    _persistBoutique();
    _enregistrerSync('boutiques', 'upsert', _boutique!.id, _boutique!.toMap());
  }

  void _compterSync() {
    if (!_enLigne) _enAttenteSync += 1;
  }

  /// Met une opération en file de synchronisation (persistée localement).
  void _enregistrerSync(String table, String action, String rowId, Map<String, Object?> data) {
    final boutiqueId = _boutique?.id;
    if (boutiqueId != null) {
      _db.insererSyncQueue(table, action, rowId, data, boutiqueId: boutiqueId);
    }
  }

  Future<void> _synchroniser({bool silencieux = false}) async {
    final sync = _sync;
    if (sync == null || !sync.configure) return;
    final boutiqueId = _boutique?.id;
    if (boutiqueId == null) return;
    final resultat = await sync.synchroniser(this, boutiqueId, silencieux: silencieux);
    if (!resultat.ok) {
      if (!silencieux) {
        notifier('Synchronisation impossible pour le moment.', TonToast.erreur);
      }
      return;
    }
    _enAttenteSync = resultat.enAttente;
    if (silencieux) return;
    if (resultat.envoyees > 0) {
      notifier(
        'Synchronisation terminée — ${resultat.envoyees} opération${resultat.envoyees > 1 ? 's' : ''} envoyée${resultat.envoyees > 1 ? 's' : ''} à l\'équipe.',
      );
    } else {
      notifier("Données à jour avec l'équipe.", TonToast.info);
    }
  }

  /// Synchronisation demandée par l'utilisateur (bouton ou geste manuel).
  Future<void> synchroniserMaintenant() async {
    if (!_enLigne) {
      notifier(
        'Hors ligne : la synchronisation reprendra au retour du réseau.',
        TonToast.info,
      );
      return;
    }
    await _synchroniser();
  }

  /// Ouvre l'écoute temps réel puis la réconciliation périodique de secours.
  Future<void> _activerTempsReel() async {
    final sync = _sync;
    final boutiqueId = _boutique?.id;
    if (sync == null || boutiqueId == null || !sync.configure || !_enLigne) {
      _tempsReelActif = false;
      return;
    }
    var actif = false;
    try {
      actif = await sync.demarrerTempsReel(this, boutiqueId);
      sync.demarrerSurveillance(
        this,
        boutiqueId,
        intervalle: actif ? const Duration(seconds: 45) : const Duration(seconds: 15),
      );
    } catch (_) {
      // Pas de temps réel disponible : on reste en réconciliation périodique.
      actif = false;
    }
    _tempsReelActif = actif;
    notifyListeners();
  }

  Future<void> _desactiverTempsReel() async {
    final sync = _sync;
    if (sync == null) return;
    sync.arreterSurveillance();
    await sync.arreterTempsReel();
    _tempsReelActif = false;
    notifyListeners();
  }

  /// Appelé quand une modification faite sur un autre appareil vient d'être
  /// appliquée localement : l'interface est prévenue sans être inondée.
  void signalerMajDistante(String table) {
    final maintenant = DateTime.now();
    _derniereMajDistante = maintenant;
    final derniere = _derniereNotificationDistante;
    if (derniere == null || maintenant.difference(derniere) > const Duration(seconds: 4)) {
      _derniereNotificationDistante = maintenant;
      notifier(libelleMajDistante(table), TonToast.info);
    } else {
      notifyListeners();
    }
  }

  /// Recharge toutes les listes depuis la base locale (après une synchro).
  Future<void> chargerDepuisBase() async {
    final boutiqueId = _boutique?.id;
    if (boutiqueId == null) return;
    await _chargerDonneesBoutique(boutiqueId);
    notifyListeners();
  }

  // ---------- Authentification ----------

  void creerBoutique({
    required String nom,
    required String styleCommerce,
    required Monnaie monnaie,
    required String emailPatron,
    required String motDePasse,
    String? logoUrl,
  }) {
    final patron = Employe(
      id: _uid(),
      nom: 'Patron',
      role: Role.patron,
      permissions: permissionsParDefaut(Role.patron),
      motDePasse: motDePasse,
      statut: StatutEmploye.actif,
      pinActif: false,
      pin: '',
      biometrie: false,
      dateCreation: _maintenantIso(),
    );
    _boutique = Boutique(
      id: _uid(),
      nom: nom,
      styleCommerce: styleCommerce,
      monnaie: monnaie,
      emailPatron: emailPatron,
      logoUrl: logoUrl,
      soldeCaisse: 0,
    );
    _employes = [patron];
    _produits = [];
    _ventes = [];
    _depenses = [];
    _retours = [];
    _notifications = [];
    _pointages = [];
    _activites = [];
    _appareils = [
      Appareil(
        id: _uid(),
        employeNom: patron.nom,
        role: Role.patron,
        nomAppareil: 'Cet appareil',
        derniereConnexion: _maintenantIso(),
        actif: true,
      ),
    ];
    _sessionId = patron.id;
    _db.setSetting('session_id', patron.id);
    _persistTout();
    _enregistrerSync('boutiques', 'upsert', _boutique!.id, _boutique!.toMap());
    _enregistrerSync('employes', 'upsert', patron.id, patron.toMap());
    for (final a in _appareils) {
      _enregistrerSync('appareils', 'upsert', a.id, a.toMap());
    }
    notifier('Boutique créée. Bienvenue !');
    unawaited(_synchroniser());
    unawaited(_activerTempsReel());
  }

  void definirLogo(String? logoUrl) {
    final b = _boutique;
    if (b == null) return;
    _boutique = b.copyWith(logoUrl: logoUrl);
    _persistBoutique();
    _enregistrerSync('boutiques', 'upsert', _boutique!.id, _boutique!.toMap());
    notifier(logoUrl != null ? 'Logo mis à jour' : 'Logo retiré',
        logoUrl != null ? TonToast.succes : TonToast.info);
  }

  Future<String?> connexion(String nomBoutique, Role role, String motDePasse) async {
    // Find boutique by name
    final rowsBoutique = await _db.toutes('boutiques');
    Boutique? boutique;
    for (final row in rowsBoutique) {
      if ((row['nom'] as String).toLowerCase() == nomBoutique.trim().toLowerCase()) {
        boutique = Boutique.fromMap(row);
        break;
      }
    }
    if (boutique == null) {
      return 'Nom de boutique inconnu.';
    }

    // Load data for this boutique
    await _chargerDonneesBoutique(boutique.id);

    // Find employee
    Employe? employe;
    for (final e in _employes) {
      if (e.role == role && e.motDePasse == motDePasse) {
        employe = e;
        break;
      }
    }
    if (employe == null) return 'Mot de passe incorrect.';
    if (employe.statut == StatutEmploye.suspendu) {
      return 'Compte suspendu. Contactez le patron.';
    }

    _boutique = boutique;
    _sessionId = employe.id;
    _verrouille = employe.pinActif;
    _db.setSetting('session_id', employe.id);
    _journaliser(NotifType.connexion, 'Connexion de ${employe.nom}');
    unawaited(_activerTempsReel());
    return null;
  }

  /// Importe une boutique depuis une row Supabase dans la base locale.
  Future<void> importerBoutiqueDepuisSupabase(Map<String, dynamic> row) async {
    final b = Boutique(
      id: row['id'] as String,
      nom: row['nom'] as String? ?? '',
      styleCommerce: row['style_commerce'] as String? ?? '',
      monnaie: MonnaieX.fromCode(row['monnaie'] as String? ?? 'FCFA'),
      emailPatron: row['email_patron'] as String? ?? '',
      logoUrl: row['logo_url'] as String?,
      soldeCaisse: (row['solde_caisse'] as num? ?? 0).toDouble(),
      statut: row['statut'] as String? ?? 'active',
      abonnementMode: row['abonnement_mode'] as String? ?? 'achat_direct',
      abonnementDebut: row['abonnement_debut'] != null ? DateTime.tryParse(row['abonnement_debut'] as String) : null,
      abonnementFin: row['abonnement_fin'] != null ? DateTime.tryParse(row['abonnement_fin'] as String) : null,
      notificationAbonnement: row['notification_abonnement'] == true,
      methodePaiement: row['methode_paiement'] as String? ?? '',
    );
    _boutique = b;
    await _db.inserer('boutiques', b.toMap());
    _enregistrerSync('boutiques', 'upsert', b.id, b.toMap());
    notifyListeners();
  }

  /// Importe un employé depuis une row Supabase dans la base locale.
  Future<void> importerEmployeDepuisSupabase(Map<String, dynamic> row) async {
    final emp = Employe(
      id: row['id'] as String,
      nom: row['nom'] as String? ?? '',
      role: RoleX.fromName(row['role'] as String? ?? 'patron'),
      permissions: _parsePermissions(row['permissions'] as String? ?? ''),
      motDePasse: row['mot_de_passe'] as String? ?? '',
      statut: StatutEmployeX.fromName(row['statut'] as String? ?? 'actif'),
      pinActif: row['pin_actif'] == true,
      pin: row['pin'] as String? ?? '',
      biometrie: row['biometrie'] == true,
      dateCreation: row['date_creation'] as String? ?? '',
    );
    final boutiqueId = row['boutique_id'] as String? ?? _boutique?.id ?? '';
    // Ajouter à la liste locale si pas déjà présent
    final existant = _employes.indexWhere((e) => e.id == emp.id);
    if (existant >= 0) {
      _employes[existant] = emp;
    } else {
      _employes.add(emp);
    }
    final data = emp.toMap();
    data['boutique_id'] = boutiqueId;
    await _db.inserer('employes', data);
    _enregistrerSync('employes', 'upsert', emp.id, data);
    notifyListeners();
  }

  List<Permission> _parsePermissions(String raw) {
    if (raw.isEmpty) return [];
    return raw.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).map(PermissionX.fromName).toList();
  }

  void deconnexion() {
    unawaited(_desactiverTempsReel());
    _sessionId = null;
    _verrouille = false;
    _boutique = null;
    _employes = [];
    _produits = [];
    _ventes = [];
    _depenses = [];
    _retours = [];
    _notifications = [];
    _pointages = [];
    _activites = [];
    _appareils = [];
    _db.setSetting('session_id', '');
    notifyListeners();
  }

  bool deverrouiller(String pin) {
    final s = session;
    if (s != null && s.pin == pin) {
      _verrouille = false;
      return true;
    }
    return false;
  }

  void verrouiller() {
    _verrouille = true;
  }

  void basculerTheme() {
    _sombre = !_sombre;
    _db.setSetting('theme', _sombre ? 'sombre' : 'clair');
    notifyListeners();
  }

  void basculerReseau() {
    _enLigne = !_enLigne;
    if (!_enLigne) {
      notifier(
        'Mode hors ligne — les opérations seront synchronisées dès le retour du réseau.',
        TonToast.info,
      );
    } else {
      final n = _enAttenteSync;
      _enAttenteSync = 0;
      if (n > 0 || (_sync?.configure ?? false)) {
        unawaited(_synchroniser());
      } else {
        notifier('De retour en ligne.', TonToast.info);
      }
      unawaited(_activerTempsReel());
    }
    if (!_enLigne) {
      unawaited(_desactiverTempsReel());
    }
    notifyListeners();
  }

  // ---------- Opérations métier ----------

  String? enregistrerVente(String produitId, double quantite, double prixUnitaire) {
    final s = session;
    if (s == null) return 'Session expirée.';
    Produit? produit;
    for (final p in _produits) {
      if (p.id == produitId) {
        produit = p;
        break;
      }
    }
    if (produit == null) return 'Produit introuvable.';
    if (quantite <= 0) return 'La quantité doit être supérieure à 0.';
    if (quantite > produit.quantite) {
      return 'Stock insuffisant : ${produit.quantite.toStringAsFixed(0)} en stock.';
    }
    if (prixUnitaire <= 0) return 'Le prix de vente doit être supérieur à 0.';

    final total = quantite * prixUnitaire;
    final vente = Vente(
      id: _uid(),
      produitId: produit.id,
      produitNom: produit.nom,
      quantite: quantite,
      prixUnitaireReel: prixUnitaire,
      prixAchatUnitaire: produit.prixAchat,
      total: total,
      vendeurId: s.id,
      vendeurNom: s.nom,
      vendeurRole: s.role,
      date: _maintenantIso(),
    );
    _ventes = [vente, ..._ventes];
    _persistVentes();
    _produits = [
      for (final p in _produits)
        if (p.id == produitId) p.copyWith(quantite: p.quantite - quantite) else p,
    ];
    _persistProduits();
    _majCaisse(total);
    _pousserNotification(
      'Nouvelle vente',
      '${s.nom} a vendu ${quantite.toStringAsFixed(0)} × ${produit.nom} — ${formatMontant(total, monnaie)}',
      NotifType.vente,
      [Role.patron, Role.manager, Role.caissiere],
    );
    _enregistrerSync('ventes', 'upsert', vente.id, vente.toMap());
    final produitMaj = produit.copyWith(quantite: produit.quantite - quantite);
    _enregistrerSync('produits', 'upsert', produitMaj.id, produitMaj.toMap());
    if (produit.quantite - quantite == 0) {
      _pousserNotification(
        'Rupture de stock',
        '${produit.nom} est épuisé (0 en stock).',
        NotifType.stock,
        [Role.patron, Role.manager, Role.caissiere],
      );
    }
    _journaliser(NotifType.vente,
        'Vente de ${quantite.toStringAsFixed(0)} × ${produit.nom} pour ${formatMontant(total, monnaie)}');
    _compterSync();
    notifier('Vente enregistrée · ${formatMontant(total, monnaie)}');
    return null;
  }

  String? signalerDefectueux(String produitId, String description) {
    final s = session;
    if (s == null) return 'Session expirée.';
    Produit? produit;
    for (final p in _produits) {
      if (p.id == produitId) {
        produit = p;
        break;
      }
    }
    if (produit == null) return 'Produit introuvable.';
    if (description.trim().isEmpty) return 'La description du problème est obligatoire.';
    if (produit.quantite < 1) return 'Aucune pièce en stock pour ce produit.';
    _produits = [
      for (final p in _produits)
        if (p.id == produitId) p.copyWith(quantite: p.quantite - 1) else p,
    ];
    _persistProduits();
    _enregistrerSync('produits', 'upsert', produitId,
        produit.copyWith(quantite: produit.quantite - 1).toMap());
    _retours = [
      Retour(
        id: _uid(),
        produitId: produit.id,
        produitNom: produit.nom,
        motif: MotifRetour.defectueux,
        description: description,
        montant: 0,
        auteurNom: s.nom,
        statut: StatutRetour.enAttente,
        date: _maintenantIso(),
      ),
      ..._retours,
    ];
    _persistRetours();
    _enregistrerSync('retours', 'upsert', _retours.first.id, _retours.first.toMap());
    _pousserNotification(
      'Produit défectueux signalé',
      '${produit.nom} — $description',
      NotifType.retour,
      [Role.patron, Role.manager],
    );
    _journaliser(NotifType.retour, 'Produit défectueux : ${produit.nom}');
    _compterSync();
    notifier('Article défectueux signalé');
    return null;
  }

  String? signalerRetour(
    String produitId,
    MotifRetour motif,
    String description,
    double montant,
  ) {
    final s = session;
    if (s == null) return 'Session expirée.';
    Produit? produit;
    for (final p in _produits) {
      if (p.id == produitId) {
        produit = p;
        break;
      }
    }
    if (produit == null) return 'Produit introuvable.';
    if (description.trim().isEmpty) return 'La description est obligatoire.';
    final b = _boutique;
    if (motif == MotifRetour.remboursement) {
      if (montant <= 0) return 'Le montant remboursé doit être supérieur à 0.';
      if (b == null || montant > b.soldeCaisse) {
        return 'Solde de caisse insuffisant : la caisse ne peut pas être négative.';
      }
    }
    _produits = [
      for (final p in _produits)
        if (p.id == produitId) p.copyWith(quantite: p.quantite + 1) else p,
    ];
    _persistProduits();
    _enregistrerSync('produits', 'upsert', produitId,
        produit.copyWith(quantite: produit.quantite + 1).toMap());
    if (motif == MotifRetour.remboursement) _majCaisse(-montant);
    _retours = [
      Retour(
        id: _uid(),
        produitId: produit.id,
        produitNom: produit.nom,
        motif: motif,
        description: description,
        montant: motif == MotifRetour.remboursement ? montant : 0,
        auteurNom: s.nom,
        statut: StatutRetour.enAttente,
        date: _maintenantIso(),
      ),
      ..._retours,
    ];
    _persistRetours();
    _enregistrerSync('retours', 'upsert', _retours.first.id, _retours.first.toMap());
    _pousserNotification(
      'Retour produit signalé',
      '${produit.nom} — ${motif == MotifRetour.remboursement ? 'remboursement' : 'échange'}',
      NotifType.retour,
      [Role.patron],
    );
    _journaliser(NotifType.retour, 'Retour ${motif == MotifRetour.remboursement ? 'remboursement' : 'échange'} : ${produit.nom}');
    _compterSync();
    notifier('Retour enregistré');
    return null;
  }

  String? enregistrerDepense(String description, double montant, TypeDepense type) {
    final s = session;
    if (s == null) return 'Session expirée.';
    if (description.trim().isEmpty) return 'Le motif est obligatoire.';
    if (montant <= 0) return 'Le montant doit être supérieur à 0.';
    final b = _boutique;
    if (b == null || montant > b.soldeCaisse) {
      return 'Solde de caisse insuffisant : la caisse ne peut pas être négative.';
    }
    _depenses = [
      Depense(
        id: _uid(),
        description: description,
        montant: montant,
        auteurNom: s.nom,
        auteurRole: s.role,
        type: type,
        date: _maintenantIso(),
      ),
      ..._depenses,
    ];
    _persistDepenses();
    _enregistrerSync('depenses', 'upsert', _depenses.first.id, _depenses.first.toMap());
    _majCaisse(-montant);
    _pousserNotification(
      type == TypeDepense.depense ? 'Dépense enregistrée' : 'Diminution de caisse justifiée',
      '$description — ${formatMontant(montant, monnaie)} par ${s.nom}',
      NotifType.depense,
      type == TypeDepense.depense
          ? [Role.patron, Role.manager, Role.caissiere]
          : [Role.patron, Role.manager],
    );
    _journaliser(NotifType.depense, '$description — ${formatMontant(montant, monnaie)}');
    _compterSync();
    notifier(type == TypeDepense.depense ? 'Dépense enregistrée' : 'Sortie de caisse justifiée');
    return null;
  }

  void ajouterProduit({
    required String nom,
    required double prixAchat,
    required double prixVente,
    required double quantite,
    List<String> images = const [],
    String categorie = 'autre',
  }) {
    final id = _uid();
    final p = Produit(
      id: id,
      nom: nom,
      prixAchat: prixAchat,
      prixVente: prixVente,
      quantite: quantite,
      actif: true,
      images: images,
      categorie: categorie,
      dateAjout: DateTime.now(),
      qrCodeData: QrCodeService.genererDataProduit(
        produitId: id,
        nom: nom,
        prixVente: prixVente,
        categorie: categorie,
      ),
    );
    _produits = [p, ..._produits];
    _persistProduits();
    _enregistrerSync('produits', 'upsert', p.id, p.toMap());
    _pousserNotification(
      'Nouveau produit ajouté',
      '${p.nom} — ${quantite.toStringAsFixed(0)} pièces',
      NotifType.produit,
      [Role.patron, Role.manager, Role.caissiere],
    );
    _journaliser(NotifType.produit, 'Produit ajouté : ${p.nom} (${quantite.toStringAsFixed(0)} pièces)');
    _compterSync();
    notifier('Produit ajouté au stock');
  }

  void modifierProduit(String id, {
    required String nom,
    required double prixAchat,
    required double prixVente,
    required double quantite,
    List<String>? images,
    String? categorie,
  }) {
    final existing = _produits.firstWhere((x) => x.id == id);
    _produits = [
      for (final x in _produits)
        if (x.id == id)
          x.copyWith(
            nom: nom,
            prixAchat: prixAchat,
            prixVente: prixVente,
            quantite: quantite,
            images: images,
            categorie: categorie,
            // Régénéré à chaque modification : l'id, le nom et le prix du QR
            // restent ainsi cohérents avec le produit (y anciens QR fautifs).
            qrCodeData: QrCodeService.genererDataProduit(
              produitId: id,
              nom: nom,
              prixVente: prixVente,
              categorie: categorie ?? existing.categorie,
            ),
          )
        else
          x,
    ];
    _persistProduits();
    final maj = _produits.firstWhere((x) => x.id == id);
    _enregistrerSync('produits', 'upsert', id, maj.toMap());
    _journaliser(NotifType.produit, 'Produit modifié : $nom');
    _compterSync();
    notifier('Produit mis à jour');
  }

  void supprimerProduit(String id) {
    String nom = '';
    for (final p in _produits) {
      if (p.id == id) nom = p.nom;
    }
    _produits = [
      for (final x in _produits) if (x.id == id) x.copyWith(actif: false) else x,
    ];
    _persistProduits();
    _enregistrerSync(
        'produits', 'upsert', id, _produits.firstWhere((x) => x.id == id).toMap());
    _journaliser(NotifType.produit, 'Produit supprimé : $nom');
    notifier('Produit retiré du stock actif — historique conservé', TonToast.info);
  }

  void traiterRetour(String id, StatutRetour statut) {
    _retours = [
      for (final r in _retours) if (r.id == id) r.copyWith(statut: statut) else r,
    ];
    _persistRetours();
    _enregistrerSync('retours', 'upsert', id, _retours.firstWhere((r) => r.id == id).toMap());
    _journaliser(NotifType.retour, 'Retour ${statut == StatutRetour.traite ? 'traité' : 'refusé'}');
    notifier(
      statut == StatutRetour.traite ? 'Retour marqué comme traité' : 'Retour refusé',
      TonToast.info,
    );
  }

  String? pointer(String sens) {
    final s = session;
    if (s == null) return 'Session expirée.';
    final jour = cleJour(DateTime.now());
    final heureNow = heureLocale(DateTime.now());
    Pointage? existant;
    for (final p in _pointages) {
      if (p.employeId == s.id && p.date == jour) {
        existant = p;
        break;
      }
    }
    if (sens == 'arrivee') {
      if (existant != null) return "Vous avez déjà pointé votre arrivée aujourd'hui.";
      _pointages = [
        Pointage(
          id: _uid(),
          employeId: s.id,
          employeNom: s.nom,
          role: s.role,
          date: jour,
          heureArrivee: heureNow,
          heureDepart: null,
        ),
        ..._pointages,
      ];
      _persistPointages();
      _enregistrerSync('pointages', 'upsert', _pointages.first.id, _pointages.first.toMap());
    } else {
      if (existant == null) return "Pointez d'abord votre arrivée.";
      if (existant.heureDepart != null) return 'Départ déjà pointé.';
      _pointages = [
        for (final p in _pointages)
          if (p.id == existant.id) p.copyWith(heureDepart: heureNow) else p,
      ];
      _persistPointages();
      final maj = _pointages.firstWhere((p) => p.id == existant!.id);
      _enregistrerSync('pointages', 'upsert', maj.id, maj.toMap());
    }
    _pousserNotification(
      'Pointage',
      '${s.nom} a pointé son ${sens == 'arrivee' ? 'arrivée' : 'départ'} à $heureNow.',
      NotifType.pointage,
      [Role.patron],
    );
    _journaliser(NotifType.pointage, 'Pointage $sens à $heureNow');
    notifier('Pointage ${sens == 'arrivee' ? "d'arrivée" : 'de départ'} enregistré · $heureNow');
    return null;
  }

  void marquerNotificationsLues() {
    final s = session;
    if (s == null) return;
    _notifications = [
      for (final n in _notifications)
        if (n.destinataires.contains(s.role)) n.copyWith(estLu: true) else n,
    ];
    _persistNotifications();
    for (final n in _notifications.where((n) => n.destinataires.contains(s.role))) {
      _enregistrerSync('notifications', 'upsert', n.id, n.toMap());
    }
    notifyListeners();
  }

  // ---------- Comptes ----------

  void creerEmploye(String nom, Role role, String motDePasse, List<Permission> permissions) {
    final employe = Employe(
      id: _uid(),
      nom: nom,
      role: role,
      permissions: permissions.isNotEmpty ? permissions : permissionsParDefaut(role),
      motDePasse: motDePasse,
      statut: StatutEmploye.actif,
      pinActif: false,
      pin: '',
      biometrie: false,
      dateCreation: _maintenantIso(),
    );
    _employes = [..._employes, employe];
    _persistEmployes();
    _enregistrerSync('employes', 'upsert', employe.id, employe.toMap());
    _pousserNotification('Compte créé', '$nom — ${role.label}', NotifType.compte, [Role.patron]);
    _journaliser(NotifType.compte,
        'Compte créé : $nom (${role.label}) avec ${employe.permissions.length} droits');
    notifier('Compte employé créé');
  }

  void modifierEmploye(String id, {required String nom, required Role role, required List<Permission> permissions}) {
    _employes = [
      for (final e in _employes)
        if (e.id == id)
          e.copyWith(nom: nom, role: role, permissions: permissions)
        else
          e,
    ];
    _persistEmployes();
    _enregistrerSync('employes', 'upsert', id, _employes.firstWhere((e) => e.id == id).toMap());
    _journaliser(NotifType.compte, 'Droits mis à jour : $nom (${role.label})');
    notifier('Rôle et permissions enregistrés');
  }

  void basculerStatutEmploye(String id) {
    Employe? cible;
    for (final e in _employes) {
      if (e.id == id) cible = e;
    }
    if (cible == null) return;
    final suspendu = cible.statut == StatutEmploye.actif;
    _employes = [
      for (final e in _employes)
        if (e.id == id)
          e.copyWith(statut: suspendu ? StatutEmploye.suspendu : StatutEmploye.actif)
        else
          e,
    ];
    _persistEmployes();
    _enregistrerSync('employes', 'upsert', id, _employes.firstWhere((e) => e.id == id).toMap());
    _journaliser(NotifType.compte, 'Compte ${suspendu ? 'suspendu' : 'réactivé'} : ${cible.nom}');
    notifier(suspendu ? 'Compte suspendu' : 'Compte réactivé', TonToast.info);
  }

  void supprimerEmploye(String id) {
    Employe? cible;
    for (final e in _employes) {
      if (e.id == id) cible = e;
    }
    _employes = _employes.where((e) => e.id != id).toList();
    _persistEmployes();
    _enregistrerSync('employes', 'delete', id, {});
    if (_sessionId == id) {
      _sessionId = null;
      _verrouille = false;
      _db.setSetting('session_id', '');
    }
    _journaliser(NotifType.compte, 'Compte supprimé : ${cible?.nom ?? ''}');
    notifier('Compte supprimé', TonToast.info);
  }

Future<void> supprimerBoutique() async {
    final patron = session;
    if (patron == null) return;

    // Suppression Supabase
    await SuperadminService.instance!.supprimerBoutique(_boutique!.id);

    // Suppression locale SQLite - supprimer toutes les tables liées
    final tables = [
      'employes', 'produits', 'ventes', 'dépenses', 'pointages',
      'retours', 'notifications', 'activités', 'appareils'
    ];
    for (final table in tables) {
      await _db.supprimer(table, '', boutiqueId: _boutique!.id);
    }
    // Supprimer la boutique elle-même
    await _db.supprimer('boutiques', _boutique!.id);

    // Reset session
    _sessionId = null;
    _verrouille = false;
    _db.setSetting('session_id', '');
    _persistEmployes();
    _enregistrerSync('employes', 'upsert', '', {});
    _journaliser(NotifType.compte, 'Boutique supprimée');
  }
  void reinitialiserMotDePasse(String id, String motDePasse) {
    _employes = [
      for (final e in _employes)
        if (e.id == id) e.copyWith(motDePasse: motDePasse) else e,
    ];
    _persistEmployes();
    _enregistrerSync('employes', 'upsert', id, _employes.firstWhere((e) => e.id == id).toMap());
    notifier('Mot de passe réinitialisé');
  }

  void definirPin(String? pin) {
    final s = session;
    if (s == null) return;
    final maj = s.copyWith(pinActif: pin != null, pin: pin ?? s.pin);
    _employes = [
      for (final e in _employes) if (e.id == s.id) maj else e,
    ];
    _persistEmployes();
    _enregistrerSync('employes', 'upsert', s.id, maj.toMap());
    notifier(pin != null ? 'Code PIN enregistré' : 'Code PIN désactivé',
        pin != null ? TonToast.succes : TonToast.info);
  }

  Future<bool> verifierBiometrie() async {
    final s = session;
    if (s == null || s.pin.isEmpty) return false;
    final result = await BiometricService.instance.authenticate(
      reason: 'Déverrouiller ${boutique?.nom ?? 'Ma Boutique'}',
      biometricOnly: false,
    );
    if (result.success) {
      _verrouille = false;
      notifyListeners();
      return true;
    } else if (result.error != null) {
      notifier(result.error!, TonToast.erreur);
    }
    return false;
  }

  Future<void> basculerBiometrie() async {
    final s = session;
    if (s == null) return;

    if (!s.biometrie) {
      final available = await BiometricService.instance.isAvailable;
      if (!available) {
        notifier('Biométrie non disponible sur cet appareil', TonToast.erreur);
        return;
      }
      final types = await BiometricService.instance.availableBiometrics;
      if (types.isEmpty) {
        notifier('Aucune biométrie configurée dans les paramètres du téléphone', TonToast.erreur);
        return;
      }
      final test = await BiometricService.instance.authenticate(
        reason: 'Activer la biométrie pour ${boutique?.nom ?? 'Ma Boutique'}',
        biometricOnly: false,
      );
      if (!test.success) {
        if (test.error != null) notifier(test.error!, TonToast.erreur);
        return;
      }
    }

    final maj = s.copyWith(biometrie: !s.biometrie);
    _employes = [
      for (final e in _employes) if (e.id == s.id) maj else e,
    ];
    _persistEmployes();
    _enregistrerSync('employes', 'upsert', s.id, maj.toMap());
    notifier(maj.biometrie ? 'Biométrie activée' : 'Biométrie désactivée', TonToast.info);
  }

  void revoquerAppareil(String id) {
    Appareil? cible;
    for (final a in _appareils) {
      if (a.id == id) cible = a;
    }
    if (cible == null) return;
    _appareils = [
      for (final a in _appareils) if (a.id == id) a.copyWith(actif: !a.actif) else a,
    ];
    _persistAppareils();
    _enregistrerSync('appareils', 'upsert', id, _appareils.firstWhere((a) => a.id == id).toMap());
    _journaliser(NotifType.compte,
        'Appareil ${cible.actif ? 'révoqué' : 'autorisé'} : ${cible.nomAppareil}');
    notifier(cible.actif ? 'Appareil révoqué et déconnecté' : 'Appareil autorisé', TonToast.info);
  }
}