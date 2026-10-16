import 'package:flutter_test/flutter_test.dart';
import 'package:ma_boutique/core/permissions.dart';
import 'package:ma_boutique/models/models.dart';

void main() {
  group('permissionsParDefaut', () {
    test('patron a gererComptes', () {
      expect(permissionsParDefaut(Role.patron), contains(Permission.gererComptes));
    });
    test('patron a tous les permissions critiques', () {
      final p = permissionsParDefaut(Role.patron);
      expect(p, contains(Permission.gererProduits));
      expect(p, contains(Permission.vendre));
      expect(p, contains(Permission.voirPrixAchat));
    });
    test('manager a ventes et depenses', () {
      final p = permissionsParDefaut(Role.manager);
      expect(p, contains(Permission.vendre));
      expect(p, contains(Permission.depense));
    });
    test('manager N A PAS gererComptes', () {
      expect(permissionsParDefaut(Role.manager), isNot(contains(Permission.gererComptes)));
    });
    test('caissière a ventes et pointer', () {
      final p = permissionsParDefaut(Role.caissiere);
      expect(p, contains(Permission.vendre));
      expect(p, contains(Permission.pointer));
    });
    test('caissière N A PAS gererProduits', () {
      expect(permissionsParDefaut(Role.caissiere), isNot(contains(Permission.gererProduits)));
    });
    test('chaque appel retourne une copie indépendante', () {
      final p1 = permissionsParDefaut(Role.patron);
      final p2 = permissionsParDefaut(Role.patron);
      expect(identical(p1, p2), isFalse);
    });
    test('patron a 16 permissions', () => expect(permissionsParDefaut(Role.patron).length, 16));
    test('manager a 9 permissions', () => expect(permissionsParDefaut(Role.manager).length, 9));
    test('caissière a 5 permissions', () => expect(permissionsParDefaut(Role.caissiere).length, 5));
  });

  group('peut', () {
    test('employe avec permission custom = true', () {
      final employe = Employe(
        id: 'e1', nom: 'Test', role: Role.patron,
        permissions: [Permission.vendre],
        motDePasse: 'x', statut: StatutEmploye.actif,
        pinActif: false, pin: '', biometrie: false,
        dateCreation: '2026-01-01',
      );
      expect(peut(employe, Permission.vendre), isTrue);
    });
    test('employe sans permission custom = false', () {
      final employe = Employe(
        id: 'e1', nom: 'Test', role: Role.patron,
        permissions: [Permission.vendre],
        motDePasse: 'x', statut: StatutEmploye.actif,
        pinActif: false, pin: '', biometrie: false,
        dateCreation: '2026-01-01',
      );
      expect(peut(employe, Permission.gererComptes), isFalse);
    });
    test('null employe retourne toujours false', () {
      expect(peut(null, Permission.vendre), isFalse);
      expect(peut(null, Permission.gererComptes), isFalse);
    });
  });

  group('permissionsReservees', () {
    test('contient gererComptes', () => expect(permissionsReservees, contains(Permission.gererComptes)));
    test('contient appareils', () => expect(permissionsReservees, contains(Permission.appareils)));
    test('contient traiterRetours', () => expect(permissionsReservees, contains(Permission.traiterRetours)));
    test('a 3 éléments', () => expect(permissionsReservees.length, 3));
  });

  group('groupesPermissions', () {
    test('a 4 groupes', () => expect(groupesPermissions.length, 4));
    test('chaque groupe a des items', () {
      for (final g in groupesPermissions) {
        expect(g.items, isNotEmpty);
      }
    });
    test('toutes les permissions uniques sont couvertes', () {
      final all = <Permission>{};
      for (final g in groupesPermissions) {
        for (final item in g.items) {
          all.add(item.cle);
        }
      }
      expect(all.length, greaterThanOrEqualTo(10));
    });
  });
}
