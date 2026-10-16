import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
return openDatabase(
      join(dbPath, 'ma_boutique.db'),
      version: 9,
      onCreate: (db, version) async {
        await _creerTables(db);
      },
      onUpgrade: (db, ancien, nouveau) async {
        if (ancien < 8) {
          // Migration v8: Add boutique_id to sync_queue (missed in v7)
          try {
            await db.execute('ALTER TABLE sync_queue ADD COLUMN boutique_id TEXT');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_boutique ON sync_queue(boutique_id)');
          } catch (_) {}
          // Migrate existing sync_queue data to first boutique
          final boutiques = await db.query('boutiques', limit: 1);
          if (boutiques.isNotEmpty) {
            final firstBoutiqueId = boutiques.first['id'] as String;
            try {
              await db.execute('UPDATE sync_queue SET boutique_id = ? WHERE boutique_id IS NULL', [firstBoutiqueId]);
            } catch (_) {}
          }
        }
        if (ancien < 7) {
          // Migration v7: Add boutique_id to all tables for multi-boutique isolation
          final tablesWithBoutiqueId = [
            'employes',
            'produits',
            'ventes',
            'depenses',
            'retours',
            'notifications',
            'pointages',
            'activites',
            'appareils',
            'sync_queue',
          ];
          for (final table in tablesWithBoutiqueId) {
            try {
              await db.execute('ALTER TABLE $table ADD COLUMN boutique_id TEXT');
              await db.execute('CREATE INDEX IF NOT EXISTS idx_${table}_boutique ON $table(boutique_id)');
            } catch (_) {}
          }
          // Migrate existing data to first boutique
          final boutiques = await db.query('boutiques', limit: 1);
          if (boutiques.isNotEmpty) {
            final firstBoutiqueId = boutiques.first['id'] as String;
            for (final table in tablesWithBoutiqueId) {
              try {
                await db.execute('UPDATE $table SET boutique_id = ? WHERE boutique_id IS NULL', [firstBoutiqueId]);
              } catch (_) {}
            }
          }
        }
        if (ancien < 6) {
          await db.execute('ALTER TABLE produits ADD COLUMN qrCodeData TEXT');
        }
        if (ancien < 5) {
          for (final t in [
            'products',
            'expenses',
            'notifications',
            'settings',
            'boutiques',
            'employes',
            'produits',
            'ventes',
            'depenses',
            'retours',
            'pointages',
            'activites',
            'appareils',
            'sync_queue',
          ]) {
            await db.execute('DROP TABLE IF EXISTS $t');
          }
          await _creerTables(db);
        }
      },
    );
  }

  Future<void> _creerTables(Database db) async {
    await db.execute('''
      CREATE TABLE boutiques(
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        styleCommerce TEXT NOT NULL DEFAULT '',
        monnaie TEXT NOT NULL DEFAULT 'FCFA',
        emailPatron TEXT NOT NULL DEFAULT '',
        logoUrl TEXT,
        soldeCaisse REAL NOT NULL DEFAULT 0,
        statut TEXT NOT NULL DEFAULT 'active',
        abonnementMode TEXT NOT NULL DEFAULT 'achat_direct',
        abonnementDebut TEXT,
        abonnementFin TEXT,
        notificationAbonnement INTEGER NOT NULL DEFAULT 0,
        methodePaiement TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE employes(
        id TEXT PRIMARY KEY,
        boutique_id TEXT NOT NULL,
        nom TEXT NOT NULL,
        role TEXT NOT NULL,
        permissions TEXT NOT NULL DEFAULT '',
        motDePasse TEXT NOT NULL,
        statut TEXT NOT NULL DEFAULT 'actif',
        pinActif INTEGER NOT NULL DEFAULT 0,
        pin TEXT NOT NULL DEFAULT '',
        biometrie INTEGER NOT NULL DEFAULT 0,
        dateCreation TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_employes_boutique ON employes(boutique_id)');
    await db.execute('''
      CREATE TABLE produits(
        id TEXT PRIMARY KEY,
        boutique_id TEXT NOT NULL,
        nom TEXT NOT NULL,
        prixAchat REAL NOT NULL,
        prixVente REAL NOT NULL,
        quantite REAL NOT NULL DEFAULT 0,
        actif INTEGER NOT NULL DEFAULT 1,
        images TEXT NOT NULL DEFAULT '',
        categorie TEXT NOT NULL DEFAULT 'autre',
        dateAjout TEXT,
        qrCodeData TEXT
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_produits_boutique ON produits(boutique_id)');
    await db.execute('''
      CREATE TABLE ventes(
        id TEXT PRIMARY KEY,
        boutique_id TEXT NOT NULL,
        produitId TEXT NOT NULL,
        produitNom TEXT NOT NULL,
        quantite REAL NOT NULL,
        prixUnitaireReel REAL NOT NULL,
        prixAchatUnitaire REAL NOT NULL,
        total REAL NOT NULL,
        vendeurId TEXT NOT NULL,
        vendeurNom TEXT NOT NULL,
        vendeurRole TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ventes_boutique ON ventes(boutique_id)');
    await db.execute('''
      CREATE TABLE depenses(
        id TEXT PRIMARY KEY,
        boutique_id TEXT NOT NULL,
        description TEXT NOT NULL,
        montant REAL NOT NULL,
        auteurNom TEXT NOT NULL,
        auteurRole TEXT NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_depenses_boutique ON depenses(boutique_id)');
    await db.execute('''
      CREATE TABLE retours(
        id TEXT PRIMARY KEY,
        boutique_id TEXT NOT NULL,
        produitId TEXT NOT NULL,
        produitNom TEXT NOT NULL,
        motif TEXT NOT NULL,
        description TEXT NOT NULL,
        montant REAL NOT NULL DEFAULT 0,
        auteurNom TEXT NOT NULL,
        statut TEXT NOT NULL DEFAULT 'en_attente',
        date TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_retours_boutique ON retours(boutique_id)');
    await db.execute('''
      CREATE TABLE notifications(
        id TEXT PRIMARY KEY,
        boutique_id TEXT NOT NULL,
        destinataires TEXT NOT NULL,
        titre TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        estLu INTEGER NOT NULL DEFAULT 0,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_boutique ON notifications(boutique_id)');
    await db.execute('''
      CREATE TABLE pointages(
        id TEXT PRIMARY KEY,
        boutique_id TEXT NOT NULL,
        employeId TEXT NOT NULL,
        employeNom TEXT NOT NULL,
        role TEXT NOT NULL,
        date TEXT NOT NULL,
        heureArrivee TEXT NOT NULL,
        heureDepart TEXT
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pointages_boutique ON pointages(boutique_id)');
    await db.execute('''
      CREATE TABLE activites(
        id TEXT PRIMARY KEY,
        boutique_id TEXT NOT NULL,
        employeNom TEXT NOT NULL,
        employeRole TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_activites_boutique ON activites(boutique_id)');
    await db.execute('''
      CREATE TABLE appareils(
        id TEXT PRIMARY KEY,
        boutique_id TEXT NOT NULL,
        employeNom TEXT NOT NULL,
        role TEXT NOT NULL,
        nomAppareil TEXT NOT NULL,
        derniereConnexion TEXT NOT NULL,
        actif INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_appareils_boutique ON appareils(boutique_id)');
    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_queue(
        id TEXT PRIMARY KEY,
        boutique_id TEXT NOT NULL,
        tableName TEXT NOT NULL,
        action TEXT NOT NULL,
        rowId TEXT NOT NULL,
        data TEXT NOT NULL,
        dateMaj TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_boutique ON sync_queue(boutique_id)');
  }

  // ---------- Génériques ----------

  Future<void> inserer(String table, Map<String, Object?> donnees, {String? boutiqueId}) async {
    final db = await database;
    if (boutiqueId != null && !donnees.containsKey('boutique_id')) {
      donnees['boutique_id'] = boutiqueId;
    }
    await db.insert(table, donnees, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> remplacer(String table, Map<String, Object?> donnees, String id, {String? boutiqueId}) async {
    final db = await database;
    if (boutiqueId != null && !donnees.containsKey('boutique_id')) {
      donnees['boutique_id'] = boutiqueId;
    }
    await db.insert(table, donnees, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> majId(String table, Map<String, Object?> donnees, String id, {String? boutiqueId}) async {
    final db = await database;
    await db.update(table, donnees, where: 'id = ? AND boutique_id = ?', whereArgs: [id, boutiqueId]);
  }

  Future<void> supprimer(String table, String id, {String? boutiqueId}) async {
    final db = await database;
    await db.delete(table, where: 'id = ? AND boutique_id = ?', whereArgs: [id, boutiqueId]);
  }

  Future<List<Map<String, Object?>>> toutes(String table, {String? ordre, String? boutiqueId}) async {
    final db = await database;
    if (boutiqueId != null) {
      return db.query(table, where: 'boutique_id = ?', whereArgs: [boutiqueId], orderBy: ordre);
    }
    return db.query(table, orderBy: ordre);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insererSyncQueue(String table, String action, String rowId, Map<String, Object?> data, {required String boutiqueId}) async {
    final db = await database;
    await db.insert('sync_queue', {
      'id': '${DateTime.now().microsecondsSinceEpoch}',
      'boutique_id': boutiqueId,
      'tableName': table,
      'action': action,
      'rowId': rowId,
      'data': data.isEmpty ? '' : jsonEncode(data),
      'dateMaj': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> listeSyncQueue({required String boutiqueId}) async {
    final db = await database;
    return db.query('sync_queue', where: 'boutique_id = ?', whereArgs: [boutiqueId], orderBy: 'dateMaj ASC');
  }

  Future<void> supprimerSyncQueue(String id, {required String boutiqueId}) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ? AND boutique_id = ?', whereArgs: [id, boutiqueId]);
  }
}