import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet_model.dart';
import 'pet_detail_screen.dart';
import 'adoption_form_screen.dart';
import 'preferences_dialog.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final CardSwiperController controller = CardSwiperController();
  Set<String> _requestedPetIds = {};
  StreamSubscription? _solicitudesSub;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _solicitudesSub = FirebaseFirestore.instance
          .collection('solicitudes')
          .where('adoptanteId', isEqualTo: uid)
          .snapshots()
          .listen((snap) {
        if (mounted) {
          setState(() {
            _requestedPetIds = snap.docs.map((d) => d.data()['petId'] as String).toSet();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _solicitudesSub?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adoptar Mascotas'),
        actions: [
          if (uid != null)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                PreferencesDialog.show(context, uid, onSaved: () {
                  setState(() {}); // Re-construye para refrescar preferencias si corresponde
                });
              },
              tooltip: 'Filtros de preferencia',
            ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('mascotas')
              .where('estado', isEqualTo: 'disponible')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error al cargar mascotas: ${snapshot.error}'));
            }

            final docs = snapshot.data?.docs ?? [];
            final pets = docs.map((doc) {
              final pet = PetModel.fromFirestore(doc);
              debugPrint('DEBUG FEED: Mascota "${pet.name}" -> orgId: "${pet.orgId}", Mi UID: "$uid"');
              return pet;
            })
            .where((pet) => pet.orgId != uid && !_requestedPetIds.contains(pet.id))
            .toList();

            if (pets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, size: 72, color: colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    Text(
                      'No hay mascotas disponibles',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Vuelve a consultar más tarde.'),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: CardSwiper(
                controller: controller,
                cardsCount: pets.length,
                numberOfCardsDisplayed: pets.length < 3 ? pets.length : 3,
                allowedSwipeDirection: const AllowedSwipeDirection.only(
                  left: true,
                  right: true,
                ),
                onSwipe: (previousIndex, currentIndex, direction) async {
                  if (direction == CardSwiperDirection.right) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdoptionFormScreen(pet: pets[previousIndex]),
                      ),
                    );
                  }
                  return true;
                },
                cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                  final pet = pets[index];
                  final bool hasImage = pet.imageUrls.isNotEmpty;
                  final String genderIcon = pet.gender == 'Macho' ? '♂' : '♀';
                  final Color genderColor = pet.gender == 'Macho' ? Colors.blue.shade300 : Colors.pink.shade300;

                  return GestureDetector(
                    onTap: () {
                      // Click en la tarjeta abre el detalle de la mascota
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PetDetailScreen(pet: pet),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: Stack(
                        children: [
                          // Imagen de la mascota (o placeholder)
                          Positioned.fill(
                            child: hasImage
                                ? Image.network(
                                    pet.imageUrls.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: colorScheme.primaryContainer,
                                        child: Icon(Icons.pets, size: 80, color: colorScheme.primary),
                                      );
                                    },
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          colorScheme.primaryContainer,
                                          colorScheme.secondaryContainer,
                                        ],
                                      ),
                                    ),
                                    child: Icon(Icons.pets, size: 100, color: colorScheme.primary),
                                  ),
                          ),

                          // Sombreado inferior para legibilidad del texto
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0.6, 1.0],
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.85),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Información de la mascota (Texto superior)
                          Positioned(
                            bottom: 24,
                            left: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pet.name,
                                        style: textTheme.headlineMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: genderColor.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: genderColor, width: 1.5),
                                      ),
                                      child: Text(
                                        '$genderIcon ${pet.gender}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${pet.breed} • ${pet.age}',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Text(
                                      pet.city,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Overlay de Swipe (Rojo para Izquierda, Verde para Derecha)
                          if (percentThresholdX != 0)
                            Positioned.fill(
                              child: Opacity(
                                opacity: (percentThresholdX.abs() / 100).clamp(0.0, 0.8),
                                child: Container(
                                  color: percentThresholdX > 0
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFC62828),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.15),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            percentThresholdX > 0
                                                ? Icons.favorite
                                                : Icons.close,
                                            color: percentThresholdX > 0
                                                ? const Color(0xFF2E7D32)
                                                : const Color(0xFFC62828),
                                            size: 48,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          percentThresholdX > 0 ? 'ADOPTAR' : 'PASAR',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black26,
                                                offset: Offset(0, 2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}