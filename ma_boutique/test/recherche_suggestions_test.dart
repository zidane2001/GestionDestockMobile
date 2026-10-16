import 'package:flutter_test/flutter_test.dart';
import 'package:ma_boutique/core/stats.dart';
import 'package:ma_boutique/models/models.dart';

Produit _p(String id, String nom, {double quantite = 5, String categorie = 'autre'}) =>
    Produit(id: id, nom: nom, prixAchat: 1000, prixVente: 2000, quantite: quantite, categorie: categorie);

void main() {
  group('normaliserRecherche', () {
    test('retire accents et ponctuation', () {
      expect(normaliserRecherche('Café crème !'), 'cafe creme');
    });

    test('compacte les espaces multiples', () {
      expect(normaliserRecherche('  Chemise   blanche  '), 'chemise blanche');
    });
  });

  group('suggestions instantanées', () {
    test('propose dès les premières lettres (préfixe)', () {
      final produits = [_p('p1', 'Chemise'), _p('p2', 'Pantalon')];
      final r = rechercheProduits(produits, 'che');
      expect(r.map((p) => p.id), ['p1']);
    });

    test('classe la correspondance exacte en premier', () {
      final produits = [_p('p1', 'Chemise blanche'), _p('p2', 'Chemise')];
      final r = rechercheProduits(produits, 'chemise');
      expect(r.first.id, 'p2');
    });

    test('ignore les accents, dans les deux sens', () {
      final produits = [_p('p1', 'Café moulu')];
      expect(rechercheProduits(produits, 'cafe').length, 1);
      expect(rechercheProduits(produits, 'café').length, 1);
    });

    test('accepte une requête en plusieurs mots', () {
      final produits = [_p('p1', 'Chemise blanche coton'), _p('p2', 'Robe')];
      final r = rechercheProduits(produits, 'chem blanche');
      expect(r.map((p) => p.id), ['p1']);
    });

    test('trouve par code de catégorie', () {
      final produits = [_p('p1', 'Article', categorie: 'chaussure')];
      expect(rechercheProduits(produits, 'chaussure').map((p) => p.id), ['p1']);
    });

    test('trouve par libellé de catégorie, accents compris', () {
      final produits = [_p('p1', 'Article', categorie: 'vetement')];
      expect(rechercheProduits(produits, 'vêtement').map((p) => p.id), ['p1']);
      expect(rechercheProduits(produits, 'vetement').map((p) => p.id), ['p1']);
    });

    test('la catégorie par défaut ne parasite pas la recherche', () {
      final produits = [_p('p1', 'Chemise')];
      expect(rechercheProduits(produits, 'zzz'), isEmpty);
    });

    test('tolère une faute de frappe', () {
      final produits = [_p('p1', 'Chemise')];
      expect(rechercheProduits(produits, 'chemisse').map((p) => p.id), ['p1']);
    });

    test('propose les produits en stock avant les ruptures', () {
      final produits = [
        _p('p1', 'Chemise bleue', quantite: 0),
        _p('p2', 'Chemise noire', quantite: 7),
      ];
      final r = rechercheProduits(produits, 'chemise');
      expect(r.map((p) => p.id), ['p2', 'p1']);
    });

    test('respecte la limite de suggestions', () {
      final produits = [_p('p1', 'Chemise'), _p('p2', 'Cheval'), _p('p3', 'Chapeau')];
      expect(rechercheProduits(produits, 'ch', limite: 2).length, 2);
    });

    test('requête vide conserve tous les produits', () {
      final produits = [_p('p1', 'Chemise'), _p('p2', 'Robe')];
      expect(rechercheProduits(produits, '   ').length, 2);
    });

    test('aucune correspondance = aucune suggestion', () {
      final produits = [_p('p1', 'Chemise')];
      expect(rechercheProduits(produits, 'zzz'), isEmpty);
    });
  });

  group('scoreCorrespondance', () {
    test('score nul pour un nom identique', () {
      expect(scoreCorrespondance(_p('p1', 'Chemise'), 'chemise'), 0);
    });

    test('score exclu au-delà de la tolérance', () {
      expect(
        scoreCorrespondance(_p('p1', 'Chemise'), 'zzzzz'),
        scoreAucuneCorrespondance,
      );
    });

    test('la tolérance grandit avec la longueur de la requête', () {
      expect(seuilTolerance('ab'), 2);
      expect(seuilTolerance('abcdefghij'), 3);
    });
  });
}
