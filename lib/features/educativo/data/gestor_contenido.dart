import '../models/contenido_educativo.dart';
import '../models/ejercicio_psicoeducativo.dart';
import 'mock_educativo_data.dart';
import 'senales_seguimiento_mock.dart';

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

  // ---------------------------------------------------------------------
  // Personalización: contenido priorizado / filtrado.
  // ---------------------------------------------------------------------

  /// Devuelve los contenidos ordenados del más al menos relevante para la
  /// usuaria. Reglas (simples y explicables, se pueden ajustar sin tocar la UI):
  ///  +3  la categoría del contenido está entre sus preferencias.
  ///  +2  señal de Seguimiento: dolor alto esta semana -> "Dolor crónico".
  ///  +2  señal de Seguimiento: ánimo bajo esta semana -> "Autocuidado".
  ///  -5  ya lo completó (baja al final para priorizar lo nuevo).
  /// Empates: primero los de nivel más básico.
  ///
  /// Si [soloPreferidos] es true y la usuaria tiene preferencias, se
  /// filtran los contenidos de categorías que no eligió.
  static List<ContenidoPriorizado> contenidosPriorizados({
    bool soloPreferidos = false,
  }) {
    final preferidas = MockEducativoData.categoriasPreferidas;

    var lista = MockEducativoData.contenidos.toList();
    if (soloPreferidos && preferidas.isNotEmpty) {
      lista = lista.where((c) => preferidas.contains(c.idCategoriaFK)).toList();
    }

    final evaluados = lista.map((c) {
      var puntaje = 0;
      final motivos = <String>[];

      if (preferidas.contains(c.idCategoriaFK)) {
        puntaje += 3;
        final categoria = MockEducativoData.categoriaPorId(c.idCategoriaFK);
        motivos.add('Porque te interesa ${categoria?.nombre ?? 'este tema'}');
      }
      if (SenalesSeguimientoMock.dolorAlto && c.idCategoriaFK == 'cat_dolor') {
        puntaje += 2;
        motivos.add('Registraste dolor alto esta semana');
      }
      if (SenalesSeguimientoMock.animoBajo &&
          c.idCategoriaFK == 'cat_autocuidado') {
        puntaje += 2;
        motivos.add('Tu ánimo ha estado bajo esta semana');
      }
      if (MockEducativoData.contenidoCompletado(c.idContenido)) {
        puntaje -= 5;
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
