/// Nivel de abundancia del sangrado registrado, según el campo
/// `abundancia` de la tabla `RegistroCiclo` del diagrama de base de datos.
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
  final String usuarioId;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final AbundanciaSangrado abundancia;

  const RegistroCiclo({
    required this.id,
    required this.usuarioId,
    required this.fechaInicio,
    this.fechaFin,
    required this.abundancia,
  });

  /// Todas las fechas cubiertas por este ciclo (de inicio a fin, inclusive).
  /// Si sigue en curso (`fechaFin` es null), solo incluye el día de inicio.
  /// Se usa para pintar el calendario día por día.
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

  factory RegistroCiclo.fromJson(Map<String, dynamic> json) {
    return RegistroCiclo(
      id: json['id'] as String,
      usuarioId: json['usuarioId'] as String,
      fechaInicio: DateTime.parse(json['fechaInicio'] as String),
      fechaFin: json['fechaFin'] != null
          ? DateTime.parse(json['fechaFin'] as String)
          : null,
      abundancia:
          AbundanciaSangrado.values.byName(json['abundancia'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin?.toIso8601String(),
      'abundancia': abundancia.name,
    };
  }
}