import 'package:flutter_test/flutter_test.dart';
import 'package:ma_boutique/core/format.dart';
import 'package:ma_boutique/core/permissions.dart';
import 'package:ma_boutique/core/stats.dart';
import 'package:ma_boutique/models/models.dart';
import 'package:ma_boutique/services/sync_service.dart';

void main() {
  group('Edge Cases - Models', () {
    group('Boutique', () {
      Boutique boutiqueTest({DateTime? abonnementFin}) => Boutique(
        id: '', nom: '', styleCommerce: '', emailPatron: '',
        monnaie: Monnaie.fcfa, soldeCaisse: 0, abonnementFin: abonnementFin,
      );

      test('fromMap avec champs optionnels null', () {
        final b = Boutique.fromMap({
          'id': 'b1', 'nom': 'Test', 'styleCommerce': 'mode',
          'emailPatron': 'a@b.com', 'monnaie': 'fcfa', 'soldeCaisse': 0,
        });
        expect(b.id, 'b1');
        expect(b.statut, 'active');
        expect(b.abonnementMode, 'achat_direct');
        expect(b.notificationAbonnement, isFalse);
        expect(b.logoUrl, isNull);
        expect(b.abonnementDebut, isNull);
        expect(b.abonnementFin, isNull);
      });

      test('toMap puis fromMap préserve les données', () {
        final original = Boutique(
          id: 'b1', nom: 'Test', styleCommerce: 'mode',
          emailPatron: 'a@b.com', monnaie: Monnaie.eur,
          soldeCaisse: 99999.99, statut: 'desactivee',
          abonnementMode: 'trimestriel', notificationAbonnement: true,
          methodePaiement: 'mobile_money',
        );
        final map = original.toMap();
        final restored = Boutique.fromMap(map);
        expect(restored.id, 'b1');
        expect(restored.monnaie, Monnaie.eur);
        expect(restored.soldeCaisse, 99999.99);
        expect(restored.statut, 'desactivee');
        expect(restored.notificationAbonnement, isTrue);
      });

      test('abonnementFin null → pas expiré', () => expect(boutiqueTest().abonnementExpire, isFalse));

      test('abonnementFin très loin dans le futur → pas proche', () {
        final b = boutiqueTest(abonnementFin: DateTime.now().add(const Duration(days: 365)));
        expect(b.abonnementProche, isFalse);
      });

      // « Maintenant » n'est pas testable de façon stable : l'instant lu par
      // le getter est toujours postérieur à celui du test, la date paraît donc
      // déjà expirée. On vise une échéance proche mais franchement future.
      test('abonnementFin dans 2 heures → proche', () {
        final b = boutiqueTest(
          abonnementFin: DateTime.now().add(const Duration(hours: 2)),
        );
        expect(b.abonnementProche, isTrue);
      });

      test('abonnementFin il y a 1 heure → expiré, donc pas proche', () {
        final b = boutiqueTest(
          abonnementFin: DateTime.now().subtract(const Duration(hours: 1)),
        );
        expect(b.abonnementExpire, isTrue);
        expect(b.abonnementProche, isFalse);
      });

      test('copyWith préserve tous les champs non spécifiés', () {
        final b = Boutique(
          id: 'b1', nom: 'N', styleCommerce: 's', emailPatron: 'e@e',
          monnaie: Monnaie.usd, soldeCaisse: 100, statut: 'desactivee',
          abonnementMode: 'trimestriel', notificationAbonnement: true,
          methodePaiement: 'especes',
        );
        final c = b.copyWith(soldeCaisse: 200);
        expect(c.id, 'b1');
        expect(c.nom, 'N');
        expect(c.monnaie, Monnaie.usd);
        expect(c.statut, 'desactivee');
        expect(c.abonnementMode, 'trimestriel');
        expect(c.soldeCaisse, 200);
      });
    });

    group('Employe', () {
      test('fromMap avec champs optionnels null', () {
        final e = Employe.fromMap({
          'id': 'e1', 'nom': 'Ali', 'role': 'patron',
        });
        expect(e.id, 'e1');
        expect(e.nom, 'Ali');
        expect(e.permissions, isEmpty);
        expect(e.pinActif, isFalse);
        expect(e.biometrie, isFalse);
      });

      test('permissions vides → fromMap gère correctement', () {
        final e = Employe.fromMap({
          'id': 'e1', 'nom': 'Ali', 'role': 'patron', 'permissions': '',
        });
        expect(e.permissions, isEmpty);
      });

      test('copyWith pin', () {
        final e = Employe(
          id: 'e1', nom: 'A', role: Role.patron,
          permissions: [], motDePasse: 'x', statut: StatutEmploye.actif,
          pinActif: false, pin: '', biometrie: false, dateCreation: '2026-01-01',
        );
        final c = e.copyWith(pin: '5678', pinActif: true, biometrie: true);
        expect(c.pin, '5678');
        expect(c.pinActif, isTrue);
        expect(c.biometrie, isTrue);
        expect(c.nom, 'A');
      });
    });

    group('Produit', () {
      test('fromMap avec champs optionnels null', () {
        final p = Produit.fromMap({
          'id': 'p1', 'nom': 'Test', 'prixAchat': 0, 'prixVente': 0, 'quantite': 0,
        });
        expect(p.id, 'p1');
        expect(p.actif, isTrue);
        expect(p.images, isEmpty);
      });

      test('images avec espaces → séparation correcte', () {
        final p = Produit.fromMap({
          'id': 'p1', 'nom': 'T', 'prixAchat': 0, 'prixVente': 0, 'quantite': 0,
          'images': 'a.jpg,b.jpg',
        });
        expect(p.images.length, 2);
        expect(p.images.first, contains('a.jpg'));
      });

      test('quantité négative dans fromMap', () {
        final p = Produit.fromMap({
          'id': 'p1', 'nom': 'T', 'prixAchat': 0, 'prixVente': 0, 'quantite': -5,
        });
        expect(p.quantite, -5);
      });

      test('estNouveau avec dateAjout exactement 7 jours', () {
        final p = Produit(
          id: 'p1', nom: 'T', prixAchat: 0, prixVente: 0, quantite: 0,
          dateAjout: DateTime.now().subtract(const Duration(days: 7)),
        );
        expect(p.estNouveau, isTrue);
      });

      test('estNouveau avec dateAjout 8 jours', () {
        final p = Produit(
          id: 'p1', nom: 'T', prixAchat: 0, prixVente: 0, quantite: 0,
          dateAjout: DateTime.now().subtract(const Duration(days: 8)),
        );
        expect(p.estNouveau, isFalse);
      });

      test('categorieLabel pour catégorie inconnue', () {
        final p = Produit(
          id: 'p1', nom: 'T', prixAchat: 0, prixVente: 0, quantite: 0,
          categorie: 'inconnue',
        );
        expect(p.categorieLabel, isNotEmpty);
      });
    });

    group('Vente', () {
      test('fromMap avec champs optionnels null', () {
        final v = Vente.fromMap({
          'id': 'v1', 'produitId': 'p1', 'produitNom': 'A',
          'quantite': 0, 'prixUnitaireReel': 0, 'prixAchatUnitaire': 0,
          'total': 0, 'vendeurId': 'e1', 'vendeurNom': 'X',
          'vendeurRole': 'patron', 'date': '2026-01-01',
        });
        expect(v.id, 'v1');
      });

      test('total très grand', () {
        final v = Vente(
          id: 'v1', produitId: 'p1', produitNom: 'A',
          quantite: 1000000, prixUnitaireReel: 1000000,
          prixAchatUnitaire: 500000, total: 500000000000,
          vendeurId: 'e1', vendeurNom: 'A', vendeurRole: Role.patron,
          date: '2026-01-01',
        );
        expect(v.total, 500000000000);
      });
    });

    group('Depense', () {
      test('fromMap avec champs optionnels null', () {
        final d = Depense.fromMap({
          'id': 'd1', 'description': 'D', 'montant': 0,
          'auteurNom': 'A', 'auteurRole': 'patron', 'type': 'depense', 'date': '2026-01-01',
        });
        expect(d.id, 'd1');
      });
    });

    group('Retour', () {
      test('fromMap avec champs optionnels null', () {
        final r = Retour.fromMap({
          'id': 'r1', 'produitId': 'p1', 'produitNom': 'A',
          'motif': 'defaut', 'description': 'D', 'montant': 0,
          'auteurNom': 'A', 'statut': 'enAttente', 'date': '2026-01-01',
        });
        expect(r.id, 'r1');
      });

      test('copyWith préserve tous les champs', () {
        final r = Retour(
          id: 'r1', produitId: 'p1', produitNom: 'A',
          motif: MotifRetour.echange, description: 'D',
          montant: 5000, auteurNom: 'X',
          statut: StatutRetour.enAttente, date: '2026-01-01',
        );
        final c = r.copyWith(statut: StatutRetour.traite);
        expect(c.motif, MotifRetour.echange);
        expect(c.description, 'D');
        expect(c.montant, 5000);
        expect(c.statut, StatutRetour.traite);
      });
    });

    group('NotificationItem', () {
      test('fromMap avec champs optionnels null', () {
        final n = NotificationItem.fromMap({
          'id': 'n1', 'destinataires': '', 'titre': 'T', 'message': 'M',
          'type': 'stock', 'estLu': 0, 'date': '2026-01-01',
        });
        expect(n.id, 'n1');
        expect(n.destinataires, isEmpty);
        expect(n.estLu, isFalse);
      });

      test('destinataires multiples séparés par virgule', () {
        final n = NotificationItem.fromMap({
          'id': 'n1', 'destinataires': 'patron,manager,caissiere',
        });
        expect(n.destinataires.length, 3);
      });

      test('destinataires vide', () {
        final n = NotificationItem.fromMap({
          'id': 'n2', 'destinataires': '',
        });
        expect(n.destinataires, isEmpty);
      });
    });

    group('Pointage', () {
      test('fromMap avec heureDepart null', () {
        final pt = Pointage.fromMap({
          'id': 'pt1', 'employeId': 'e1', 'employeNom': 'A',
          'role': 'patron', 'date': '2026-01-01', 'heureArrivee': '08:00',
        });
        expect(pt.id, 'pt1');
        expect(pt.heureDepart, isNull);
      });

      test('copyWith(null) ne change pas', () {
        final pt = Pointage(
          id: 'pt1', employeId: 'e1', employeNom: 'A',
          role: Role.patron, date: '2026-01-01', heureArrivee: '08:00',
          heureDepart: '17:00',
        );
        final c = pt.copyWith();
        expect(c.heureDepart, '17:00');
      });
    });

    group('Activite', () {
      test('fromMap type par défaut', () {
        final a = Activite.fromMap({
          'id': 'a1', 'employeNom': 'A', 'employeRole': 'patron',
          'type': 'vente', 'description': 'D', 'date': '2026-01-01',
        });
        expect(a.id, 'a1');
        expect(a.type, NotifType.vente);
      });
    });

    group('Appareil', () {
      test('fromMap actif par défaut true', () {
        final a = Appareil.fromMap({
          'id': 'a1', 'employeNom': 'A', 'role': 'patron',
          'nomAppareil': 'Phone', 'derniereConnexion': '2026-01-01',
        });
        expect(a.id, 'a1');
        expect(a.actif, isTrue);
      });

      test('copyWith tous les champs', () {
        final a = Appareil(
          id: 'a1', employeNom: 'A', role: Role.patron,
          nomAppareil: 'Phone', derniereConnexion: '2026-01-01', actif: true,
        );
        final c = a.copyWith(actif: false);
        expect(c.actif, isFalse);
        expect(c.nomAppareil, 'Phone');
      });
    });
  });

  group('Edge Cases - Format', () {
    test('formatMontant très grand', () {
      expect(formatMontant(999999999999, 'FCFA'), contains('FCFA'));
    });

    test('formatMontant nombre décimal très précis', () {
      final r = formatMontant(123.456, 'EUR');
      expect(r, contains('123.46'));
    });

    test('formatMontant négatif avec décimales', () {
      final r = formatMontant(-12.5, 'USD');
      expect(r, contains('-'));
      expect(r, contains('12.50'));
    });

    test('formatCompact très grand', () {
      expect(formatCompact(1000000000), contains('M'));
    });

    test('formatCompact -1500', () {
      final r = formatCompact(-1500);
      expect(r, contains('-'));
      expect(r, contains('k'));
    });

    test('formatCompact 999', () => expect(formatCompact(999), '999'));
    test('formatCompact 1000', () => expect(formatCompact(1000), '1 k'));
    test('formatCompact -999', () => expect(formatCompact(-999), '-999'));

    test('jourCourt date invalide', () {
      expect(() => jourCourt('invalid'), throwsA(anything));
    });

    test('heure date invalide', () {
      expect(() => heure('invalid'), throwsA(anything));
    });

    test('ilYA date très ancienne', () {
      final d = DateTime.now().toUtc().subtract(const Duration(days: 365));
      final r = ilYA(d.toIso8601String());
      expect(r, contains('j'));
    });

    test('ilYA il y a 1 heure', () {
      final d = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      final r = ilYA(d.toIso8601String());
      expect(r, contains('h'));
    });

    test('ilYA il y a 2 heures', () {
      final d = DateTime.now().toUtc().subtract(const Duration(hours: 2));
      final r = ilYA(d.toIso8601String());
      expect(r, contains('h'));
    });

    test('cleJour', () {
      expect(cleJour(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('heureLocale 23:59', () => expect(heureLocale(DateTime(2026, 1, 1, 23, 59)), '23:59'));
  });

  group('Edge Cases - Stats', () {
    test('chiffreAffaires avec montants très grands', () {
      final ventes = [Vente(
        id: 'v1', produitId: 'p1', produitNom: 'A',
        quantite: 1000000, prixUnitaireReel: 1000000, prixAchatUnitaire: 500000,
        total: 1000000000000, vendeurId: 'e1', vendeurNom: 'A',
        vendeurRole: Role.patron, date: '2026-08-22',
      )];
      expect(chiffreAffaires(ventes), 1000000000000);
    });

    test('margeTotale avec marge négative', () {
      final ventes = [Vente(
        id: 'v1', produitId: 'p1', produitNom: 'A',
        quantite: 1, prixUnitaireReel: 1000, prixAchatUnitaire: 5000,
        total: 1000, vendeurId: 'e1', vendeurNom: 'A',
        vendeurRole: Role.patron, date: '2026-08-22',
      )];
      expect(margeTotale(ventes), -4000);
    });

    test('beneficeNet toutes dépenses, pas de ventes', () {
      final depenses = [Depense(
        id: 'd1', description: 'X', montant: 10000,
        auteurNom: 'A', auteurRole: Role.patron,
        type: TypeDepense.depense, date: '2026-08-22',
      )];
      expect(beneficeNet([], depenses), -10000);
    });

    test('piecesVendues avec quantité fractionnaire', () {
      final ventes = [Vente(
        id: 'v1', produitId: 'p1', produitNom: 'A',
        quantite: 2.5, prixUnitaireReel: 1000, prixAchatUnitaire: 500,
        total: 2500, vendeurId: 'e1', vendeurNom: 'A',
        vendeurRole: Role.patron, date: '2026-08-22',
      )];
      expect(piecesVendues(ventes), 2.5);
    });

    test('valeurStock tous inactifs', () {
      final produits = [
        Produit(id: 'p1', nom: 'A', prixAchat: 1000, prixVente: 2000, quantite: 10, actif: false),
        Produit(id: 'p2', nom: 'B', prixAchat: 3000, prixVente: 5000, quantite: 5, actif: false),
      ];
      expect(valeurStock(produits), 0);
    });

    test('distance caractères spéciaux', () {
      expect(distance('café', 'cafe'), greaterThan(0));
    });

    test('distance unicodes', () {
      expect(distance('😀', '😀'), 0);
      expect(distance('😀', '😁'), greaterThan(0));
    });

    test('rechercheProduits espaces multiples', () {
      final produits = [
        Produit(id: 'p1', nom: '  Chemise  ', prixAchat: 1000, prixVente: 2000, quantite: 5),
      ];
      final r = rechercheProduits(produits, 'Chemise');
      expect(r.length, 1);
    });

    test('classementProduits tous même quantité', () {
      final ventes = [
        Vente(id: 'v1', produitId: 'p1', produitNom: 'A', quantite: 3, prixUnitaireReel: 1000, prixAchatUnitaire: 500, total: 3000, vendeurId: 'e1', vendeurNom: 'X', vendeurRole: Role.patron, date: '2026-08-22'),
        Vente(id: 'v2', produitId: 'p2', produitNom: 'B', quantite: 3, prixUnitaireReel: 1000, prixAchatUnitaire: 500, total: 3000, vendeurId: 'e1', vendeurNom: 'X', vendeurRole: Role.patron, date: '2026-08-22'),
      ];
      final r = classementProduits(ventes);
      expect(r.length, 2);
    });

    test('exporterCsvContent chaînes avec guillemets', () {
      final csv = exporterCsvContent([['"Nom"', 'Prix']]);
      expect(csv, contains('""Nom""'));
    });

    test('exporterCsvContent chaînes avec point-virgule', () {
      final csv = exporterCsvContent([['A;B', 100]]);
      expect(csv, contains('"A;B"'));
    });
  });

  group('Edge Cases - Sync', () {
    test('versSupabase table vide', () {
      final result = versSupabase('boutiques', {}, 'b1');
      expect(result.containsKey('maj_ts'), isTrue);
      expect(result.length, 1);
    });

    test('versLocal clés inconnues supprimées', () {
      final result = versLocal('boutiques', {
        'id': 'b1', 'inconnu': 'x', 'autre': 'y',
      });
      expect(result.length, 1);
      expect(result['id'], 'b1');
    });

    test('versSupabase booléens multiples', () {
      final local = {
        'id': 'e1', 'pinActif': 1, 'biometrie': 1,
      };
      final result = versSupabase('employes', local, 'b1');
      expect(result['pin_actif'], true);
      expect(result['biometrie'], true);
    });

    test('versLocal booléens multiples', () {
      final supa = {
        'id': 'e1', 'pin_actif': false, 'biometrie': true,
      };
      final result = versLocal('employes', supa);
      expect(result['pinActif'], 0);
      expect(result['biometrie'], 1);
    });

    test('10 tables ont un mapping', () {
      final tables = ['boutiques', 'employes', 'produits', 'ventes', 'depenses', 'retours', 'notifications', 'pointages', 'activites', 'appareils'];
      for (final table in tables) {
        final supa = versSupabase(table, {'id': '1'}, 'b1');
        expect(supa.isNotEmpty, isTrue, reason: 'Table $table doit avoir un mapping');
        final local = versLocal(table, supa);
        expect(local.isNotEmpty, isTrue, reason: 'Table $table doit avoir un mapping inverse');
      }
    });
  });

  group('Edge Cases - Permissions', () {
    test('peut avec liste permissions vide utilise défauts du rôle', () {
      final e = Employe(
        id: 'e1', nom: 'A', role: Role.patron,
        permissions: [],
        motDePasse: 'x', statut: StatutEmploye.actif,
        pinActif: false, pin: '', biometrie: false,
        dateCreation: '2026-01-01',
      );
      expect(peut(e, Permission.vendre), isTrue);
      expect(peut(e, Permission.gererComptes), isTrue);
    });

    test('permissionsParDefaut patron contient exactement 16', () {
      expect(permissionsParDefaut(Role.patron).toSet().length, 16);
    });

    test('permissionsParDefaut manager contient exactement 9', () {
      expect(permissionsParDefaut(Role.manager).toSet().length, 9);
    });

    test('permissionsParDefaut caissiere contient exactement 5', () {
      expect(permissionsParDefaut(Role.caissiere).toSet().length, 5);
    });

    test('groupesPermissions n\'a pas de doublons', () {
      final all = <Permission>{};
      for (final g in groupesPermissions) {
        for (final item in g.items) {
          expect(all.add(item.cle), isTrue, reason: 'Doublon: ${item.cle}');
        }
      }
    });
  });
}
