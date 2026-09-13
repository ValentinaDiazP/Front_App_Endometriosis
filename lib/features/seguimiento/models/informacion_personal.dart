/// Datos personales relevantes para el módulo de Seguimiento: nombre,
/// fecha de nacimiento y fecha de diagnóstico de endometriosis.
///
/// Corresponde a un subconjunto de la tabla `Usuario` del diagrama de base
/// de datos (se excluyen correo y contraseña, que pertenecen al módulo de
/// autenticación general de la app, no a Seguimiento).
///
/// `fechaDiagnostico` es opcional porque una usuaria puede estar en proceso
/// de diagnóstico y aún no tener una fecha confirmada.
class InformacionPersonal {
  final String usuarioId;
  final String nombre;
  final DateTime fechaNacimiento;
  final DateTime? fechaDiagnostico;

  const InformacionPersonal({
    required this.usuarioId,
    required this.nombre,
    required this.fechaNacimiento,
    this.fechaDiagnostico,
  });

  factory InformacionPersonal.fromJson(Map<String, dynamic> json) {
    return InformacionPersonal(
      usuarioId: json['usuarioId'] as String,
      nombre: json['nombre'] as String,
      fechaNacimiento: DateTime.parse(json['fechaNacimiento'] as String),
      fechaDiagnostico: json['fechaDiagnostico'] != null
          ? DateTime.parse(json['fechaDiagnostico'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuarioId': usuarioId,
      'nombre': nombre,
      'fechaNacimiento': fechaNacimiento.toIso8601String(),
      'fechaDiagnostico': fechaDiagnostico?.toIso8601String(),
    };
  }
}