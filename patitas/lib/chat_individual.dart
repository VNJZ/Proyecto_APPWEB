import 'package:flutter/material.dart';
import 'pantalla_mensajes.dart';

// Modelo Mensaje con los mismos campos que tendrá en Firebase
class Mensaje {
  final String id;
  final String texto;
  final String senderUid;
  final DateTime timestamp;

  Mensaje({
    required this.id,
    required this.texto,
    required this.senderUid,
    required this.timestamp,
  });
}

// UID del usuario actual (cuando conectemos Firebase vendrá de FirebaseAuth)
const String uidActual = 'usuario_prueba_123';

// Mensajes mock por chat
final Map<String, List<Mensaje>> mensajesMock = {
  'chat_001': [
    Mensaje(
      id: 'msg_001',
      texto: 'Hola, me interesa adoptar a Mariano.',
      senderUid: 'usuario_prueba_123',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    Mensaje(
      id: 'msg_002',
      texto: 'Tu solicitud está siendo revisada.',
      senderUid: 'refugio_001',
      timestamp: DateTime.now().subtract(const Duration(minutes: 23)),
    ),
  ],
  'chat_002': [
    Mensaje(
      id: 'msg_003',
      texto: 'Buenos días, ¿Max sigue disponible?',
      senderUid: 'usuario_prueba_123',
      timestamp: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    Mensaje(
      id: 'msg_004',
      texto: '¡Bienvenido! ¿Tienes alguna pregunta sobre Max?',
      senderUid: 'refugio_002',
      timestamp: DateTime.now().subtract(const Duration(hours: 11)),
    ),
    Mensaje(
      id: 'msg_005',
      texto: '¿Cuántos años tiene?',
      senderUid: 'usuario_prueba_123',
      timestamp: DateTime.now().subtract(const Duration(hours: 10)),
    ),
  ],
  'chat_003': [],
};

class ChatIndividual extends StatefulWidget {
  final Chat chat;

  const ChatIndividual({super.key, required this.chat});

  @override
  State<ChatIndividual> createState() => _ChatIndividualState();
}

class _ChatIndividualState extends State<ChatIndividual> {
  final TextEditingController _controlador = TextEditingController();
  late List<Mensaje> _mensajes;

  @override
  void initState() {
    super.initState();
    _mensajes = List.from(mensajesMock[widget.chat.id] ?? []);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _enviarMensaje() {
    final texto = _controlador.text.trim();
    if (texto.isEmpty) return;
    setState(() {
      _mensajes.add(Mensaje(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        texto: texto,
        senderUid: uidActual,
        timestamp: DateTime.now(),
      ));
    });
    _controlador.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chat.nombre)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _mensajes.length,
              itemBuilder: (context, index) {
                final mensaje = _mensajes[index];
                final esMio = mensaje.senderUid == uidActual;
                return Align(
                  alignment:
                      esMio ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(   // Burbuja de mensaje
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: esMio
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      mensaje.texto,
                      style: TextStyle(
                        color: esMio
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (!widget.chat.matchAprobado)
            SafeArea(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 18),
                    SizedBox(width: 10),
                    Text('Esperando aprobación del refugio'),
                  ],
                ),
              ),
            )

          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controlador,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _enviarMensaje,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
