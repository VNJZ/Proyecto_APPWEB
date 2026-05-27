import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

// UID del usuario actual desde Firebase Auth.
String get uidActual =>
    FirebaseAuth.instance.currentUser?.uid ?? 'usuario_anonimo';

class ChatIndividual extends StatefulWidget {
  final Chat chat;

  const ChatIndividual({super.key, required this.chat});

  @override
  State<ChatIndividual> createState() => _ChatIndividualState();
}

class _ChatIndividualState extends State<ChatIndividual> {
  final TextEditingController _controlador = TextEditingController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _enviarMensaje() async {
    final texto = _controlador.text.trim();
    if (texto.isEmpty) return;
    _controlador.clear();

    try {
      final db = FirebaseFirestore.instance;
      final chatRef = db.collection('chats').doc(widget.chat.id);
      
      final msgRef = chatRef.collection('messages').doc();
      final batch = db.batch();
      
      batch.set(msgRef, {
        'id': msgRef.id,
        'texto': texto,
        'senderUid': uidActual,
        'timestamp': FieldValue.serverTimestamp(),
      });

      batch.update(chatRef, {
        'ultimoMensaje': texto,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error al enviar mensaje: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').doc(widget.chat.id).snapshots(),
      builder: (context, chatSnapshot) {
        final chatData = chatSnapshot.data?.data() as Map<String, dynamic>?;
        final bool matchAprobado = chatData?['matchAprobado'] ?? widget.chat.matchAprobado;
        final String chatNombre = chatData?['nombre'] ?? widget.chat.nombre;

        return Scaffold(
          appBar: AppBar(title: Text(chatNombre)),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chat.id)
                      .collection('messages')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, msgSnapshot) {
                    if (msgSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final docs = msgSnapshot.data?.docs ?? [];
                    final mensajes = docs.map((doc) {
                      final mData = doc.data() as Map<String, dynamic>;
                      final ts = mData['timestamp'];
                      final DateTime time = ts is Timestamp ? ts.toDate() : DateTime.now();
                      
                      return Mensaje(
                        id: doc.id,
                        texto: mData['texto'] ?? '',
                        senderUid: mData['senderUid'] ?? '',
                        timestamp: time,
                      );
                    }).toList();

                    if (mensajes.isEmpty) {
                      return Center(
                        child: Text(
                          matchAprobado 
                              ? '¡Chat desbloqueado! Comienza la conversación.' 
                              : 'Solicitud enviada. Chat bloqueado hasta la aprobación.',
                          style: TextStyle(color: Theme.of(context).colorScheme.outline),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: mensajes.length,
                      itemBuilder: (context, index) {
                        final mensaje = mensajes[index];
                        final esMio = mensaje.senderUid == uidActual;
                        return Align(
                          alignment:
                              esMio ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
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
                    );
                  },
                ),
              ),
              if (!matchAprobado)
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
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Escribe un mensaje...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            onSubmitted: (_) => _enviarMensaje(),
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
      },
    );
  }
}
