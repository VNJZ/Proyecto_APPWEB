import 'package:flutter/material.dart';
import 'screens/feed_screen.dart';
import 'pantalla_mensajes.dart';

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
      home: const PaginaPrincipal(),
    );
  }
}

class PaginaPrincipal extends StatefulWidget {
  const PaginaPrincipal({super.key});

  @override
  State<PaginaPrincipal> createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  int _paginaActual = 0;

  final List<Widget> _paginas = const [
    FeedScreen(),
    PantallaMensajes(),
    Center(child: Text('Perfil')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _paginas[_paginaActual],
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
