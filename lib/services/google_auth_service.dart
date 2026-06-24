import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static const clientId =
      '766716089536-agkfc5doku43tcf8m9d13hrai813cgv0.apps.googleusercontent.com';

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  static bool _initialized = false;

  Stream<GoogleSignInAuthenticationEvent> get events =>
      _signIn.authenticationEvents;

  bool get usesExternalWebFlow => false;

  bool get isSupported {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (!isSupported) {
      throw Exception('Google no esta disponible en este dispositivo.');
    }

    try {
      await _signIn.initialize(serverClientId: clientId);
      _initialized = true;
    } on UnimplementedError {
      throw Exception('Google no esta disponible en este dispositivo.');
    }
  }

  Future<void> authenticate({bool registration = false}) async {
    try {
      await initialize();
      if (!_signIn.supportsAuthenticate()) {
        throw Exception('Google no esta disponible en este dispositivo.');
      }
      await _signIn.authenticate();
    } on UnimplementedError {
      throw Exception('Google no esta disponible en este dispositivo.');
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return;

      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw Exception(
          'Google no esta configurado para este APK. Revisa el paquete y la huella SHA-1.',
        );
      }

      throw Exception(
        error.description?.trim().isNotEmpty == true
            ? error.description!
            : 'No se pudo iniciar sesion con Google.',
      );
    }
  }
}
