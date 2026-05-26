import '../models/auth_session.dart';

class MockAuthService {
  static const String demoEmail = 'camila.rojas@patitas.app';
  static const String demoPassword = 'patitas123';

  static AuthSession? _currentSession;

  static AuthSession? get currentSession => _currentSession;

  static Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedEmail != demoEmail || normalizedPassword != demoPassword) {
      throw const AuthException(
        'Credenciales invalidas. Usa la cuenta de prueba para entrar.',
      );
    }

    final session = AuthSession(
      userId: 'usuario_prueba_123',
      email: demoEmail,
      displayName: 'Camila Rojas',
    );

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
