import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';

class Champ extends StatelessWidget {
  final String label;
  final Widget enfant;
  final String? aide;
  final String? erreur;

  const Champ({super.key, required this.label, required this.enfant, this.aide, this.erreur});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink),
        ),
        const SizedBox(height: 6),
        enfant,
        if (erreur != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              erreur!,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.danger),
            ),
          )
        else if (aide != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(aide!, style: TextStyle(fontSize: 12, color: c.muted)),
          ),
      ],
    );
  }
}

/// Champ de saisie reprenant la classe `inputClass` du design React.
class Saisie extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? clavier;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;
  final TextAlign alignement;
  final bool masque;
  final int? maxLongueur;
  final String? Function(String)? filtre;
  final Widget? icone;
  final Widget? suffixe;

  const Saisie({
    super.key,
    this.controller,
    this.hint,
    this.clavier,
    this.onChanged,
    this.style,
    this.alignement = TextAlign.start,
    this.masque = false,
    this.maxLongueur,
    this.filtre,
    this.icone,
    this.suffixe,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final contenu = TextField(
      controller: controller,
      obscureText: masque,
      keyboardType: clavier,
      maxLength: maxLongueur,
      textAlign: alignement,
      style: (style ?? const TextStyle(fontSize: 15)).copyWith(
        color: c.ink,
      ),
      inputFormatters: filtre != null
          ? [
              _FiltreFormatter(filtre!),
            ]
          : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.muted.withValues(alpha: 0.7), fontSize: 15),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.primary),
        ),
        filled: true,
        fillColor: c.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        prefixIcon: icone != null
            ? Padding(padding: const EdgeInsets.only(left: 12, right: 8), child: icone)
            : null,
        suffixIcon: suffixe,
      ),
      onChanged: onChanged,
    );

    if (icone == null) return contenu;
    return SizedBox(
      height: 48,
      child: contenu,
    );
  }
}

class _FiltreFormatter extends TextInputFormatter {
  final String? Function(String) filtre;
  _FiltreFormatter(this.filtre);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final f = filtre(newValue.text);
    final resultat = f ?? newValue.text;
    if (resultat == newValue.text) return newValue;
    return TextEditingValue(
      text: resultat,
      selection: TextSelection.collapsed(offset: resultat.length),
    );
  }
}

/// Zone de texte multi-lignes reprenant `textareaClass`.
class ZoneTexte extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;

  const ZoneTexte({super.key, this.controller, this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 6,
      style: TextStyle(fontSize: 15, color: c.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.muted.withValues(alpha: 0.7), fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.primary),
        ),
        filled: true,
        fillColor: c.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      onChanged: onChanged,
    );
  }
}