class DisponibilidadSlot {
  final int id;
  final String diaSemana;
  final String horaInicio;
  final String horaFin;

  DisponibilidadSlot({
    required this.id,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
  });

  factory DisponibilidadSlot.fromJson(Map<String, dynamic> json) {
    return DisponibilidadSlot(
      id: json['id'] as int,
      diaSemana: json['dia_semana'] as String? ?? '',
      horaInicio: json['hora_inicio'] as String? ?? '',
      horaFin: json['hora_fin'] as String? ?? '',
    );
  }
}
