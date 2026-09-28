import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/publicacion_model.dart';
import '../../services/comunidad_service.dart';

class ComunidadFeedScreen extends StatefulWidget {
  final String? token; // Token de la usuaria autenticada (opcional)

  const ComunidadFeedScreen({super.key, this.token});

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
      _futurePublicaciones = _service.obtenerPublicaciones(token: widget.token);
    });
  }

  // ===========================================================================
  // 1. DIÁLOGO PARA REPORTAR PUBLICACIÓN
  // ===========================================================================
  void _mostrarDialogoReporte(int publicacionId) {
    final TextEditingController motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reportar publicación'),
        content: TextField(
          controller: motivoController,
          decoration: const InputDecoration(
            hintText: 'Describe el motivo del reporte...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final motivo = motivoController.text.trim();
              if (motivo.isNotEmpty) {
                final exito = await _service.reportar(publicacionId, motivo, widget.token);
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      exito ? 'Reporte enviado a revisión exitosamente' : 'Error al enviar reporte',
                    ),
                  ),
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. MODAL PARA COMENTARIOS
  // ===========================================================================
  void _mostrarModalComentarios(Publicacion post) {
    final TextEditingController comentarioController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Comentarios',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: post.comentarios.isEmpty
                    ? const Center(child: Text('Aún no hay comentarios. ¡Sé la primera!'))
                    : ListView.builder(
                        itemCount: post.comentarios.length,
                        itemBuilder: (context, index) {
                          final c = post.comentarios[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              c.usuarioNombre ?? 'Anónima',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(c.texto),
                          );
                        },
                      ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: comentarioController,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un comentario...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.purple),
                    onPressed: () async {
                      final texto = comentarioController.text.trim();
                      if (texto.isNotEmpty) {
                        final exito = await _service.comentar(post.id, texto, widget.token);
                        if (!mounted) return;
                        if (exito) {
                          Navigator.pop(ctx);
                          _actualizarFeed(); // Refresca para listar el nuevo comentario
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. MODAL PARA CREAR PUBLICACIÓN
  // ===========================================================================
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
                            token: widget.token,
                          );

                          if (exito && mounted) {
                            Navigator.pop(context);
                            _actualizarFeed();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Publicación enviada a revisión por administración'),
                              ),
                            );
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

  // ===========================================================================
  // 4. CONSTRUCCIÓN DE LA PANTALLA
  // ===========================================================================
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
            return const Center(
              child: Text('Aún no hay publicaciones aprobadas. ¡Sé la primera en escribir!'),
            );
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
                      // Encabezado con foto, nombre, fecha y menú de tres puntos (Reportar)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text(
                            post.usuarioNombre.isNotEmpty
                                ? post.usuarioNombre.substring(0, 1).toUpperCase()
                                : 'A',
                          ),
                        ),
                        title: Text(
                          post.usuarioNombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(post.fechaCreacion.split('T')[0]),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'reportar') {
                              _mostrarDialogoReporte(post.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'reportar',
                              child: Row(
                                children: [
                                  Icon(Icons.flag_outlined, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Reportar publicación'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Texto de la publicación
                      Text(post.contenido, style: const TextStyle(fontSize: 15)),

                      // Imagen adjunta si existe
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

                      // Barra inferior con Reacciones (Likes) y Comentarios
                      Row(
                        children: [
                          // Botón de Me Gusta
                          InkWell(
                            onTap: () async {
                              await _service.reaccionar(post.id, widget.token);
                              _actualizarFeed();
                            },
                            child: Row(
                              children: [
                                Icon(
                                  post.meGusta ? Icons.favorite : Icons.favorite_border,
                                  size: 20,
                                  color: post.meGusta ? Colors.red : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text('${post.totalLikes}'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Botón de Comentarios
                          InkWell(
                            onTap: () => _mostrarModalComentarios(post),
                            child: Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                                const SizedBox(width: 5),
                                Text('${post.totalComentarios} comentarios'),
                              ],
                            ),
                          ),
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