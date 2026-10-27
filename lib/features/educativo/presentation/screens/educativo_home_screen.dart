import 'package:flutter/material.dart';
import '../../data/educativo_repository.dart';
import '../../models/progreso_aprendizaje.dart';
import '../widgets/aviso_recompensa.dart';
import '../widgets/carga_educativo.dart';
import 'categorias_screen.dart';
import 'para_ti_screen.dart';
import 'ejercicios_screen.dart';
import 'rutas_screen.dart';
import 'chatbot_screen.dart';
import 'mi_progreso_screen.dart';

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
class EducativoHomeScreen extends StatefulWidget {
  final String? token;

  const EducativoHomeScreen({super.key, this.token});

  @override
  State<EducativoHomeScreen> createState() => _EducativoHomeScreenState();
}

class _EducativoHomeScreenState extends State<EducativoHomeScreen> {
  String? get token => widget.token;

  @override
  void initState() {
    super.initState();
    // Aviso de puntos, rachas, niveles e insignias (motor de aprendizaje).
    EducativoRepository.alGanarRecompensa = _mostrarRecompensa;
  }

  @override
  void dispose() {
    if (EducativoRepository.alGanarRecompensa == _mostrarRecompensa) {
      EducativoRepository.alGanarRecompensa = null;
    }
    super.dispose();
  }

  void _mostrarRecompensa(ResultadoGamificacion recompensa) {
    // Pequeña espera para que la pantalla que guardó termine de cerrarse y
    // el aviso no quede tapado por su propio mensaje.
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) mostrarAvisoRecompensa(context, recompensa);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Educativo'),
          actions: [
            IconButton(
              icon: const Icon(Icons.emoji_events_outlined),
              tooltip: 'Mi progreso',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MiProgresoScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.support_agent),
              tooltip: 'Asistente Endometriosis',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatbotScreen(token: token),
                  ),
                );
              },
            ),
          ],
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
