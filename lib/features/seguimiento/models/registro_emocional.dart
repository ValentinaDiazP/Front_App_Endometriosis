/// Check-in emocional diario: un registro por usuaria y día (el backend
/// actualiza en vez de duplicar si ya existe uno para hoy).
///
/// Solo `estadoAnimo` es obligatorio; los demás campos del check-in
/// ampliado (energía, sueño, descanso, estrés, capacidad del día) son
/// opcionales y llegan null si la usuaria no los respondió.
class RegistroEmocional {
  final int id;
  final DateTime fecha;
  final int estadoAnimo; // Escala 1-5
  final String? notaLibre;
  final int? energia; // 1-5
  final int? horasSueno; // 0-24
  final int? descanso; // 1-5
  final int? estres; // 1-5
  final String? capacidadDia; // todo | casi_todo | poco | no_pude

  const RegistroEmocional({
    required this.id,
    required this.fecha,
    required this.estadoAnimo,
    this.notaLibre,
    this.energia,
    this.horasSueno,
    this.descanso,
    this.estres,
    this.capacidadDia,
  });

  static const List<String> emojis = ['😣', '😔', '😐', '🙂', '😊'];
  static const List<String> etiquetas = [
    'Muy bajo',
    'Bajo',
    'Estable',
    'Bueno',
    'Muy bueno',
  ];

  /// Clave que usa la API -> texto que ve la usuaria.
  static const Map<String, String> capacidades = {
    'todo': 'Todo',
    'casi_todo': 'Casi todo',
    'poco': 'Poco',
    'no_pude': 'No pude',
  };

  String get emoji => emojis[estadoAnimo - 1];
  String get etiqueta => etiquetas[estadoAnimo - 1];
  String? get capacidadEtiqueta => capacidades[capacidadDia];

  factory RegistroEmocional.fromJson(Map<String, dynamic> json) {
    return RegistroEmocional(
      id: json['id'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      estadoAnimo: json['estado_animo'] as int,
      notaLibre: json['nota_libre'] as String?,
      energia: json['energia'] as int?,
      horasSueno: json['horas_sueno'] as int?,
      descanso: json['descanso'] as int?,
      estres: json['estres'] as int?,
      capacidadDia: json['capacidad_dia'] as String?,
    );
  }
}