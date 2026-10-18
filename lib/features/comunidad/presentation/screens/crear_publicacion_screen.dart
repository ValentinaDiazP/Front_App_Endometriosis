import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/comunidad_service.dart';

class CrearPublicacionScreen extends StatefulWidget {
  final String? token;
  final ComunidadService service;

  const CrearPublicacionScreen({
    super.key,
    required this.token,
    required this.service,
  });

  @override
  State<CrearPublicacionScreen> createState() => _CrearPublicacionScreenState();
}

class _CrearPublicacionScreenState extends State<CrearPublicacionScreen> {
  final TextEditingController _contenidoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imagenSeleccionada;
  bool _esAnonimo = false;
  bool _enviando = false;

  // Categoría seleccionada por defecto (obligatoria)
  String _categoriaSeleccionada = 'HISTORIAS_APOYO';

  final List<Map<String, String>> _categoriasOpciones = [
    {
      'key': 'DIAGNOSTICO_TRATAMIENTO',
      'label': 'Diagnóstico y Tratamiento',
    },
    {
      'key': 'ESTILO_VIDA',
      'label': 'Alimentación y Estilo de Vida',
    },
    {
      'key': 'HISTORIAS_APOYO',
      'label': 'Historias y Apoyo Emocional',
    },
  ];

  @override
  void dispose() {
    _contenidoController.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    if (_contenidoController.text.trim().isEmpty || _enviando) return;

    setState(() => _enviando = true);
    final exito = await widget.service.crearPublicacion(
      _contenidoController.text,
      _imagenSeleccionada,
      esAnonimo: _esAnonimo,
      categoria: _categoriaSeleccionada,
      token: widget.token,
    );
    if (!mounted) return;
    setState(() => _enviando = false);

    if (exito) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo publicar. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Crear Publicación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Selector obligatorio de Hilo / Categoría
            const Text(
              'Selecciona el hilo para tu publicación:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _categoriaSeleccionada,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _categoriasOpciones.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat['key'],
                  child: Text(cat['label']!),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _categoriaSeleccionada = val);
                }
              },
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _contenidoController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '¿Qué quieres compartir hoy con la comunidad?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Publicar de forma anónima'),
              subtitle: const Text(
                'Tu nombre no se mostrará en el feed. La administración sí podrá identificar el origen.',
              ),
              value: _esAnonimo,
              onChanged: (valor) => setState(() => _esAnonimo = valor),
            ),
            if (_imagenSeleccionada != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.file(_imagenSeleccionada!, height: 120, fit: BoxFit.cover),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => setState(() => _imagenSeleccionada = null),
                  ),
                ],
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.purple),
                  onPressed: () async {
                    final XFile? image = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() => _imagenSeleccionada = File(image.path));
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.purple),
                  onPressed: () async {
                    final XFile? image = await _picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null) {
                      setState(() => _imagenSeleccionada = File(image.path));
                    }
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _enviando ? null : _publicar,
                  child: Text(_enviando ? 'Publicando...' : 'Publicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
