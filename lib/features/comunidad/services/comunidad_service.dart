import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/publicacion_model.dart';

class ComunidadService {
  final String baseUrl = 'http://10.0.2.2:8000/api/bienestar';

  Future<List<Publicacion>> obtenerPublicaciones() async {
    final response = await http.get(Uri.parse('$baseUrl/publicaciones/'));

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((item) => Publicacion.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar las publicaciones');
    }
  }

  Future<bool> crearPublicacion(String contenido, File? imagen) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/publicaciones/'));

    // TODO: [PENDIENTE REGISTRO]
    // Cuando se implemente autenticación, adjuntar token en headers.
    request.fields['contenido'] = contenido;

    if (imagen != null) {
      request.files.add(await http.MultipartFile.fromPath('imagen', imagen.path));
    }

    var streamedResponse = await request.send();
    return streamedResponse.statusCode == 201;
  }
}
