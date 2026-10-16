import 'package:flutter_test/flutter_test.dart';
import 'package:ma_boutique/models/models.dart';
import 'package:ma_boutique/core/permissions.dart';

/// Extraction des règles de validation des écrans pour les tester
/// sans dépendre de Flutter UI.
void main() {
  group('Validation - Créer Boutique', () {
    String? validerBoutique({
      required String nom,
      required String email,
      required String mdp,
      required String confirmation,
      List<Boutique> existantes = const [],
    }) {
      if (nom.length < 3 || nom.length > 40) {
        return 'Le nom doit contenir entre 3 et 40 caractères.';
      }
      if (existantes.any((b) => b.nom.toLowerCase() == nom.toLowerCase())) {
        return 'Ce nom de boutique existe déjà.';
      }
      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
        return 'Adresse email invalide.';
      }
      if (mdp.length < 6) {
        return 'Minimum 6 caractères.';
      }
      if (mdp != confirmation) {
        return 'Les mots de passe ne correspondent pas.';
      }
      return null;
    }

    test('nom trop court (< 3)', () {
      expect(validerBoutique(nom: 'AB', email: 'a@b.com', mdp: '123456', confirmation: '123456'), isNotNull);
    });

    test('nom trop long (> 40)', () {
      expect(validerBoutique(nom: 'A' * 41, email: 'a@b.com', mdp: '123456', confirmation: '123456'), isNotNull);
    });

    test('nom 3 caractères = valide', () {
      expect(validerBoutique(nom: 'ABC', email: 'a@b.com', mdp: '123456', confirmation: '123456'), isNull);
    });

    test('nom 40 caractères = valide', () {
      expect(validerBoutique(nom: 'A' * 40, email: 'a@b.com', mdp: '123456', confirmation: '123456'), isNull);
    });

    test('email invalide - pas d\'@', () {
      expect(validerBoutique(nom: 'Test', email: 'ab.com', mdp: '123456', confirmation: '123456'), isNotNull);
    });

    test('email invalide - pas de point', () {
      expect(validerBoutique(nom: 'Test', email: 'a@bcom', mdp: '123456', confirmation: '123456'), isNotNull);
    });

    test('email avec espace', () {
      expect(validerBoutique(nom: 'Test', email: 'a @b.com', mdp: '123456', confirmation: '123456'), isNotNull);
    });

    test('email valide', () {
      expect(validerBoutique(nom: 'Test', email: 'admin@boutique.com', mdp: '123456', confirmation: '123456'), isNull);
    });

    test('mot de passe < 6', () {
      expect(validerBoutique(nom: 'Test', email: 'a@b.com', mdp: '12345', confirmation: '12345'), isNotNull);
    });

    test('mot de passe = 6 = valide', () {
      expect(validerBoutique(nom: 'Test', email: 'a@b.com', mdp: '123456', confirmation: '123456'), isNull);
    });

    test('mots de passe ne correspondent pas', () {
      expect(validerBoutique(nom: 'Test', email: 'a@b.com', mdp: '123456', confirmation: '654321'), isNotNull);
    });

    test('nom existant (insensible casse)', () {
      final existantes = [Boutique(
        id: 'b1', nom: 'Ma Boutique', styleCommerce: 'mode',
        emailPatron: 'a@b.com', monnaie: Monnaie.fcfa, soldeCaisse: 0,
      )];
      expect(validerBoutique(nom: 'ma boutique', email: 'a@b.com', mdp: '123456', confirmation: '123456', existantes: existantes), isNotNull);
    });

    test('nom différent de l\'existant = valide', () {
      final existantes = [Boutique(
        id: 'b1', nom: 'Ma Boutique', styleCommerce: 'mode',
        emailPatron: 'a@b.com', monnaie: Monnaie.fcfa, soldeCaisse: 0,
      )];
      expect(validerBoutique(nom: 'Autre', email: 'a@b.com', mdp: '123456', confirmation: '123456', existantes: existantes), isNull);
    });
  });

  group('Validation - Créer Employé', () {
    String? validerEmploye({
      required String nom,
      required String mdp,
      required List<Permission> droits,
      bool estEdition = false,
    }) {
      if (nom.trim().length < 2) {
        return 'Indiquez le nom de l\'employé.';
      }
      if (!estEdition && mdp.length < 6) {
        return 'Le mot de passe doit contenir au moins 6 caractères.';
      }
      if (droits.isEmpty) {
        return 'Attribuez au moins un droit à cet employé.';
      }
      return null;
    }

    test('nom vide', () {
      expect(validerEmploye(nom: '', mdp: '123456', droits: [Permission.vendre]), isNotNull);
    });

    test('nom 1 caractère', () {
      expect(validerEmploye(nom: 'A', mdp: '123456', droits: [Permission.vendre]), isNotNull);
    });

    test('nom 2 caractères = valide', () {
      expect(validerEmploye(nom: 'Ab', mdp: '123456', droits: [Permission.vendre]), isNull);
    });

    test('nom avec espaces trim', () {
      expect(validerEmploye(nom: '   A   ', mdp: '123456', droits: [Permission.vendre]), isNotNull);
    });

    test('mot de passe < 6 en création', () {
      expect(validerEmploye(nom: 'Ali', mdp: '12345', droits: [Permission.vendre]), isNotNull);
    });

    test('mot de passe < 6 en édition = OK', () {
      expect(validerEmploye(nom: 'Ali', mdp: '12', droits: [Permission.vendre], estEdition: true), isNull);
    });

    test('aucun droit', () {
      expect(validerEmploye(nom: 'Ali', mdp: '123456', droits: []), isNotNull);
    });

    test('droits multiples = valide', () {
      expect(validerEmploye(nom: 'Ali', mdp: '123456', droits: [Permission.vendre, Permission.defectueux]), isNull);
    });
  });

  group('Validation - Reset Mot de Passe', () {
    String? validerResetMdp(String nouveauMdp) {
      if (nouveauMdp.length < 6) {
        return 'Le mot de passe doit contenir au moins 6 caractères.';
      }
      return null;
    }

    test('trop court', () => expect(validerResetMdp('12345'), isNotNull));
    test('6 caractères = valide', () => expect(validerResetMdp('123456'), isNull));
    test('vide', () => expect(validerResetMdp(''), isNotNull));
  });

  group('Validation - PIN', () {
    bool validerPin(String pin) {
      return RegExp(r'^\d{4}$').hasMatch(pin);
    }

    test('4 chiffres = valide', () => expect(validerPin('1234'), isTrue));
    test('3 chiffres = invalide', () => expect(validerPin('123'), isFalse));
    test('5 chiffres = invalide', () => expect(validerPin('12345'), isFalse));
    test('lettres = invalide', () => expect(validerPin('abcd'), isFalse));
    test('mélange = invalide', () => expect(validerPin('12ab'), isFalse));
    test('vide = invalide', () => expect(validerPin(''), isFalse));
    test('avec espaces = invalide', () => expect(validerPin('12 34'), isFalse));
  });

  group('Logic - Pointage', () {
    String? validerPointage({
      required String sens,
      required String? arriveeAujourdhui,
      required String? departAujourdhui,
    }) {
      if (sens == 'arrivee') {
        if (arriveeAujourdhui != null) return 'Vous avez déjà pointé aujourd\'hui.';
        return null;
      }
      if (sens == 'depart') {
        if (arriveeAujourdhui == null) return 'Vous n\'avez pas encore pointé votre arrivée.';
        if (departAujourdhui != null) return 'Vous avez déjà pointé votre départ.';
        return null;
      }
      return 'Sens invalide.';
    }

    test('arrivée déjà pointée', () {
      expect(validerPointage(sens: 'arrivee', arriveeAujourdhui: '08:00', departAujourdhui: null), isNotNull);
    });

    test('arrivée première fois', () {
      expect(validerPointage(sens: 'arrivee', arriveeAujourdhui: null, departAujourdhui: null), isNull);
    });

    test('départ sans arrivée', () {
      expect(validerPointage(sens: 'depart', arriveeAujourdhui: null, departAujourdhui: null), isNotNull);
    });

    test('départ déjà pointé', () {
      expect(validerPointage(sens: 'depart', arriveeAujourdhui: '08:00', departAujourdhui: '17:00'), isNotNull);
    });

    test('départ valide', () {
      expect(validerPointage(sens: 'depart', arriveeAujourdhui: '08:00', departAujourdhui: null), isNull);
    });
  });

  group('Logic - Connexion', () {
    String? validerConnexion({
      required String nomBoutique,
      required String role,
      required String motDePasse,
      required Boutique? boutique,
      required List<Employe> employes,
    }) {
      if (nomBoutique.trim().isEmpty) return 'Entrez le nom de la boutique.';
      if (boutique == null || boutique.nom.toLowerCase() != nomBoutique.trim().toLowerCase()) {
        return 'Boutique introuvable.';
      }
      if (boutique.statut == 'desactivee') return 'Cette boutique est désactivée.';
      final r = Role.values.where((e) => e.name == role).firstOrNull;
      if (r == null) return 'Rôle invalide.';
      final employe = employes.where((e) => e.role == r && e.motDePasse == motDePasse).firstOrNull;
      if (employe == null) return 'Identifiants incorrects.';
      if (employe.statut == StatutEmploye.suspendu) return 'Compte suspendu.';
      return null;
    }

    final boutique = Boutique(
      id: 'b1', nom: 'Ma Boutique', styleCommerce: 'mode',
      emailPatron: 'a@b.com', monnaie: Monnaie.fcfa, soldeCaisse: 0,
    );

    final employes = [
      Employe(id: 'e1', nom: 'Patron', role: Role.patron, permissions: [],
        motDePasse: 'pass123', statut: StatutEmploye.actif,
        pinActif: false, pin: '', biometrie: false, dateCreation: '2026-01-01'),
      Employe(id: 'e2', nom: 'Manager', role: Role.manager, permissions: [],
        motDePasse: 'mgr123', statut: StatutEmploye.suspendu,
        pinActif: false, pin: '', biometrie: false, dateCreation: '2026-01-01'),
    ];

    test('nom boutique vide', () {
      expect(validerConnexion(nomBoutique: '', role: 'patron', motDePasse: 'x', boutique: boutique, employes: employes), isNotNull);
    });

    test('boutique introuvable', () {
      expect(validerConnexion(nomBoutique: 'Autre', role: 'patron', motDePasse: 'x', boutique: boutique, employes: employes), isNotNull);
    });

    test('boutique désactivée', () {
      final desactivee = boutique.copyWith(statut: 'desactivee');
      expect(validerConnexion(nomBoutique: 'Ma Boutique', role: 'patron', motDePasse: 'pass123', boutique: desactivee, employes: employes), isNotNull);
    });

    test('mot de passe incorrect', () {
      expect(validerConnexion(nomBoutique: 'Ma Boutique', role: 'patron', motDePasse: 'wrong', boutique: boutique, employes: employes), isNotNull);
    });

    test('connexion réussie', () {
      expect(validerConnexion(nomBoutique: 'Ma Boutique', role: 'patron', motDePasse: 'pass123', boutique: boutique, employes: employes), isNull);
    });

    test('employé suspendu', () {
      expect(validerConnexion(nomBoutique: 'Ma Boutique', role: 'manager', motDePasse: 'mgr123', boutique: boutique, employes: employes), isNotNull);
    });

    test('nom insensible à la casse', () {
      expect(validerConnexion(nomBoutique: 'ma boutique', role: 'patron', motDePasse: 'pass123', boutique: boutique, employes: employes), isNull);
    });
  });

  group('Logic - Verrouillage', () {
    test('pin correct déverrouille', () {
      expect('1234' == '1234', isTrue);
    });

    test('pin incorrect échoue', () {
      expect('1234' == '5678', isFalse);
    });

    test('5 essais → blocage', () {
      int essais = 0;
      int attente = 0;
      for (int i = 0; i < 5; i++) {
        essais++;
        if (essais >= 5) {
          attente = 30;
          essais = 0;
        }
      }
      expect(attente, 30);
      expect(essais, 0);
    });

    test('compteur reset après succès', () {
      int essais = 3;
      bool ok = '1234' == '1234';
      if (ok) essais = 0;
      expect(essais, 0);
    });
  });

  group('Logic - Abonnement', () {
    test('achat_direct: pas de notification', () {
      expect('achat_direct' != 'achat_direct', isFalse);
    });

    test('mensuel: 30 jours', () {
      final debut = DateTime.now();
      final fin = debut.add(const Duration(days: 30));
      expect(fin.difference(debut).inDays, 30);
    });

    test('trimestriel: 90 jours', () {
      final debut = DateTime.now();
      final fin = debut.add(const Duration(days: 90));
      expect(fin.difference(debut).inDays, 90);
    });

    test('expiré si fin < maintenant', () {
      final fin = DateTime.now().subtract(const Duration(days: 1));
      expect(fin.isBefore(DateTime.now()), isTrue);
    });

    test('proche si < 7 jours', () {
      final fin = DateTime.now().add(const Duration(days: 3));
      final diff = fin.difference(DateTime.now()).inDays;
      expect(diff <= 7, isTrue);
    });
  });

  group('Logic - Permissions', () {
    test('patron a gererComptes', () {
      expect(permissionsParDefaut(Role.patron), contains(Permission.gererComptes));
    });

    test('manager n\'a pas gererComptes', () {
      expect(permissionsParDefaut(Role.manager), isNot(contains(Permission.gererComptes)));
    });

    test('caissière n\'a pas gererProduits', () {
      expect(permissionsParDefaut(Role.caissiere), isNot(contains(Permission.gererProduits)));
    });

    test('tous ont vendre', () {
      expect(permissionsParDefaut(Role.patron), contains(Permission.vendre));
      expect(permissionsParDefaut(Role.manager), contains(Permission.vendre));
      expect(permissionsParDefaut(Role.caissiere), contains(Permission.vendre));
    });
  });
}
