import '../models/auth_session.dart';

class MockAuthService {
  // ── Cuenta demo: adoptante ──────────────────────────────────────────────────
  static const String adoptanteEmail = 'camila.rojas@patitas.app';
  static const String adoptantePassword = 'patitas123';

  // ── Cuenta demo: organización/refugio ──────────────────────────────────────
  static const String orgEmail = 'refugio.patitas@patitas.app';
  static const String orgPassword = 'refugio123';
  static const String orgIdFijo = 'org_refugio_patitas_001';

  /// Alias retrocompatibles. LoginScreen los usa para prellenar los campos.
  static const String demoEmail = adoptanteEmail;
  static const String demoPassword = adoptantePassword;

  static AuthSession? _currentSession;

  static AuthSession? get currentSession => _currentSession;

  static Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    AuthSession? session;

    if (normalizedEmail == adoptanteEmail &&
        normalizedPassword == adoptantePassword) {
      session = const AuthSession(
        userId: 'usuario_prueba_123',
        email: adoptanteEmail,
        displayName: 'Camila Rojas',
        role: UserRole.adoptante,
      );
    } else if (normalizedEmail == orgEmail &&
        normalizedPassword == orgPassword) {
      session = const AuthSession(
        userId: orgIdFijo,
        email: orgEmail,
        displayName: 'Refugio Patitas',
        role: UserRole.organizacion,
        orgId: orgIdFijo,
      );
    }

    if (session == null) {
      throw const AuthException(
        'Credenciales invalidas. Usa una de las cuentas de prueba.',
      );
    }

    _currentSession = session;
    return session;
  }

  static void signOut() {
    _currentSession = null;
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}
