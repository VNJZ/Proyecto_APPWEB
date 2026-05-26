import 'package:flutter/material.dart';
import 'models/auth_session.dart';
import 'screens/feed_screen.dart';
import 'models/user_profile.dart';
import 'pantalla_mensajes.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'services/mock_auth_service.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AuthSession? _session = MockAuthService.currentSession;

  void _handleLogin(AuthSession session) {
    setState(() => _session = session);
  }

  void _handleLogout() {
    MockAuthService.signOut();
    setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return LoginScreen(onLoginSuccess: _handleLogin);
    }

    return PaginaPrincipal(
      session: _session!,
      onLogout: _handleLogout,
    );
  }
}

class PaginaPrincipal extends StatefulWidget {
  final AuthSession session;
  final VoidCallback onLogout;

  const PaginaPrincipal({
    super.key,
    required this.session,
    required this.onLogout,
  });

  @override
  State<PaginaPrincipal> createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  int _paginaActual = 0;
  UserProfile _profile = mockUserProfile;

  @override
  void initState() {
    super.initState();
    _profile = mockUserProfile.copyWith(
      fullName: widget.session.displayName,
      email: widget.session.email,
    );
  }

  void _updateProfile(UserProfile updatedProfile) {
    setState(() => _profile = updatedProfile);
  }

  void _handleLogout() {
    setState(() => _paginaActual = 0);
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final paginas = [
      const FeedScreen(),
      const PantallaMensajes(),
      ProfileScreen(
        profile: _profile,
        onProfileUpdated: _updateProfile,
        onLogout: _handleLogout,
      ),
    ];

    return Scaffold(
      body: paginas[_paginaActual],
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
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
  }
}
