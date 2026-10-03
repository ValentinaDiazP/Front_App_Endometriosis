/// Indicaciones de las prácticas guiadas (ACT y Mindfulness). Durante la
/// práctica se muestran una tras otra, repartidas a lo largo del tiempo del
/// ejercicio (`minutosEstimados`).
///
/// Igual que ModulosPsicoeducativosMock, viven en el frontend por ahora; el
/// audio guiado, si existe, es el `urlRecurso` del ejercicio.
class PracticasGuiadasMock {
  PracticasGuiadasMock._();

  /// Indicaciones del ejercicio, o unas generales si no tiene propias.
  static List<String> deEjercicio(String idEjercicio) =>
      _porEjercicio[idEjercicio] ?? _generales;

  static const _porEjercicio = <String, List<String>>{
    // Aceptar el dolor sin pelear contra él (ACT)
    'e3': [
      'Busca una postura cómoda. Si quieres, cierra los ojos.',
      'Respira con calma. No tienes que hacerlo de ninguna forma especial.',
      'Nota dónde sientes el dolor ahora mismo. No intentes cambiarlo: solo obsérvalo.',
      'Ponle nombre: "estoy notando una sensación de…" (presión, calor, punzada).',
      'Imagina que le haces espacio, como si respiraras alrededor de esa sensación.',
      'Si aparecen pensamientos como "no lo soporto", déjalos pasar como nubes.',
      'Recuerda algo que te importa hoy, aunque el dolor esté presente.',
      'Vuelve a tu respiración. Cuando estés lista, abre los ojos despacio.',
    ],
    // Mindfulness para el dolor pélvico
    'e4': [
      'Siéntate o recuéstate en un lugar tranquilo. Apoya una mano en tu abdomen.',
      'Inhala por la nariz y siente cómo sube tu mano. Exhala despacio por la boca.',
      'Lleva la atención a tus pies y tus piernas. Nota si hay tensión y suéltala.',
      'Sube la atención a tus caderas y a la parte baja de la espalda.',
      'Ahora, a tu zona pélvica. Obsérvala con amabilidad, sin juzgar lo que sientes.',
      'Con cada exhalación, imagina que esa zona se ablanda un poco.',
      'Si tu mente se distrae, está bien. Vuelve con suavidad a la respiración.',
      'Nota tu cuerpo completo. Cuando quieras, mueve los dedos y abre los ojos.',
    ],
  };

  static const _generales = [
    'Busca una postura cómoda y respira con calma.',
    'Nota las sensaciones de tu cuerpo, sin intentar cambiarlas.',
    'Si tu mente se distrae, vuelve con suavidad a la respiración.',
    'Cuando estés lista, abre los ojos despacio.',
  ];
}
