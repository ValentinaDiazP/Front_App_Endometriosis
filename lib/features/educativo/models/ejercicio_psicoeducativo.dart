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

  const EjercicioPsicoeducativo({
    required this.idEjercicio,
    required this.nombre,
    required this.tipo,
    required this.descripcion,
    required this.instrucciones,
    required this.minutosEstimados,
  });
}
