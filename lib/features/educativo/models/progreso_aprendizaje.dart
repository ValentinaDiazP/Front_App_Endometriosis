/// Modelos del motor de aprendizaje (puntos, niveles, rachas e insignias por
/// ruta). Espejo de GET /api/educativo/progreso/ y del bloque `gamificacion`
/// que devuelven los POST de lectura de contenido y de ejercicios.
library;

class NivelAprendizaje {
  final String nombre;
  final String emoji;
  final int puntosMinimos;

  const NivelAprendizaje({
    required this.nombre,
    required this.emoji,
    required this.puntosMinimos,
  });

  factory NivelAprendizaje.fromJson(Map<String, dynamic> j) => NivelAprendizaje(
        nombre: (j['nombre'] as String?) ?? 'Exploradora',
        emoji: (j['emoji'] as String?) ?? '',
        puntosMinimos: (j['puntos_minimos'] as num?)?.toInt() ?? 0,
      );
}

class InsigniaRuta {
  final int id;
  final String nombre;
  final String descripcion;
  final String emoji;
  final String rutaId;
  final String rutaNombre;
  final bool obtenida;
  final String? fechaObtenida;
  final int contenidosCompletados;
  final int contenidosTotal;

  /// La ruta tiene contenido premium y la usuaria es gratuita: no puede completarla.
  final bool requierePremium;

  const InsigniaRuta({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.emoji,
    required this.rutaId,
    required this.rutaNombre,
    required this.obtenida,
    required this.fechaObtenida,
    required this.contenidosCompletados,
    required this.contenidosTotal,
    this.requierePremium = false,
  });

  factory InsigniaRuta.fromJson(Map<String, dynamic> j) => InsigniaRuta(
        id: (j['id'] as num).toInt(),
        nombre: j['nombre'] as String,
        descripcion: (j['descripcion'] as String?) ?? '',
        emoji: (j['emoji'] as String?) ?? '',
        rutaId: j['ruta_id'] as String,
        rutaNombre: j['ruta_nombre'] as String,
        obtenida: j['obtenida'] as bool,
        fechaObtenida: j['fecha_obtenida'] as String?,
        contenidosCompletados: (j['contenidos_completados'] as num).toInt(),
        contenidosTotal: (j['contenidos_total'] as num).toInt(),
        requierePremium: (j['requiere_premium'] as bool?) ?? false,
      );
}

class ReglaPuntos {
  final String descripcion;
  final int puntos;

  const ReglaPuntos({required this.descripcion, required this.puntos});

  factory ReglaPuntos.fromJson(Map<String, dynamic> j) => ReglaPuntos(
        descripcion: j['descripcion'] as String,
        puntos: (j['puntos'] as num).toInt(),
      );
}

class MovimientoPuntos {
  final String fecha;
  final String motivo;
  final int puntos;

  const MovimientoPuntos({required this.fecha, required this.motivo, required this.puntos});

  factory MovimientoPuntos.fromJson(Map<String, dynamic> j) => MovimientoPuntos(
        fecha: j['fecha'] as String,
        motivo: j['motivo'] as String,
        puntos: (j['puntos'] as num).toInt(),
      );
}

/// Todo lo que muestra la pantalla "Mi progreso".
class ProgresoAprendizaje {
  final int puntosTotales;
  final NivelAprendizaje nivel;
  final NivelAprendizaje? siguienteNivel;

  /// Avance dentro del nivel actual hacia el siguiente, de 0.0 a 1.0.
  final double progresoNivel;
  final int rachaActual;
  final int rachaMaxima;
  final bool activaHoy;
  final List<InsigniaRuta> insignias;
  final List<ReglaPuntos> reglas;
  final List<MovimientoPuntos> historial;

  const ProgresoAprendizaje({
    required this.puntosTotales,
    required this.nivel,
    required this.siguienteNivel,
    required this.progresoNivel,
    required this.rachaActual,
    required this.rachaMaxima,
    required this.activaHoy,
    required this.insignias,
    required this.reglas,
    required this.historial,
  });

  int get puntosParaSiguiente =>
      siguienteNivel == null ? 0 : siguienteNivel!.puntosMinimos - puntosTotales;

  factory ProgresoAprendizaje.fromJson(Map<String, dynamic> j) {
    final siguiente = j['siguiente_nivel'];
    return ProgresoAprendizaje(
      puntosTotales: (j['puntos_totales'] as num).toInt(),
      nivel: NivelAprendizaje.fromJson(j['nivel'] as Map<String, dynamic>),
      siguienteNivel: siguiente == null
          ? null
          : NivelAprendizaje.fromJson(siguiente as Map<String, dynamic>),
      progresoNivel: (j['progreso_nivel'] as num).toDouble().clamp(0.0, 1.0).toDouble(),
      rachaActual: (j['racha_actual'] as num).toInt(),
      rachaMaxima: (j['racha_maxima'] as num).toInt(),
      activaHoy: j['activa_hoy'] as bool,
      insignias: (j['insignias'] as List<dynamic>)
          .map((e) => InsigniaRuta.fromJson(e as Map<String, dynamic>))
          .toList(),
      reglas: (j['reglas'] as List<dynamic>)
          .map((e) => ReglaPuntos.fromJson(e as Map<String, dynamic>))
          .toList(),
      historial: (j['historial'] as List<dynamic>)
          .map((e) => MovimientoPuntos.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Recompensa que devuelve el backend al leer un contenido o completar un
/// ejercicio (bloque `gamificacion` de la respuesta).
class ResultadoGamificacion {
  final int puntosGanados;
  final int puntosTotales;
  final int rachaActual;
  final String? subioDeNivel;
  final List<String> insigniasNuevas;

  const ResultadoGamificacion({
    required this.puntosGanados,
    required this.puntosTotales,
    required this.rachaActual,
    required this.subioDeNivel,
    required this.insigniasNuevas,
  });

  /// Si hay algo que celebrar (si no, no se muestra ningún aviso).
  bool get hayNovedad =>
      puntosGanados > 0 || subioDeNivel != null || insigniasNuevas.isNotEmpty;

  factory ResultadoGamificacion.fromJson(Map<String, dynamic> j) => ResultadoGamificacion(
        puntosGanados: (j['puntos_ganados'] as num).toInt(),
        puntosTotales: (j['puntos_totales'] as num).toInt(),
        rachaActual: (j['racha_actual'] as num).toInt(),
        subioDeNivel: j['subio_de_nivel'] as String?,
        insigniasNuevas: (j['insignias_nuevas'] as List<dynamic>)
            .map((e) => (e as Map<String, dynamic>)['nombre'] as String)
            .toList(),
      );
}
