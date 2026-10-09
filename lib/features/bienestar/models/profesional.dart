class Profesional {
  final int id;
  final String nombre;
  final String especialidad;
  final String tarifa;
  final String disponibilidad;
  final String whatsapp;

  const Profesional({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.tarifa,
    required this.disponibilidad,
    required this.whatsapp,
  });

  bool get disponibleHoy {
    final texto = disponibilidad.toLowerCase();
    return texto.contains('hoy') || texto.contains('disponible');
  }

  String get etiquetaDisponibilidad {
    if (disponibilidad.trim().isEmpty) {
      return disponibleHoy ? 'Disponible hoy' : 'Próxima cita';
    }
    return disponibilidad;
  }

  factory Profesional.fromJson(Map<String, dynamic> json) {
    return Profesional(
      id: json['id'] as int,
      nombre: (json['name'] ?? json['nombre'] ?? 'Sin nombre') as String,
      especialidad: (json['specialty'] ?? json['especialidad'] ?? '') as String,
      tarifa: (json['rate'] ?? json['tarifa'] ?? '') as String,
      disponibilidad:
          (json['availability'] ?? json['disponibilidad'] ?? '') as String,
      whatsapp: (json['whatsapp'] ?? json['telefono'] ?? '') as String,
    );
  }
}
