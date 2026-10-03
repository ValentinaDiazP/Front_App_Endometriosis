/// Nivel de abundancia del sangrado. Los nombres coinciden con los valores
/// que guarda el backend ('leve', 'moderada', 'abundante').
enum AbundanciaSangrado {
  leve,
  moderada,
  abundante;

  String get etiqueta {
    switch (this) {
      case AbundanciaSangrado.leve:
        return 'Leve';
      case AbundanciaSangrado.moderada:
        return 'Moderada';
      case AbundanciaSangrado.abundante:
        return 'Abundante';
    }
  }
}

/// Registro de un ciclo menstrual: fecha de inicio, fecha de fin (opcional,
/// porque el ciclo puede seguir en curso) y abundancia del sangrado.
class RegistroCiclo {
  final String id;
  final String? usuarioId;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final AbundanciaSangrado abundancia;

  const RegistroCiclo({
    required this.id,
    this.usuarioId,
    required this.fechaInicio,
    this.fechaFin,
    required this.abundancia,
  });

  /// Todas las fechas cubiertas por este ciclo (de inicio a fin, inclusive).
  /// Si sigue en curso (`fechaFin` es null), solo incluye el día de inicio.
  List<DateTime> get diasCubiertos {
    final fin = fechaFin ?? fechaInicio;
    final dias = <DateTime>[];
    var actual =
        DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
    final ultimo = DateTime(fin.year, fin.month, fin.day);
    while (!actual.isAfter(ultimo)) {
      dias.add(actual);
      actual = actual.add(const Duration(days: 1));
    }
    return dias;
  }

  /// El backend manda el id como número; aquí se guarda como String para
  /// no cambiar el resto del código que ya lo trata así.
  factory RegistroCiclo.fromJson(Map<String, dynamic> json) {
    return RegistroCiclo(
      id: json['id'].toString(),
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      fechaFin: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'] as String)
          : null,
      abundancia:
          AbundanciaSangrado.values.byName(json['abundancia'] as String),
    );
  }
}