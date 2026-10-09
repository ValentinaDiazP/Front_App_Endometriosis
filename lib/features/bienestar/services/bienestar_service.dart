import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/profesional.dart';

class BienestarService {
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/bienestar';
    }
    return 'http://127.0.0.1:8000/api/bienestar';
  }

  static Map<String, String> _headers({String? token, bool json = true}) {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  static Future<List<Profesional>> obtenerProfesionales({String? token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/professionals/'),
      headers: _headers(token: token),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al conectar con la API de profesionales');
    }
    final lista = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return lista
        .map((e) => Profesional.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<bool> registrarSolicitudContacto({
    required int profesionalId,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/solicitudes-contacto/'),
      headers: _headers(token: token),
      body: jsonEncode({'profesional': profesionalId}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
