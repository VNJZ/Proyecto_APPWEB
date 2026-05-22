import 'package:flutter/material.dart';
import 'chat_individual.dart';

// Modelo Chat con los mismos campos que tendrá en Firebase
class Chat {
  final String id;
  final String nombre;
  final String ultimoMensaje;
  final DateTime timestamp;
  final String petId;
  final bool matchAprobado;
  final List<String> participantes;

  Chat({
    required this.id,
    required this.nombre,
    required this.ultimoMensaje,
    required this.timestamp,
    required this.petId,
    required this.matchAprobado,
    required this.participantes,
  });
}

// Datos falsos (mock) — cuando conectemos Firebase, solo cambiamos de dónde vienen
final List<Chat> chatsMock = [
  Chat(
    id: 'chat_001',
    nombre: 'Refugio Huelitas',
    ultimoMensaje: 'Tu solicitud está siendo resada.',
    timestamp: DateTime.now().subtract(const Duration(minutes: 23)),
    petId: 'pet_001',
    matchAprobado: false,
    participantes: ['usuario_prueba_123', 'refugio_001'],
  ),
  Chat(
    id: 'chat_002',
    nombre: 'Refugio Patitas Felices',
    ultimoMensaje: '¡Bienvenido! ¿Tienes alguna pregunta sobre Max?',
    timestamp: DateTime.now().subtract(const Duration(hours: 11)),
    petId: 'pet_002',
    matchAprobado: true,
    participantes: ['usuario_prueba_123', 'refugio_002'],
  ),
  Chat(
    id: 'chat_003',
    nombre: 'Refugio El Arca',
    ultimoMensaje: 'Gracias por tu interés en adoptar.',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    petId: 'pet_003',
    matchAprobado: false,
    participantes: ['usuario_prueba_123', 'refugio_003'],
  ),
];

class PantallaMensajes extends StatelessWidget {
  const PantallaMensajes({super.key});

  String _formatearHora(DateTime timestamp) {
    final diferencia = DateTime.now().difference(timestamp);
    if (diferencia.inMinutes < 60) return 'hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24) return 'hace ${diferencia.inHours} h';
    return 'hace ${diferencia.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes')),
      body: ListView.separated(
        itemCount: chatsMock.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final chat = chatsMock[index];
          return ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatIndividual(chat: chat)),
              );
            },
            leading: CircleAvatar(
              child: Text(chat.nombre[0]),
            ),
            title: Text(chat.nombre),
            subtitle: Text(
              chat.matchAprobado ? chat.ultimoMensaje : '🔒 Chat bloqueado — esperando aprobación',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              _formatearHora(chat.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        },
      ),
    );
  }
}
