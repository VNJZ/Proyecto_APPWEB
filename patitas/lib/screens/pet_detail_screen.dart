import 'package:flutter/material.dart';
import '../models/pet_model.dart';

class PetDetailScreen extends StatelessWidget {
  final PetModel pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true, // Para que la imagen suba hasta el tope
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Imagen Principal (Ocupando la parte superior)
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Icon(Icons.pets, size: 120, color: colorScheme.primary),
            ),
            const SizedBox(height: 20),

            // 2. Información Principal y Distancia
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(pet.name, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                      // Badge Macho/Hembra (Fondo rosa/rojo suave según mockup)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('♂ Macho', style: TextStyle(color: Colors.pink.shade300, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${pet.breed} Mestizo', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.orange.shade300, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('A ${pet.distance} de ti • Albergue central', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Tarjetas de Edad, Peso y Tamaño (NUEVO)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoBox(title: 'Edad', value: pet.age, icon: Icons.access_time),
                  _InfoBox(title: 'Peso', value: pet.weight, icon: Icons.scale),
                  _InfoBox(title: 'Tamaño', value: pet.size, icon: Icons.straighten),

                  //TEXTOS HARDCODEADOS PARA VER SI QUEDABA BIEN EL FRONT JIIJI
                  //const _InfoBox(title: 'Peso', value: '6.5 kg', icon: Icons.scale),
                  //const _InfoBox(title: 'Tamaño', value: 'Pequeño', icon: Icons.straighten),



                ],
              ),
            ),
            const SizedBox(height: 32),

            // 4. Publicado por (Refugio)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.home, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PUBLICADO POR', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, letterSpacing: 1)),
                        const Text('Refugio Patitas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.verified_outlined, color: colorScheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // 5. Botones de Acción: Favorito y Adoptar (CORREGIDO)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  // Botón Corazón
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.pink),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Botón Adoptar
                  Expanded(
                    child: FilledButton(
                      onPressed: () {}, // TODO: Juan Pablo conectará aquí
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text('Adoptar a ${pet.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para las 3 cajitas (Edad, Peso, Tamaño)
class _InfoBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoBox({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50, // Color cálido como el mockup
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orange.shade300),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}