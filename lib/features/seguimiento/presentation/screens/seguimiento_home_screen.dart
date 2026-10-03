import 'package:flutter/material.dart';
import '../../models/informacion_personal.dart';
import 'progreso_screen.dart';
import 'registro_ciclo_screen.dart';
import 'registro_emocional_screen.dart';
import 'registro_sintoma_screen.dart';

class SeguimientoHomeScreen extends StatefulWidget {
  final InformacionPersonal informacionPersonal;
  final String token;

  const SeguimientoHomeScreen({
    super.key,
    required this.informacionPersonal,
    required this.token,
  });

  @override
  State<SeguimientoHomeScreen> createState() => _SeguimientoHomeScreenState();
}

class _SeguimientoHomeScreenState extends State<SeguimientoHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _ultimoIndice = 0;

  /// Cambiar esta llave fuerza a ProgresoScreen a reconstruirse (y volver a
  /// pedir sus datos) cada vez que la usuaria entra a la pestaña.
  int _refrescoProgreso = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      final indice = _tabController.index;
      if (indice == 3 && _ultimoIndice != 3) {
        setState(() => _refrescoProgreso++);
      }
      _ultimoIndice = indice;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Síntomas'),
            Tab(text: 'Ciclo'),
            Tab(text: 'Ánimo'),
            Tab(text: 'Progreso'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RegistroSintomaScreen(
            informacionPersonal: widget.informacionPersonal,
            token: widget.token,
          ),
                    RegistroCicloScreen(token: widget.token),
          RegistroEmocionalScreen(token: widget.token),
          ProgresoScreen(
            key: ValueKey(_refrescoProgreso),
            token: widget.token,
          ),
        ],
      ),
    );
  }
}