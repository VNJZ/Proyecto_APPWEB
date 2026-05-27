import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PublishPetScreen extends StatefulWidget {
  const PublishPetScreen({super.key});

  @override
  State<PublishPetScreen> createState() => _PublishPetScreenState();
}

class _PublishPetScreenState extends State<PublishPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _razaController = TextEditingController();
  final _edadController = TextEditingController();
  final _pesoController = TextEditingController();
  
  String _animalType = 'Perro';
  String _genero = 'Macho';
  File? _imagenSeleccionada;
  bool _publicando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _razaController.dispose();
    _edadController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de Galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar con Cámara'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _imagenSeleccionada = File(picked.path));
      }
    }
  }

  Future<String?> _subirImagen(String petId) async {
    if (_imagenSeleccionada == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref('mascotas/$petId/principal.jpg');
      await ref.putFile(_imagenSeleccionada!);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Storage no disponible/configurado (se guardará sin imagen o con placeholder): $e');
      return null;
    }
  }

  Future<void> _publicarMascota() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _publicando = true);

    try {
      final orgId = FirebaseAuth.instance.currentUser?.uid ?? 'org_desconocida';
      final docRef = FirebaseFirestore.instance.collection('mascotas').doc();
      final imageUrl = await _subirImagen(docRef.id);
      final bool imageUploadFailed = _imagenSeleccionada != null && imageUrl == null;

      await docRef.set({
        'id': docRef.id,
        'nombre': _nombreController.text.trim(),
        'tipo': _animalType,
        'raza': _razaController.text.trim(),
        'edad': _edadController.text.trim(),
        'peso': '${_pesoController.text.trim()} Kg',
        'genero': _genero,
        'imagenUrl': imageUrl ?? '',
        'orgId': orgId,
        'estado': 'disponible',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(imageUploadFailed
              ? 'Mascota publicada con éxito (sin foto debido a la configuración de Storage)'
              : 'Mascota publicada exitosamente'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al publicar: $e')),
      );
    } finally {
      if (mounted) setState(() => _publicando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar mascota')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de foto
              Center(
                child: GestureDetector(
                  onTap: _seleccionarImagen,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: _imagenSeleccionada != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(_imagenSeleccionada!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Agregar foto',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nombreController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 12),

              // Selector Tipo Animal
              Text('Tipo de mascota', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Perro', label: Text('Perro'), icon: Icon(Icons.pets)),
                  ButtonSegment(value: 'Gato', label: Text('Gato'), icon: Icon(Icons.pets)),
                ],
                selected: {_animalType},
                onSelectionChanged: (s) => setState(() => _animalType = s.first),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _razaController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Raza',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa la raza' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _edadController,
                      decoration: const InputDecoration(
                        labelText: 'Edad',
                        border: OutlineInputBorder(),
                        hintText: 'ej: 2 años',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pesoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Peso',
                        border: OutlineInputBorder(),
                        suffixText: 'Kg',
                        hintText: 'ej: 5.5',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        if (double.tryParse(v.trim()) == null) return 'Solo números';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Toggle de género — SegmentedButton (MD3)
              Text('Género', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'Macho',
                    label: Text('Macho'),
                    icon: Icon(Icons.male),
                  ),
                  ButtonSegment(
                    value: 'Hembra',
                    label: Text('Hembra'),
                    icon: Icon(Icons.female),
                  ),
                ],
                selected: {_genero},
                onSelectionChanged: (s) => setState(() => _genero = s.first),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _publicando ? null : _publicarMascota,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _publicando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Publicar mascota',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
