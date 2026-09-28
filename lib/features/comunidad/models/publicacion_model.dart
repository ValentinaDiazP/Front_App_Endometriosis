class Comentario {
  final int id;
  final String? usuarioNombre;
  final String texto;
  final String fechaCreacion;

  Comentario({
    required this.id,
    this.usuarioNombre,
    required this.texto,
    required this.fechaCreacion,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'],
      usuarioNombre: json['usuario_nombre'],
      texto: json['texto'] ?? '',
      fechaCreacion: json['fecha_creacion'] ?? '',
    );
  }
}

class Publicacion {
  final int id;
  final String usuarioNombre;
  final String contenido;
  final String? imagenUrl;
  final String fechaCreacion;
  final int totalLikes;
  final bool meGusta;
  final int totalComentarios;
  final List<Comentario> comentarios;

  Publicacion({
    required this.id,
    required this.usuarioNombre,
    required this.contenido,
    this.imagenUrl,
    required this.fechaCreacion,
    required this.totalLikes,
    required this.meGusta,
    required this.totalComentarios,
    required this.comentarios,
  });

  factory Publicacion.fromJson(Map<String, dynamic> json) {
    return Publicacion(
      id: json['id'],
      usuarioNombre: json['usuario_nombre'] ?? 'Anónima',
      contenido: json['contenido'] ?? '',
      imagenUrl: json['imagen'],
      fechaCreacion: json['fecha_creacion'] ?? '',
      totalLikes: json['total_likes'] ?? 0,
      meGusta: json['me_gusta'] ?? false,
      totalComentarios: json['total_comentarios'] ?? 0,
      comentarios: (json['comentarios'] as List? ?? [])
          .map((c) => Comentario.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}