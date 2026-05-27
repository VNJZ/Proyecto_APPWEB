import 'package:cloud_firestore/cloud_firestore.dart';

class PetModel {
  final String id;
  final String name;
  final String breed;
  final String age;
  final String distance;
  final String weight;
  final String size;
  final List<String> imageUrls;
  final String gender;
  final String orgId;

  PetModel({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.distance,
    required this.weight,
    required this.size,
    required this.imageUrls,
    required this.gender,
    required this.orgId,
  });

  factory PetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Si hay un peso en número, podemos inferir el tamaño
    String inferredSize = data['size'] ?? data['tamaño'] ?? '';
    if (inferredSize.isEmpty) {
      final pesoStr = data['peso'] as String? ?? '5';
      final pesoClean = double.tryParse(pesoStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 5.0;
      if (pesoClean < 8) {
        inferredSize = 'Pequeño';
      } else if (pesoClean < 22) {
        inferredSize = 'Mediano';
      } else {
        inferredSize = 'Grande';
      }
    }

    final singleImage = data['imagenUrl'] as String?;
    final images = data['imageUrls'] as List<dynamic>?;
    final List<String> urls = [];
    if (singleImage != null && singleImage.isNotEmpty) {
      urls.add(singleImage);
    }
    if (images != null) {
      urls.addAll(images.map((e) => e.toString()));
    }

    return PetModel(
      id: doc.id,
      name: data['nombre'] ?? data['name'] ?? 'Mascota',
      breed: data['raza'] ?? data['breed'] ?? 'Mestizo',
      age: data['edad'] ?? data['age'] ?? '1 año',
      distance: data['distance'] as String? ?? '2.5 km',
      weight: data['peso'] as String? ?? '5 kg',
      size: inferredSize,
      imageUrls: urls,
      gender: data['genero'] ?? data['gender'] ?? 'Macho',
      orgId: data['orgId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'nombre': name,
      'raza': breed,
      'edad': age,
      'peso': weight,
      'genero': gender,
      'imagenUrl': imageUrls.isNotEmpty ? imageUrls.first : '',
      'imageUrls': imageUrls,
      'orgId': orgId,
      'estado': 'disponible',
    };
  }
}
