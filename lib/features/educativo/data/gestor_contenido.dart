import '../models/contenido_educativo.dart';
import '../models/ejercicio_psicoeducativo.dart';
import 'educativo_repository.dart';

/// Resultado de la recomendación: qué actividad pendiente mostrarle a la
/// usuaria y de qué tipo es (para saber a qué pantalla llevarla si toca el
/// aviso).
class RecomendacionPendiente {
  final String titulo;
  final TipoRecomendacion tipo;
  final Object item; // ContenidoEducativo o EjercicioPsicoeducativo

  const RecomendacionPendiente({
    required this.titulo,
    required this.tipo,
    required this.item,
  });
}

enum TipoRecomendacion { contenido, ejercicio }

/// Un contenido ya evaluado por el gestor: con su puntaje y el motivo
/// legible por la usuaria ("Porque te interesa Dolor crónico").
class ContenidoPriorizado {
  final ContenidoEducativo contenido;
  final int puntaje;
  final String? motivo;

  const ContenidoPriorizado({
    required this.contenido,
    required this.puntaje,
    this.motivo,
  });
}

/// Gestor de contenido: encapsula la lógica de "qué le falta a la usuaria
/// por hacer" dentro del módulo Educativo, para poder mostrárselo como un
/// aviso/recordatorio (p. ej. "Tienes pendiente terminar...").
///
/// Decide con los datos que EducativoRepository trae del backend (el primer
/// contenido/ejercicio sin completar según InteraccionContenido y
/// RegistroEjercicio). Nunca sugiere algo bloqueado por Premium.
///
/// Las recomendaciones de "Para ti" las calcula el backend con los datos de
/// Seguimiento (GET /recomendaciones/); [contenidosPriorizados] queda solo
/// como respaldo si esa consulta falla.
class GestorContenidoEducativo {
  GestorContenidoEducativo._();

  /// Devuelve la siguiente recomendación pendiente para mostrar a la
  /// usuaria, o null si ya completó todo el contenido y ejercicios
  /// disponibles.
  static RecomendacionPendiente? siguientePendiente() {
    final ContenidoEducativo? contenidoPendiente =
        EducativoRepository.contenidos.cast<ContenidoEducativo?>().firstWhere(
              (c) => !c!.bloqueado && !EducativoRepository.contenidoCompletado(c.idContenido),
              orElse: () => null,
            );

    if (contenidoPendiente != null) {
      return RecomendacionPendiente(
        titulo: contenidoPendiente.titulo,
        tipo: TipoRecomendacion.contenido,
        item: contenidoPendiente,
      );
    }

    final EjercicioPsicoeducativo? ejercicioPendiente = EducativoRepository
        .ejercicios
        .cast<EjercicioPsicoeducativo?>()
        .firstWhere(
          (e) => !e!.bloqueado && !EducativoRepository.ejercicioCompletado(e.idEjercicio),
          orElse: () => null,
        );

    if (ejercicioPendiente != null) {
      return RecomendacionPendiente(
        titulo: ejercicioPendiente.nombre,
        tipo: TipoRecomendacion.ejercicio,
        item: ejercicioPendiente,
      );
    }

    return null; // ya completó todo lo disponible
  }

  // ---------------------------------------------------------------------
  // Personalización: contenido priorizado / filtrado.
  // ---------------------------------------------------------------------

  /// Respaldo local de "Para ti" si el backend no responde: ordena solo por
  /// preferencias (sin datos de Seguimiento).
  ///  +3  la categoría del contenido está entre sus preferencias.
  ///  -2  está bloqueado por Premium.
  ///  -10 ya lo completó (baja al final para priorizar lo nuevo).
  /// Empates: primero los de nivel más básico.
  ///
  /// Si [soloPreferidos] es true y la usuaria tiene preferencias, se
  /// filtran los contenidos de categorías que no eligió.
  static List<ContenidoPriorizado> contenidosPriorizados({
    bool soloPreferidos = false,
  }) {
    final preferidas = EducativoRepository.categoriasPreferidas;

    var lista = EducativoRepository.contenidos.toList();
    if (soloPreferidos && preferidas.isNotEmpty) {
      lista = lista.where((c) => preferidas.contains(c.idCategoriaFK)).toList();
    }

    final evaluados = lista.map((c) {
      var puntaje = 0;
      final motivos = <String>[];

      if (preferidas.contains(c.idCategoriaFK)) {
        puntaje += 3;
        final categoria = EducativoRepository.categoriaPorId(c.idCategoriaFK);
        motivos.add('Porque te interesa ${categoria?.nombre ?? 'este tema'}');
      }
      if (c.bloqueado) {
        puntaje -= 2;
      }
      if (EducativoRepository.contenidoCompletado(c.idContenido)) {
        puntaje -= 10;
      }

      return ContenidoPriorizado(
        contenido: c,
        puntaje: puntaje,
        motivo: motivos.isEmpty ? null : motivos.join(' · '),
      );
    }).toList();

    evaluados.sort((a, b) {
      final porPuntaje = b.puntaje.compareTo(a.puntaje);
      if (porPuntaje != 0) return porPuntaje;
      return a.contenido.nivel.index.compareTo(b.contenido.nivel.index);
    });

    return evaluados;
  }
}
