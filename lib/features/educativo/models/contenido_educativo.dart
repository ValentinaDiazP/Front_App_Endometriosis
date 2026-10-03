/// Tipos de material soportados (según el diagrama: "texto, video, audio").
enum TipoContenido { texto, video, audio }

/// Nivel de profundidad del contenido.
enum NivelContenido { basico, intermedio, avanzado }

/// Espejo del frontend de la tabla `ContenidoEducativo`.
///
/// idCategoriaFK referencia a [CategoriaContenido.idCategoria].
/// Se llena desde el endpoint GET /api/educativo/contenidos/ (ver
/// EducativoService).
class ContenidoEducativo {
  final String idContenido;
  final String idCategoriaFK;
  final String titulo;
  final TipoContenido tipo;
  final NivelContenido nivel;
  final bool esPremium;
  final DateTime fechaPublicacion;
  final String resumen;
  final String cuerpo; // texto largo / guion del audio-video (placeholder)
  final int minutosEstimados;

  /// Enlace opcional a un video o podcast externo (YouTube, Spotify…).
  final String? urlRecurso;

  const ContenidoEducativo({
    required this.idContenido,
    required this.idCategoriaFK,
    required this.titulo,
    required this.tipo,
    required this.nivel,
    required this.esPremium,
    required this.fechaPublicacion,
    required this.resumen,
    required this.cuerpo,
    required this.minutosEstimados,
    this.urlRecurso,
  });
}
