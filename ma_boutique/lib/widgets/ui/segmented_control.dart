import 'package:flutter/material.dart';

import '../../core/theme.dart';

class OptionSegmente<T> {
  final T valeur;
  final String label;

  const OptionSegmente(this.valeur, this.label);
}

class ControleSegmente<T> extends StatelessWidget {
  final List<OptionSegmente<T>> options;
  final T valeur;
  final ValueChanged<T> onChange;
  final String? libelle;

  const ControleSegmente({
    super.key,
    required this.options,
    required this.valeur,
    required this.onChange,
    this.libelle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: libelle,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final o in options)
              _Puce(
                actif: o.valeur == valeur,
                label: o.label,
                onTap: () => onChange(o.valeur),
              ),
          ],
        ),
      ),
    );
  }
}

class _Puce extends StatelessWidget {
  final bool actif;
  final String label;
  final VoidCallback onTap;

  const _Puce({required this.actif, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: actif ? c.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: actif ? c.ink : c.muted,
            ),
          ),
        ),
      ),
    );
  }
}