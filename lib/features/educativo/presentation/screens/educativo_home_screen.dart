import 'package:flutter/material.dart';
import 'biblioteca_screen.dart';
import 'ejercicios_screen.dart';
import 'rutas_screen.dart';

/// Pantalla contenedora del módulo Educativo.
///
/// Arquitectura de navegación elegida: un TabBar interno con 3 pestañas
/// (Biblioteca, Ejercicios, Rutas), en vez de 3 pantallas sueltas en el
/// bottom nav principal de la app. Esto porque las 3 secciones comparten
/// el mismo "tema" (contenido educativo) y una usuaria normalmente entra
/// una vez al módulo y explora las tres cosas en la misma sesión.
///
/// Este contenedor es el que se cuelga del ítem "Educativo" del bottom
/// navigation general de la app (junto a Comunidad, Seguimiento, etc.).
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
            tabs: [
              Tab(text: 'Biblioteca'),
              Tab(text: 'Ejercicios'),
              Tab(text: 'Rutas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BibliotecaScreen(),
            EjerciciosScreen(),
            RutasScreen(),
          ],
        ),
      ),
    );
  }
}
