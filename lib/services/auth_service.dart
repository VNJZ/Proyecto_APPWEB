import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_session.dart';

/// Servicio de autenticación basado en Firebase Auth + Firestore.
///
/// Cada cuenta tiene un documento `users/{uid}` con su rol. Al iniciar sesión
/// o al recibir un cambio de estado de Auth, este servicio lee ese doc y
/// arma una [AuthSession] con `role` y `orgId` (cuando aplica).
///
/// Convención: si `role == organizacion`, entonces `orgId == uid` del usuario.
/// Eso simplifica las queries `where('orgId', isEqualTo: ...)` en mascotas.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream que emite la sesión actual del usuario, o `null` si no hay nadie
  /// logueado. Se dispara cada vez que cambia el estado de Firebase Auth.
  ///
  /// El [AppShell] lo escucha vía `StreamBuilder` para decidir entre Login
  /// y la app principal sin tener que manejar estado manualmente.
  static Stream<AuthSession?> authStateChanges() {
    return _auth.authStateChanges().asyncMap(_buildSession);
  }

  static Future<AuthSession?> _buildSession(User? user) async {
    if (user == null) return null;
    return _readSessionFromFirestore(user);
  }

  static Future<AuthSession> _readSessionFromFirestore(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        // Usuario autenticado pero sin perfil — degradamos a adoptante.
        // Esto puede pasar si alguien crea la cuenta a mano en Firebase Console.
        return AuthSession(
          userId: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? user.email ?? 'Usuario',
          role: UserRole.adoptante,
        );
      }
      return _sessionFromDoc(user, doc.data()!);
    } catch (_) {
      // Sin conexión o error de Firestore: fallback a adoptante.
      return AuthSession(
        userId: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Usuario',
        role: UserRole.adoptante,
      );
    }
  }

  static AuthSession _sessionFromDoc(User user, Map<String, dynamic> data) {
    final roleStr = data['role'] as String? ?? 'adoptante';
    final role = roleStr == 'organizacion'
        ? UserRole.organizacion
        : UserRole.adoptante;
    return AuthSession(
      userId: user.uid,
      email: user.email ?? '',
      displayName: (data['displayName'] as String?) ??
          user.displayName ??
          user.email ??
          'Usuario',
      role: role,
      orgId: role == UserRole.organizacion ? user.uid : null,
    );
  }

  /// Inicia sesión con correo y contraseña. Después de autenticar,
  /// lee el doc `users/{uid}` para obtener el rol.
  static Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('No se pudo obtener el usuario.');
      }
      return _readSessionFromFirestore(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  /// Inicia sesión con Google.
  /// Si la cuenta de Google es nueva en el sistema de base de datos,
  /// la inicializamos por defecto como una cuenta de Adoptante.
  static Future<AuthSession> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw const AuthException('Inicio de sesión con Google cancelado.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw const AuthException('No se pudo obtener el usuario de Google.');
      }

      // Verificamos si existe su perfil en Firestore, si no, lo creamos como adoptante
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'displayName': user.displayName ?? 'Usuario Google',
          'email': user.email ?? '',
          'role': 'adoptante',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return _readSessionFromFirestore(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (e) {
      throw AuthException('Error en Google Sign-In: $e');
    }
  }

  /// Crea una nueva cuenta en Firebase Auth y escribe el doc `users/{uid}`
  /// con el rol elegido. Devuelve la sesión recién creada.
  static Future<AuthSession> signUp({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('No se pudo crear el usuario.');
      }

      // Guardar displayName en Auth para que aparezca en la UI por defecto.
      await user.updateDisplayName(displayName.trim());

      // Persistir el rol en Firestore.
      final roleStr =
          role == UserRole.organizacion ? 'organizacion' : 'adoptante';
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': displayName.trim(),
        'email': email.trim(),
        'role': roleStr,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return AuthSession(
        userId: user.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        role: role,
        orgId: role == UserRole.organizacion ? user.uid : null,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  static Future<void> signOut() => _auth.signOut();

  /// Mapea los códigos de error de Firebase Auth a mensajes en español.
  static String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Correo inválido.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos.';
      default:
        return 'Error de autenticación: ${e.message ?? e.code}';
    }
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}
