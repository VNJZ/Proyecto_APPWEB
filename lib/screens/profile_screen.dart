import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/auth_session.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'org_panel_screen.dart';

class ProfileScreen extends StatelessWidget {
  final AuthSession session;
  final UserProfile profile; // Mantenido por retrocompatibilidad de firma
  final ValueChanged<UserProfile> onProfileUpdated; // Mantenido por retrocompatibilidad de firma

  const ProfileScreen({
    super.key,
    required this.session,
    required this.profile,
    required this.onProfileUpdated,
  });

  void _openOrgPanel(BuildContext context) {
    final orgId = session.orgId;
    if (orgId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrgPanelScreen(orgId: orgId),
      ),
    );
  }

  Future<void> _openEditProfile(BuildContext context, UserProfile currentProfile) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: currentProfile),
      ),
    );
    // Como escuchamos un StreamBuilder de Firestore, los cambios se reflejan solos.
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Deseas cerrar tu sesión actual?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;
    await AuthService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(session.userId).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final fullName = userData['displayName'] ?? session.displayName;
        final email = userData['email'] ?? session.email;
        final phone = userData['phone'] ?? '';
        final city = userData['city'] ?? '';
        final bio = userData['bio'] ?? '';
        final photoUrl = userData['photoUrl'] as String? ?? '';

        final currentProfile = UserProfile(
          id: session.userId,
          fullName: fullName,
          email: email,
          phone: phone.isEmpty ? 'Sin teléfono' : phone,
          city: city.isEmpty ? 'Sin ciudad' : city,
          bio: bio.isEmpty ? 'Sin biografía' : bio,
          photoUrl: photoUrl,
          activeApplications: 0,
          completedAdoptions: 0,
          adoptionHistory: [],
        );

        // Consultamos las solicitudes para llenar contadores e historial
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('solicitudes')
              .where(session.isOrganizacion ? 'orgId' : 'adoptanteId', isEqualTo: session.userId)
              .snapshots(),
          builder: (context, solSnapshot) {
            int activeApps = 0;
            int completedAdoptions = 0;
            final List<AdoptionHistoryItem> history = [];

            if (solSnapshot.hasData) {
              final docs = solSnapshot.data!.docs.toList();
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                return bTime.compareTo(aTime);
              });
              for (var doc in docs) {
                final solData = doc.data() as Map<String, dynamic>;
                final estado = solData['estado'] as String? ?? 'pendiente';
                
                if (estado == 'pendiente') {
                  activeApps++;
                } else if (estado == 'aprobada') {
                  completedAdoptions++;
                }

                history.add(AdoptionHistoryItem(
                  petName: solData['petName'] ?? 'Mascota',
                  species: solData['petBreed'] ?? 'Mascota',
                  shelterName: session.isOrganizacion ? fullName : 'Refugio Patitas',
                  date: (solData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  status: estado == 'aprobada'
                      ? 'Completada'
                      : estado == 'pendiente'
                          ? 'En revisión'
                          : 'Rechazada',
                ));
              }
            }

            final finalProfile = currentProfile.copyWith(
              activeApplications: activeApps,
              completedAdoptions: completedAdoptions,
              adoptionHistory: history,
            );

            return Scaffold(
              appBar: AppBar(
                title: const Text('Mi perfil'),
                actions: [
                  IconButton(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout),
                    tooltip: 'Cerrar sesion',
                  ),
                ],
              ),
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.secondaryContainer,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            backgroundImage: finalProfile.photoUrl.isNotEmpty
                                ? NetworkImage(finalProfile.photoUrl)
                                : null,
                            child: finalProfile.photoUrl.isEmpty
                                ? Text(
                                    finalProfile.initials,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            finalProfile.fullName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 18),
                              const SizedBox(width: 4),
                              Text(finalProfile.city),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _openEditProfile(context, finalProfile),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Editar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _confirmLogout(context),
                                  icon: const Icon(Icons.logout),
                                  label: const Text('Salir'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (!session.isOrganizacion) ...[
                          Expanded(
                            child: _StatCard(
                              label: 'En proceso',
                              value: finalProfile.activeApplications.toString(),
                              icon: Icons.pets_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: _StatCard(
                            label: 'Adopciones',
                            value: finalProfile.completedAdoptions.toString(),
                            icon: Icons.favorite_outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (session.isOrganizacion) ...[
                      _SectionCard(
                        title: 'Panel de organización',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Revisa las solicitudes de adopción pendientes y gestiona las mascotas publicadas por tu refugio.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => _openOrgPanel(context),
                                icon: const Icon(Icons.dashboard_outlined),
                                label: const Text('Abrir panel'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _SectionCard(
                      title: 'Datos de contacto',
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.phone_outlined,
                            label: 'Telefono',
                            value: finalProfile.phone,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.mail_outline,
                            label: 'Correo',
                            value: finalProfile.email,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Sobre mi',
                      child: Text(
                        finalProfile.bio,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Historial de adopciones',
                      child: finalProfile.adoptionHistory.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text('No hay historial de adopciones aún.'),
                              ),
                            )
                          : Column(
                              children: finalProfile.adoptionHistory
                                  .map((item) => _HistoryTile(item: item))
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final AdoptionHistoryItem item;

  const _HistoryTile({required this.item});

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.secondaryContainer,
            child: const Icon(Icons.pets),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.petName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(item.species),
                const SizedBox(height: 4),
                Text('Refugio: ${item.shelterName}'),
                const SizedBox(height: 6),
                Text('Fecha: ${_formatDate(item.date)}'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
