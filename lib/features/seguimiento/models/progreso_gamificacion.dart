/// Nivel de gamificación (nombre y puntos mínimos para alcanzarlo).
class NivelInfo {
  final String nombre;
  final int puntosMinimos;

  const NivelInfo({required this.nombre, required this.puntosMinimos});

  factory NivelInfo.fromJson(Map<String, dynamic> json) {
    return NivelInfo(
      nombre: json['nombre'] as String,
      puntosMinimos: json['puntos_minimos'] as int,
    );
  }
}

/// Una fila del historial: cuándo y por qué se ganaron puntos.
class MovimientoPuntos {
  final DateTime fecha;
  final String motivo;
  final int puntos;

  const MovimientoPuntos({
    required this.fecha,
    required this.motivo,
    required this.puntos,
  });

  factory MovimientoPuntos.fromJson(Map<String, dynamic> json) {
    return MovimientoPuntos(
      fecha: DateTime.parse(json['fecha'] as String),
      motivo: json['motivo'] as String,
      puntos: json['puntos'] as int,
    );
  }
}

/// Progreso completo, tal como lo devuelve GET /api/sintomas/gamificacion/.
class ProgresoGamificacion {
  final int puntosTotales;
  final int rachaActual;
  final int rachaMaxima;
  final NivelInfo? nivel;
  final NivelInfo? siguienteNivel;
  final List<MovimientoPuntos> historial;

  const ProgresoGamificacion({
    required this.puntosTotales,
    required this.rachaActual,
    required this.rachaMaxima,
    required this.nivel,
    required this.siguienteNivel,
    required this.historial,
  });

  /// Avance (0.0 a 1.0) dentro del nivel actual hacia el siguiente.
  double get fraccionHaciaSiguiente {
    final siguiente = siguienteNivel;
    if (siguiente == null) return 1.0;
    final base = nivel?.puntosMinimos ?? 0;
    final tramo = siguiente.puntosMinimos - base;
    if (tramo <= 0) return 1.0;
    return ((puntosTotales - base) / tramo).clamp(0.0, 1.0);
  }

  factory ProgresoGamificacion.fromJson(Map<String, dynamic> json) {
    return ProgresoGamificacion(
      puntosTotales: json['puntos_totales'] as int,
      rachaActual: json['racha_actual'] as int,
      rachaMaxima: json['racha_maxima'] as int,
      nivel: json['nivel'] != null
          ? NivelInfo.fromJson(json['nivel'] as Map<String, dynamic>)
          : null,
      siguienteNivel: json['siguiente_nivel'] != null
          ? NivelInfo.fromJson(json['siguiente_nivel'] as Map<String, dynamic>)
          : null,
      historial: (json['historial'] as List<dynamic>)
          .map((e) => MovimientoPuntos.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}