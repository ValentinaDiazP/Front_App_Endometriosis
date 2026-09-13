/// Nombres de ruta del módulo Seguimiento, centralizados para que no haya
/// strings mágicos repetidos por las pantallas. Cuando se integre este
/// módulo al proyecto Flutter general de Florecer, este archivo se importa
/// desde el router principal (junto con educativo_routes.dart,
/// bienestar_routes.dart, etc.).
class SeguimientoRoutes {
  SeguimientoRoutes._();

  static const home = '/seguimiento';
  static const informacionPersonal = '/seguimiento/informacion-personal';
  static const registroSintoma = '/seguimiento/registro';
}