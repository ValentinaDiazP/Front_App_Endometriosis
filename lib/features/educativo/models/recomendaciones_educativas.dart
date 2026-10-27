/// Recomendaciones automáticas de la pestaña "Para ti". Espejo de
/// GET /api/educativo/recomendaciones/: el backend cruza las preferencias,
/// el progreso y los datos de Seguimiento (dolor, ánimo y ciclo de los
/// últimos 7 días) y devuelve contenidos y ejercicios ya ordenados.
library;

/// Lo que el backend sabe de Seguimiento y usó para recomendar.
class SenalesSeguimiento {
  final int diasVentana;
  final bool hayDatos;

  /// Frase lista para mostrar: "Dolor promedio 6.5/10 · ánimo bajo".
  final String resumen;
  final bool dolorAlto;
  final bool animoBajo;
  final bool enPeriodo;

  const SenalesSeguimiento({
    required this.diasVentana,
    required this.hayDatos,
    required this.resumen,
    required this.dolorAlto,
    required this.animoBajo,
    required this.enPeriodo,
  });

  factory SenalesSeguimiento.fromJson(Map<String, dynamic> j) => SenalesSeguimiento(
        diasVentana: (j['dias_ventana'] as num?)?.toInt() ?? 7,
        hayDatos: (j['hay_datos'] as bool?) ?? false,
        resumen: (j['resumen'] as String?) ?? '',
        dolorAlto: (j['dolor_alto'] as bool?) ?? false,
        animoBajo: (j['animo_bajo'] as bool?) ?? false,
        enPeriodo: (j['en_periodo'] as bool?) ?? false,
      );
}

/// Un contenido o ejercicio recomendado (se identifica por su id).
class Recomendacion {
  final String id;
  final int puntaje;

  /// Por qué se recomienda ("Registraste dolor alto esta semana"), o null.
  final String? motivo;
  final bool completado;
  final bool bloqueado;

  const Recomendacion({
    required this.id,
    required this.puntaje,
    required this.motivo,
    required this.completado,
    required this.bloqueado,
  });

  factory Recomendacion.fromJson(Map<String, dynamic> j) => Recomendacion(
        id: j['id'] as String,
        puntaje: (j['puntaje'] as num).toInt(),
        motivo: j['motivo'] as String?,
        completado: (j['completado'] as bool?) ?? false,
        bloqueado: (j['bloqueado'] as bool?) ?? false,
      );
}

class RecomendacionesEducativas {
  final SenalesSeguimiento senales;
  final bool esPremium;
  final List<Recomendacion> contenidos;
  final List<Recomendacion> ejercicios;

  const RecomendacionesEducativas({
    required this.senales,
    required this.esPremium,
    required this.contenidos,
    required this.ejercicios,
  });

  factory RecomendacionesEducativas.fromJson(Map<String, dynamic> j) {
    List<Recomendacion> lista(String clave) => (j[clave] as List<dynamic>)
        .map((e) => Recomendacion.fromJson(e as Map<String, dynamic>))
        .toList();
    return RecomendacionesEducativas(
      senales: SenalesSeguimiento.fromJson(j['senales'] as Map<String, dynamic>),
      esPremium: (j['es_premium'] as bool?) ?? false,
      contenidos: lista('contenidos'),
      ejercicios: lista('ejercicios'),
    );
  }
}
