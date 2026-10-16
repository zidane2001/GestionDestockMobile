import 'package:flutter_test/flutter_test.dart';
import 'package:ma_boutique/core/format.dart';
import 'package:ma_boutique/models/models.dart';

void main() {
  group('formatMontant', () {
    test('FCFA affiche un nombre entier sans décimales', () {
      final r = formatMontant(12000, 'FCFA');
      expect(r, contains('12'));
      expect(r, isNot(contains('.')));
    });
    test('FCFA groupe les milliers', () {
      expect(formatMontant(125000, 'FCFA'), contains('FCFA'));
    });
    test('EUR affiche 2 décimales avec point', () {
      final r = formatMontant(12.5, 'EUR');
      expect(r, contains('€'));
      expect(r, contains('12.50'));
    });
    test('USD affiche 2 décimales avec point', () {
      final r = formatMontant(99.9, 'USD');
      expect(r, contains(r'$'));
      expect(r, contains('99.90'));
    });
    test('valeur 0', () => expect(formatMontant(0, 'FCFA'), contains('0')));
    test('valeur négative', () => expect(formatMontant(-5000, 'FCFA'), contains('-')));
    test('montant très grand', () => expect(formatMontant(1500000, 'FCFA'), contains('FCFA')));
    test('monnaie par défaut est FCFA', () => expect(formatMontant(1000), contains('FCFA')));
  });

  group('formatCompact', () {
    test('millions', () => expect(formatCompact(1200000), '1.2 M'));
    test('milliers', () => expect(formatCompact(486000), '486 k'));
    test('petit nombre', () => expect(formatCompact(120), '120'));
    test('zéro', () => expect(formatCompact(0), '0'));
    test('négatif', () => expect(formatCompact(-5000), contains('-')));
  });

  group('cleJour', () {
    test('format YYYY-MM-DD', () => expect(cleJour(DateTime(2026, 8, 22)), '2026-08-22'));
    test('jours < 10 zéro-padded', () => expect(cleJour(DateTime(2026, 1, 5)), '2026-01-05'));
  });

  group('heureLocale', () {
    test('format HH:mm', () => expect(heureLocale(DateTime(2026, 8, 22, 14, 5)), '14:05'));
    test('minuit', () => expect(heureLocale(DateTime(2026, 8, 22, 0, 0)), '00:00'));
  });

  group('jourCourt / jourCourtDate', () {
    test('jourCourt avec ISO string', () {
      final r = jourCourt('2026-08-22T10:30:00');
      expect(r, isNotEmpty);
      expect(r, isNot(contains('T')));
    });
    test('jourCourtDate avec DateTime', () => expect(jourCourtDate(DateTime(2026, 1, 1)), isNotEmpty));
  });

  group('jourLongDate', () {
    test('format complet', () => expect(jourLongDate(DateTime(2026, 8, 22)), isNotEmpty));
  });

  group('heure', () {
    test('extrait HH:mm depuis ISO', () => expect(heure('2026-08-22T14:30:00'), '14:30'));
  });

  group('dateHeure', () {
    test('combine date et heure', () => expect(dateHeure('2026-08-22T14:30:00'), isNotEmpty));
  });

  group('ilYA', () {
    test('moment très récent = à l\'instant', () {
      final now = DateTime.now().toUtc().toIso8601String();
      expect(ilYA(now), contains('instant'));
    });
    test('il y a quelques minutes', () {
      final d = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
      expect(ilYA(d.toIso8601String()), contains('min'));
    });
    test('hier', () {
      final d = DateTime.now().toUtc().subtract(const Duration(hours: 25));
      expect(ilYA(d.toIso8601String()).toLowerCase(), contains('hier'));
    });
  });

  group('roleLabel', () {
    test('patron', () => expect(roleLabel(Role.patron), isNotEmpty));
    test('manager', () => expect(roleLabel(Role.manager), isNotEmpty));
    test('caissière', () => expect(roleLabel(Role.caissiere), isNotEmpty));
  });
}
