/// Nombres de ruta del módulo Educativo, centralizados para que no haya
/// strings mágicos repetidos por las pantallas. Cuando se integre este
/// módulo al proyecto Flutter general de Florecer, este archivo se importa
/// desde el router principal (junto con comunidad_routes.dart,
/// seguimiento_routes.dart, etc.).
class EducativoRoutes {
  EducativoRoutes._();

  static const home = '/educativo';
  static const biblioteca = '/educativo/biblioteca';
  static const contenidoDetalle = '/educativo/biblioteca/detalle';
  static const ejercicios = '/educativo/ejercicios';
  static const ejercicioDetalle = '/educativo/ejercicios/detalle';
  static const rutas = '/educativo/rutas';
  static const rutaDetalle = '/educativo/rutas/detalle';

  /// Solo para la demo aislada del wireframe: simula el paso de preferencias
  /// del onboarding y, al terminar, entra a [home]. En la app real, este
  /// paso lo llama el flujo de onboarding del equipo (ver PreferenciasScreen).
  static const onboardingPreferencias = '/educativo/onboarding-preferencias';
}
