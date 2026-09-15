import 'package:flutter/material.dart';
import 'categorias_screen.dart';
import 'ejercicios_screen.dart';
import 'rutas_screen.dart';

/// Pantalla contenedora del módulo Educativo.
///
/// Arquitectura de navegación: un TabBar interno con 3 pestañas
/// (Biblioteca, Ejercicios, Rutas), colgado del ítem "Educativo" del
/// bottom navigation general de la app.
///
/// La pestaña "Biblioteca" arranca en [CategoriasScreen] (la puerta de
/// entrada por categorías) en vez de mostrar la lista de contenidos
/// directamente; desde ahí se navega a la lista filtrada.
class EducativoHomeScreen extends StatelessWidget {
  const EducativoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Educativo'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Biblioteca'),
              Tab(text: 'Ejercicios'),
              Tab(text: 'Rutas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CategoriasScreen(),
            EjerciciosScreen(),
            RutasScreen(),
          ],
        ),
      ),
    );
  }
}
