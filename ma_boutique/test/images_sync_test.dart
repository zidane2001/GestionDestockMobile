import 'package:flutter_test/flutter_test.dart';
import 'package:ma_boutique/services/image_service.dart';

void main() {
  group('cheminObjetImage', () {
    test('construit boutique/produit/fichier depuis un chemin Android', () {
      expect(
        cheminObjetImage('b1', 'p1', '/data/user/0/app/product_images/123.jpg'),
        'b1/p1/123.jpg',
      );
    });

    test('normalise les séparateurs Windows', () {
      expect(
        cheminObjetImage('b1', 'p1', r'C:\Users\z\product_images\456.png'),
        'b1/p1/456.png',
      );
      expect(cheminObjetImage('b1', 'p1', 'C:/tmp/789.webp'), 'b1/p1/789.webp');
    });

    test('conserve un nom déjà simple', () {
      expect(cheminObjetImage('b1', 'p1', '789.webp'), 'b1/p1/789.webp');
    });

    test('le chemin ne dépend pas de l’appareil qui le fabrique', () {
      // Deux appareils produisent le même objet pour le même fichier.
      final depuisAndroid =
          cheminObjetImage('boutique-a', 'produit-1', '/data/user/0/x/photo.jpg');
      final depuisWindows = cheminObjetImage(
        'boutique-a',
        'produit-1',
        r'C:\Users\z\photo.jpg',
      );
      expect(depuisAndroid, depuisWindows);
      expect(depuisAndroid, 'boutique-a/produit-1/photo.jpg');
    });
  });

  group('estCheminLocal', () {
    test('reconnaît un chemin Android/iOS', () {
      expect(ImageService.estCheminLocal('/data/user/0/app/x.jpg'), isTrue);
    });

    test('reconnaît un chemin Windows', () {
      expect(ImageService.estCheminLocal(r'C:\images\x.jpg'), isTrue);
      expect(ImageService.estCheminLocal('C:/images/x.jpg'), isTrue);
    });

    test('ne confond pas un chemin d’objet Storage avec un fichier local', () {
      expect(ImageService.estCheminLocal('boutique/produit/x.jpg'), isFalse);
      expect(ImageService.estCheminLocal('boutique/produit/sous-dossier/x.jpg'), isFalse);
    });
  });
}
