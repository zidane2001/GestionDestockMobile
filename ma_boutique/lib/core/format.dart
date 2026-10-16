import 'package:flutter/material.dart';

import '../models/models.dart';

const _monnaies = {
  'FCFA': 'FCFA',
  'EUR': '€',
  'USD': r'$',
};

/// Formatte un montant à la française (groupe de milliers en espace fine).
/// FCFA : entier + suffixe ; EUR/USD : 2 décimales max + symbole préfixé.
String formatMontant(double valeur, [String monnaie = 'FCFA']) {
  final arrondi = (valeur * 100).round() / 100;
  final maxDec = monnaie == 'FCFA' ? 0 : 2;
  final n = arrondi.toStringAsFixed(maxDec);
  final entiere = n.split('.')[0];
  final decimale = n.contains('.') ? '.${n.split('.')[1]}' : '';
  final groupee = _grouper(entiere);
  final texte = '$groupee$decimale';
  if (monnaie == 'FCFA') return '$texte FCFA';
  return '${_monnaies[monnaie] ?? ''}$texte';
}

String _grouper(String digits) {
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('\u202F');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Version compacte : "1.2 M", "486 k", "120".
String formatCompact(double valeur) {
  final abs = valeur.abs();
  if (abs >= 1000000) return '${(valeur / 1000000).toStringAsFixed(1)} M';
  if (abs >= 1000) return '${(valeur / 1000).round()} k';
  return valeur.round().toString();
}

const _moisCourt = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

const _joursSemaine = [
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];

DateTime _local(String iso) => DateTime.parse(iso).toLocal();

String jourCourt(String iso) {
  final d = _local(iso);
  return '${d.day.toString().padLeft(2, '0')} ${_moisCourt[d.month - 1]}';
}

String jourCourtDate(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')} ${_moisCourt[d.month - 1]}';
}

String jourLongDate(DateTime d) {
  return '${_joursSemaine[d.weekday - 1]} ${d.day.toString().padLeft(2, '0')} ${_moisCourt[d.month - 1]}';
}

String heure(String iso) {
  final d = _local(iso);
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

String dateHeure(String iso) => '${jourCourt(iso)} · ${heure(iso)}';

String ilYA(String iso) {
  final diff = DateTime.now().difference(DateTime.parse(iso));
  final min = diff.inMinutes;
  if (min < 1) return "à l'instant";
  if (min < 60) return 'il y a $min min';
  final h = (min / 60).round();
  if (h < 24) return 'il y a $h h';
  final j = (h / 24).round();
  return j == 1 ? 'hier' : 'il y a $j j';
}

/// Clé de jour au format ISO (AAAA-MM-JJ), fuseau local.
String cleJour(DateTime d) {
  final local = DateTime(d.year, d.month, d.day);
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Heure courante locale au format HH:mm (français).
String heureLocale(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String roleLabel(Role role) => role.label;

/// Style de texte pour chiffres à largeur tabulaire (tnum).
TextStyle tnum(TextStyle base) => base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);