import '../models/registro_ciclo.dart';

/// Semilla inicial de ciclos ya registrados, para que el calendario tenga
/// algo que mostrar antes de conectar el backend. RegistroCicloScreen toma
/// esta lista una sola vez al abrir y luego la crece en memoria con lo que
/// la usuaria vaya registrando durante la sesión.
class MockCicloData {
  MockCicloData._();

  static List<RegistroCiclo> seedInicial(String usuarioId) {
    final ahora = DateTime.now();
    final inicioAnterior = DateTime(ahora.year, ahora.month, ahora.day)
        .subtract(const Duration(days: 30));
    return [
      RegistroCiclo(
        id: 'ciclo_seed_1',
        usuarioId: usuarioId,
        fechaInicio: inicioAnterior,
        fechaFin: inicioAnterior.add(const Duration(days: 4)),
        abundancia: AbundanciaSangrado.moderada,
      ),
    ];
  }
}