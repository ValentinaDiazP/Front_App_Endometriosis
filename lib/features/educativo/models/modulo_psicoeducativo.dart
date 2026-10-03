/// Un paso (pantalla) dentro de un módulo informativo guiado.
class PasoModulo {
  final String titulo;
  final List<String> parrafos;

  /// Idea clave del paso, mostrada resaltada. Se repite en el resumen final.
  final String? puntoClave;

  const PasoModulo({
    required this.titulo,
    required this.parrafos,
    this.puntoClave,
  });
}

/// Módulo informativo guiado de un ejercicio de tipo Psicoeducación.
///
/// `idEjercicio` apunta al [EjercicioPsicoeducativo] al que pertenece. El
/// modelo de datos actual (ER del módulo) NO tiene una tabla de pasos: hoy
/// los pasos viven solo en el frontend (datos mock). Para llevarlos al
/// backend hace falta una tabla `PasoModulo` (ejercicio, orden, titulo,
/// parrafos, punto_clave) o guardar los pasos en formato estructurado.
class ModuloPsicoeducativo {
  final String idEjercicio;
  final List<PasoModulo> pasos;

  const ModuloPsicoeducativo({
    required this.idEjercicio,
    required this.pasos,
  });

  int get totalPasos => pasos.length;
}
