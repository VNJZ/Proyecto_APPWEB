import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/pet_model.dart';
import 'pet_detail_screen.dart'; // Importamos tu pantalla de detalle

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final CardSwiperController controller = CardSwiperController();

  final List<PetModel> pets = [
    PetModel(id: '1', name: 'Max', breed: 'Labrador', age: '2 años', distance: '2 km', weight: '5 kg',size: 'Pequeño',imageUrls: []),
    PetModel(id: '2', name: 'Luna', breed: 'Pug', age: '1 año', distance: '5 km', weight: '2.4 kg',size: 'Mediano',imageUrls: []),
    PetModel(id: '3', name: 'Rocky', breed: 'Bulldog', age: '3 años', distance: '1.5 km', weight: '14 kg',size: 'Gigante',imageUrls: []),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adoptar Mascotas'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CardSwiper(
            controller: controller,
            cardsCount: pets.length,
            // AQUÍ AGREGAMOS LA LÓGICA DEL SWIPE
            onSwipe: (previousIndex, currentIndex, direction) {
              if (direction == CardSwiperDirection.left) {
                print('Pasar (Descartado)'); 
              } else if (direction == CardSwiperDirection.right) {
                // Navegamos al perfil del perrito
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PetDetailScreen(pet: pets[previousIndex]),
                  ),
                );
              }
              return true; // Permitir que la tarjeta se deslice
            },
            cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
              final pet = pets[index];
              return Card(
                color: Colors.green.shade100,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pets, size: 80, color: Colors.green),
                      const SizedBox(height: 20),
                      Text(pet.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      Text(pet.breed, style: const TextStyle(fontSize: 20)),
                      Text('${pet.age} • a ${pet.distance}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}