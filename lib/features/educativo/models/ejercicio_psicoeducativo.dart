/// Enfoque terapéutico del ejercicio, según el diagrama ER:
/// "TCC, ACT, Mindfulness, Psicoeducación".
enum TipoEjercicio { psicoeducacion, tcc, actMindfulness }

extension TipoEjercicioLabel on TipoEjercicio {
  String get label {
    switch (this) {
      case TipoEjercicio.psicoeducacion:
        return 'Psicoeducación';
      case TipoEjercicio.tcc:
        return 'TCC';
      case TipoEjercicio.actMindfulness:
        return 'ACT y Mindfulness';
    }
  }
}

/// Espejo del frontend de la tabla `EjercicioPsicoeducativo`.
///
/// El estado de completado NO vive aquí: se consulta en vivo con
/// EducativoRepository.ejercicioCompletado(idEjercicio), igual que con los
/// contenidos de la biblioteca.
class EjercicioPsicoeducativo {
  final String idEjercicio;
  final String nombre;
  final TipoEjercicio tipo;
  final String descripcion;
  final String instrucciones;
  final int minutosEstimados;

  /// Enlace opcional a un video o podcast externo (YouTube, Spotify…).
  final String? urlRecurso;

  /// Solo para usuarias con plan premium (u hospital).
  final bool esPremium;

  /// Premium y la usuaria no lo es: el backend no manda las instrucciones
  /// ni el enlace, y no deja completarlo.
  final bool bloqueado;

  const EjercicioPsicoeducativo({
    required this.idEjercicio,
    required this.nombre,
    required this.tipo,
    required this.descripcion,
    required this.instrucciones,
    required this.minutosEstimados,
    this.urlRecurso,
    this.esPremium = false,
    this.bloqueado = false,
  });
}
