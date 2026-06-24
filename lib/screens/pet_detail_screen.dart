import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet_model.dart';
import 'adoption_form_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final PetModel pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  bool _isFavorite = false;

  bool _yaSolicitado = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _checkIfSolicitado();
  }

  Future<void> _checkIfSolicitado() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final snap = await FirebaseFirestore.instance
        .collection('solicitudes')
        .where('adoptanteId', isEqualTo: uid)
        .where('petId', isEqualTo: widget.pet.id)
        .get();

    if (snap.docs.isNotEmpty && mounted) {
      setState(() {
        _yaSolicitado = true;
      });
    }
  }

  Future<void> _checkIfFavorite() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favs_list_$uid') ?? [];
    if (mounted) {
      setState(() {
        _isFavorite = favorites.contains(widget.pet.id);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favs_list_$uid') ?? [];
    
    if (_isFavorite) {
      favorites.remove(widget.pet.id);
    } else {
      favorites.add(widget.pet.id);
    }
    
    await prefs.setStringList('favs_list_$uid', favorites);
    
    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite 
                ? 'Agregado a tus favoritos' 
                : 'Eliminado de tus favoritos'
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pet = widget.pet;

    final String genderIcon = pet.gender == 'Macho' ? '♂ Macho' : '♀ Hembra';
    final Color genderColor = pet.gender == 'Macho' ? Colors.blue.shade600 : Colors.pink.shade600;
    final Color genderBgColor = pet.gender == 'Macho' ? Colors.blue.shade50 : Colors.pink.shade50;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Imagen Principal
            Container(
              height: 380,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: pet.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(36),
                        bottomRight: Radius.circular(36),
                      ),
                      child: Image.network(
                        pet.imageUrls.first,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(Icons.pets, size: 120, color: colorScheme.primary),
            ),
            const SizedBox(height: 24),

            // 2. Información Principal y Distancia
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pet.name,
                        style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      // Badge Macho/Hembra
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: genderBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          genderIcon,
                          style: TextStyle(color: genderColor, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pet.breed,
                    style: textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFF2A62F), // Naranja corporativo
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 18, color: colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        pet.city,
                        style: TextStyle(color: colorScheme.outline, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Tarjetas de Edad, Peso y Tamaño
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoBox(title: 'Edad', value: pet.age, icon: Icons.access_time),
                  _InfoBox(title: 'Peso', value: pet.weight, icon: Icons.scale),
                  _InfoBox(title: 'Tamaño', value: pet.size, icon: Icons.straighten),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Publicado por (Refugio)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.home, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(pet.orgId).get(),
                        builder: (context, snapshot) {
                          String shelterName = 'Refugio Patitas';
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final userData = snapshot.data!.data() as Map<String, dynamic>?;
                            shelterName = userData?['displayName'] ?? 'Refugio Patitas';
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PUBLICADO POR',
                                style: TextStyle(fontSize: 10, color: colorScheme.outline, letterSpacing: 1),
                              ),
                              Text(
                                shelterName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Icon(Icons.verified_outlined, color: colorScheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 5. Botones de Acción: Favorito y Adoptar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  // Botón Corazón
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: _isFavorite ? Colors.pink.shade50 : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.pink : colorScheme.outline,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Botón Adoptar
                  Expanded(
                    child: FilledButton(
                      onPressed: _yaSolicitado
                          ? null
                          : () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdoptionFormScreen(pet: pet),
                                ),
                              );
                              // Al volver del formulario, re-chequear si se envió la solicitud
                              _checkIfSolicitado();
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: _yaSolicitado ? Colors.grey : colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _yaSolicitado ? 'Solicitud enviada' : 'Adoptar a ${pet.name}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
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
        color: const Color(0xFFFFF7EC), // Tono crema cálido
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFF2A62F)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}