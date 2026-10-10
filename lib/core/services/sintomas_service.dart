import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import '../../features/seguimiento/models/localizacion_dolor.dart';
import '../../features/seguimiento/models/registro_sintoma.dart';
import '../../features/seguimiento/models/sintoma_asociado.dart';
import '../../features/seguimiento/models/registro_emocional.dart';
import '../../features/seguimiento/models/progreso_gamificacion.dart';
import '../../features/seguimiento/models/registro_ciclo.dart';
import '../../features/seguimiento/models/historial_sintoma.dart';
/// Cliente HTTP para /api/sintomas/ (catálogos y registros de síntomas).
class SintomasService {
  SintomasService._();

  static String get _baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/sintomas';
    }
    return 'http://127.0.0.1:8000/api/sintomas';
  }

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      };

  static Future<List<LocalizacionDolor>> obtenerLocalizaciones(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/localizaciones-dolor/'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar las localizaciones.');
    }
    final lista = jsonDecode(response.body) as List<dynamic>;
    // El backend usa ids numéricos; el frontend los espera como String
    // (para que "otro"/"ninguno" convivan como ids especiales no numéricos).
    return lista
        .map((e) => LocalizacionDolor(
              id: (e['id'] as int).toString(),
              nombre: e['nombre'] as String,
            ))
        .toList();
  }

  static Future<List<SintomaAsociado>> obtenerSintomas(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/sintomas-asociados/'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los síntomas.');
    }
    final lista = jsonDecode(response.body) as List<dynamic>;
    return lista
        .map((e) => SintomaAsociado(
              id: (e['id'] as int).toString(),
              nombre: e['nombre'] as String,
            ))
        .toList();
  }

  static Future<void> guardarRegistro({
    required String token,
    required RegistroSintoma registro,
  }) async {
    // Solo se mandan los ids numéricos reales del catálogo; "Otro" y
    // "Ninguno" (ids no numéricos) se excluyen — "Otro" va aparte en
    // localizacion_otro_detalle, y "Ninguno" simplemente no manda nada.
    final idsLocalizaciones = registro.localizaciones
        .where((l) => !l.esOtro && !l.esNinguno)
        .map((l) => int.parse(l.id))
        .toList();

    final response = await http.post(
      Uri.parse('$_baseUrl/registros-sintoma/'),
      headers: _headers(token),
      body: jsonEncode({
        'intensidad_dolor': registro.intensidadDolor,
        'localizaciones': idsLocalizaciones,
        if (registro.localizacionOtroDetalle != null)
          'localizacion_otro_detalle': registro.localizacionOtroDetalle,
        'sintomas_asociados':
            registro.sintomasAsociados.map((s) => int.parse(s.id)).toList(),
        if (registro.observacion != null) 'observacion': registro.observacion,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('No se pudo guardar el registro. Intenta de nuevo.');
    }
  }

    static Future<RegistroEmocional?> obtenerCheckInHoy(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/registros-emocionales/hoy/'),
      headers: _headers(token),
    );
    if (response.statusCode == 204) return null; // No hay check-in hoy
    if (response.statusCode != 200) {
      throw Exception('No se pudo consultar el check-in de hoy.');
    }
    return RegistroEmocional.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<RegistroEmocional> guardarCheckIn({
    required String token,
    required int estadoAnimo,
    String? notaLibre,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/registros-emocionales/'),
      headers: _headers(token),
      body: jsonEncode({
        'estado_animo': estadoAnimo,
        if (notaLibre != null && notaLibre.trim().isNotEmpty)
          'nota_libre': notaLibre.trim(),
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('No se pudo guardar el check-in.');
    }
    return RegistroEmocional.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
     /// Todos los check-ins emocionales de la usuaria (para Reportes).
    static Future<List<RegistroEmocional>> obtenerCheckIns(String token) async {
      final response = await http.get(
        Uri.parse('$_baseUrl/registros-emocionales/'),
        headers: _headers(token),
      );
      if (response.statusCode != 200) {
        throw Exception('No se pudo cargar tu historial de ánimo.');
      }
      final lista = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      final registros = lista
          .map((e) => RegistroEmocional.fromJson(e as Map<String, dynamic>))
          .toList();
      registros.sort((a, b) => a.fecha.compareTo(b.fecha));
      return registros;
    }
      /// Todos los registros de síntomas de la usuaria, del más antiguo al más reciente.
    static Future<List<HistorialSintoma>> obtenerHistorialSintomas(String token) async {
      final response = await http.get(
        Uri.parse('$_baseUrl/registros-sintoma/'),
        headers: _headers(token),
      );
      if (response.statusCode != 200) {
        throw Exception('No se pudo cargar tu historial de síntomas.');
      }
      final lista = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      final registros = lista
          .map((e) => HistorialSintoma.fromJson(e as Map<String, dynamic>))
          .toList();
      registros.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
      return registros;
    }

    static Future<ProgresoGamificacion> obtenerProgreso(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/gamificacion/'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar tu progreso.');
    }
    return ProgresoGamificacion.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

    static String _fechaApi(DateTime fecha) =>
      fecha.toIso8601String().split('T').first;

  static Map<String, dynamic> _cuerpoCiclo(
    DateTime inicio,
    DateTime? fin,
    AbundanciaSangrado abundancia,
  ) =>
      {
        'fecha_inicio': _fechaApi(inicio),
        // null explícito: así editar un ciclo permite borrar la fecha de fin.
        'fecha_fin': fin == null ? null : _fechaApi(fin),
        'abundancia': abundancia.name,
      };

  static Future<List<RegistroCiclo>> obtenerCiclos(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/registros-ciclo/'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar tus ciclos.');
    }
    final lista = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return lista
        .map((e) => RegistroCiclo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> crearCiclo({
    required String token,
    required DateTime inicio,
    DateTime? fin,
    required AbundanciaSangrado abundancia,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/registros-ciclo/'),
      headers: _headers(token),
      body: jsonEncode(_cuerpoCiclo(inicio, fin, abundancia)),
    );
    if (response.statusCode != 201) {
      throw Exception('No se pudo guardar el ciclo. Intenta de nuevo.');
    }
  }

  static Future<void> actualizarCiclo({
    required String token,
    required String id,
    required DateTime inicio,
    DateTime? fin,
    required AbundanciaSangrado abundancia,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/registros-ciclo/$id/'),
      headers: _headers(token),
      body: jsonEncode(_cuerpoCiclo(inicio, fin, abundancia)),
    );
    if (response.statusCode != 200) {
      throw Exception('No se pudo actualizar el ciclo. Intenta de nuevo.');
    }
  }

  static Future<void> eliminarCiclo({
    required String token,
    required String id,
  }) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/registros-ciclo/$id/'),
      headers: _headers(token),
    );
    if (response.statusCode != 204) {
      throw Exception('No se pudo eliminar el ciclo. Intenta de nuevo.');
    }
  }
}