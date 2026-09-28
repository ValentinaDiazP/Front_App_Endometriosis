import '../models/categoria_contenido.dart';
import '../models/contenido_educativo.dart';
import '../models/ejercicio_psicoeducativo.dart';
import '../models/ruta_aprendizaje.dart';

/// Fuente de datos falsa (in-memory) para poder navegar el wireframe sin
/// backend. Cuando exista `GET /api/educativo/...`, esta clase se reemplaza
/// por un `EducativoRepository` que llame a Django; las pantallas no
/// deberían tener que cambiar porque ya consumen estos mismos modelos.
class MockEducativoData {
  MockEducativoData._();

  static const categorias = [
    CategoriaContenido(
      idCategoria: 'cat_endometriosis',
      nombre: 'Endometriosis',
      descripcion: 'Qué es, cómo se diagnostica y cómo evoluciona.',
    ),
    CategoriaContenido(
      idCategoria: 'cat_dolor',
      nombre: 'Dolor crónico',
      descripcion: 'Entender el dolor persistente y cómo manejarlo.',
    ),
    CategoriaContenido(
      idCategoria: 'cat_autocuidado',
      nombre: 'Autocuidado',
      descripcion: 'Hábitos, alimentación y bienestar emocional diario.',
    ),
  ];

  static final contenidos = <ContenidoEducativo>[
    ContenidoEducativo(
      idContenido: 'c1',
      idCategoriaFK: 'cat_endometriosis',
      titulo: '¿Qué es la endometriosis?',
      tipo: TipoContenido.texto,
      nivel: NivelContenido.basico,
      esPremium: false,
      fechaPublicacion: DateTime(2026, 1, 10),
      resumen: 'Una introducción clara a qué le pasa a tu cuerpo.',
      cuerpo:
          'La endometriosis es una condición en la que tejido similar al '
          'endometrio crece fuera del útero... (contenido de ejemplo)',
      minutosEstimados: 5,
    ),
    ContenidoEducativo(
      idContenido: 'c2',
      idCategoriaFK: 'cat_dolor',
      titulo: 'Entendiendo el dolor crónico',
      tipo: TipoContenido.video,
      nivel: NivelContenido.basico,
      esPremium: false,
      fechaPublicacion: DateTime(2026, 1, 12),
      resumen: 'Por qué el dolor persiste incluso sin daño activo.',
      cuerpo: 'Guion del video de ejemplo...',
      minutosEstimados: 8,
    ),
    ContenidoEducativo(
      idContenido: 'c3',
      idCategoriaFK: 'cat_autocuidado',
      titulo: 'Rutina de autocuidado para días difíciles',
      tipo: TipoContenido.audio,
      nivel: NivelContenido.intermedio,
      esPremium: false,
      fechaPublicacion: DateTime(2026, 1, 15),
      resumen: 'Pequeños hábitos para los días de más dolor.',
      cuerpo: 'Guion del audio de ejemplo...',
      minutosEstimados: 6,
    ),
    ContenidoEducativo(
      idContenido: 'c4',
      idCategoriaFK: 'cat_dolor',
      titulo: 'Catastrofización del dolor: cómo identificarla',
      tipo: TipoContenido.texto,
      nivel: NivelContenido.avanzado,
      esPremium: true,
      fechaPublicacion: DateTime(2026, 1, 20),
      resumen: 'Contenido premium con enfoque TCC.',
      cuerpo: 'Contenido de ejemplo premium...',
      minutosEstimados: 10,
    ),
  ];

  static const ejercicios = <EjercicioPsicoeducativo>[
    EjercicioPsicoeducativo(
      idEjercicio: 'e1',
      nombre: '¿Qué le pasa a mi cuerpo cuando duele?',
      tipo: TipoEjercicio.psicoeducacion,
      descripcion: 'Módulo guiado para entender el ciclo del dolor.',
      instrucciones:
          'Lee cada tarjeta y marca la casilla al terminar. Tómate tu tiempo.',
      minutosEstimados: 7,
    ),
    EjercicioPsicoeducativo(
      idEjercicio: 'e2',
      nombre: 'Reestructurando pensamientos catastróficos',
      tipo: TipoEjercicio.tcc,
      descripcion: 'Identifica y transforma pensamientos como "esto nunca va a mejorar".',
      instrucciones:
          'Escribe un pensamiento difícil, luego una versión más balanceada.',
      minutosEstimados: 10,
    ),
    EjercicioPsicoeducativo(
      idEjercicio: 'e3',
      nombre: 'Aceptar el dolor sin pelear contra él',
      tipo: TipoEjercicio.actMindfulness,
      descripcion: 'Ejercicio de aceptación basado en ACT.',
      instrucciones: 'Sigue el audio guiado de 5 minutos.',
      minutosEstimados: 5,
    ),
    EjercicioPsicoeducativo(
      idEjercicio: 'e4',
      nombre: 'Mindfulness para el dolor pélvico',
      tipo: TipoEjercicio.actMindfulness,
      descripcion: 'Práctica breve de atención plena orientada al dolor.',
      instrucciones: 'Busca un lugar tranquilo y sigue las instrucciones.',
      minutosEstimados: 8,
    ),
  ];

  static List<RutaAprendizaje> get rutas => [
        RutaAprendizaje(
          idRuta: 'r1',
          nombre: 'Primeros pasos con la endometriosis',
          descripcion: 'Ruta introductoria para usuarias recién diagnosticadas.',
          contenidos: [contenidos[0], contenidos[1], contenidos[2]],
        ),
        RutaAprendizaje(
          idRuta: 'r2',
          nombre: 'Manejo del dolor con enfoque TCC',
          descripcion: 'Ruta intermedia centrada en pensamientos y dolor.',
          contenidos: [contenidos[1], contenidos[3]],
        ),
      ];

  // ---------------------------------------------------------------------
  // Estado de progreso (mock, en memoria). Cuando exista backend, esto se
  // reemplaza por lecturas/escrituras reales a InteraccionContenido y
  // RegistroEjercicio (ver diagrama ER del módulo).
  // ---------------------------------------------------------------------

  static final Set<String> _contenidosCompletados = {'c1'};
  static final Set<String> _ejerciciosCompletados = {'e1'};

  static bool contenidoCompletado(String idContenido) =>
      _contenidosCompletados.contains(idContenido);

  static void marcarContenidoCompletado(String idContenido) {
    _contenidosCompletados.add(idContenido);
  }

  static bool ejercicioCompletado(String idEjercicio) =>
      _ejerciciosCompletados.contains(idEjercicio);

  static void marcarEjercicioCompletado(String idEjercicio) {
    _ejerciciosCompletados.add(idEjercicio);
  }

  static int get totalContenidosCompletados => _contenidosCompletados
      .where((id) => contenidos.any((c) => c.idContenido == id))
      .length;

  static int get totalContenidos => contenidos.length;

  // ---------------------------------------------------------------------
  // Preferencias de la usuaria (mock, en memoria). Equivale a la tabla
  // `PreferenciaUsuario` del diagrama ER (idUsuario + idCategoria). Se llena
  // en la pantalla de preferencias del onboarding (PreferenciasScreen).
  // Cuando exista backend: POST/GET /api/educativo/preferencias/.
  // ---------------------------------------------------------------------

  static final Set<String> _categoriasPreferidas = {};

  static Set<String> get categoriasPreferidas =>
      Set<String>.of(_categoriasPreferidas);

  static bool get tienePreferencias => _categoriasPreferidas.isNotEmpty;

  static void guardarPreferencias(Set<String> idsCategorias) {
    _categoriasPreferidas
      ..clear()
      ..addAll(idsCategorias);
  }

  static CategoriaContenido? categoriaPorId(String id) {
    for (final c in categorias) {
      if (c.idCategoria == id) return c;
    }
    return null;
  }
}
