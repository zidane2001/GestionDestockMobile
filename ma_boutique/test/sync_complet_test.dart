import 'package:flutter_test/flutter_test.dart';
import 'package:ma_boutique/services/sync_service.dart';

void main() {
  group('versSupabase mapping', () {
    test('convertit boutique en snake_case', () {
      final local = {
        'id': 'b1', 'nom': 'Ma boutique', 'monnaie': 'FCFA',
        'soldeCaisse': 50000, 'notificationAbonnement': 1,
      };
      final result = versSupabase('boutiques', local, 'b1');
      expect(result['nom'], 'Ma boutique');
      // La caisse est tenue par les triggers serveur (vente/dépense) : le
      // client ne l'écrit jamais, sinon il pourrait la falsifier.
      expect(result.containsKey('solde_caisse'), isFalse);
      expect(result['notification_abonnement'], true);
      expect(result.containsKey('boutique_id'), isFalse, reason: 'boutiques table n\'a pas de boutique_id');
    });

    test('convertit employes en snake_case', () {
      final local = {
        'id': 'e1', 'nom': 'Ali', 'role': 'patron',
        'pinActif': 1, 'biometrie': 0,
      };
      final result = versSupabase('employes', local, 'b1');
      expect(result['boutique_id'], 'b1');
      expect(result['nom'], 'Ali');
      expect(result['role'], 'patron');
      expect(result['pin_actif'], true);
      expect(result['biometrie'], false);
    });

    test('convertit produits en snake_case', () {
      final local = {
        'id': 'p1', 'nom': 'Chemise', 'prixAchat': 3000,
        'prixVente': 5000, 'quantite': 10, 'actif': 1,
      };
      final result = versSupabase('produits', local, 'b1');
      expect(result['boutique_id'], 'b1');
      expect(result['prix_achat'], 3000);
      expect(result['prix_vente'], 5000);
      expect(result['actif'], true);
    });

    test('convertit ventes en snake_case', () {
      final local = {
        'id': 'v1', 'produitId': 'p1', 'produitNom': 'A',
        'quantite': 2, 'prixUnitaireReel': 5000,
        'prixAchatUnitaire': 3000, 'total': 10000,
        'vendeurId': 'e1', 'vendeurNom': 'Ali',
        'vendeurRole': 'caissiere', 'date': '2026-08-22',
      };
      final result = versSupabase('ventes', local, 'b1');
      expect(result['boutique_id'], 'b1');
      expect(result['produit_id'], 'p1');
      expect(result['prix_unitaire_reel'], 5000);
      expect(result['vendeur_id'], 'e1');
    });

    test('convertit depenses en snake_case', () {
      final local = {
        'id': 'd1', 'description': 'Loyer', 'montant': 50000,
        'auteurNom': 'Ali', 'auteurRole': 'patron',
        'type': 'depense', 'date': '2026-08-22',
      };
      final result = versSupabase('depenses', local, 'b1');
      expect(result['boutique_id'], 'b1');
      expect(result['auteur_nom'], 'Ali');
      expect(result['auteur_role'], 'patron');
    });

    test('convertit retours en snake_case', () {
      final local = {
        'id': 'r1', 'produitId': 'p1', 'produitNom': 'A',
        'motif': 'defaut', 'description': 'x', 'montant': 5000,
        'auteurNom': 'Ali', 'statut': 'enAttente', 'date': '2026-08-22',
      };
      final result = versSupabase('retours', local, 'b1');
      expect(result['boutique_id'], 'b1');
      expect(result['produit_id'], 'p1');
      expect(result['auteur_nom'], 'Ali');
    });

    test('convertit notifications en snake_case', () {
      final local = {
        'id': 'n1', 'destinataires': 'patron,manager',
        'titre': 'Alerte', 'message': 'Stock bas',
        'type': 'stock', 'estLu': 0, 'date': '2026-08-22',
      };
      final result = versSupabase('notifications', local, 'b1');
      expect(result['boutique_id'], 'b1');
      expect(result['est_lu'], false);
    });

    test('convertit pointages en snake_case', () {
      final local = {
        'id': 'pt1', 'employeId': 'e1', 'employeNom': 'Ali',
        'role': 'patron', 'date': '2026-08-22',
        'heureArrivee': '08:00', 'heureDepart': '17:00',
      };
      final result = versSupabase('pointages', local, 'b1');
      expect(result['boutique_id'], 'b1');
      expect(result['employe_id'], 'e1');
      expect(result['heure_arrivee'], '08:00');
      expect(result['heure_depart'], '17:00');
    });

    test('convertit activites en snake_case', () {
      final local = {
        'id': 'a1', 'employeNom': 'Ali', 'employeRole': 'patron',
        'type': 'vente', 'description': 'Vente A', 'date': '2026-08-22',
      };
      final result = versSupabase('activites', local, 'b1');
      expect(result['boutique_id'], 'b1');
      expect(result['employe_nom'], 'Ali');
      expect(result['employe_role'], 'patron');
    });

    test('convertit appareils en snake_case', () {
      final local = {
        'id': 'app1', 'employeNom': 'Ali', 'role': 'patron',
        'nomAppareil': 'Galaxy S24', 'derniereConnexion': '2026-08-22',
        'actif': 1,
      };
      final result = versSupabase('appareils', local, 'b1');
      expect(result['boutique_id'], 'b1');
      expect(result['nom_appareil'], 'Galaxy S24');
      expect(result['derniere_connexion'], '2026-08-22');
      expect(result['actif'], true);
    });

    test('ajoute maj_ts', () {
      final result = versSupabase('boutiques', {'id': 'b1'}, 'b1');
      expect(result.containsKey('maj_ts'), isTrue);
    });

    test('ignore les clés inconnues', () {
      final result = versSupabase('boutiques', {'id': 'b1', 'trucInconnu': 'val'}, 'b1');
      expect(result.containsKey('trucInconnu'), isFalse);
    });
  });

  group('versLocal mapping', () {
    test('convertit boutiques en camelCase', () {
      final supabase = {
        'id': 'b1', 'nom': 'Ma boutique', 'solde_caisse': 50000,
        'notification_abonnement': true, 'maj_ts': '2026-08-22',
      };
      final result = versLocal('boutiques', supabase);
      expect(result['soldeCaisse'], 50000);
      expect(result['notificationAbonnement'], 1);
      expect(result.containsKey('maj_ts'), isFalse);
    });

    test('convertit employes en camelCase', () {
      final supabase = {
        'id': 'e1', 'nom': 'Ali', 'pin_actif': true,
        'biometrie': false, 'boutique_id': 'b1',
      };
      final result = versLocal('employes', supabase);
      expect(result['pinActif'], 1);
      expect(result['biometrie'], 0);
      expect(result.containsKey('boutique_id'), isFalse);
    });

    test('convertit produits en camelCase', () {
      final supabase = {
        'id': 'p1', 'prix_achat': 3000, 'prix_vente': 5000,
        'actif': true, 'boutique_id': 'b1',
      };
      final result = versLocal('produits', supabase);
      expect(result['prixAchat'], 3000);
      expect(result['prixVente'], 5000);
      expect(result['actif'], 1);
    });

    test('convertit notifications en camelCase', () {
      final supabase = {
        'id': 'n1', 'est_lu': true, 'boutique_id': 'b1',
      };
      final result = versLocal('notifications', supabase);
      expect(result['estLu'], 1);
    });

    test('supprime boutique_id et maj_ts', () {
      final result = versLocal('boutiques', {'id': 'x', 'boutique_id': 'b1', 'maj_ts': 't'});
      expect(result.containsKey('boutique_id'), isFalse);
      expect(result.containsKey('maj_ts'), isFalse);
    });

    test('ignore les clés inconnues', () {
      final result = versLocal('boutiques', {'id': 'b1', 'truc_inconnu': 'val'});
      expect(result.containsKey('truc_inconnu'), isFalse);
    });
  });

  group('mapping roundtrip', () {
    test('9 tables avec boutique_id (hors boutiques)', () {
      final tablesSansBoutique = ['employes', 'produits', 'ventes', 'depenses', 'retours', 'notifications', 'pointages', 'activites', 'appareils'];
      for (final table in tablesSansBoutique) {
        final result = versSupabase(table, {'id': '1'}, 'b1');
        expect(result.containsKey('boutique_id'), isTrue, reason: 'Table $table doit avoir boutique_id');
      }
    });

    test('table boutiques sans boutique_id', () {
      final result = versSupabase('boutiques', {'id': 'b1'}, 'b1');
      expect(result.containsKey('boutique_id'), isFalse);
    });

    test('versSupabase puis versLocal préserve les données booléennes (produits)', () {
      final local = {'id': 'e1', 'nom': 'Ali', 'actif': 1};
      final supa = versSupabase('produits', local, 'b1');
      expect(supa['actif'], true);
      final back = versLocal('produits', supa);
      expect(back['actif'], 1);
    });

    test('versSupabase puis versLocal préserve les données booléennes (employes)', () {
      final local = {'id': 'e1', 'nom': 'Ali', 'pinActif': 1, 'biometrie': 0};
      final supa = versSupabase('employes', local, 'b1');
      expect(supa['pin_actif'], true);
      expect(supa['biometrie'], false);
      final back = versLocal('employes', supa);
      expect(back['pinActif'], 1);
      expect(back['biometrie'], 0);
    });
  });
}
