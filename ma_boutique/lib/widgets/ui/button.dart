import 'package:flutter/material.dart';

import '../../core/theme.dart';

enum VarianteBouton { primaire, secondaire, fantome, danger }

enum TailleBouton { sm, md, lg }

class Bouton extends StatelessWidget {
  final VarianteBouton variante;
  final TailleBouton taille;
  final bool pleineLargeur;
  final VoidCallback? onPressed;
  final Widget child;

  const Bouton({
    super.key,
    this.variante = VarianteBouton.primaire,
    this.taille = TailleBouton.md,
    this.pleineLargeur = false,
    this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (hauteur, rayon, tailleTexte, espace) = switch (taille) {
      TailleBouton.sm => (36.0, 12.0, 13.0, 6.0),
      TailleBouton.md => (44.0, 12.0, 14.0, 8.0),
      TailleBouton.lg => (56.0, 16.0, 15.0, 8.0),
    };
    final (fond, texte, bordure) = switch (variante) {
      VarianteBouton.primaire => (c.primary, c.onPrimary, null),
      VarianteBouton.secondaire => (c.surface2, c.ink, c.line),
      VarianteBouton.fantome => (Colors.transparent, c.ink, null),
      VarianteBouton.danger => (c.danger, Colors.white, null),
    };

    return SizedBox(
      width: pleineLargeur ? double.infinity : null,
      height: hauteur,
      child: Material(
        color: fond,
        borderRadius: BorderRadius.circular(rayon),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(rayon),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: espace * 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(rayon),
              border: bordure != null ? Border.all(color: bordure) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontSize: tailleTexte,
                      fontWeight: FontWeight.w600,
                      color: texte,
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}