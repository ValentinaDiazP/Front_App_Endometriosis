import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/profesional.dart';
import '../models/disponibilidad_slot.dart';
import '../models/cita_medica.dart';
import '../models/producto.dart';

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

  static Future<List<DisponibilidadSlot>> obtenerDisponibilidad(int profesionalId, {String? token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/professionals/$profesionalId/disponibilidad/'),
      headers: _headers(token: token),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al consultar la disponibilidad del profesional');
    }
    final lista = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return lista
        .map((e) => DisponibilidadSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CitaMedica>> obtenerCitas({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profesionales/citas/'),
      headers: _headers(token: token),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al cargar las citas médicas');
    }
    final lista = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return lista
        .map((e) => CitaMedica.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<CitaMedica> crearCita({required Map<String, dynamic> data, required String token}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profesionales/citas/'),
      headers: _headers(token: token),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al agendar la cita médica');
    }
    return CitaMedica.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
  }

  static Future<CitaMedica> actualizarEstadoCita(int citaId, String nuevoEstado, {required String token}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/profesionales/citas/$citaId/'),
      headers: _headers(token: token),
      body: jsonEncode({'estado': nuevoEstado}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar el estado de la cita');
    }
    return CitaMedica.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
  }

  static Future<Map<String, dynamic>> obtenerReporteSalud(int citaId, {required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profesionales/citas/$citaId/reporte-salud/'),
      headers: _headers(token: token),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al obtener el reporte de salud');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
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

  // --- TIENDA VIRTUAL ---
  static Future<List<Producto>> obtenerProductos() async {
    final response = await http.get(Uri.parse('$baseUrl/productos/'));
    if (response.statusCode != 200) {
      throw Exception('Error al cargar la tienda de bienestar');
    }
    final lista = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return lista.map((e) => Producto.fromJson(e)).toList();
  }

  static Future<List<ItemCarrito>> obtenerCarrito({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/carrito/'),
      headers: _headers(token: token),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al cargar el carrito');
    }
    final lista = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return lista.map((e) => ItemCarrito.fromJson(e)).toList();
  }

  static Future<void> agregarAlCarrito({required int productoId, required int cantidad, required String token}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/carrito/'),
      headers: _headers(token: token),
      body: jsonEncode({'producto': productoId, 'cantidad': cantidad}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al agregar producto al carrito');
    }
  }

  static Future<void> eliminarItemCarrito({required int itemId, required String token}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/carrito/$itemId/'),
      headers: _headers(token: token),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar item del carrito');
    }
  }

  static Future<Map<String, dynamic>> confirmarCompra({required String token}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/compras/confirmar/'),
      headers: _headers(token: token),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Error al confirmar la compra');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}

