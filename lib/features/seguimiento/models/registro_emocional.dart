/// Check-in emocional diario: un registro por usuaria y día (el backend
/// actualiza en vez de duplicar si ya existe uno para hoy).
class RegistroEmocional {
  final int id;
  final DateTime fecha;
  final int estadoAnimo; // Escala 1-5
  final String? notaLibre;

  const RegistroEmocional({
    required this.id,
    required this.fecha,
    required this.estadoAnimo,
    this.notaLibre,
  });

  static const List<String> emojis = ['😣', '😔', '😐', '🙂', '😊'];
  static const List<String> etiquetas = [
    'Muy bajo',
    'Bajo',
    'Estable',
    'Bueno',
    'Muy bueno',
  ];

  String get emoji => emojis[estadoAnimo - 1];
  String get etiqueta => etiquetas[estadoAnimo - 1];

  factory RegistroEmocional.fromJson(Map<String, dynamic> json) {
    return RegistroEmocional(
      id: json['id'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      estadoAnimo: json['estado_animo'] as int,
      notaLibre: json['nota_libre'] as String?,
    );
  }
}