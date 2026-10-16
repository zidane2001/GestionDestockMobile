import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/theme.dart';

class ProductImage extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? categorie;

  const ProductImage({
    super.key,
    this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.categorie,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (imagePath == null || imagePath!.isEmpty) {
      return _Placeholder(c, borderRadius, categorie, width, height);
    }

    if (kIsWeb) {
      return _WebImage(imagePath!, width, height, fit, borderRadius, c, categorie);
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.file(
        File(imagePath!),
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (_, _, _) => _Placeholder(c, borderRadius, categorie, width, height),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final AppColors c;
  final BorderRadius? borderRadius;
  final String? categorie;
  final double? width;
  final double? height;

  const _Placeholder(this.c, this.borderRadius, this.categorie, this.width, this.height);

  @override
  Widget build(BuildContext context) {
    final icone = _iconeCategorie(categorie);
    final couleur = _couleurCategorie(categorie);

    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            couleur.withValues(alpha: 0.15),
            couleur.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Icon(icone, size: 48, color: couleur.withValues(alpha: 0.6)),
      ),
    );
  }

  IconData _iconeCategorie(String? cat) {
    switch (cat) {
      case 'vetement':
        return Icons.checkroom_rounded;
      case 'chaussure':
        return Icons.sports_football_rounded;
      case 'accessoire':
        return Icons.watch_rounded;
      case 'beaute':
        return Icons.face_rounded;
      case 'maison':
        return Icons.home_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Color _couleurCategorie(String? cat) {
    switch (cat) {
      case 'vetement':
        return const Color(0xFF4A90D9);
      case 'chaussure':
        return const Color(0xFFD4A76A);
      case 'accessoire':
        return const Color(0xFF9B59B6);
      case 'beaute':
        return const Color(0xFFE91E8C);
      case 'maison':
        return const Color(0xFF2ECC71);
      default:
        return const Color(0xFF95A5A6);
    }
  }
}

class _WebImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final AppColors c;
  final String? categorie;

  const _WebImage(this.imagePath, this.width, this.height, this.fit, this.borderRadius, this.c, this.categorie);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Container(
        width: width,
        height: height,
        color: c.surface2,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 32, color: c.muted),
              const SizedBox(height: 4),
              Text(
                'Images non supportées sur Web',
                style: TextStyle(fontSize: 10, color: c.muted),
                textAlign: TextAlign.center,
              ),
              Text(
                imagePath.split('/').last,
                style: TextStyle(fontSize: 9, color: c.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductImagePicker extends StatelessWidget {
  final List<String> images;
  final void Function(List<String>) onChanged;
  final int maxImages;
  final String? categorie;

  const ProductImagePicker({
    super.key,
    required this.images,
    required this.onChanged,
    this.maxImages = 5,
    this.categorie,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ProductImage(
                      imagePath: images[i],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(10),
                      categorie: categorie,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        final updated = List<String>.from(images)..removeAt(i);
                        onChanged(updated);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  if (i == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Principale',
                          style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (images.length < maxImages)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: () async {
                final picker = ImagePicker();
                final xfiles = await picker.pickMultiImage(imageQuality: 80, maxWidth: 1024, maxHeight: 1024);
                if (xfiles.isNotEmpty) {
                  final dir = await getApplicationDocumentsDirectory();
                  final imagesDir = Directory(p.join(dir.path, 'product_images'));
                  if (!await imagesDir.exists()) await imagesDir.create(recursive: true);
                  final newPaths = <String>[];
                  for (final xfile in xfiles.take(maxImages - images.length)) {
                    final ext = p.extension(xfile.path);
                    final nom = '${DateTime.now().microsecondsSinceEpoch}$ext';
                    final dest = p.join(imagesDir.path, nom);
                    await File(xfile.path).copy(dest);
                    newPaths.add(dest);
                  }
                  onChanged([...images, ...newPaths]);
                }
              },
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(images.isEmpty ? 'Ajouter des images' : 'Ajouter plus (${maxImages - images.length} max)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.primary,
                side: BorderSide(color: c.line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
      ],
    );
  }
}
