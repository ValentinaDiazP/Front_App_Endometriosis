import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/publicacion_model.dart';
import '../../services/comunidad_service.dart';

class ComunidadFeedScreen extends StatefulWidget {
  const ComunidadFeedScreen({super.key});

  @override
  State<ComunidadFeedScreen> createState() => _ComunidadFeedScreenState();
}

class _ComunidadFeedScreenState extends State<ComunidadFeedScreen> {
  final ComunidadService _service = ComunidadService();
  late Future<List<Publicacion>> _futurePublicaciones;

  @override
  void initState() {
    super.initState();
    _actualizarFeed();
  }

  void _actualizarFeed() {
    setState(() {
      _futurePublicaciones = _service.obtenerPublicaciones();
    });
  }

  void _mostrarModalCrearPost() {
    final TextEditingController contenidoController = TextEditingController();
    File? imagenSeleccionada;
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Crear Publicación',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contenidoController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: '¿Qué quieres compartir hoy?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (imagenSeleccionada != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.file(imagenSeleccionada!, height: 120, fit: BoxFit.cover),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => setModalState(() => imagenSeleccionada = null),
                        )
                      ],
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_library, color: Colors.purple),
                        onPressed: () async {
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            setModalState(() => imagenSeleccionada = File(image.path));
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.purple),
                        onPressed: () async {
                          final XFile? image = await picker.pickImage(source: ImageSource.camera);
                          if (image != null) {
                            setModalState(() => imagenSeleccionada = File(image.path));
                          }
                        },
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () async {
                          if (contenidoController.text.trim().isEmpty) return;

                          bool exito = await _service.crearPublicacion(
                            contenidoController.text,
                            imagenSeleccionada,
                          );

                          if (exito && mounted) {
                            Navigator.pop(context);
                            _actualizarFeed();
                          }
                        },
                        child: const Text('Publicar'),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad Florecer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _actualizarFeed,
          )
        ],
      ),
      body: FutureBuilder<List<Publicacion>>(
        future: _futurePublicaciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aún no hay publicaciones. ¡Sé la primera en escribir!'));
          }

          final publicaciones = snapshot.data!;
          return ListView.builder(
            itemCount: publicaciones.length,
            itemBuilder: (context, index) {
              final post = publicaciones[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text(post.usuarioNombre.substring(0, 1).toUpperCase()),
                        ),
                        title: Text(post.usuarioNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(post.fechaCreacion.split('T')[0]),
                      ),
                      Text(post.contenido, style: const TextStyle(fontSize: 15)),
                      if (post.imagenUrl != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            post.imagenUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                      ],
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text('${post.comentariosCount} comentarios'),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarModalCrearPost,
        child: const Icon(Icons.edit),
      ),
    );
  }
}