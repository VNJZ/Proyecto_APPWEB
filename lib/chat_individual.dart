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

  Future<void> _aprobarAdopcion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Aprobar Adopción?'),
        content: const Text('Esto cerrará la adopción, actualizará el historial del adoptante y retirará a la mascota del muro público.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancelar')
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Aprobar')
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      
      // 1. Actualizar chat
      final chatRef = db.collection('chats').doc(widget.chat.id);
      batch.update(chatRef, {'adopcionFinalizada': true});
      
      // 2. Actualizar mascota
      final petRef = db.collection('mascotas').doc(widget.chat.petId);
      batch.update(petRef, {'estado': 'adoptado'});
      
      // 3. Actualizar solicitud
      final solRef = db.collection('solicitudes').doc(widget.chat.id);
      batch.update(solRef, {'estado': 'aprobada'});
      
      // 4. Enviar mensaje automático
      final msgRef = chatRef.collection('messages').doc();
      final msgTexto = '¡Felicidades! La adopción ha sido aprobada oficialmente. 🎉';
      batch.set(msgRef, {
        'id': msgRef.id,
        'texto': msgTexto,
        'senderUid': 'sistema',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      batch.update(chatRef, {
        'ultimoMensaje': msgTexto,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adopción aprobada con éxito'))
      );
    } catch (e) {
      debugPrint('Error al aprobar: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
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
        final bool adopcionFinalizada = chatData?['adopcionFinalizada'] ?? widget.chat.adopcionFinalizada;
        final String orgId = chatData?['orgId'] ?? widget.chat.orgId;

        return Scaffold(
          appBar: AppBar(
            title: Text(chatNombre),
            actions: [
              if (uidActual == orgId && !adopcionFinalizada)
                TextButton.icon(
                  onPressed: _aprobarAdopcion,
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  label: const Text(
                    'Aprobar Adopción', 
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                  ),
                ),
            ],
          ),
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
                          '¡Comienza la conversación!',
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
                        final esSistema = mensaje.senderUid == 'sistema';

                        if (esSistema) {
                          return Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Text(
                                mensaje.texto,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }

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
