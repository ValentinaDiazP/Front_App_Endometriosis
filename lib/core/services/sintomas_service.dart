import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import '../../features/seguimiento/models/localizacion_dolor.dart';
import '../../features/seguimiento/models/registro_sintoma.dart';
import '../../features/seguimiento/models/sintoma_asociado.dart';

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
}