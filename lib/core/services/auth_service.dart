import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class RegistroExitoso {
  final String token;
  final int usuarioId;
  final String username;
  const RegistroExitoso({required this.token, required this.usuarioId, required this.username});
}

class LoginExitoso {
  final String token;
  const LoginExitoso({required this.token});
}

/// Perfil completo de la usuaria autenticada, tal como lo devuelve
/// GET /api/usuarios/me/.
class PerfilUsuaria {
  final int usuarioId;
  final String username;
  final String nombre;
  final DateTime fechaNacimiento;
  final DateTime? fechaDiagnostico;
  final String? diagnostico;
  final int edad;
  final bool onboardingCompletado;

  const PerfilUsuaria({
    required this.usuarioId,
    required this.username,
    required this.nombre,
    required this.fechaNacimiento,
    this.fechaDiagnostico,
    this.diagnostico,
    required this.edad,
    required this.onboardingCompletado,
  });

  factory PerfilUsuaria.fromJson(Map<String, dynamic> json) {
    return PerfilUsuaria(
      usuarioId: json['usuario_id'] as int,
      username: json['username'] as String,
      nombre: json['nombre'] as String,
      fechaNacimiento: DateTime.parse(json['fecha_nacimiento'] as String),
      fechaDiagnostico: json['fecha_diagnostico'] != null
          ? DateTime.parse(json['fecha_diagnostico'] as String)
          : null,
      diagnostico: json['diagnostico'] as String?,
      edad: json['edad'] as int,
      onboardingCompletado: json['onboarding_completado'] as bool,
    );
  }
}

/// Cliente HTTP para /api/usuarios/ (registro, login, perfil, onboarding).
class AuthService {
  AuthService._();

    /// 127.0.0.1 funciona en Chrome (web) y en escritorio. 10.0.2.2 es el
  /// alias especial que usa un emulador Android para referirse a la propia
  /// máquina donde corre el backend — sin esto, la app fallaría al probar
  /// en emulador, igual que le pasa a Bienestar en Chrome por lo contrario.
  static String get _baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/usuarios';
    }
    return 'http://127.0.0.1:8000/api/usuarios';
  }

  static String _formatearFecha(DateTime fecha) =>
      fecha.toIso8601String().split('T').first;

  /// Extrae el primer mensaje de error de una respuesta de DRF, que puede
  /// venir como {"campo": ["mensaje"]} o como {"detail": "..."}.
  static String _extraerMensajeError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data.containsKey('detail')) return data['detail'].toString();
      final primerError = data.values.first;
      return primerError is List
          ? primerError.first.toString()
          : primerError.toString();
    } catch (_) {
      return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
  }

  static Future<RegistroExitoso> registrar({
    required String username,
    required String password,
    required String nombre,
    required DateTime fechaNacimiento,
    String? diagnostico,
    DateTime? fechaDiagnostico,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/registro/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'nombre': nombre,
        'fecha_nacimiento': _formatearFecha(fechaNacimiento),
        if (diagnostico != null && diagnostico.trim().isNotEmpty)
          'diagnostico': diagnostico.trim(),
        if (fechaDiagnostico != null)
          'fecha_diagnostico': _formatearFecha(fechaDiagnostico),
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return RegistroExitoso(
        token: data['token'] as String,
        usuarioId: data['usuario_id'] as int,
        username: data['username'] as String,
      );
    }
    throw Exception(_extraerMensajeError(response.body));
  }

  static Future<LoginExitoso> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return LoginExitoso(token: data['token'] as String);
    }
    throw Exception(_extraerMensajeError(response.body));
  }

  static Future<PerfilUsuaria> obtenerPerfil(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/me/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      return PerfilUsuaria.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(_extraerMensajeError(response.body));
  }

  static Future<void> completarOnboarding(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/completar-onboarding/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(_extraerMensajeError(response.body));
    }
  }
}