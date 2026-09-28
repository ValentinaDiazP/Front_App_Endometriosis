import '../models/categoria_contenido.dart';
import '../models/contenido_educativo.dart';
import '../models/ejercicio_psicoeducativo.dart';
import '../models/ruta_aprendizaje.dart';
import '../services/educativo_service.dart';

/// Fuente de datos del módulo Educativo (reemplaza al antiguo
/// MockEducativoData, con la misma interfaz de lectura).
///
/// Al entrar al módulo se llama [asegurarCargado] con el token de la
/// usuaria: trae de Django el catálogo, sus preferencias y su progreso, y lo
/// deja en memoria. Desde ahí las pantallas leen de forma síncrona, como
/// antes. Las escrituras (preferencias, completar contenido/ejercicio) van
/// primero al backend.
///
/// Si entra otra usuaria (token distinto), se vuelve a cargar todo.
class EducativoRepository {
  EducativoRepository._();

  static String? _token;
  static Future<void>? _cargaEnCurso;
  static DatosEducativos? _datos;

  static final Set<String> _categoriasPreferidas = {};
  static final Set<String> _contenidosCompletados = {};
  static final Set<String> _ejerciciosCompletados = {};

  static bool get cargado => _datos != null;

  /// Si ya están en memoria los datos de [token] (o de la última usuaria,
  /// si [token] es null), para poder mostrarlos sin pasar por "cargando".
  static bool cargadoPara(String? token) =>
      _datos != null && (token == null || token == _token);

  /// Carga los datos de la usuaria dueña de [token] si aún no están en
  /// memoria. Si [token] es null, reutiliza el de la última carga.
  static Future<void> asegurarCargado([String? token]) {
    final tokenEfectivo = token ?? _token;
    if (tokenEfectivo == null) {
      return Future.error(Exception('Inicia sesión para ver el contenido educativo.'));
    }
    if (tokenEfectivo == _token) {
      if (_datos != null) return Future.value();
      if (_cargaEnCurso != null) return _cargaEnCurso!;
    }

    _token = tokenEfectivo;
    _datos = null;
    final carga = _cargar(tokenEfectivo);
    _cargaEnCurso = carga;
    return carga;
  }

  static Future<void> _cargar(String token) async {
    try {
      final datos = await EducativoService.cargarTodo(token);
      if (token != _token) return; // entró otra usuaria mientras cargaba
      _datos = datos;
      _categoriasPreferidas
        ..clear()
        ..addAll(datos.categoriasPreferidas);
      _contenidosCompletados
        ..clear()
        ..addAll(datos.contenidosCompletados);
      _ejerciciosCompletados
        ..clear()
        ..addAll(datos.ejerciciosCompletados);
    } finally {
      if (token == _token) _cargaEnCurso = null;
    }
  }

  // ---------------------------------------------------------------------
  // Catálogo
  // ---------------------------------------------------------------------

  static List<CategoriaContenido> get categorias => _datos?.categorias ?? const [];
  static List<ContenidoEducativo> get contenidos => _datos?.contenidos ?? const [];
  static List<EjercicioPsicoeducativo> get ejercicios => _datos?.ejercicios ?? const [];
  static List<RutaAprendizaje> get rutas => _datos?.rutas ?? const [];

  static CategoriaContenido? categoriaPorId(String id) {
    for (final c in categorias) {
      if (c.idCategoria == id) return c;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Progreso (InteraccionContenido / RegistroEjercicio)
  // ---------------------------------------------------------------------

  static bool contenidoCompletado(String idContenido) =>
      _contenidosCompletados.contains(idContenido);

  static Future<void> marcarContenidoCompletado(String idContenido) async {
    if (_contenidosCompletados.contains(idContenido)) return;
    await EducativoService.marcarContenidoCompletado(_tokenActual, idContenido);
    _contenidosCompletados.add(idContenido);
  }

  static bool ejercicioCompletado(String idEjercicio) =>
      _ejerciciosCompletados.contains(idEjercicio);

  static Future<void> marcarEjercicioCompletado(String idEjercicio) async {
    await EducativoService.registrarEjercicio(_tokenActual, idEjercicio);
    _ejerciciosCompletados.add(idEjercicio);
  }

  static int get totalContenidosCompletados => _contenidosCompletados
      .where((id) => contenidos.any((c) => c.idContenido == id))
      .length;

  static int get totalContenidos => contenidos.length;

  // ---------------------------------------------------------------------
  // Preferencias (PreferenciaUsuario)
  // ---------------------------------------------------------------------

  static Set<String> get categoriasPreferidas => Set<String>.of(_categoriasPreferidas);

  static bool get tienePreferencias => _categoriasPreferidas.isNotEmpty;

  static Future<void> guardarPreferencias(Set<String> idsCategorias) async {
    await EducativoService.guardarPreferencias(_tokenActual, idsCategorias);
    _categoriasPreferidas
      ..clear()
      ..addAll(idsCategorias);
  }

  static String get _tokenActual {
    final token = _token;
    if (token == null) throw StateError('EducativoRepository no se ha cargado.');
    return token;
  }
}
