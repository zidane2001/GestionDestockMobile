import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service de gestion des images produits.
/// Stocke les images dans le répertoire documents de l'app.
class ImageService {
  static final ImageService instance = ImageService._();
  ImageService._();

  Future<String> get _dossier async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'product_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir.path;
  }

  /// Ouvre la galerie et retourne les chemins des images sélectionnées.
  Future<List<String>> selectionnerImages({int maxImages = 5}) async {
    final picker = ImagePicker();
    final xfiles = await picker.pickMultiImage(imageQuality: 80);
    if (xfiles.isEmpty) return [];
    final result = <String>[];
    final dossier = await _dossier;
    for (final xfile in xfiles.take(maxImages - result.length)) {
      final ext = p.extension(xfile.path);
      final nom = '${DateTime.now().microsecondsSinceEpoch}$ext';
      final dest = p.join(dossier, nom);
      await File(xfile.path).copy(dest);
      result.add(dest);
    }
    return result;
  }

  /// Ajoute une image à la liste existante.
  Future<String?> ajouterImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xfile == null) return null;
    final dossier = await _dossier;
    final ext = p.extension(xfile.path);
    final nom = '${DateTime.now().microsecondsSinceEpoch}$ext';
    final dest = p.join(dossier, nom);
    await File(xfile.path).copy(dest);
    return dest;
  }

  /// Supprime une image du stockage local.
  Future<void> supprimerImage(String chemin) async {
    final f = File(chemin);
    if (await f.exists()) await f.delete();
  }

  /// Vérifie si un fichier image existe.
  Future<bool> existe(String chemin) async {
    return File(chemin).exists();
  }
}
