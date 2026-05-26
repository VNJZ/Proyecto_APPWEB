class UserProfile {
  final String id;
  final String fullName;
  final String city;
  final String bio;
  final String phone;
  final String email;
  final int activeApplications;
  final int completedAdoptions;
  final List<AdoptionHistoryItem> adoptionHistory;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.city,
    required this.bio,
    required this.phone,
    required this.email,
    required this.activeApplications,
    required this.completedAdoptions,
    required this.adoptionHistory,
  });

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'UP';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  UserProfile copyWith({
    String? fullName,
    String? city,
    String? bio,
    String? phone,
    String? email,
    int? activeApplications,
    int? completedAdoptions,
    List<AdoptionHistoryItem>? adoptionHistory,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      activeApplications: activeApplications ?? this.activeApplications,
      completedAdoptions: completedAdoptions ?? this.completedAdoptions,
      adoptionHistory: adoptionHistory ?? this.adoptionHistory,
    );
  }
}

class AdoptionHistoryItem {
  final String petName;
  final String species;
  final String shelterName;
  final DateTime date;
  final String status;

  const AdoptionHistoryItem({
    required this.petName,
    required this.species,
    required this.shelterName,
    required this.date,
    required this.status,
  });
}

final UserProfile mockUserProfile = UserProfile(
  id: 'user_001',
  fullName: 'Camila Rojas',
  city: 'Valparaiso',
  bio: 'Amante de los animales, voluntaria de fines de semana y en busca de darle hogar a mas mascotas.',
  phone: '+56 9 1234 5678',
  email: 'camila.rojas@patitas.app',
  activeApplications: 2,
  completedAdoptions: 3,
  adoptionHistory: [
    AdoptionHistoryItem(
      petName: 'Luna',
      species: 'Perra mestiza',
      shelterName: 'Refugio Patitas Felices',
      date: DateTime(2025, 9, 12),
      status: 'Adopcion completada',
    ),
    AdoptionHistoryItem(
      petName: 'Milo',
      species: 'Gato naranja',
      shelterName: 'Fundacion Bigotes',
      date: DateTime(2025, 3, 4),
      status: 'Seguimiento al dia',
    ),
    AdoptionHistoryItem(
      petName: 'Nina',
      species: 'Poodle toy',
      shelterName: 'Refugio San Roque',
      date: DateTime(2024, 11, 21),
      status: 'Solicitud en revision',
    ),
  ],
);
