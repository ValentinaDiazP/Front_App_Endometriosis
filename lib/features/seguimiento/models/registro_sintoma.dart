import 'localizacion_dolor.dart';
import 'sintoma_asociado.dart';

/// Registro diario de síntomas físicos: intensidad de dolor (escala 0-10),
/// una o varias zonas corporales afectadas, síntomas asociados, y una
/// observación libre opcional.
///
/// Corresponde a la tabla `RegistroSintoma` del diagrama de base de datos.
/// `localizaciones` es una lista (no un solo valor) porque el dolor puede
/// presentarse en varias zonas a la vez. `localizacionOtroDetalle` solo
/// tiene valor cuando `localizaciones` incluye la opción "Otro".
///
/// Los campos de "otros tipos de dolor" y medicación son opcionales y solo
/// se llenan cuando hubo dolor. La app solo ANOTA lo que la usuaria tomó;
/// nunca recomienda medicamentos ni dosis.
class RegistroSintoma {
  final String id;
  final String usuarioId;
  final DateTime fechaHora;
  final int intensidadDolor; // Escala 0-10
  final List<LocalizacionDolor> localizaciones;
  final String? localizacionOtroDetalle;
  final List<SintomaAsociado> sintomasAsociados;
  final String? observacion;
  final String? otrosTiposDolor;
  final bool? tomoMedicacion; // null = no respondió
  final String? medicacionDetalle;
  final String? alivioMedicacion; // nada | algo | mucho

  const RegistroSintoma({
    required this.id,
    required this.usuarioId,
    required this.fechaHora,
    required this.intensidadDolor,
    required this.localizaciones,
    this.localizacionOtroDetalle,
    required this.sintomasAsociados,
    this.observacion,
    this.otrosTiposDolor,
    this.tomoMedicacion,
    this.medicacionDetalle,
    this.alivioMedicacion,
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
      localizaciones: (json['localizaciones'] as List<dynamic>)
          .map((e) => LocalizacionDolor.fromJson(e as Map<String, dynamic>))
          .toList(),
      localizacionOtroDetalle: json['localizacionOtroDetalle'] as String?,
      sintomasAsociados: (json['sintomasAsociados'] as List<dynamic>)
          .map((e) => SintomaAsociado.fromJson(e as Map<String, dynamic>))
          .toList(),
      observacion: json['observacion'] as String?,
      otrosTiposDolor: json['otrosTiposDolor'] as String?,
      tomoMedicacion: json['tomoMedicacion'] as bool?,
      medicacionDetalle: json['medicacionDetalle'] as String?,
      alivioMedicacion: json['alivioMedicacion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'fechaHora': fechaHora.toIso8601String(),
      'intensidadDolor': intensidadDolor,
      'localizaciones': localizaciones.map((l) => l.toJson()).toList(),
      'localizacionOtroDetalle': localizacionOtroDetalle,
      'sintomasAsociados': sintomasAsociados.map((s) => s.toJson()).toList(),
      'observacion': observacion,
      'otrosTiposDolor': otrosTiposDolor,
      'tomoMedicacion': tomoMedicacion,
      'medicacionDetalle': medicacionDetalle,
      'alivioMedicacion': alivioMedicacion,
    };
  }
}