import 'package:flutter/material.dart';
import '../../features/educativo/educativo_routes.dart';
import '../../features/educativo/models/contenido_educativo.dart';
import '../../features/educativo/models/ejercicio_psicoeducativo.dart';
import '../../features/educativo/models/ruta_aprendizaje.dart';
import '../../features/educativo/presentation/screens/educativo_home_screen.dart';
import '../../features/educativo/presentation/screens/contenido_detail_screen.dart';
import '../../features/educativo/presentation/screens/ejercicio_detail_screen.dart';
import '../../features/educativo/presentation/screens/ruta_detail_screen.dart';
import '../../features/seguimiento/seguimiento_routes.dart';
import '../../features/seguimiento/presentation/screens/registro_sintoma_screen.dart';
import '../../features/seguimiento/models/informacion_personal.dart';
/// Router centralizado por `onGenerateRoute`. Es deliberadamente simple
/// (sin paquetes externos como go_router) para que sea fácil de fusionar con
/// el router del proyecto completo más adelante; si el equipo decide usar
/// go_router para toda la app, esta misma tabla de rutas se traduce 1 a 1
/// a GoRoute(...).
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case EducativoRoutes.home:
        return _page(const EducativoHomeScreen());

      case EducativoRoutes.contenidoDetalle:
        final contenido = settings.arguments as ContenidoEducativo;
        return _page(ContenidoDetailScreen(contenido: contenido));

      case EducativoRoutes.ejercicioDetalle:
        final ejercicio = settings.arguments as EjercicioPsicoeducativo;
        return _page(EjercicioDetailScreen(ejercicio: ejercicio));

      case EducativoRoutes.rutaDetalle:
        final ruta = settings.arguments as RutaAprendizaje;
        return _page(RutaDetailScreen(ruta: ruta));
        
      case SeguimientoRoutes.registroSintoma:
        final informacionPersonal = settings.arguments as InformacionPersonal;
        return _page(RegistroSintomaScreen(informacionPersonal: informacionPersonal));

      default:
        return _page(
          Scaffold(
            appBar: AppBar(title: const Text('Página no encontrada')),
            body: Center(child: Text('Ruta desconocida: ${settings.name}')),
          ),
        );
    }
  }

  static MaterialPageRoute _page(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }
}
