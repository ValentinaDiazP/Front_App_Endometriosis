import 'package:flutter/material.dart';
import '../../models/informacion_personal.dart';
import 'registro_ciclo_screen.dart';
import 'registro_sintoma_screen.dart';

/// Pantalla contenedora del módulo de Seguimiento, con pestañas internas
/// (Síntomas, Ciclo). Mismo patrón que EducativoHomeScreen. Los colores del
/// TabBar se fijan explícitamente (blanco/blanco translúcido) porque el
/// tema global de la app no estiliza TabBar de forma confiable (main.dart
/// usa su propia paleta AppColors, no el AppTheme de core/theme).
class SeguimientoHomeScreen extends StatelessWidget {
  final InformacionPersonal informacionPersonal;

  const SeguimientoHomeScreen({super.key, required this.informacionPersonal});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Seguimiento'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Síntomas'),
              Tab(text: 'Ciclo'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RegistroSintomaScreen(informacionPersonal: informacionPersonal),
            RegistroCicloScreen(informacionPersonal: informacionPersonal),
          ],
        ),
      ),
    );
  }
}