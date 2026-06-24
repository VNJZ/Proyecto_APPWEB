import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_individual.dart';

//Fire contiene los mismos modelos que utilizamos en los codigos
class Chat {
  final String id;
  final String nombre;
  final String ultimoMensaje;
  final DateTime timestamp;
  final String petId;
  final bool matchAprobado;
  final List<String> participantes;
  final String orgId;
  final String adoptanteId;
  final bool adopcionFinalizada;

  Chat({
    required this.id,
    required this.nombre,
    required this.ultimoMensaje,
    required this.timestamp,
    required this.petId,
    required this.matchAprobado,
    required this.participantes,
    required this.orgId,
    required this.adoptanteId,
    required this.adopcionFinalizada,
  });
}

class PantallaMensajes extends StatelessWidget {
  const PantallaMensajes({super.key});

  String _formatearHora(DateTime timestamp) {
    final diferencia = DateTime.now().difference(timestamp);
    if (diferencia.isNegative) return 'ahora';
    if (diferencia.inMinutes < 1) return 'ahora';
    if (diferencia.inMinutes < 60) return 'hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24) return 'hace ${diferencia.inHours} h';
    return 'hace ${diferencia.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participantes', arrayContains: uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar chats: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes conversaciones aún',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Envía una solicitud para iniciar un chat.'),
                ],
              ),
            );
          }

          final chats = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestampRaw = data['timestamp'];
            final DateTime time = timestampRaw is Timestamp
                ? timestampRaw.toDate()
                : (timestampRaw is int
                      ? DateTime.fromMillisecondsSinceEpoch(timestampRaw)
                      : DateTime.now());

            return Chat(
              id: doc.id,
              nombre: data['nombre'] ?? 'Organización',
              ultimoMensaje: data['ultimoMensaje'] ?? '',
              timestamp: time,
              petId: data['petId'] ?? '',
              matchAprobado: data['matchAprobado'] ?? false,
              participantes: List<String>.from(data['participantes'] ?? []),
              orgId: data['orgId'] ?? '',
              adoptanteId: data['adoptanteId'] ?? '',
              adopcionFinalizada: data['adopcionFinalizada'] ?? false,
            );
          }).toList();

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatIndividual(chat: chat),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: Text(
                    chat.nombre.isNotEmpty ? chat.nombre[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(
                  chat.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  chat.ultimoMensaje,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _formatearHora(chat.timestamp),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
