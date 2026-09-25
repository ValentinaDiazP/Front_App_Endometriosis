class Publicacion {
  final int id;
  final String usuarioNombre;
  final String contenido;
  final String? imagenUrl;
  final String fechaCreacion;
  final int comentariosCount;

  Publicacion({
    required this.id,
    required this.usuarioNombre,
    required this.contenido,
    this.imagenUrl,
    required this.fechaCreacion,
    required this.comentariosCount,
  });

  factory Publicacion.fromJson(Map<String, dynamic> json) {
    return Publicacion(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      usuarioNombre: (json['usuario_nombre'] as String?) ?? 'Anónima',
      contenido: (json['contenido'] as String?) ?? '',
      imagenUrl: json['imagen'] as String?,
      fechaCreacion: (json['fecha_creacion'] as String?) ?? '',
      comentariosCount: (json['comentarios_count'] as int?) ?? 0,
    );
  }
}