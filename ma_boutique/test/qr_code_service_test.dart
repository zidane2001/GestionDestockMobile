import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ma_boutique/services/qr_code_service.dart';

void main() {
  group('QrCodeService.genererDataProduit', () {
    test('émet du JSON valide contenant le prix et la catégorie', () {
      final data = QrCodeService.genererDataProduit(
        produitId: 't9kntsf5',
        nom: 'QA F3 test',
        prixVente: 950,
        categorie: 'autre',
      );

      final decode = jsonDecode(data);
      expect(decode, isA<Map<String, dynamic>>());
      expect(decode['type'], 'produit');
      expect(decode['id'], 't9kntsf5');
      expect(decode['nom'], 'QA F3 test');
      expect(decode['prix'], 950.0);
      expect(decode['cat'], 'autre');
    });

    test("ne renvoie plus le toString() d'une carte Dart (ancien format fautif)",
        () {
      final data = QrCodeService.genererDataProduit(
        produitId: 'abc12345',
        nom: 'T-shirt',
        prixVente: 1200,
        categorie: 'autre',
      );

      // L'ancien rendu commençait par « {type: produit, id: ... » sans guillemets.
      expect(data, isNot(startsWith('{type:')));
      expect(data, contains('"id":"abc12345"'));
      expect(() => jsonDecode(data), returnsNormally);
    });
  });

  group('QrCodeService.parserQrProduit', () {
    test('relit le JSON généré (aller-retour)', () {
      final data = QrCodeService.genererDataProduit(
        produitId: 'abc12345',
        nom: 'T-shirt QA',
        prixVente: 1200,
        categorie: 'vetement',
      );

      final p = QrCodeService.parserQrProduit(data);
      expect(p, isNotNull);
      expect(p!['id'], 'abc12345');
      expect(p['nom'], 'T-shirt QA');
      expect(p['prix'], 1200.0);
      expect(p['categorie'], 'vetement');
    });

    test('lit l’ancien format toString() réellement stocké en base', () {
      // Chaîne relevée dans databases/ma_boutique.db sur un QR pré-correction :
      // {type: produit, id: fpa0klgo, nom: T-shirt QA, prix: 1200.0, cat: autre, v: 1}
      const legacy =
          '{type: produit, id: fpa0klgo, nom: T-shirt QA, prix: 1200.0, cat: autre, v: 1}';

      final p = QrCodeService.parserQrProduit(legacy);
      expect(p, isNotNull);
      expect(p!['id'], 'fpa0klgo');
      expect(p['nom'], 'T-shirt QA');
      expect(p['prix'], 1200.0);
      expect(p['categorie'], 'autre');
    });

    test('retourne null sur une donnée inexploitable', () {
      expect(QrCodeService.parserQrProduit(''), isNull);
      expect(QrCodeService.parserQrProduit('nimporte quoi'), isNull);
      expect(QrCodeService.parserQrProduit('{"type":"autre"}'), isNull);
    });
  });
}
