import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService instance = BiometricService._();
  final LocalAuthentication _auth = LocalAuthentication();
  BiometricService._();

  Future<bool> get isAvailable async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  String getBiometricLabel(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Empreinte digitale';
    if (types.contains(BiometricType.strong)) return 'Biométrie forte';
    if (types.contains(BiometricType.weak)) return 'Biométrie simple';
    return 'Biométrie';
  }

  Future<BiometricResult> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool biometricOnly = false, // Samsung needs false for credential fallback
  }) async {
    try {
      final available = await isAvailable;
      if (!available) {
        return BiometricResult(success: false, error: 'Biométrie non disponible sur cet appareil');
      }

      final types = await availableBiometrics;
      if (types.isEmpty) {
        return BiometricResult(success: false, error: 'Aucune biométrie configurée dans les paramètres du téléphone');
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
        ),
      );

      return BiometricResult(success: didAuthenticate);
    } on PlatformException catch (e) {
      String error;
      switch (e.code) {
        case 'NotEnrolled':
          error = 'Aucune biométrie enregistrée. Ajoutez-en une dans les paramètres.';
          break;
        case 'LockedOut':
          error = 'Trop de tentatives. Utilisez votre code PIN.';
          break;
        case 'PermanentlyLockedOut':
          error = 'Biométrie verrouillée définitivement. Utilisez votre code PIN.';
          break;
        case 'UserCancel':
          error = 'Annulé par l\'utilisateur';
          break;
        case 'NotAvailable':
          error = 'Biométrie non disponible';
          break;
        default:
          error = 'Erreur biométrie: ${e.message}';
      }
      return BiometricResult(success: false, error: error);
    } catch (e) {
      return BiometricResult(success: false, error: 'Erreur inattendue: $e');
    }
  }
}

class BiometricResult {
  final bool success;
  final String? error;

  BiometricResult({required this.success, this.error});
}