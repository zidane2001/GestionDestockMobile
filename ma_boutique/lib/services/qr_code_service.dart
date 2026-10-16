import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';

class QrCodeService {
  static const int _qrSize = 300;

  /// Génère les données QR pour un produit (JSON compact)
  static String genererDataProduit({
    required String produitId,
    required String nom,
    required double prixVente,
    required String categorie,
  }) {
    final data = {
      'type': 'produit',
      'id': produitId,
      'nom': nom,
      'prix': prixVente,
      'cat': categorie,
      'v': 1,
    };
    return jsonEncode(data);
  }

  /// Génère un widget QR code affichable
  static Widget buildQrWidget(String data, {double size = 200}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      gapless: false,
      errorStateBuilder: (context, error) => Container(
        width: size,
        height: size,
        color: Colors.grey[200],
        child: const Center(child: Text('Erreur QR')),
      ),
    );
  }

  /// Génère le QR code en bytes pour impression/partage
  static Future<Uint8List?> genererQrBytes(String data, {int size = _qrSize}) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: false,
      );
      painter.paint(canvas, Size(size.toDouble(), size.toDouble()));
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Parse les données QR produit (JSON, avec repli sur l'ancien format
  /// `toString()` des QR générés avant correction).
  static Map<String, dynamic>? parserQrProduit(String data) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map && decoded['id'] != null) {
        return {
          'id': '${decoded['id']}',
          'nom': '${decoded['nom'] ?? ''}',
          'prix': (decoded['prix'] as num?)?.toDouble() ?? 0,
          'categorie': '${decoded['cat'] ?? ''}',
        };
      }
    } catch (_) {}
    // Anciens QR : `Map.toString()`, ni JSON ni guillemets.
    // Exemple réel en base : {type: produit, id: fpa0klgo, nom: T-shirt QA, ...}
    final id = _champTexte(data, 'id');
    if (id.isEmpty) return null;
    return {
      'id': id,
      'nom': _champTexte(data, 'nom'),
      'prix': double.tryParse(_champTexte(data, 'prix')) ?? 0,
      'categorie': _champTexte(data, 'cat'),
    };
  }

  /// Lit une valeur de l'ancien format, qu'elle soit citée (`'id': 'x'`)
  /// ou nue (`id: x`) — les deux existent dans les QR déjà émis.
  static String _champTexte(String data, String cle) {
    final m = RegExp("$cle['\"]?\\s*:\\s*([^,}]+)").firstMatch(data);
    if (m == null) return '';
    return (m.group(1) ?? '').trim().replaceAll(RegExp(r"^'+|'+$"), '');
  }
}