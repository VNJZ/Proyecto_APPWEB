class PetModel {
  final String id;
  final String name;
  final String breed;
  final String age;
  final String distance;
  final List<String> imageUrls;

  PetModel({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.distance,
    required this.imageUrls,
  });
}
