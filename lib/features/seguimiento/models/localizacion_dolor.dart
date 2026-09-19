/// Zona corporal donde la usuaria puede registrar dolor (mapa corporal o
/// lista de zonas, según el diagrama de base de datos de Seguimiento).
///
/// Por ahora se alimenta de datos mock (mock_seguimiento_data.dart); cuando
/// se conecte el backend, `fromJson`/`toJson` ya quedan listos para no tener
/// que tocar las pantallas que consumen este modelo.
class LocalizacionDolor {
  final String id;
  final String nombre;

  const LocalizacionDolor({
    required this.id,
    required this.nombre,
  });

  /// IDs especiales reconocidos por RegistroSintomaScreen para aplicar
  /// reglas particulares de selección: "Otro" habilita un campo de texto
  /// libre, y "Ninguno" es mutuamente excluyente con cualquier otra zona.
  static const String idOtro = 'loc_otro';
  static const String idNinguno = 'loc_ninguno';

  bool get esOtro => id == idOtro;
  bool get esNinguno => id == idNinguno;

  factory LocalizacionDolor.fromJson(Map<String, dynamic> json) {
    return LocalizacionDolor(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}