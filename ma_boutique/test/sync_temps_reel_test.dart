import 'package:flutter_test/flutter_test.dart';
import 'package:ma_boutique/data/database.dart';
import 'package:ma_boutique/providers/app_provider.dart';
import 'package:ma_boutique/services/sync_service.dart';

void main() {
  group('protection de la réconciliation du compte', () {
    test(
      'préserve la boutique locale avec une modification en attente',
      () async {
        var ecritures = 0;
        final appliquee = await appliquerSiAucuneOperationEnAttente(
          lireFile: () async => [
            {'tableName': 'boutiques', 'rowId': 'b1'},
          ],
          table: 'boutiques',
          id: 'b1',
          appliquer: () async {
            ecritures++;
          },
        );
        expect(appliquee, isFalse);
        expect(ecritures, 0);
      },
    );

    test('applique la boutique distante quand la file est vide', () async {
      var ecritures = 0;
      final appliquee = await appliquerSiAucuneOperationEnAttente(
        lireFile: () async => [],
        table: 'boutiques',
        id: 'b1',
        appliquer: () async {
          ecritures++;
        },
      );
      expect(appliquee, isTrue);
      expect(ecritures, 1);
    });

    test(
      'une autre ligne ou table en attente ne bloque pas le compte',
      () async {
        var ecritures = 0;
        final appliquee = await appliquerSiAucuneOperationEnAttente(
          lireFile: () async => [
            {'tableName': 'boutiques', 'rowId': 'b2'},
            {'tableName': 'produits', 'rowId': 'b1'},
          ],
          table: 'boutiques',
          id: 'b1',
          appliquer: () async {
            ecritures++;
          },
        );
        expect(appliquee, isTrue);
        expect(ecritures, 1);
      },
    );

    test(
      'une erreur de lecture ne déclenche pas l’écriture distante',
      () async {
        var ecritures = 0;
        await expectLater(
          appliquerSiAucuneOperationEnAttente(
            lireFile: () async => throw StateError('file indisponible'),
            table: 'boutiques',
            id: 'b1',
            appliquer: () async {
              ecritures++;
            },
          ),
          throwsStateError,
        );
        expect(ecritures, 0);
      },
    );
  });

  group('tablesSynchronisees', () {
    test('couvre les 10 tables du tenant', () {
      expect(tablesSynchronisees.length, 10);
      expect(
        tablesSynchronisees,
        containsAll([
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
        ]),
      );
    });
  });

  group('interpreterChangement', () {
    test('écrit une ligne de la bonne boutique', () {
      final decision = interpreterChangement(
        table: 'produits',
        boutiqueId: 'b1',
        evenement: 'INSERT',
        nouveau: {
          'id': 'p1',
          'boutique_id': 'b1',
          'nom': 'Chemise',
          'prix_achat': 3000,
          'prix_vente': 5000,
          'quantite': 4,
          'actif': true,
          'categorie': 'chaussures',
          'images': 'a.jpg',
        },
        ancien: {},
      );
      expect(decision.type, decisionEcrire);
      expect(decision.id, 'p1');
      expect(decision.ligne!['nom'], 'Chemise');
      expect(decision.ligne!['quantite'], 4);
      expect(decision.ligne!['actif'], 1);
      expect(decision.ligne!['categorie'], 'chaussures');
      expect(decision.ligne!['images'], 'a.jpg');
    });

    test('ignore la ligne d\'une autre boutique', () {
      final decision = interpreterChangement(
        table: 'produits',
        boutiqueId: 'b1',
        evenement: 'INSERT',
        nouveau: {'id': 'p9', 'boutique_id': 'b2', 'nom': 'X'},
        ancien: {},
      );
      expect(decision.type, decisionIgnorer);
    });

    test('accepte la boutique dont l\'id est le tenant', () {
      final decision = interpreterChangement(
        table: 'boutiques',
        boutiqueId: 'b1',
        evenement: 'UPDATE',
        nouveau: {'id': 'b1', 'nom': 'Ma boutique', 'solde_caisse': 1000},
        ancien: {'id': 'b1'},
      );
      expect(decision.type, decisionEcrire);
      expect(decision.ligne!['soldeCaisse'], 1000);
    });

    test('refuse une boutique étrangère', () {
      final decision = interpreterChangement(
        table: 'boutiques',
        boutiqueId: 'b1',
        evenement: 'UPDATE',
        nouveau: {'id': 'b2', 'nom': 'Autre'},
        ancien: {'id': 'b2'},
      );
      expect(decision.type, decisionIgnorer);
    });

    test('supprime une ligne de la boutique courante', () {
      final decision = interpreterChangement(
        table: 'ventes',
        boutiqueId: 'b1',
        evenement: 'DELETE',
        nouveau: const {},
        ancien: {'id': 'v1', 'boutique_id': 'b1'},
      );
      expect(decision.type, decisionSupprimer);
      expect(decision.id, 'v1');
    });

    test('ignore le DELETE d\'une autre boutique', () {
      final decision = interpreterChangement(
        table: 'ventes',
        boutiqueId: 'b1',
        evenement: 'DELETE',
        nouveau: const {},
        ancien: {'id': 'v1', 'boutique_id': 'b2'},
      );
      expect(decision.type, decisionIgnorer);
    });

    test('ignore un DELETE sans tenant au lieu de supprimer à l\'aveugle', () {
      final decision = interpreterChangement(
        table: 'ventes',
        boutiqueId: 'b1',
        evenement: 'DELETE',
        nouveau: const {},
        ancien: {'id': 'v1'},
      );
      expect(decision.type, decisionIgnorer);
    });

    test('ignore un événement sans identifiant', () {
      final decision = interpreterChangement(
        table: 'ventes',
        boutiqueId: 'b1',
        evenement: 'DELETE',
        nouveau: const {},
        ancien: const {},
      );
      expect(decision.type, decisionIgnorer);
    });
  });

  group('JournalEcritures', () {
    test('reconnaît l\'écho de sa propre écriture', () {
      final journal = JournalEcritures();
      journal.noter('produits', 'p1', '2026-10-16T10:00:00.000Z');
      expect(
        journal.distantPlusRecent('produits', 'p1', '2026-10-16T10:00:00.000Z'),
        isFalse,
      );
      expect(
        journal.distantPlusRecent('produits', 'p1', '2026-10-16T09:00:00.000Z'),
        isFalse,
      );
    });

    test('accepte une modification plus récente d\'un autre appareil', () {
      final journal = JournalEcritures();
      journal.noter('produits', 'p1', '2026-10-16T10:00:00.000Z');
      expect(
        journal.distantPlusRecent('produits', 'p1', '2026-10-16T10:05:00.000Z'),
        isTrue,
      );
    });

    test('accepte toute ligne jamais écrite localement', () {
      final journal = JournalEcritures();
      expect(
        journal.distantPlusRecent('ventes', 'v1', '2026-10-16T10:00:00.000Z'),
        isTrue,
      );
    });

    test('purge les entrées anciennes', () {
      final journal = JournalEcritures();
      journal.noter('produits', 'p1', '2020-01-01T00:00:00.000Z');
      journal.purger();
      expect(
        journal.distantPlusRecent('produits', 'p1', '2026-01-01T00:00:00.000Z'),
        isTrue,
      );
    });

    test('se vide complètement', () {
      final journal = JournalEcritures();
      journal.noter('produits', 'p1', '2026-10-16T10:00:00.000Z');
      journal.vider();
      expect(
        journal.distantPlusRecent('produits', 'p1', '2026-10-16T09:59:00.000Z'),
        isTrue,
      );
    });
  });

  group('libelleMajDistante', () {
    test('annonce le domaine concerné', () {
      expect(libelleMajDistante('produits'), contains('Stock'));
      expect(libelleMajDistante('ventes'), contains('vente'));
      expect(libelleMajDistante('inconnu'), contains('Mise à jour'));
    });
  });

  group('produits : nouvelles colonnes synchronisées', () {
    test('versSupabase transmet images, catégorie, date et QR', () {
      final ligne = versSupabase('produits', {
        'id': 'p1',
        'nom': 'Chemise',
        'prixAchat': 3000,
        'prixVente': 5000,
        'quantite': 2,
        'actif': 1,
        'images': 'a.jpg,b.jpg',
        'categorie': 'chaussures',
        'dateAjout': '2026-10-16T10:00:00.000Z',
        'qrCodeData': '{"id":"p1"}',
      }, 'b1');
      expect(ligne['images'], 'a.jpg,b.jpg');
      expect(ligne['categorie'], 'chaussures');
      expect(ligne['date_ajout'], '2026-10-16T10:00:00.000Z');
      expect(ligne['qr_code_data'], '{"id":"p1"}');
    });

    test('versLocal restaure les mêmes champs', () {
      final locale = versLocal('produits', {
        'id': 'p1',
        'boutique_id': 'b1',
        'nom': 'Chemise',
        'actif': true,
        'images': 'a.jpg',
        'categorie': 'chaussures',
        'date_ajout': '2026-10-16T10:00:00+00:00',
        'qr_code_data': '{"id":"p1"}',
        'maj_ts': '2026-10-16T10:00:00+00:00',
      });
      expect(locale['images'], 'a.jpg');
      expect(locale['categorie'], 'chaussures');
      expect(locale['dateAjout'], '2026-10-16T10:00:00+00:00');
      expect(locale['qrCodeData'], '{"id":"p1"}');
      expect(locale.containsKey('maj_ts'), isFalse);
      expect(locale.containsKey('boutique_id'), isFalse);
    });
  });

  group('amorçage d\'un serveur vide', () {
    test('détecte un serveur sans donnée métier', () {
      expect(serveurSansDonneesMetier(0), isTrue);
      expect(serveurSansDonneesMetier(1), isFalse);
    });

    test('ne retient que la boutique ouverte', () {
      final boutiques = [
        {'id': 'b1', 'nom': 'La mienne'},
        {'id': 'b2', 'nom': 'Une autre'},
      ];
      final lignes = lignesAAmorcer('boutiques', 'b1', boutiques, const []);
      expect(lignes.length, 1);
      expect(lignes.first['nom'], 'La mienne');
    });

    test('envoie toutes les lignes locales des autres tables', () {
      final produits = [
        {'id': 'p1', 'boutique_id': 'b1'},
        {'id': 'p2', 'boutique_id': 'b1'},
      ];
      expect(lignesAAmorcer('produits', 'b1', const [], produits).length, 2);
    });
  });

  group('synchroniser', () {
    test('ne touche pas au réseau sans boutique ouverte', () async {
      final service = SyncService(DatabaseHelper.instance);
      final provider = AppProvider();
      final resultat = await service.synchroniser(provider, 'b1');
      expect(resultat.ok, isFalse);
      expect(resultat.envoyees, 0);
      expect(service.tempsReelActif, isFalse);
    });
  });
}
