import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import '../models/categoria_contenido.dart';
import '../models/contenido_educativo.dart';
import '../models/ejercicio_psicoeducativo.dart';
import '../models/ruta_aprendizaje.dart';

/// Todo lo que el módulo necesita al entrar: catálogo + datos de la usuaria.
class DatosEducativos {
  final List<CategoriaContenido> categorias;
  final List<ContenidoEducativo> contenidos;
  final List<EjercicioPsicoeducativo> ejercicios;
  final List<RutaAprendizaje> rutas;
  final Set<String> categoriasPreferidas;
  final Set<String> contenidosCompletados;
  final Set<String> ejerciciosCompletados;

  const DatosEducativos({
    required this.categorias,
    required this.contenidos,
    required this.ejercicios,
    required this.rutas,
    required this.categoriasPreferidas,
    required this.contenidosCompletados,
    required this.ejerciciosCompletados,
  });
}

/// Cliente HTTP para /api/educativo/.
class EducativoService {
  EducativoService._();

  static String get _baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/educativo';
    }
    return 'http://127.0.0.1:8000/api/educativo';
  }

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      };

  static Future<dynamic> _get(String token, String ruta) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/$ruta'), headers: _headers(token))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el contenido educativo (${response.statusCode}).');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  // ---------------------------------------------------------------------
  // Lectura
  // ---------------------------------------------------------------------

  static Future<DatosEducativos> cargarTodo(String token) async {
    final respuestas = await Future.wait([
      _get(token, 'categorias/'),
      _get(token, 'contenidos/'),
      _get(token, 'ejercicios/'),
      _get(token, 'rutas/'),
      _get(token, 'preferencias/'),
      _get(token, 'interacciones-contenido/'),
      _get(token, 'registros-ejercicio/'),
    ]);

    final interacciones = respuestas[5] as List<dynamic>;
    final registros = respuestas[6] as List<dynamic>;

    return DatosEducativos(
      categorias: (respuestas[0] as List<dynamic>).map(_categoria).toList(),
      contenidos: (respuestas[1] as List<dynamic>).map(_contenido).toList(),
      ejercicios: (respuestas[2] as List<dynamic>).map(_ejercicio).toList(),
      rutas: (respuestas[3] as List<dynamic>).map(_ruta).toList(),
      categoriasPreferidas:
          ((respuestas[4] as Map<String, dynamic>)['categorias'] as List<dynamic>)
              .cast<String>()
              .toSet(),
      contenidosCompletados: interacciones
          .where((i) => i['completado'] == true)
          .map((i) => i['contenido'] as String)
          .toSet(),
      ejerciciosCompletados: registros.map((r) => r['ejercicio'] as String).toSet(),
    );
  }

  // ---------------------------------------------------------------------
  // Escritura
  // ---------------------------------------------------------------------

  static Future<void> guardarPreferencias(String token, Set<String> idsCategorias) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/preferencias/'),
          headers: _headers(token),
          body: jsonEncode({'categorias': idsCategorias.toList()}),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('No se pudieron guardar tus preferencias. Intenta de nuevo.');
    }
  }

  static Future<void> marcarContenidoCompletado(String token, String idContenido) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/interacciones-contenido/'),
          headers: _headers(token),
          body: jsonEncode({'contenido': idContenido, 'completado': true}),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('No se pudo guardar tu progreso. Intenta de nuevo.');
    }
  }

  static Future<void> registrarEjercicio(String token, String idEjercicio) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/registros-ejercicio/'),
          headers: _headers(token),
          body: jsonEncode({'ejercicio': idEjercicio}),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 201) {
      throw Exception('No se pudo guardar el ejercicio. Intenta de nuevo.');
    }
  }

  // ---------------------------------------------------------------------
  // JSON -> modelos. Los valores de `tipo` y `nivel` que manda Django son
  // exactamente los nombres de los enums de Dart.
  // ---------------------------------------------------------------------

  static CategoriaContenido _categoria(dynamic j) => CategoriaContenido(
        idCategoria: j['id'] as String,
        nombre: j['nombre'] as String,
        descripcion: j['descripcion'] as String,
      );

  static ContenidoEducativo _contenido(dynamic j) => ContenidoEducativo(
        idContenido: j['id'] as String,
        idCategoriaFK: j['categoria'] as String,
        titulo: j['titulo'] as String,
        tipo: TipoContenido.values.byName(j['tipo'] as String),
        nivel: NivelContenido.values.byName(j['nivel'] as String),
        esPremium: j['es_premium'] as bool,
        fechaPublicacion: DateTime.parse(j['fecha_publicacion'] as String),
        resumen: j['resumen'] as String,
        cuerpo: j['cuerpo'] as String,
        minutosEstimados: j['minutos_estimados'] as int,
      );

  static EjercicioPsicoeducativo _ejercicio(dynamic j) => EjercicioPsicoeducativo(
        idEjercicio: j['id'] as String,
        nombre: j['nombre'] as String,
        tipo: TipoEjercicio.values.byName(j['tipo'] as String),
        descripcion: j['descripcion'] as String,
        instrucciones: j['instrucciones'] as String,
        minutosEstimados: j['minutos_estimados'] as int,
      );

  static RutaAprendizaje _ruta(dynamic j) => RutaAprendizaje(
        idRuta: j['id'] as String,
        nombre: j['nombre'] as String,
        descripcion: j['descripcion'] as String,
        contenidos: (j['contenidos'] as List<dynamic>).map(_contenido).toList(),
      );
}
