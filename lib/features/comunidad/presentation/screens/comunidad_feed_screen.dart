import 'package:flutter/material.dart';
import '../../models/publicacion_model.dart';
import '../../services/comunidad_service.dart';
import 'crear_publicacion_screen.dart';

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
  // 1.B. DIÁLOGO PARA REPORTAR COMENTARIO
  // ===========================================================================
  void _mostrarDialogoReporteComentario(int comentarioId, VoidCallback onEliminarLocal) {
    final TextEditingController motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reportar comentario'),
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
                final exito = await _service.reportarComentario(comentarioId, motivo, widget.token);
                if (!mounted) return;
                Navigator.pop(ctx);
                if (exito) {
                  onEliminarLocal();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comentario reportado y eliminado de la vista')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al reportar comentario')),
                  );
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. MODAL PARA COMENTARIOS (CON ORDENAMIENTO Y REPORTAR COMENTARIO)
  // ===========================================================================
  void _mostrarModalComentarios(Publicacion post) {
    final TextEditingController comentarioController = TextEditingController();
    String ordenSeleccionado = 'recientes'; // 'recientes' o 'top'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateModal) {
          // Copia y ordenamiento de comentarios
          List<Comentario> comentariosList = List.from(post.comentarios);
          if (ordenSeleccionado == 'top') {
            comentariosList.sort((a, b) => b.totalLikes.compareTo(a.totalLikes));
          }

          // Identificar el comentario más apoyado si hay top
          int? maxLikesTop;
          if (comentariosList.isNotEmpty) {
            maxLikesTop = comentariosList.map((c) => c.totalLikes).reduce((a, b) => a > b ? a : b);
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Comentarios',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      // Selector de Ordenamiento
                      DropdownButton<String>(
                        value: ordenSeleccionado,
                        items: const [
                          DropdownMenuItem(value: 'recientes', child: Text('Más recientes')),
                          DropdownMenuItem(value: 'top', child: Text('Top comentarios')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setStateModal(() {
                              ordenSeleccionado = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: comentariosList.isEmpty
                        ? const Center(child: Text('Aún no hay comentarios. ¡Sé la primera!'))
                        : ListView.builder(
                            itemCount: comentariosList.length,
                            itemBuilder: (context, index) {
                              final c = comentariosList[index];
                              final bool esTopApoyado = ordenSeleccionado == 'top' &&
                                  maxLikesTop != null &&
                                  maxLikesTop > 0 &&
                                  c.totalLikes == maxLikesTop;

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Row(
                                  children: [
                                    Text(
                                      c.usuarioNombre ?? 'Anónima',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    if (esTopApoyado) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber[100],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.star_rounded, size: 12, color: Colors.brown),
                                            SizedBox(width: 2),
                                            Text(
                                              'Más apoyado',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(c.texto),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'reportar_comentario') {
                                      _mostrarDialogoReporteComentario(c.id, () {
                                        setStateModal(() {
                                          post.comentarios.removeWhere((item) => item.id == c.id);
                                        });
                                        setState(() {});
                                      });
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'reportar_comentario',
                                      child: Row(
                                        children: [
                                          Icon(Icons.flag_outlined, color: Colors.red, size: 18),
                                          SizedBox(width: 8),
                                          Text('Reportar comentario'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 3. MODAL PARA CREAR PUBLICACIÓN
  // ===========================================================================
  void _mostrarModalCrearPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CrearPublicacionScreen(
          token: widget.token,
          service: _service,
        );
      },
    ).then((exito) {
      if (exito == true && mounted) {
        _actualizarFeed();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicación creada')),
        );
      }
    });
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
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildCardProposito(),
                const SizedBox(height: 40),
                const Center(
                  child: Text('Aún no hay publicaciones aprobadas. ¡Sé la primera en escribir!'),
                ),
              ],
            );
          }

          final publicaciones = snapshot.data!;
          return ListView.builder(
            itemCount: publicaciones.length + 1, // +1 para incluir la tarjeta de propósito al inicio
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCardProposito();
              }

              final post = publicaciones[index - 1];
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

  // Tarjeta de Propósito en el Feed (Sin emojis, usando Iconos vectoriales)
  Widget _buildCardProposito() {
    return Card(
      margin: const EdgeInsets.all(12),
      color: Colors.purple[50],
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Para qué es la Comunidad Florecer?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
            ),
            const SizedBox(height: 8),
            const Text(
              'Un espacio seguro y libre de juicios para compartir experiencias sobre endometriosis y bienestar femenino.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.edit_note, size: 16, color: Colors.purple),
                SizedBox(width: 4),
                Text('+10 pts por publicar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
                SizedBox(width: 12),
                Icon(Icons.chat_bubble_outline, size: 14, color: Colors.purple),
                SizedBox(width: 4),
                Text('+5 pts por apoyar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
