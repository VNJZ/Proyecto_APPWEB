import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet_model.dart';
import 'pet_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<String> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = prefs.getStringList('favs_list_$uid') ?? [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Favoritos')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 72, color: colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      Text(
                        'Aún no tienes favoritos',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Desliza a la derecha para añadir mascotas.'),
                    ],
                  ),
                )
              : FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('mascotas')
                      .where(FieldPath.documentId, whereIn: _favorites.length > 10 ? _favorites.sublist(0, 10) : _favorites) // limit to 10 for simplicity in 'whereIn'
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(child: Text('No se encontraron las mascotas favoritas.'));
                    }

                    final pets = docs.map((doc) => PetModel.fromFirestore(doc)).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: pets.length,
                      itemBuilder: (context, index) {
                        final pet = pets[index];
                        final hasImage = pet.imageUrls.isNotEmpty;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)),
                              );
                              _loadFavorites(); // Reload in case it was removed from details
                            },
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: hasImage
                                      ? Image.network(pet.imageUrls.first, fit: BoxFit.cover)
                                      : Container(
                                          color: colorScheme.surfaceContainerHighest,
                                          child: Icon(Icons.pets, color: colorScheme.primary),
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(pet.name, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                      Text(pet.breed, style: textTheme.bodyMedium),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_outlined, size: 16, color: colorScheme.outline),
                                          const SizedBox(width: 4),
                                          Text(pet.city, style: textTheme.bodySmall),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.favorite, color: Colors.pink),
                                  onPressed: () async {
                                    final uid = FirebaseAuth.instance.currentUser?.uid;
                                    if (uid == null) return;
                                    final prefs = await SharedPreferences.getInstance();
                                    _favorites.remove(pet.id);
                                    await prefs.setStringList('favs_list_$uid', _favorites);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
