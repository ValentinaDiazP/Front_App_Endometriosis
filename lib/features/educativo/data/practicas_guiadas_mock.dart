import 'educativo_repository.dart';

/// Indicaciones de las prácticas guiadas (ACT y Mindfulness). Durante la
/// práctica se muestran una tras otra, repartidas a lo largo del tiempo del
/// ejercicio (`minutosEstimados`).
///
/// Las indicaciones YA NO viven en el código: se editan desde el admin de
/// Django (Ejercicios psicoeducativos → "Indicaciones de la práctica guiada")
/// y llegan en el campo `indicaciones` de cada ejercicio. El nombre de la
/// clase se conserva para no tocar las pantallas que la usan; el audio
/// guiado, si existe, es el `urlRecurso` del ejercicio.
class PracticasGuiadasMock {
  PracticasGuiadasMock._();

  /// Indicaciones del ejercicio, o unas generales si no tiene propias.
  static List<String> deEjercicio(String idEjercicio) {
    for (final ejercicio in EducativoRepository.ejercicios) {
      if (ejercicio.idEjercicio == idEjercicio && ejercicio.indicaciones.isNotEmpty) {
        return ejercicio.indicaciones;
      }
    }
    return _generales;
  }

  static const _generales = [
    'Busca una postura cómoda y respira con calma.',
    'Nota las sensaciones de tu cuerpo, sin intentar cambiarlas.',
    'Si tu mente se distrae, vuelve con suavidad a la respiración.',
    'Cuando estés lista, abre los ojos despacio.',
  ];
}
