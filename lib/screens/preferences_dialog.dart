import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Diálogo estético de Material Design 3 para guardar/editar las preferencias.
class PreferencesDialog extends StatefulWidget {
  final String userId;
  final VoidCallback? onSaved;

  const PreferencesDialog({
    super.key,
    required this.userId,
    this.onSaved,
  });

  static void show(BuildContext context, String userId, {VoidCallback? onSaved}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PreferencesDialog(userId: userId, onSaved: onSaved),
    );
  }

  @override
  State<PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<PreferencesDialog> {
  final _formKey = GlobalKey<FormState>();
  final _breedController = TextEditingController();
  
  String _animalType = 'Ambos';
  String _ageGroup = 'Cualquiera';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _breedController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = widget.userId;
    setState(() {
      _animalType = prefs.getString('pref_tipo_$uid') ?? 'Ambos';
      _breedController.text = prefs.getString('pref_raza_$uid') ?? '';
      _ageGroup = prefs.getString('pref_edad_$uid') ?? 'Cualquiera';
      _loading = false;
    });
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;
    
    final prefs = await SharedPreferences.getInstance();
    final uid = widget.userId;

    await prefs.setString('pref_tipo_$uid', _animalType);
    await prefs.setString('pref_raza_$uid', _breedController.text.trim());
    await prefs.setString('pref_edad_$uid', _ageGroup);
    await prefs.setBool('pref_set_$uid', true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferencias guardadas exitosamente'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
      if (widget.onSaved != null) widget.onSaved!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return const AlertDialog(
        content: SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.tune, color: colorScheme.primary),
          const SizedBox(width: 10),
          const Text('Mis Preferencias'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cuéntanos qué estás buscando para ayudarte a encontrar tu mascota ideal.',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // Tipo de animal
              Text('Tipo de mascota', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Perro', label: Text('Perros')),
                  ButtonSegment(value: 'Gato', label: Text('Gatos')),
                  ButtonSegment(value: 'Ambos', label: Text('Ambos')),
                ],
                selected: {_animalType},
                onSelectionChanged: (s) => setState(() => _animalType = s.first),
              ),
              const SizedBox(height: 16),

              // Raza
              TextFormField(
                controller: _breedController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Raza preferida (opcional)',
                  hintText: 'Ej: Poodle, Mestizo, Cualquiera',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),

              // Edad
              Text('Edad de preferencia', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _ageGroup,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'Cachorro', child: Text('Cachorro (menos de 1 año)')),
                  DropdownMenuItem(value: 'Joven', child: Text('Joven (1-3 años)')),
                  DropdownMenuItem(value: 'Adulto', child: Text('Adulto (más de 3 años)')),
                  DropdownMenuItem(value: 'Cualquiera', child: Text('Cualquier edad')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _ageGroup = val);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _savePreferences,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
