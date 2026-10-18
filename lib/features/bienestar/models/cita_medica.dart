class CitaMedica {
  final int id;
  final int? especialista;
  final String? especialistaNombre;
  final String nombreEspecialista;
  final String especialidad;
  final DateTime fechaHora;
  final String lugarOLink;
  final String estado; // PROGRAMADA, CONFIRMADA, COMPLETADA, CANCELADA
  final String notas;
  final bool puntosOtorgados;

  CitaMedica({
    required this.id,
    this.especialista,
    this.especialistaNombre,
    required this.nombreEspecialista,
    required this.especialidad,
    required this.fechaHora,
    required this.lugarOLink,
    required this.estado,
    required this.notas,
    required this.puntosOtorgados,
  });

  factory CitaMedica.fromJson(Map<String, dynamic> json) {
    return CitaMedica(
      id: json['id'] as int,
      especialista: json['especialista'] as int?,
      especialistaNombre: json['especialista_nombre'] as String?,
      nombreEspecialista: json['nombre_especialista'] as String? ?? '',
      especialidad: json['especialidad'] as String? ?? '',
      fechaHora: json['fecha_hora'] != null
          ? DateTime.parse(json['fecha_hora'])
          : DateTime.now(),
      lugarOLink: json['lugar_o_link'] as String? ?? '',
      estado: json['estado'] as String? ?? 'PROGRAMADA',
      notas: json['notas'] as String? ?? '',
      puntosOtorgados: json['puntos_otorgados'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (especialista != null) 'especialista': especialista,
      'nombre_especialista': nombreEspecialista,
      'especialidad': especialidad,
      'fecha_hora': fechaHora.toIso8601String(),
      'lugar_o_link': lugarOLink,
      'estado': estado,
      'notas': notas,
    };
  }
}
