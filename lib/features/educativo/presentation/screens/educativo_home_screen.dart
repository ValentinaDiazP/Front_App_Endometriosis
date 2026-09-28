import 'package:flutter/material.dart';
import '../widgets/carga_educativo.dart';
import 'categorias_screen.dart';
import 'para_ti_screen.dart';
import 'ejercicios_screen.dart';
import 'rutas_screen.dart';

/// Pantalla contenedora del módulo Educativo.
///
/// Arquitectura de navegación: un TabBar interno con 4 pestañas
/// (Para ti, Biblioteca, Ejercicios, Rutas), colgado del ítem "Educativo" del
/// bottom navigation general de la app.
///
/// La pestaña "Biblioteca" arranca en [CategoriasScreen] (la puerta de
/// entrada por categorías) en vez de mostrar la lista de contenidos
/// directamente; desde ahí se navega a la lista filtrada.
///
/// [token] es el de la usuaria que inició sesión: con él se cargan desde
/// Django el catálogo, sus preferencias y su progreso.
class EducativoHomeScreen extends StatelessWidget {
  final String? token;

  const EducativoHomeScreen({super.key, this.token});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Educativo'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Para ti'),
              Tab(text: 'Biblioteca'),
              Tab(text: 'Ejercicios'),
              Tab(text: 'Rutas'),
            ],
          ),
        ),
        body: CargaEducativo(
          token: token,
          builder: (_) => const TabBarView(
            children: [
              ParaTiScreen(),
              CategoriasScreen(),
              EjerciciosScreen(),
              RutasScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
