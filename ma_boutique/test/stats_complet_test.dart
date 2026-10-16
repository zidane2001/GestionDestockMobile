import 'package:flutter_test/flutter_test.dart';
import 'package:ma_boutique/core/stats.dart';
import 'package:ma_boutique/models/models.dart';

Vente _v({
  required String produitId,
  required String produitNom,
  required double quantite,
  required double prixUnitaireReel,
  required double prixAchatUnitaire,
  required String date,
}) {
  return Vente(
    id: 'v_${DateTime.now().microsecondsSinceEpoch}',
    produitId: produitId, produitNom: produitNom,
    quantite: quantite, prixUnitaireReel: prixUnitaireReel,
    prixAchatUnitaire: prixAchatUnitaire, total: quantite * prixUnitaireReel,
    vendeurId: 'e1', vendeurNom: 'Test', vendeurRole: Role.caissiere, date: date,
  );
}

void main() {
  group('chiffreAffaires', () {
    test('somme des totaux', () {
      final ventes = [
        _v(produitId: 'p1', produitNom: 'A', quantite: 2, prixUnitaireReel: 5000, prixAchatUnitaire: 3000, date: '2026-08-20T10:00:00'),
        _v(produitId: 'p2', produitNom: 'B', quantite: 1, prixUnitaireReel: 10000, prixAchatUnitaire: 6000, date: '2026-08-20T11:00:00'),
      ];
      expect(chiffreAffaires(ventes), 20000);
    });
    test('liste vide = 0', () => expect(chiffreAffaires([]), 0));
  });

  group('margeTotale', () {
    test('calcule la marge correctement', () {
      final ventes = [
        _v(produitId: 'p1', produitNom: 'A', quantite: 2, prixUnitaireReel: 5000, prixAchatUnitaire: 3000, date: '2026-08-20T10:00:00'),
      ];
      expect(margeTotale(ventes), 4000);
    });
    test('liste vide = 0', () => expect(margeTotale([]), 0));
  });

  group('beneficeNet', () {
    test('marge moins dépenses', () {
      final ventes = [
        _v(produitId: 'p1', produitNom: 'A', quantite: 1, prixUnitaireReel: 10000, prixAchatUnitaire: 6000, date: '2026-08-20T10:00:00'),
      ];
      final depenses = [
        Depense(id: 'd1', description: 'Loyer', montant: 2000, auteurNom: 'Test', auteurRole: Role.patron, type: TypeDepense.depense, date: '2026-08-20T12:00:00'),
      ];
      expect(beneficeNet(ventes, depenses), 2000);
    });
    test('sans dépenses', () {
      final ventes = [
        _v(produitId: 'p1', produitNom: 'A', quantite: 1, prixUnitaireReel: 10000, prixAchatUnitaire: 6000, date: '2026-08-20T10:00:00'),
      ];
      expect(beneficeNet(ventes, []), 4000);
    });
    test('sans ventes = -dépenses', () {
      final depenses = [
        Depense(id: 'd1', description: 'Loyer', montant: 3000, auteurNom: 'Test', auteurRole: Role.patron, type: TypeDepense.depense, date: '2026-08-20T12:00:00'),
      ];
      expect(beneficeNet([], depenses), -3000);
    });
  });

  group('piecesVendues', () {
    test('somme des quantités', () {
      final ventes = [
        _v(produitId: 'p1', produitNom: 'A', quantite: 3, prixUnitaireReel: 5000, prixAchatUnitaire: 3000, date: '2026-08-20T10:00:00'),
        _v(produitId: 'p2', produitNom: 'B', quantite: 5, prixUnitaireReel: 10000, prixAchatUnitaire: 6000, date: '2026-08-20T11:00:00'),
      ];
      expect(piecesVendues(ventes), 8);
    });
  });

  group('valeurStock', () {
    test('produits actifs uniquement', () {
      final produits = [
        Produit(id: 'p1', nom: 'A', prixAchat: 3000, prixVente: 5000, quantite: 10, actif: true),
        Produit(id: 'p2', nom: 'B', prixAchat: 6000, prixVente: 10000, quantite: 5, actif: false),
      ];
      expect(valeurStock(produits), 50000);
    });
    test('liste vide = 0', () => expect(valeurStock([]), 0));
    test('produits avec quantité 0', () {
      expect(valeurStock([Produit(id: 'p1', nom: 'A', prixAchat: 3000, prixVente: 5000, quantite: 0)]), 0);
    });
  });

  group('distance (Levenshtein)', () {
    test('mots identiques = 0', () => expect(distance('chat', 'chat'), 0));
    test('un caractère diffère', () => expect(distance('chat', 'chats'), 1));
    test('complètement différents', () => expect(distance('abc', 'xyz'), greaterThan(0)));
    test('chaine vide', () {
      expect(distance('', 'test'), 4);
      expect(distance('test', ''), 4);
      expect(distance('', ''), 0);
    });
  });

  group('rechercheProduits', () {
    test('recherche par nom', () {
      final produits = [
        Produit(id: 'p1', nom: 'Chemise coton', prixAchat: 3000, prixVente: 5000, quantite: 10),
        Produit(id: 'p2', nom: 'Robe wax', prixAchat: 6000, prixVente: 10000, quantite: 5),
      ];
      expect(rechercheProduits(produits, 'Chemise').length, 1);
    });
    test('requête vide = tous les produits', () {
      expect(rechercheProduits([Produit(id: 'p1', nom: 'A', prixAchat: 3000, prixVente: 5000, quantite: 10)], '').length, 1);
    });
    test('pas de résultat', () {
      expect(rechercheProduits([Produit(id: 'p1', nom: 'Chemise', prixAchat: 3000, prixVente: 5000, quantite: 10)], 'xyz'), isEmpty);
    });
    test('insensible à la casse', () {
      expect(rechercheProduits([Produit(id: 'p1', nom: 'Chemise', prixAchat: 3000, prixVente: 5000, quantite: 10)], 'chemise').length, 1);
    });
  });

  group('classementProduits', () {
    test('trie par quantité décroissante', () {
      final ventes = [
        _v(produitId: 'p1', produitNom: 'A', quantite: 2, prixUnitaireReel: 5000, prixAchatUnitaire: 3000, date: '2026-08-20T10:00:00'),
        _v(produitId: 'p2', produitNom: 'B', quantite: 5, prixUnitaireReel: 10000, prixAchatUnitaire: 6000, date: '2026-08-20T11:00:00'),
        _v(produitId: 'p1', produitNom: 'A', quantite: 1, prixUnitaireReel: 5000, prixAchatUnitaire: 3000, date: '2026-08-20T12:00:00'),
      ];
      final r = classementProduits(ventes);
      expect(r.length, 2);
      expect(r.first.produitId, 'p2');
      expect(r.first.pieces, 5);
      expect(r.last.produitId, 'p1');
      expect(r.last.pieces, 3);
    });
    test('liste vide', () => expect(classementProduits([]), isEmpty));
  });

  group('ventesRecentes', () {
    test('filtre par date', () {
      final now = DateTime.now();
      final ventes = [
        _v(produitId: 'p1', produitNom: 'A', quantite: 1, prixUnitaireReel: 5000, prixAchatUnitaire: 3000, date: now.toIso8601String()),
        _v(produitId: 'p2', produitNom: 'B', quantite: 1, prixUnitaireReel: 5000, prixAchatUnitaire: 3000, date: now.subtract(const Duration(days: 10)).toIso8601String()),
      ];
      expect(ventesRecentes(ventes, 7).length, 1);
    });
  });

  group('tendance', () {
    test('pas de ventes = 0', () => expect(tendance([], 7), 0));
  });

  group('exporterCsvContent', () {
    test('contient le séparateur ;', () {
      final csv = exporterCsvContent([['Nom', 'Prix'], ['A', 1000]]);
      expect(csv, contains(';'));
      expect(csv, contains('Nom'));
      expect(csv, contains('A'));
    });
    test('BOM utf-8', () {
      final csv = exporterCsvContent([['Test']]);
      expect(csv.codeUnitAt(0), 0xFEFF);
    });
  });
}
