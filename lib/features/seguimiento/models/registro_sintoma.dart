import 'localizacion_dolor.dart';
import 'sintoma_asociado.dart';

/// Registro diario de síntomas físicos: intensidad de dolor (escala 0-10),
/// zona corporal afectada y síntomas asociados (náuseas, fatiga, etc.),
/// más una observación libre opcional.
///
/// Corresponde a la tabla `RegistroSintoma` del diagrama de base de datos.
/// Aquí se guarda `fechaHora` como un solo DateTime por simplicidad en el
/// frontend; el backend lo separa en columnas `fecha` y `hora`.
class RegistroSintoma {
  final String id;
  final String usuarioId;
  final DateTime fechaHora;
  final int intensidadDolor; // Escala 0-10
  final LocalizacionDolor localizacion;
  final List<SintomaAsociado> sintomasAsociados;
  final String? observacion;

  const RegistroSintoma({
    required this.id,
    required this.usuarioId,
    required this.fechaHora,
    required this.intensidadDolor,
    required this.localizacion,
    required this.sintomasAsociados,
    this.observacion,
  }) : assert(
          intensidadDolor >= 0 && intensidadDolor <= 10,
          'La intensidad de dolor debe estar entre 0 y 10',
        );

  factory RegistroSintoma.fromJson(Map<String, dynamic> json) {
    return RegistroSintoma(
      id: json['id'] as String,
      usuarioId: json['usuarioId'] as String,
      fechaHora: DateTime.parse(json['fechaHora'] as String),
      intensidadDolor: json['intensidadDolor'] as int,
      localizacion: LocalizacionDolor.fromJson(
        json['localizacion'] as Map<String, dynamic>,
      ),
      sintomasAsociados: (json['sintomasAsociados'] as List<dynamic>)
          .map((e) => SintomaAsociado.fromJson(e as Map<String, dynamic>))
          .toList(),
      observacion: json['observacion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'fechaHora': fechaHora.toIso8601String(),
      'intensidadDolor': intensidadDolor,
      'localizacion': localizacion.toJson(),
      'sintomasAsociados': sintomasAsociados.map((s) => s.toJson()).toList(),
      'observacion': observacion,
    };
  }
}