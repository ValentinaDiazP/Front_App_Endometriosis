/// Señales SIMULADAS del módulo de Seguimiento (Mariana), que Educativo
/// usará para priorizar contenido. Hoy son valores fijos de ejemplo.
///
/// Cuando exista integración real, esta clase se reemplaza por una consulta
/// a la API de síntomas (por ejemplo, promedio de intensidad de dolor de los
/// últimos 7 días desde /api/sintomas/registros-sintoma/ y el estado de ánimo
/// del registro emocional). El resto del módulo no debería cambiar: solo
/// consume estos getters.
class SenalesSeguimientoMock {
  SenalesSeguimientoMock._();

  /// Promedio de intensidad de dolor (0-10) de los últimos 7 días.
  static const double dolorPromedio7Dias = 7.0;

  /// Promedio de estado de ánimo (1 = muy bajo ... 5 = muy bueno).
  static const double animoPromedio7Dias = 2.5;

  static bool get dolorAlto => dolorPromedio7Dias >= 6;
  static bool get animoBajo => animoPromedio7Dias <= 3;

  /// Texto corto para mostrar en la pantalla "Para ti".
  static String get resumen =>
      'Dolor promedio ${dolorPromedio7Dias.toStringAsFixed(0)}/10 '
      'esta semana · ánimo ${animoBajo ? 'bajo' : 'estable'}';
}
