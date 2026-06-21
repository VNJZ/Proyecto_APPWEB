import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet_model.dart';

class AdoptionFormScreen extends StatefulWidget {
  final PetModel pet;

  const AdoptionFormScreen({super.key, required this.pet});

  @override
  State<AdoptionFormScreen> createState() => _AdoptionFormScreenState();
}

class _AdoptionFormScreenState extends State<AdoptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _motivoController = TextEditingController();
  bool _enviando = false;
  bool _cargandoDatos = true;

  // Valores originales cargados desde users/{uid}, para detectar ediciones (T2).
  String _nombreOriginal = '';
  String _correoOriginal = '';
  String _telefonoOriginal = '';
  String _direccionOriginal = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosAdoptante();
  }

  // T1 · Precargar nombre, correo, teléfono y dirección desde users/{uid}.
  Future<void> _cargarDatosAdoptante() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;

      Map<String, dynamic> data = {};
      if (uid != null) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        data = doc.data() ?? {};
      }

      _nombreOriginal = (data['displayName'] ?? user?.displayName ?? '').toString();
      _correoOriginal = (data['email'] ?? user?.email ?? '').toString();
      _telefonoOriginal = (data['phone'] ?? '').toString();
      _direccionOriginal = (data['city'] ?? '').toString();

      if (!mounted) return;
      setState(() {
        _nombreController.text = _nombreOriginal;
        _correoController.text = _correoOriginal;
        _telefonoController.text = _telefonoOriginal;
        _direccionController.text = _direccionOriginal;
        _cargandoDatos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoDatos = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonimo';
      final orgId = widget.pet.orgId;
      
      final db = FirebaseFirestore.instance;
      final solDocRef = db.collection('solicitudes').doc();
      final solId = solDocRef.id;

      final batch = db.batch();

      // 1. Guardar solicitud
      batch.set(solDocRef, {
        'id': solId,
        'petId': widget.pet.id,
        'petName': widget.pet.name,
        'petBreed': widget.pet.breed,
        'orgId': orgId,
        'adoptanteId': uid,
        'nombre': _nombreController.text.trim(),
        'correo': _correoController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'motivo': _motivoController.text.trim(),
        'estado': 'pendiente',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Crear chat correspondiente (bloqueado por defecto: matchAprobado = false)
      final chatDocRef = db.collection('chats').doc(solId);
      batch.set(chatDocRef, {
        'id': solId,
        'nombre': 'Solicitud: ${widget.pet.name}',
        'ultimoMensaje': 'Solicitud de adopción enviada.',
        'timestamp': FieldValue.serverTimestamp(),
        'petId': widget.pet.id,
        'matchAprobado': false,
        'participantes': [uid, orgId],
        'adoptanteId': uid,
        'orgId': orgId,
      });

      // T2 · Si el adoptante editó algún dato de contacto, persistirlo en
      // users/{uid} (merge:true) para precargarlo en la próxima solicitud.
      final nombre = _nombreController.text.trim();
      final correo = _correoController.text.trim();
      final telefono = _telefonoController.text.trim();
      final direccion = _direccionController.text.trim();

      final cambios = <String, dynamic>{};
      if (nombre != _nombreOriginal) cambios['displayName'] = nombre;
      if (correo != _correoOriginal) cambios['email'] = correo;
      if (telefono != _telefonoOriginal) cambios['phone'] = telefono;
      if (direccion != _direccionOriginal) cambios['city'] = direccion;

      if (cambios.isNotEmpty && uid != 'anonimo') {
        batch.set(
          db.collection('users').doc(uid),
          cambios,
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada con éxito')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar: $e')),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud de adopción')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: foto + nombre + refugio
            Container(
              width: double.infinity,
              color: colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: widget.pet.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              widget.pet.imageUrls.first,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.pets, size: 36, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pet.name,
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.pet.breed,
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.home_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Refugio Patitas',
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Formulario
            if (_cargandoDatos)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tus datos', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nombreController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _correoController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                        if (!v.contains('@')) return 'Correo inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Ingresa tu teléfono' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección / Ciudad',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Ingresa tu dirección' : null,
                    ),
                    const SizedBox(height: 24),

                    Text(
                      '¿Por qué quieres adoptar a ${widget.pet.name}?',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _motivoController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Cuéntanos un poco sobre ti y tu hogar...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 20) {
                          return 'Mínimo 20 caracteres (${v?.trim().length ?? 0}/20)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _enviando ? null : _enviarSolicitud,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _enviando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Enviar solicitud',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
