import '../models/contenido_educativo.dart';
import '../models/ejercicio_psicoeducativo.dart';
import 'mock_educativo_data.dart';

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

/// Gestor de contenido: encapsula la lógica de "qué le falta a la usuaria
/// por hacer" dentro del módulo Educativo, para poder mostrárselo como un
/// aviso/recordatorio (p. ej. "Tienes pendiente terminar...").
///
/// Hoy decide en base a los datos mock (el primer contenido/ejercicio sin
/// completar). Cuando exista backend, la misma interfaz (un solo método
/// `siguientePendiente()`) se puede reimplementar consultando las señales
/// reales de InteraccionContenido / RegistroEjercicio y la personalización
/// definida en PreferenciaUsuario, sin tener que cambiar la UI que lo usa.
class GestorContenidoEducativo {
  GestorContenidoEducativo._();

  /// Devuelve la siguiente recomendación pendiente para mostrar a la
  /// usuaria, o null si ya completó todo el contenido y ejercicios
  /// disponibles.
  static RecomendacionPendiente? siguientePendiente() {
    final ContenidoEducativo? contenidoPendiente =
        MockEducativoData.contenidos.cast<ContenidoEducativo?>().firstWhere(
              (c) => !MockEducativoData.contenidoCompletado(c!.idContenido),
              orElse: () => null,
            );

    if (contenidoPendiente != null) {
      return RecomendacionPendiente(
        titulo: contenidoPendiente.titulo,
        tipo: TipoRecomendacion.contenido,
        item: contenidoPendiente,
      );
    }

    final EjercicioPsicoeducativo? ejercicioPendiente = MockEducativoData
        .ejercicios
        .cast<EjercicioPsicoeducativo?>()
        .firstWhere(
          (e) => !MockEducativoData.ejercicioCompletado(e!.idEjercicio),
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
}
