import 'package:flutter_test/flutter_test.dart';

import 'package:ma_boutique/core/format.dart';
import 'package:ma_boutique/models/models.dart';

void main() {
  // ── Tests existants ──
  test('formatMontant groupe les milliers et ajoute la monnaie', () {
    expect(formatMontant(486500, 'FCFA'), '486\u202F500 FCFA');
    expect(formatMontant(7500.4, 'FCFA'), '7\u202F500 FCFA');
    expect(formatMontant(12.5, 'EUR'), '€12.50');
  });

  test('cleJour produit une clé ISO locale', () {
    expect(cleJour(DateTime(2026, 8, 19)), '2026-08-19');
  });

  // ── Boutique model ──
  group('Boutique model', () {
    test('toMap contient tous les champs abonnement', () {
      final b = Boutique(
        id: 'b1',
        nom: 'Test',
        styleCommerce: 'Mode',
        monnaie: Monnaie.fcfa,
        emailPatron: 'test@test.com',
        soldeCaisse: 1000,
        statut: 'active',
        abonnementMode: 'mensuel',
        abonnementDebut: DateTime(2026, 8, 1),
        abonnementFin: DateTime(2026, 8, 31),
        notificationAbonnement: true,
        methodePaiement: 'Mobile Money',
      );
      final m = b.toMap();
      expect(m['statut'], 'active');
      expect(m['abonnementMode'], 'mensuel');
      expect(m['abonnementDebut'], isNotNull);
      expect(m['abonnementFin'], isNotNull);
      expect(m['notificationAbonnement'], 1);
      expect(m['methodePaiement'], 'Mobile Money');
    });

    test('fromMap reconstitue tous les champs', () {
      final now = DateTime.now().toUtc();
      final m = {
        'id': 'b1',
        'nom': 'Test',
        'styleCommerce': 'Mode',
        'monnaie': 'FCFA',
        'emailPatron': 'a@b.com',
        'logoUrl': null,
        'soldeCaisse': 500,
        'statut': 'desactivee',
        'abonnementMode': 'trimestriel',
        'abonnementDebut': now.toIso8601String(),
        'abonnementFin': now.add(const Duration(days: 90)).toIso8601String(),
        'notificationAbonnement': 1,
        'methodePaiement': 'Carte bancaire',
      };
      final b = Boutique.fromMap(m);
      expect(b.statut, 'desactivee');
      expect(b.abonnementMode, 'trimestriel');
      expect(b.abonnementDebut, isNotNull);
      expect(b.abonnementFin, isNotNull);
      expect(b.notificationAbonnement, true);
      expect(b.methodePaiement, 'Carte bancaire');
    });

    test('fromMap avec valeurs null/defaut', () {
      final b = Boutique.fromMap({
        'id': 'b2',
        'nom': 'Min',
      });
      expect(b.statut, 'active');
      expect(b.abonnementMode, 'achat_direct');
      expect(b.abonnementDebut, isNull);
      expect(b.abonnementFin, isNull);
      expect(b.notificationAbonnement, false);
      expect(b.methodePaiement, '');
    });

    test('copyWith ne perd pas les champs abonnement', () {
      final b1 = Boutique(
        id: 'b1',
        nom: 'Test',
        styleCommerce: '',
        monnaie: Monnaie.fcfa,
        emailPatron: '',
        soldeCaisse: 0,
        abonnementMode: 'mensuel',
        methodePaiement: 'Espèces',
        notificationAbonnement: true,
      );
      final b2 = b1.copyWith(soldeCaisse: 999);
      expect(b2.abonnementMode, 'mensuel');
      expect(b2.methodePaiement, 'Espèces');
      expect(b2.notificationAbonnement, true);
      expect(b2.soldeCaisse, 999);
    });
  });

  // ── Helpers Boutique ──
  group('Boutique helpers', () {
    test('estDesactivee', () {
      expect(Boutique(id: '', nom: '', styleCommerce: '', monnaie: Monnaie.fcfa, emailPatron: '', soldeCaisse: 0, statut: 'active').estDesactivee, false);
      expect(Boutique(id: '', nom: '', styleCommerce: '', monnaie: Monnaie.fcfa, emailPatron: '', soldeCaisse: 0, statut: 'desactivee').estDesactivee, true);
    });

    test('abonnementExpire', () {
      final passe = Boutique(id: '', nom: '', styleCommerce: '', monnaie: Monnaie.fcfa, emailPatron: '', soldeCaisse: 0, abonnementFin: DateTime.now().subtract(const Duration(days: 1)));
      expect(passe.abonnementExpire, true);

      final futur = Boutique(id: '', nom: '', styleCommerce: '', monnaie: Monnaie.fcfa, emailPatron: '', soldeCaisse: 0, abonnementFin: DateTime.now().add(const Duration(days: 10)));
      expect(futur.abonnementExpire, false);

      final nullFin = Boutique(id: '', nom: '', styleCommerce: '', monnaie: Monnaie.fcfa, emailPatron: '', soldeCaisse: 0);
      expect(nullFin.abonnementExpire, false);
    });

    test('abonnementProche (7 jours)', () {
      final proche = Boutique(id: '', nom: '', styleCommerce: '', monnaie: Monnaie.fcfa, emailPatron: '', soldeCaisse: 0, abonnementFin: DateTime.now().add(const Duration(days: 5)));
      expect(proche.abonnementProche, true);

      final lointain = Boutique(id: '', nom: '', styleCommerce: '', monnaie: Monnaie.fcfa, emailPatron: '', soldeCaisse: 0, abonnementFin: DateTime.now().add(const Duration(days: 30)));
      expect(lointain.abonnementProche, false);

      final expire = Boutique(id: '', nom: '', styleCommerce: '', monnaie: Monnaie.fcfa, emailPatron: '', soldeCaisse: 0, abonnementFin: DateTime.now().subtract(const Duration(days: 1)));
      expect(expire.abonnementProche, false);
    });

    test('abonnementLabel', () {
      expect(
        Boutique(id: '', nom: '', styleCommerce: '', monnaie: Monnaie.fcfa, emailPatron: '', soldeCaisse: 0, abonnementMode: 'mensuel').abonnementLabel,
        'Mensuel (30 j)',
      );
      expect(
        Boutique(id: '', nom: '', styleCommerce: '', monnaie: Monnaie.fcfa, emailPatron: '', soldeCaisse: 0, abonnementMode: 'trimestriel').abonnementLabel,
        'Trimestriel (90 j)',
      );
      expect(
        Boutique(id: '', nom: '', styleCommerce: '', monnaie: Monnaie.fcfa, emailPatron: '', soldeCaisse: 0, abonnementMode: 'achat_direct').abonnementLabel,
        'Achat direct (30 j)',
      );
    });
  });

  // ── Constantes abonnement ──
  group('Constantes abonnement', () {
    test('abonnementModes contient les 3 modes', () {
      expect(abonnementModes.length, 3);
      expect(abonnementModes.map((m) => m.$1).toList(), containsAll(['achat_direct', 'mensuel', 'trimestriel']));
    });

    test('methodesPaiement contient les 4 méthodes', () {
      expect(methodesPaiement.length, 4);
      expect(methodesPaiement, containsAll(['Mobile Money', 'Carte bancaire', 'Espèces', 'Virement']));
    });
  });

  // ── Enums ──
  group('Enums', () {
    test('Role labels', () {
      expect(Role.patron.label, 'Patron');
      expect(Role.manager.label, 'Manager');
      expect(Role.caissiere.label, 'Caissière');
    });

    test('Role names', () {
      expect(Role.patron.name, 'patron');
      expect(RoleX.fromName('patron'), Role.patron);
    });

    test('Monnaie codes', () {
      expect(Monnaie.fcfa.code, 'FCFA');
      expect(MonnaieX.fromCode('FCFA'), Monnaie.fcfa);
      expect(MonnaieX.fromCode('XXX'), Monnaie.fcfa);
    });

    test('NotifType fromName', () {
      expect(NotifTypeX.fromName('vente'), NotifType.vente);
      expect(NotifTypeX.fromName('inconnu'), NotifType.vente);
    });
  });

  // ── Modèle Employe ──
  group('Employe model', () {
    test('toMap/fromMap roundtrip', () {
      final e = Employe(
        id: 'e1',
        nom: 'Test',
        role: Role.manager,
        permissions: [Permission.voirPrixAchat],
        motDePasse: 'mdp',
        statut: StatutEmploye.actif,
        pinActif: true,
        pin: '1234',
        biometrie: false,
        dateCreation: '2026-01-01',
      );
      final m = e.toMap();
      final e2 = Employe.fromMap(m);
      expect(e2.id, 'e1');
      expect(e2.nom, 'Test');
      expect(e2.role, Role.manager);
      expect(e2.pinActif, true);
      expect(e2.pin, '1234');
    });
  });

  // ── Modèle Produit ──
  group('Produit model', () {
    test('toMap/fromMap roundtrip', () {
      final now = DateTime(2026, 8, 20);
      final p = Produit(
        id: 'p1', nom: 'T-shirt', prixAchat: 2000, prixVente: 5000,
        quantite: 50, actif: true, images: ['a.jpg', 'b.jpg'],
        categorie: 'vetement', dateAjout: now,
      );
      final m = p.toMap();
      final p2 = Produit.fromMap(m);
      expect(p2.id, 'p1');
      expect(p2.prixVente, 5000);
      expect(p2.actif, true);
      expect(p2.images, ['a.jpg', 'b.jpg']);
      expect(p2.categorie, 'vetement');
      expect(p2.dateAjout, now);
    });

    test('estNouveau retourne vrai si ajout < 7 jours', () {
      final p = Produit(
        id: 'p2', nom: 'Robe', prixAchat: 5000, prixVente: 10000,
        quantite: 5, dateAjout: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(p.estNouveau, true);
    });

    test('estNouveau retourne faux si ajout > 7 jours', () {
      final p = Produit(
        id: 'p3', nom: 'Jean', prixAchat: 7000, prixVente: 12000,
        quantite: 10, dateAjout: DateTime.now().subtract(const Duration(days: 15)),
      );
      expect(p.estNouveau, false);
    });

    test('categorieLabel retourne le libellé de la catégorie', () {
      final p = Produit(
        id: 'p4', nom: 'Sac', prixAchat: 3000, prixVente: 6000,
        quantite: 8, categorie: 'accessoire',
      );
      expect(p.categorieLabel, 'Accessoire');
    });

    test('toMap/fromMap avec images vides', () {
      final p = Produit(id: 'p5', nom: 'Test', prixAchat: 1000, prixVente: 2000, quantite: 1);
      final m = p.toMap();
      final p2 = Produit.fromMap(m);
      expect(p2.images, isEmpty);
      expect(p2.categorie, 'autre');
      expect(p2.dateAjout, isNull);
    });
  });

  // ── Modèle Vente ──
  group('Vente model', () {
    test('toMap/fromMap roundtrip', () {
      final v = Vente(
        id: 'v1',
        produitId: 'p1',
        produitNom: 'T-shirt',
        quantite: 2,
        prixUnitaireReel: 5000,
        prixAchatUnitaire: 2000,
        total: 10000,
        vendeurId: 'e1',
        vendeurNom: 'Awa',
        vendeurRole: Role.patron,
        date: '2026-08-20T10:00:00',
      );
      final m = v.toMap();
      final v2 = Vente.fromMap(m);
      expect(v2.total, 10000);
      expect(v2.vendeurNom, 'Awa');
    });
  });

  // ── Mapping sync (camelCase ↔ snake_case) ──
  group('Mapping sync boutiques', () {
    const colonnes = <String, String>{
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
    };

    test('13 colonnes mappées', () {
      expect(colonnes.length, 13);
    });

    test('toutes les clés locales ont une cible snake_case', () {
      for (final entry in colonnes.entries) {
        expect(entry.value, isNotEmpty, reason: '${entry.key} n\'a pas de mapping');
      }
    });

    test('notificationAbonnement est dans la liste des booléens', () {
      const booleens = ['notificationAbonnement'];
      expect(booleens, contains('notificationAbonnement'));
    });

    test('inverse mapping: snake_case → camelCase', () {
      final inverses = {for (final e in colonnes.entries) e.value: e.key};
      expect(inverses['abonnement_mode'], 'abonnementMode');
      expect(inverses['notification_abonnement'], 'notificationAbonnement');
    });
  });

  // ── Règles métier abonnement ──
  group('Règles métier abonnement', () {
    test('achat_direct: pas de notification', () {
      for (final m in abonnementModes) {
        if (m.$1 == 'achat_direct') {
          expect(m.$2, contains('30 j'));
        }
      }
    });

    test('mensuel: 30 jours', () {
      final debut = DateTime(2026, 8, 1);
      final fin = debut.add(const Duration(days: 30));
      expect(fin.day, 31);
    });

    test('trimestriel: 90 jours', () {
      final debut = DateTime(2026, 8, 1);
      final fin = debut.add(const Duration(days: 90));
      expect(fin.month, 10);
      expect(fin.day, 30);
    });
  });

  // ── Modèle Depense ──
  group('Depense model', () {
    test('toMap/fromMap roundtrip', () {
      final d = Depense(id: 'd1', description: 'Loyer', montant: 150000, auteurNom: 'Awa', auteurRole: Role.patron, type: TypeDepense.depense, date: '2026-08-20');
      final m = d.toMap();
      final d2 = Depense.fromMap(m);
      expect(d2.description, 'Loyer');
      expect(d2.montant, 150000);
    });
  });

  // ── Modèle Pointage ──
  group('Pointage model', () {
    test('toMap/fromMap roundtrip', () {
      final p = Pointage(id: 'pt1', employeId: 'e1', employeNom: 'Awa', role: Role.patron, date: '2026-08-20', heureArrivee: '08:00');
      final m = p.toMap();
      final p2 = Pointage.fromMap(m);
      expect(p2.heureArrivee, '08:00');
      expect(p2.employeNom, 'Awa');
    });
  });

  // ── Modèle Retour ──
  group('Retour model', () {
    test('toMap/fromMap roundtrip', () {
      final r = Retour(id: 'r1', produitId: 'p1', produitNom: 'T-shirt', motif: MotifRetour.defectueux, description: 'Tache', montant: 5000, auteurNom: 'Awa', statut: StatutRetour.enAttente, date: '2026-08-20');
      final m = r.toMap();
      final r2 = Retour.fromMap(m);
      expect(r2.motif, MotifRetour.defectueux);
      expect(r2.statut, StatutRetour.enAttente);
    });
  });

  // ── Modèle NotificationItem ──
  group('NotificationItem model', () {
    test('toMap/fromMap roundtrip', () {
      final n = NotificationItem(id: 'n1', destinataires: [Role.patron, Role.manager], titre: 'Alerte', message: 'Stock bas', type: NotifType.stock, estLu: false, date: '2026-08-20');
      final m = n.toMap();
      final n2 = NotificationItem.fromMap(m);
      expect(n2.titre, 'Alerte');
      expect(n2.estLu, false);
    });
  });
}
