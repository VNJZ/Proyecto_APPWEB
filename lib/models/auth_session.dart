/// Rol del usuario dentro de la app.
/// Determina qué pantallas y acciones tiene disponibles.
enum UserRole { adoptante, organizacion }

class AuthSession {
  final String userId;
  final String email;
  final String displayName;
  final UserRole role;

  /// Id de la organización dueña de las mascotas publicadas.
  /// Sólo presente cuando [role] es [UserRole.organizacion].
  final String? orgId;

  const AuthSession({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    this.orgId,
  });

  bool get isOrganizacion => role == UserRole.organizacion;
}
