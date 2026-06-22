import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrgPanelScreen extends StatelessWidget {
  final String orgId;

  const OrgPanelScreen({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de publicaciones')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mascotas')
            .where('orgId', isEqualTo: orgId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final mascotas = snapshot.data?.docs ?? [];
          if (mascotas.isEmpty) {
            final colorScheme = Theme.of(context).colorScheme;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets,
                    size: 64,
                    color: colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text('No hay mascotas publicadas aún'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: mascotas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = mascotas[index].data() as Map<String, dynamic>;
              final estado = data['estado'] as String? ?? 'disponible';
              return _MascotaCard(
                petId: mascotas[index].id,
                data: data,
                estado: estado,
              );
            },
          );
        },
      ),
    );
  }
}

class _MascotaCard extends StatelessWidget {
  final String petId;
  final Map<String, dynamic> data;
  final String estado;

  const _MascotaCard({
    required this.petId,
    required this.data,
    required this.estado,
  });

  String get _estadoLabel => switch (estado) {
    'disponible' => 'Disponible',
    'en_proceso' => 'En proceso',
    'adoptado' => 'Adoptado',
    _ => estado,
  };

  Color _colorEstado(BuildContext context) => switch (estado) {
    'disponible' => Theme.of(context).colorScheme.primary,
    'en_proceso' => Theme.of(context).colorScheme.tertiary,
    'adoptado' => Theme.of(context).colorScheme.outline,
    _ => Theme.of(context).colorScheme.outline,
  };

  void _mostrarSolicitudes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SolicitudesSheet(
        petId: petId,
        petNombre: data['nombre']?.toString() ?? 'Mascota',
      ),
    );
  }

  Future<void> _marcarComoAdoptada(BuildContext context) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    final solicitudes = await db
        .collection('solicitudes')
        .where('petId', isEqualTo: petId)
        .get();

    batch.update(db.collection('mascotas').doc(petId), {'estado': 'adoptado'});

    for (final doc in solicitudes.docs) {
      final solData = doc.data();
      final solEstado = solData['estado'] as String? ?? 'pendiente';

      if (solEstado == 'aprobada') {
        batch.update(doc.reference, {'estado': 'adoptada'});
        batch.set(db.collection('chats').doc(doc.id), {
          'ultimoMensaje': 'La mascota fue marcada como adoptada.',
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else if (solEstado == 'pendiente') {
        batch.update(doc.reference, {'estado': 'rechazada'});
        batch.set(db.collection('chats').doc(doc.id), {
          'ultimoMensaje':
              'La publicación se cerró porque la mascota fue adoptada.',
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    await batch.commit();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mascota marcada como adoptada')),
    );
  }

  void _confirmarMarcarComoAdoptada(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Marcar como adoptada'),
          content: Text(
            '¿Confirmas que ${data['nombre'] ?? 'esta mascota'} ya fue adoptada?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _marcarComoAdoptada(context);
              },
              child: const Text('Marcar adoptada'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final estadoColor = _colorEstado(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _mostrarSolicitudes(context),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: (data['imagenUrl'] as String?)?.isNotEmpty ?? false
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              data['imagenUrl'],
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.pets, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['nombre']?.toString() ?? '',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${data['raza'] ?? ''} • ${data['edad'] ?? ''}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      _estadoLabel,
                      style: TextStyle(
                        color: estadoColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    side: BorderSide(color: estadoColor),
                    backgroundColor: estadoColor.withValues(alpha: 0.12),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _mostrarSolicitudes(context),
                    icon: const Icon(Icons.inbox_outlined),
                    label: const Text('Ver solicitudes'),
                  ),
                ),
                if (estado == 'en_proceso') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _confirmarMarcarComoAdoptada(context),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Marcar adoptada'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SolicitudesSheet extends StatelessWidget {
  final String petId;
  final String petNombre;

  const _SolicitudesSheet({
    required this.petId,
    required this.petNombre,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Text(
                    'Solicitudes - $petNombre',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('solicitudes')
                    .where('petId', isEqualTo: petId)
                    .where('estado', isEqualTo: 'pendiente')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final solicitudes = snapshot.data?.docs ?? [];
                  if (solicitudes.isEmpty) {
                    final colorScheme = Theme.of(context).colorScheme;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sin solicitudes pendientes',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: solicitudes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final data =
                          solicitudes[index].data() as Map<String, dynamic>;
                      return _SolicitudCard(
                        solId: solicitudes[index].id,
                        petId: petId,
                        data: data,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  final String solId;
  final String petId;
  final Map<String, dynamic> data;

  const _SolicitudCard({
    required this.solId,
    required this.petId,
    required this.data,
  });

  Future<void> _actualizarEstado(BuildContext context, String nuevoEstado) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    batch.update(db.collection('solicitudes').doc(solId), {'estado': nuevoEstado});

    if (nuevoEstado == 'aprobada') {
      final competidoras = await db
          .collection('solicitudes')
          .where('petId', isEqualTo: petId)
          .where('estado', isEqualTo: 'pendiente')
          .get();

      batch.update(db.collection('mascotas').doc(petId), {'estado': 'en_proceso'});
      batch.set(db.collection('chats').doc(solId), {
        'matchAprobado': true,
        'ultimoMensaje': '¡Solicitud aprobada! Chat desbloqueado.',
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      for (final doc in competidoras.docs) {
        if (doc.id == solId) continue;
        batch.update(doc.reference, {'estado': 'rechazada'});
        batch.set(db.collection('chats').doc(doc.id), {
          'ultimoMensaje':
              'Otra solicitud fue aprobada para esta mascota.',
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } else if (nuevoEstado == 'rechazada') {
      batch.set(db.collection('chats').doc(solId), {
        'ultimoMensaje': 'Solicitud rechazada.',
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();

    if (!context.mounted) return;
    Navigator.pop(context);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nuevoEstado == 'aprobada'
              ? 'Solicitud aprobada y resto de postulaciones cerradas'
              : 'Solicitud rechazada',
        ),
      ),
    );
  }

  void _confirmar(BuildContext context, bool esAprobar) {
    final nuevoEstado = esAprobar ? 'aprobada' : 'rechazada';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(esAprobar ? 'Aprobar solicitud' : 'Rechazar solicitud'),
          content: Text(
            '¿Confirmas que deseas ${esAprobar ? 'aprobar' : 'rechazar'} '
            'la solicitud de ${data['nombre']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => _actualizarEstado(dialogContext, nuevoEstado),
              style: esAprobar
                  ? null
                  : FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
              child: Text(esAprobar ? 'Aprobar' : 'Rechazar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final inicial = (data['nombre'] as String?)?.trim().isNotEmpty ?? false
        ? (data['nombre'] as String).trim()[0].toUpperCase()
        : '?';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    inicial,
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['nombre']?.toString() ?? '',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        data['correo']?.toString() ?? '',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tel: ${data['telefono'] ?? '-'}',
              style: textTheme.bodySmall,
            ),
            Text(
              'Ciudad: ${data['direccion'] ?? '-'}',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Motivo:',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(data['motivo']?.toString() ?? '', style: textTheme.bodySmall),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmar(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _confirmar(context, true),
                    child: const Text('Aprobar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
