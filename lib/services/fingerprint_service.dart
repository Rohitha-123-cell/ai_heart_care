import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class FingerprintService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Check if biometrics are available on the device
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Check if device has any fingerprint sensor (in-display or side/root)
  Future<bool> hasFingerprintSensor() async {
    final availableBiometrics = await getAvailableBiometrics();
    return availableBiometrics.contains(BiometricType.fingerprint) ||
           availableBiometrics.contains(BiometricType.strong) ||
           availableBiometrics.contains(BiometricType.weak);
  }

  /// Authenticate using fingerprint (in-display or side-mounted)
  Future<bool> authenticate({
    String reason = 'Please authenticate to access the app',
  }) async {
    try {
      final canAuthenticate = await canCheckBiometrics() || 
                              await isDeviceSupported();
      
      if (!canAuthenticate) {
        return false;
      }

      // First try biometric-only authentication
      bool success = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      // If biometric fails, try without biometricOnly restriction
      // This allows fallback to device PIN/pattern/password
      if (!success) {
        success = await _localAuth.authenticate(
          localizedReason: reason,
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );
      }

      return success;
    } on PlatformException catch (e) {
      // Handle specific error codes
      print('Fingerprint authentication error: ${e.code} - ${e.message}');
      
      // Try fallback authentication on error
      try {
        return await _localAuth.authenticate(
          localizedReason: reason,
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );
      } on PlatformException {
        return false;
      }
    }
  }

  /// Get biometric type description
  Future<String> getBiometricTypeDescription() async {
    final availableBiometrics = await getAvailableBiometrics();
    
    if (availableBiometrics.contains(BiometricType.strong)) {
      return 'Strong biometric (in-display fingerprint)';
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint sensor (side/root fingerprint)';
    } else if (availableBiometrics.contains(BiometricType.weak)) {
      return 'Weak biometric';
    } else if (availableBiometrics.contains(BiometricType.face)) {
      return 'Face recognition';
    } else if (availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris recognition';
    }
    
    return 'No biometric sensor available';
  }

  /// Stop any ongoing authentication
  Future<bool> stopAuthentication() async {
    try {
      return await _localAuth.stopAuthentication();
    } on PlatformException {
      return false;
    }
  }
}
