import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bucket Storage qui porte les images produits d'une boutique.
const String bucketImages = 'produits';

/// Chemin d'un objet dans le bucket : `boutique/produit/fichier.ext`.
///
/// Il est identique sur tous les appareils, contrairement à un chemin
/// absolu comme `/data/user/0/.../product_images/x.jpg` qui ne désigne
/// un fichier que sur l'appareil qui l'a créé.
String cheminObjetImage(String boutiqueId, String produitId, String chemin) {
  final nom = chemin.split(RegExp(r'[\\/]')).last;
  return '$boutiqueId/$produitId/$nom';
}

/// Service de gestion des images produits.
/// Stocke les images dans le répertoire documents de l'app et les partage
/// entre les appareils de la boutique via Supabase Storage.
class ImageService {
  static final ImageService instance = ImageService._();
  ImageService._();

  /// Vrai pour un chemin de fichier propre à cet appareil (`/data/...`,
  /// `C:\...`). Un chemin d'objet Storage est relatif.
  static bool estCheminLocal(String valeur) =>
      valeur.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(valeur);

  static String _typeMime(String chemin) {
    switch (p.extension(chemin).toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Envoie une image vers Storage et renvoie son chemin d'objet.
  Future<String> televerser(
    SupabaseClient client,
    String cheminLocal,
    String boutiqueId,
    String produitId,
  ) async {
    final objet = cheminObjetImage(boutiqueId, produitId, cheminLocal);
    final fichier = File(cheminLocal);
    if (!await fichier.exists()) return objet;
    await client.storage.from(bucketImages).uploadBinary(
          objet,
          await fichier.readAsBytes(),
          fileOptions: FileOptions(
            upsert: true,
            contentType: _typeMime(cheminLocal),
          ),
        );
    return objet;
  }

  /// Rapatrie une image de Storage et renvoie son chemin local, ou `null`
  /// si le téléchargement échoue. Un fichier déjà présent n'est pas
  /// retéléchargé.
  Future<String?> telecharger(SupabaseClient client, String objet) async {
    final dossier = await _dossier;
    final dest = p.join(dossier, p.basename(objet));
    final fichier = File(dest);
    if (await fichier.exists() && await fichier.length() > 0) return dest;
    final octets = await client.storage.from(bucketImages).download(objet);
    if (octets.isEmpty) return null;
    await fichier.writeAsBytes(octets);
    return dest;
  }

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
