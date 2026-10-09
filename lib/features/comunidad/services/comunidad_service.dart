import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/publicacion_model.dart';

class ComunidadService {
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/bienestar';
    }
    return 'http://127.0.0.1:8000/api/bienestar';
  }

  // Obtenemos solo publicaciones APROBADAS desde el backend
  Future<List<Publicacion>> obtenerPublicaciones({String? token}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/publicaciones/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((item) => Publicacion.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar las publicaciones');
    }
  }

  // Crear publicación con soporte para anonimato (se crea en estado APROBADO por defecto)
  Future<bool> crearPublicacion(
    String contenido, 
    File? imagen, {
    bool esAnonimo = false, 
    String? token
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/publicaciones/'));

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Token $token';
    }

    request.fields['contenido'] = contenido;
    request.fields['es_anonimo'] = esAnonimo.toString();

    if (imagen != null) {
      request.files.add(await http.MultipartFile.fromPath('imagen', imagen.path));
    }

    var streamedResponse = await request.send();
    return streamedResponse.statusCode == 201 || streamedResponse.statusCode == 200;
  }

  // 1. Dar o quitar Me Gusta
  Future<bool> reaccionar(int publicacionId, String? token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/publicaciones/$publicacionId/reaccionar/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Token $token',
      },
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // 2. Enviar Comentario
  Future<bool> comentar(int publicacionId, String texto, String? token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/publicaciones/$publicacionId/comentar/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Token $token',
      },
      body: jsonEncode({'texto': texto}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // 3. Reportar Publicación (Acepta HTTP 200 o 201)
  Future<bool> reportar(int publicacionId, String motivo, String? token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/publicaciones/$publicacionId/reportar/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Token $token',
      },
      body: jsonEncode({'motivo': motivo}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // 4. Reportar Comentario
  Future<bool> reportarComentario(int comentarioId, String motivo, String? token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/comentarios/$comentarioId/reportar/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Token $token',
      },
      body: jsonEncode({'motivo': motivo}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
