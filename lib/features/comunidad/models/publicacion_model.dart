class Comentario {
  final int id;
  final String? usuarioNombre;
  final String texto;
  final String fechaCreacion;
  final int totalLikes;
  final bool meGusta;

  Comentario({
    required this.id,
    this.usuarioNombre,
    required this.texto,
    required this.fechaCreacion,
    this.totalLikes = 0,
    this.meGusta = false,
  });

  Comentario copyWith({
    int? id,
    String? usuarioNombre,
    String? texto,
    String? fechaCreacion,
    int? totalLikes,
    bool? meGusta,
  }) {
    return Comentario(
      id: id ?? this.id,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      texto: texto ?? this.texto,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      totalLikes: totalLikes ?? this.totalLikes,
      meGusta: meGusta ?? this.meGusta,
    );
  }

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'],
      usuarioNombre: json['usuario_nombre'],
      texto: json['texto'] ?? '',
      fechaCreacion: json['fecha_creacion'] ?? '',
      totalLikes: json['total_likes'] ?? 0,
      meGusta: json['me_gusta'] ?? false,
    );
  }
}

class Publicacion {
  final int id;
  final String usuarioNombre;
  final String contenido;
  final String? imagenUrl;
  final String fechaCreacion;
  final String categoria;
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
    required this.categoria,
    required this.totalLikes,
    required this.meGusta,
    required this.totalComentarios,
    required this.comentarios,
  });

  Publicacion copyWith({
    int? id,
    String? usuarioNombre,
    String? contenido,
    String? imagenUrl,
    String? fechaCreacion,
    String? categoria,
    int? totalLikes,
    bool? meGusta,
    int? totalComentarios,
    List<Comentario>? comentarios,
  }) {
    return Publicacion(
      id: id ?? this.id,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      contenido: contenido ?? this.contenido,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      categoria: categoria ?? this.categoria,
      totalLikes: totalLikes ?? this.totalLikes,
      meGusta: meGusta ?? this.meGusta,
      totalComentarios: totalComentarios ?? this.totalComentarios,
      comentarios: comentarios ?? this.comentarios,
    );
  }

  factory Publicacion.fromJson(Map<String, dynamic> json) {
    return Publicacion(
      id: json['id'],
      usuarioNombre: json['usuario_nombre'] ?? 'Anónima',
      contenido: json['contenido'] ?? '',
      imagenUrl: json['imagen'],
      fechaCreacion: json['fecha_creacion'] ?? '',
      categoria: json['categoria'] ?? 'HISTORIAS_APOYO',
      totalLikes: json['total_likes'] ?? 0,
      meGusta: json['me_gusta'] ?? false,
      totalComentarios: json['total_comentarios'] ?? 0,
      comentarios: (json['comentarios'] as List? ?? [])
          .map((c) => Comentario.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
