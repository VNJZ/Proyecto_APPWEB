import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrgPanelScreen extends StatelessWidget {
  /// Id de la organización cuyas mascotas y solicitudes se van a mostrar.
  /// Se pasa por constructor en vez de leerlo de FirebaseAuth, así la pantalla
  /// funciona también con el MockAuthService mientras no migramos a Firebase Auth.
  final String orgId;

  const OrgPanelScreen({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de organización')),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  const Text('No hay mascotas publicadas aún'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: mascotas.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = mascotas[i].data() as Map<String, dynamic>;
              final petId = mascotas[i].id;
              final estado = data['estado'] as String? ?? 'disponible';
              return _MascotaCard(petId: petId, data: data, estado: estado);
            },
          );
        },
      ),
    );
  }
}

// ─── Tarjeta de mascota ────────────────────────────────────────────────────────

class _MascotaCard extends StatelessWidget {
  final String petId;
  final Map<String, dynamic> data;
  final String estado;

  const _MascotaCard({
    required this.petId,
    required this.data,
    required this.estado,
  });

  Color _colorEstado(BuildContext context) => switch (estado) {
        'disponible' => Theme.of(context).colorScheme.primary,
        'en_proceso' => const Color(0xFFF2A62A),
        'adoptado' => Theme.of(context).colorScheme.outline,
        _ => Theme.of(context).colorScheme.outline,
      };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = _colorEstado(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarSolicitudes(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Foto
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: data['imagenUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(data['imagenUrl'], fit: BoxFit.cover),
                      )
                    : Icon(Icons.pets, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),

              // Nombre + raza
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['nombre'] ?? '',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${data['raza'] ?? ''} • ${data['edad'] ?? ''}',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              // Chip de estado
              Chip(
                label: Text(
                  estado,
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                side: BorderSide(color: color),
                backgroundColor: color.withOpacity(0.1),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarSolicitudes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SolicitudesSheet(petId: petId, petNombre: data['nombre'] ?? ''),
    );
  }
}

// ─── Bottom sheet de solicitudes ──────────────────────────────────────────────

class _SolicitudesSheet extends StatelessWidget {
  final String petId;
  final String petNombre;

  const _SolicitudesSheet({required this.petId, required this.petNombre});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Text(
                  'Solicitudes — $petNombre',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sin solicitudes pendientes',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final data = solicitudes[i].data() as Map<String, dynamic>;
                    return _SolicitudCard(
                      solId: solicitudes[i].id,
                      petId: petId,
                      data: data,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de solicitud ─────────────────────────────────────────────────────

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

    // Al aprobar: marcar mascota en_proceso y habilitar chat
    if (nuevoEstado == 'aprobada') {
      batch.update(db.collection('mascotas').doc(petId), {'estado': 'en_proceso'});
      batch.update(db.collection('chats').doc(solId), {
        'matchAprobado': true,
        'ultimoMensaje': '¡Solicitud aprobada! Chat desbloqueado.',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else if (nuevoEstado == 'rechazada') {
      batch.update(db.collection('chats').doc(solId), {
        'ultimoMensaje': 'Solicitud rechazada.',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    try {
      await batch.commit();
      // Cerrar modal + bottom sheet
      if (context.mounted) {
        Navigator.pop(context); // cierra AlertDialog
        Navigator.pop(context); // cierra bottom sheet
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _confirmar(BuildContext context, bool esAprobar) {
    final nuevoEstado = esAprobar ? 'aprobada' : 'rechazada';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(esAprobar ? 'Aprobar solicitud' : 'Rechazar solicitud'),
        content: Text(
          '¿Confirmas que deseas ${esAprobar ? 'aprobar' : 'rechazar'} '
          'la solicitud de ${data['nombre']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => _actualizarEstado(context, nuevoEstado),
            style: esAprobar
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
            child: Text(esAprobar ? 'Aprobar' : 'Rechazar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre + correo
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    (data['nombre'] as String? ?? '?')[0].toUpperCase(),
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['nombre'] ?? '',
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        data['correo'] ?? '',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Datos de contacto
            Text('Tel: ${data['telefono'] ?? '-'}', style: textTheme.bodySmall),
            Text('Ciudad: ${data['direccion'] ?? '-'}', style: textTheme.bodySmall),
            const SizedBox(height: 8),

            // Motivo
            Text('Motivo:', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(data['motivo'] ?? '', style: textTheme.bodySmall),
            const SizedBox(height: 16),

            // Acciones
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
