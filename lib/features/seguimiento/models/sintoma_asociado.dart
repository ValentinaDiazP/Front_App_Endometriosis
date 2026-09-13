/// Síntoma asociado que la usuaria puede marcar junto con su dolor
/// (según el diagrama de base de datos: náuseas, distensión abdominal,
/// fatiga, etc.). Es una relación muchos-a-muchos con RegistroSintoma:
/// un registro puede tener varios síntomas asociados a la vez.
class SintomaAsociado {
  final String id;
  final String nombre;

  const SintomaAsociado({
    required this.id,
    required this.nombre,
  });

  factory SintomaAsociado.fromJson(Map<String, dynamic> json) {
    return SintomaAsociado(
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