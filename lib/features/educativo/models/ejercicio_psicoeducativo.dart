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
class EjercicioPsicoeducativo {
  final String idEjercicio;
  final String nombre;
  final TipoEjercicio tipo;
  final String descripcion;
  final String instrucciones;
  final int minutosEstimados;
  final bool completadoPorUsuario; // vendrá de RegistroEjercicio en el back

  const EjercicioPsicoeducativo({
    required this.idEjercicio,
    required this.nombre,
    required this.tipo,
    required this.descripcion,
    required this.instrucciones,
    required this.minutosEstimados,
    this.completadoPorUsuario = false,
  });
}
