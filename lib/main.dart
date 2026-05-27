import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'models/auth_session.dart';
import 'models/user_profile.dart';
import 'screens/feed_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/publish_pet_screen.dart';
import 'screens/preferences_dialog.dart';
import 'pantalla_mensajes.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patitas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1D9E75),
      ),
      home: const AppShell(),
    );
  }
}

// ── Shell: escucha el estado de Firebase Auth ────────────────────────────────

/// Reacciona en tiempo real a los cambios de sesión.
///
/// - Mientras se resuelve la primera lectura: pantalla de carga.
/// - Sin sesión: muestra [LoginScreen].
/// - Con sesión: muestra [PaginaPrincipal] con la [AuthSession] del usuario.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthSession?>(
      stream: AuthService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data;
        if (session == null) {
          return const LoginScreen();
        }
        return PaginaPrincipal(session: session);
      },
    );
  }
}

// ── Navegación principal ──────────────────────────────────────────────────────

class PaginaPrincipal extends StatefulWidget {
  final AuthSession session;

  const PaginaPrincipal({super.key, required this.session});

  @override
  State<PaginaPrincipal> createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  int _paginaActual = 0;
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = mockUserProfile.copyWith(
      fullName: widget.session.displayName,
      email: widget.session.email,
    );
    if (!widget.session.isOrganizacion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verificarPreferencias();
      });
    }
  }

  Future<void> _verificarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = widget.session.userId;
    final yaDefinido = prefs.getBool('pref_set_$uid') ?? false;
    if (!yaDefinido && mounted) {
      PreferencesDialog.show(context, uid);
    }
  }

  void _updateProfile(UserProfile updated) {
    setState(() => _profile = updated);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.session.userId).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final roleStr = userData['role'] as String? ?? (widget.session.isOrganizacion ? 'organizacion' : 'adoptante');
        final isOrganizacion = roleStr == 'organizacion';
        final displayName = userData['displayName'] as String? ?? widget.session.displayName;

        final currentSession = AuthSession(
          userId: widget.session.userId,
          email: widget.session.email,
          displayName: displayName,
          role: isOrganizacion ? UserRole.organizacion : UserRole.adoptante,
          orgId: isOrganizacion ? widget.session.userId : null,
        );

        final paginas = [
          const FeedScreen(),
          const PantallaMensajes(),
          ProfileScreen(
            session: currentSession,
            profile: _profile,
            onProfileUpdated: _updateProfile,
          ),
        ];

        return Scaffold(
          body: paginas[_paginaActual],
          // FAB de publicar mascota — visible para todos los usuarios.
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PublishPetScreen()),
            ),
            tooltip: 'Publicar mascota',
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.home,
                    color: _paginaActual == 0
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: () => setState(() => _paginaActual = 0),
                  tooltip: 'Inicio',
                ),
                const SizedBox(width: 48),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chat,
                        color: _paginaActual == 1
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () => setState(() => _paginaActual = 1),
                      tooltip: 'Mensajes',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.person,
                        color: _paginaActual == 2
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () => setState(() => _paginaActual = 2),
                      tooltip: 'Perfil',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
