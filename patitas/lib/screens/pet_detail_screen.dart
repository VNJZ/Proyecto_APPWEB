import 'package:flutter/material.dart';
import '../models/pet_model.dart';

class PetDetailScreen extends StatelessWidget {
  final PetModel pet; // Recibe el modelo de datos que creaste (BORRAR COMENTARIO)

  const PetDetailScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Perfil de: ${pet.name}', style: const TextStyle(fontSize: 24)),
            Text('Raza: ${pet.breed}'),
            Text('Edad: ${pet.age}'),
            Text('Distancia: ${pet.distance}'),
            // iran las fotos y el boton de adopcion
          ],
        ),
      ),
    );
  }
}