import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Logo de la boutique, avec repli sur une icône si aucun logo n'a été fourni.
class LogoBoutique extends StatelessWidget {
  final String? logoUrl;
  final String? nom;
  final double taille;

  const LogoBoutique({super.key, this.logoUrl, this.nom, this.taille = 40});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (logoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(logoUrl!),
          width: taille,
          height: taille,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _defaut(c),
        ),
      );
    }
    return _defaut(c);
  }

  Widget _defaut(AppColors c) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        color: c.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.storefront_rounded, size: taille * 0.48, color: c.onPrimary),
    );
  }
}