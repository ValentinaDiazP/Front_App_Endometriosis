import '../models/localizacion_dolor.dart';
import '../models/sintoma_asociado.dart';

/// Datos de prueba (mock) para el módulo de Seguimiento, mientras no hay
/// backend conectado. Centralizarlos aquí evita listas "hardcodeadas"
/// repetidas dentro de las pantallas.
///
/// Cuando se conecte el backend, estas listas se reemplazan por llamadas
/// reales a la API (por ejemplo GET /localizaciones y GET /sintomas), sin
/// tener que tocar las pantallas que las consumen.
class MockSeguimientoData {
  MockSeguimientoData._();

  static const List<LocalizacionDolor> localizaciones = [
    LocalizacionDolor(id: 'loc_1', nombre: 'Abdomen bajo'),
    LocalizacionDolor(id: 'loc_2', nombre: 'Espalda baja'),
    LocalizacionDolor(id: 'loc_3', nombre: 'Pelvis'),
    LocalizacionDolor(id: 'loc_4', nombre: 'Piernas'),
    LocalizacionDolor(id: 'loc_5', nombre: 'Cabeza'),
    LocalizacionDolor(id: LocalizacionDolor.idOtro, nombre: 'Otro'),
    LocalizacionDolor(id: LocalizacionDolor.idNinguno, nombre: 'Ninguno'),
  ];

  static const List<SintomaAsociado> sintomas = [
    SintomaAsociado(id: 'sint_1', nombre: 'Náuseas'),
    SintomaAsociado(id: 'sint_2', nombre: 'Distensión abdominal'),
    SintomaAsociado(id: 'sint_3', nombre: 'Fatiga'),
    SintomaAsociado(id: 'sint_4', nombre: 'Mareo'),
  ];
}