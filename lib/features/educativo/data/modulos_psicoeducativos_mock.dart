import '../models/modulo_psicoeducativo.dart';
import 'educativo_repository.dart';

/// Módulos informativos guiados (Psicoeducación).
///
/// El contenido YA NO vive en el código: los pasos de cada módulo se editan
/// desde el admin de Django (Ejercicios psicoeducativos → "Pasos del módulo
/// guiado") y llegan en el campo `pasos` de cada ejercicio. El nombre de la
/// clase se conserva para no tocar las pantallas que la usan.
///
/// El texto es informativo y general: no diagnostica ni reemplaza la
/// atención profesional. El contenido definitivo debe ser revisado por una
/// persona del área de la salud antes de publicarse.
class ModulosPsicoeducativosMock {
  ModulosPsicoeducativosMock._();

  /// El módulo del ejercicio, o null si no tiene pasos cargados.
  static ModuloPsicoeducativo? deEjercicio(String idEjercicio) {
    for (final ejercicio in EducativoRepository.ejercicios) {
      if (ejercicio.idEjercicio == idEjercicio && ejercicio.pasos.isNotEmpty) {
        return ModuloPsicoeducativo(idEjercicio: idEjercicio, pasos: ejercicio.pasos);
      }
    }
    return null;
  }
}
