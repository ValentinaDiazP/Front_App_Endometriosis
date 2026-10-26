/// Versión de solo lectura de un registro de síntomas, pensada para el
/// historial y el gráfico de Reportes. Usa los nombres reales que devuelve
/// la API (snake_case); el modelo RegistroSintoma sigue siendo el que se
/// usa para guardar.
class HistorialSintoma {
  final int id;
  final DateTime fechaHora;
  final int intensidadDolor; // Escala 0-10
  final List<String> localizaciones;
  final List<String> sintomasAsociados;
  final String? observacion;
  final String? otrosTiposDolor;
  final bool? tomoMedicacion;
  final String? medicacionDetalle;
  final String? alivioMedicacion; // nada | algo | mucho

  const HistorialSintoma({
    required this.id,
    required this.fechaHora,
    required this.intensidadDolor,
    required this.localizaciones,
    required this.sintomasAsociados,
    this.observacion,
    this.otrosTiposDolor,
    this.tomoMedicacion,
    this.medicacionDetalle,
    this.alivioMedicacion,
  });

  factory HistorialSintoma.fromJson(Map<String, dynamic> json) {
    final otro = json['localizacion_otro_detalle'] as String?;
    final zonas = (json['localizaciones_detalle'] as List<dynamic>)
        .map((e) => e['nombre'] as String)
        .toList();
    // Si escribió una zona en "Otro", se muestra junto a las del catálogo.
    if (otro != null && otro.trim().isNotEmpty) zonas.add(otro.trim());

    return HistorialSintoma(
      id: json['id'] as int,
      fechaHora: DateTime.parse(json['fecha_hora'] as String).toLocal(),
      intensidadDolor: json['intensidad_dolor'] as int,
      localizaciones: zonas,
      sintomasAsociados: (json['sintomas_asociados_detalle'] as List<dynamic>)
          .map((e) => e['nombre'] as String)
          .toList(),
      observacion: json['observacion'] as String?,
      otrosTiposDolor: json['otros_tipos_dolor'] as String?,
      tomoMedicacion: json['tomo_medicacion'] as bool?,
      medicacionDetalle: json['medicacion_detalle'] as String?,
      alivioMedicacion: json['alivio_medicacion'] as String?,
    );
  }
}