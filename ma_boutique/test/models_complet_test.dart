import 'package:flutter_test/flutter_test.dart';
import 'package:ma_boutique/models/models.dart';

void main() {
  group('Enums', () {
    group('Role', () {
      test('fromName patron', () => expect(Role.values.byName('patron'), Role.patron));
      test('fromName manager', () => expect(Role.values.byName('manager'), Role.manager));
      test('fromName caissiere', () => expect(Role.values.byName('caissiere'), Role.caissiere));
      test('label patron', () => expect(Role.patron.label, isNotEmpty));
      test('label manager', () => expect(Role.manager.label, isNotEmpty));
      test('label caissiere', () => expect(Role.caissiere.label, isNotEmpty));
    });

    group('Permission', () {
      test('fromName vendre', () => expect(Permission.values.byName('vendre'), Permission.vendre));
      test('fromName gererProduits', () => expect(Permission.values.byName('gererProduits'), Permission.gererProduits));
      test('fromName gererComptes', () => expect(Permission.values.byName('gererComptes'), Permission.gererComptes));
    });

    group('Monnaie', () {
      test('enum fcfa', () => expect(Monnaie.fcfa, Monnaie.fcfa));
      test('code fcfa', () => expect(Monnaie.fcfa.code, 'FCFA'));
      test('label fcfa', () => expect(Monnaie.fcfa.label, isNotEmpty));
      test('code eur', () => expect(Monnaie.eur.code, 'EUR'));
      test('code usd', () => expect(Monnaie.usd.code, 'USD'));
    });

    group('StatutEmploye', () {
      test('fromName actif', () => expect(StatutEmploye.values.byName('actif'), StatutEmploye.actif));
      test('fromName suspendu', () => expect(StatutEmploye.values.byName('suspendu'), StatutEmploye.suspendu));
    });

    group('TypeDepense', () {
      test('fromName depense', () => expect(TypeDepense.values.byName('depense'), TypeDepense.depense));
      test('fromName sortieJustifiee', () => expect(TypeDepense.values.byName('sortieJustifiee'), TypeDepense.sortieJustifiee));
    });

    group('MotifRetour', () {
      test('fromName remboursement', () => expect(MotifRetour.values.byName('remboursement'), MotifRetour.remboursement));
      test('fromName echange', () => expect(MotifRetour.values.byName('echange'), MotifRetour.echange));
      test('fromName defectueux', () => expect(MotifRetour.values.byName('defectueux'), MotifRetour.defectueux));
      test('label remboursement', () => expect(MotifRetour.remboursement.label, isNotEmpty));
    });

    group('StatutRetour', () {
      test('fromName enAttente', () => expect(StatutRetour.values.byName('enAttente'), StatutRetour.enAttente));
      test('fromName traite', () => expect(StatutRetour.values.byName('traite'), StatutRetour.traite));
      test('fromName refuse', () => expect(StatutRetour.values.byName('refuse'), StatutRetour.refuse));
      test('label enAttente', () => expect(StatutRetour.enAttente.label, isNotEmpty));
    });

    group('NotifType', () {
      test('fromName stock', () => expect(NotifType.values.byName('stock'), NotifType.stock));
    });

    group('TonToast', () {
      test('fromName succes', () => expect(TonToast.values.byName('succes'), TonToast.succes));
      test('fromName erreur', () => expect(TonToast.values.byName('erreur'), TonToast.erreur));
    });
  });

  group('Constantes', () {
    test('abonnementModes a 3 éléments', () => expect(abonnementModes.length, 3));
    test('abonnementModes contient achat_direct', () => expect(abonnementModes.map((e) => e.$1), contains('achat_direct')));
    test('methodesPaiement a 4 éléments', () => expect(methodesPaiement.length, 4));
    test('categoriesProduit a 6 éléments', () => expect(categoriesProduit.length, 6));
    test('categoriesProduit contient vetement', () => expect(categoriesProduit.map((e) => e.$1), contains('vetement')));
  });

  group('Boutique', () {
    Boutique _b({
      String statut = 'active',
      String abonnementMode = 'mensuel',
      DateTime? abonnementDebut,
      DateTime? abonnementFin,
    }) {
      return Boutique(
        id: 'b1', nom: 'Ma boutique', styleCommerce: 'mode',
        emailPatron: 'patron@test.com', monnaie: Monnaie.fcfa,
        soldeCaisse: 50000, statut: statut,
        abonnementMode: abonnementMode,
        abonnementDebut: abonnementDebut,
        abonnementFin: abonnementFin,
      );
    }

    test('estDesactivee quand statut desactivee', () => expect(_b(statut: 'desactivee').estDesactivee, isTrue));
    test('estDesactivee false quand active', () => expect(_b(statut: 'active').estDesactivee, isFalse));

    test('abonnementExpire vrai si date fin < now', () {
      final b = _b(abonnementFin: DateTime.now().subtract(const Duration(days: 1)));
      expect(b.abonnementExpire, isTrue);
    });
    test('abonnementExpire faux si date fin > now', () {
      final b = _b(abonnementFin: DateTime.now().add(const Duration(days: 10)));
      expect(b.abonnementExpire, isFalse);
    });
    test('abonnementProche vrai si < 7 jours et pas expiré', () {
      final b = _b(abonnementFin: DateTime.now().add(const Duration(days: 3)));
      expect(b.abonnementProche, isTrue);
    });
    test('abonnementProche faux si > 7 jours', () {
      final b = _b(abonnementFin: DateTime.now().add(const Duration(days: 30)));
      expect(b.abonnementProche, isFalse);
    });
    test('abonnementLabel retourne le label du mode', () => expect(_b(abonnementMode: 'mensuel').abonnementLabel, isNotEmpty));

    test('toMap/fromMap roundtrip', () {
      final original = _b();
      final map = original.toMap();
      final restored = Boutique.fromMap(map);
      expect(restored.id, original.id);
      expect(restored.nom, original.nom);
      expect(restored.monnaie, original.monnaie);
      expect(restored.soldeCaisse, original.soldeCaisse);
    });

    test('copyWith ne perd pas les champs', () {
      final original = _b();
      final copied = original.copyWith(soldeCaisse: 75000);
      expect(copied.soldeCaisse, 75000);
      expect(copied.monnaie, original.monnaie);
      expect(copied.id, original.id);
    });

    test('fromMap avec valeurs null/defaut', () {
      final map = {
        'id': 'b2', 'nom': 'Test', 'styleCommerce': 'mode',
        'emailPatron': 'a@b.com', 'monnaie': 'fcfa',
        'soldeCaisse': 0,
      };
      final b = Boutique.fromMap(map);
      expect(b.statut, 'active');
      expect(b.abonnementMode, 'achat_direct');
      expect(b.notificationAbonnement, isFalse);
    });
  });

  group('Employe', () {
    test('toMap/fromMap roundtrip', () {
      final original = Employe(
        id: 'e1', nom: 'Ali', role: Role.patron,
        permissions: [Permission.vendre, Permission.gererProduits],
        motDePasse: 'pass123', statut: StatutEmploye.actif,
        pinActif: true, pin: '1234', biometrie: true,
        dateCreation: '2026-01-01',
      );
      final map = original.toMap();
      final restored = Employe.fromMap(map);
      expect(restored.id, 'e1');
      expect(restored.nom, 'Ali');
      expect(restored.role, Role.patron);
      expect(restored.permissions.length, 2);
      expect(restored.pinActif, isTrue);
      expect(restored.pin, '1234');
      expect(restored.biometrie, isTrue);
    });

    test('copyWith change le statut', () {
      final e = Employe(
        id: 'e1', nom: 'Ali', role: Role.manager,
        permissions: [], motDePasse: 'x', statut: StatutEmploye.actif,
        pinActif: false, pin: '', biometrie: false, dateCreation: '2026-01-01',
      );
      final s = e.copyWith(statut: StatutEmploye.suspendu);
      expect(s.statut, StatutEmploye.suspendu);
    });
  });

  group('Produit', () {
    test('estNouveau vrai si < 7 jours', () {
      final p = Produit(id: 'p1', nom: 'Test', prixAchat: 1000, prixVente: 2000, quantite: 5,
        dateAjout: DateTime.now().subtract(const Duration(days: 2)));
      expect(p.estNouveau, isTrue);
    });
    test('estNouveau faux si > 7 jours', () {
      final p = Produit(id: 'p1', nom: 'Test', prixAchat: 1000, prixVente: 2000, quantite: 5,
        dateAjout: DateTime.now().subtract(const Duration(days: 10)));
      expect(p.estNouveau, isFalse);
    });
    test('estNouveau faux si dateAjout null', () {
      final p = Produit(id: 'p1', nom: 'Test', prixAchat: 1000, prixVente: 2000, quantite: 5, dateAjout: null);
      expect(p.estNouveau, isFalse);
    });
    test('categorieLabel retourne un label', () {
      final p = Produit(id: 'p1', nom: 'Test', prixAchat: 1000, prixVente: 2000, quantite: 5, categorie: 'vetement');
      expect(p.categorieLabel, isNotEmpty);
    });
    test('toMap/fromMap roundtrip avec images et catégorie', () {
      final original = Produit(id: 'p1', nom: 'Chemise', prixAchat: 3000, prixVente: 5000, quantite: 10,
        actif: true, images: ['img1.jpg', 'img2.jpg'], categorie: 'vetement', dateAjout: DateTime(2026, 8, 22));
      final map = original.toMap();
      final restored = Produit.fromMap(map);
      expect(restored.id, 'p1');
      expect(restored.images.length, 2);
      expect(restored.categorie, 'vetement');
      expect(restored.actif, isTrue);
    });
    test('fromMap gère images vides', () {
      final p = Produit.fromMap({
        'id': 'p1', 'nom': 'Test', 'prixAchat': 1000, 'prixVente': 2000,
        'quantite': 5, 'actif': 1, 'images': '', 'categorie': '',
      });
      expect(p.images, isEmpty);
    });
    test('copyWith', () {
      final p = Produit(id: 'p1', nom: 'Test', prixAchat: 1000, prixVente: 2000, quantite: 5);
      final c = p.copyWith(nom: 'Nouveau', quantite: 10);
      expect(c.nom, 'Nouveau');
      expect(c.quantite, 10);
      expect(c.prixAchat, 1000);
    });
  });

  group('Vente', () {
    test('toMap/fromMap roundtrip', () {
      final original = Vente(id: 'v1', produitId: 'p1', produitNom: 'A',
        quantite: 2, prixUnitaireReel: 5000, prixAchatUnitaire: 3000,
        total: 10000, vendeurId: 'e1', vendeurNom: 'Ali',
        vendeurRole: Role.caissiere, date: '2026-08-22T10:00:00');
      final map = original.toMap();
      final restored = Vente.fromMap(map);
      expect(restored.id, 'v1');
      expect(restored.total, 10000);
      expect(restored.vendeurRole, Role.caissiere);
    });
  });

  group('Depense', () {
    test('toMap/fromMap roundtrip', () {
      final original = Depense(id: 'd1', description: 'Loyer', montant: 50000,
        auteurNom: 'Ali', auteurRole: Role.patron,
        type: TypeDepense.depense, date: '2026-08-22T10:00:00');
      final map = original.toMap();
      final restored = Depense.fromMap(map);
      expect(restored.id, 'd1');
      expect(restored.montant, 50000);
      expect(restored.type, TypeDepense.depense);
    });
  });

  group('Retour', () {
    test('toMap/fromMap roundtrip', () {
      final original = Retour(id: 'r1', produitId: 'p1', produitNom: 'A',
        motif: MotifRetour.remboursement, description: 'Defaut',
        montant: 5000, auteurNom: 'Ali',
        statut: StatutRetour.enAttente, date: '2026-08-22T10:00:00');
      final map = original.toMap();
      final restored = Retour.fromMap(map);
      expect(restored.id, 'r1');
      expect(restored.motif, MotifRetour.remboursement);
      expect(restored.statut, StatutRetour.enAttente);
    });
    test('copyWith change le statut', () {
      final r = Retour(id: 'r1', produitId: 'p1', produitNom: 'A',
        motif: MotifRetour.remboursement, description: 'x',
        montant: 5000, auteurNom: 'Ali',
        statut: StatutRetour.enAttente, date: '2026-08-22');
      final c = r.copyWith(statut: StatutRetour.traite);
      expect(c.statut, StatutRetour.traite);
      expect(c.montant, 5000);
    });
  });

  group('NotificationItem', () {
    test('toMap/fromMap roundtrip avec destinataires', () {
      final original = NotificationItem(id: 'n1', destinataires: [Role.patron, Role.manager],
        titre: 'Alerte', message: 'Stock bas',
        type: NotifType.stock, estLu: false, date: '2026-08-22T10:00:00');
      final map = original.toMap();
      final restored = NotificationItem.fromMap(map);
      expect(restored.id, 'n1');
      expect(restored.destinataires.length, 2);
      expect(restored.estLu, isFalse);
    });
    test('copyWith estLu', () {
      final n = NotificationItem(id: 'n1', destinataires: [Role.patron],
        titre: 'T', message: 'M', type: NotifType.stock, estLu: false, date: '2026-08-22');
      expect(n.copyWith(estLu: true).estLu, isTrue);
    });
  });

  group('Pointage', () {
    test('toMap/fromMap roundtrip', () {
      final original = Pointage(id: 'pt1', employeId: 'e1', employeNom: 'Ali',
        role: Role.patron, date: '2026-08-22',
        heureArrivee: '08:00', heureDepart: '17:00');
      final map = original.toMap();
      final restored = Pointage.fromMap(map);
      expect(restored.id, 'pt1');
      expect(restored.heureDepart, '17:00');
    });
    test('copyWith heureDepart', () {
      final pt = Pointage(id: 'pt1', employeId: 'e1', employeNom: 'Ali',
        role: Role.patron, date: '2026-08-22', heureArrivee: '08:00');
      expect(pt.copyWith(heureDepart: '17:00').heureDepart, '17:00');
    });
  });

  group('Activite', () {
    test('toMap/fromMap roundtrip', () {
      final original = Activite(id: 'a1', employeNom: 'Ali', employeRole: Role.patron,
        type: NotifType.stock, description: 'Vente A', date: '2026-08-22T10:00:00');
      final map = original.toMap();
      final restored = Activite.fromMap(map);
      expect(restored.id, 'a1');
      expect(restored.type, NotifType.stock);
    });
  });

  group('Appareil', () {
    test('toMap/fromMap roundtrip', () {
      final original = Appareil(id: 'app1', employeNom: 'Ali', role: Role.patron,
        nomAppareil: 'Galaxy S24', derniereConnexion: '2026-08-22T10:00:00', actif: true);
      final map = original.toMap();
      final restored = Appareil.fromMap(map);
      expect(restored.id, 'app1');
      expect(restored.actif, isTrue);
    });
    test('copyWith actif', () {
      final a = Appareil(id: 'app1', employeNom: 'Ali', role: Role.patron,
        nomAppareil: 'Galaxy', derniereConnexion: '2026-08-22', actif: true);
      expect(a.copyWith(actif: false).actif, isFalse);
    });
  });
}
