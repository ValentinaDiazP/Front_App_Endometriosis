import 'package:flutter/material.dart';
import '../../models/informacion_personal.dart';
import 'registro_ciclo_screen.dart';
import 'registro_emocional_screen.dart';
import 'registro_sintoma_screen.dart';

class SeguimientoHomeScreen extends StatelessWidget {
  final InformacionPersonal informacionPersonal;
  final String token;

  const SeguimientoHomeScreen({
    super.key,
    required this.informacionPersonal,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
              Tab(text: 'Ánimo'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RegistroSintomaScreen(
              informacionPersonal: informacionPersonal,
              token: token,
            ),
            RegistroCicloScreen(token: token),
            RegistroEmocionalScreen(token: token),
          ],
        ),
      ),
    );
  }
}