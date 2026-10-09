import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/sintomas_service.dart';
import '../../models/informacion_personal.dart';
import '../../models/progreso_gamificacion.dart';

class PerfilScreen extends StatefulWidget {
  final InformacionPersonal informacionPersonal;
  final String token;

  const PerfilScreen({
    super.key,
    required this.informacionPersonal,
    required this.token,
  });

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  PerfilUsuaria? _perfil;
  ProgresoGamificacion? _progreso;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resultados = await Future.wait([
        AuthService.obtenerPerfil(widget.token),
        SintomasService.obtenerProgreso(widget.token),
      ]);
      if (!mounted) return;
      setState(() {
        _perfil = resultados[0] as PerfilUsuaria;
        _progreso = resultados[1] as ProgresoGamificacion;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final perfil = _perfil;
    final progreso = _progreso;
    final nombre = perfil?.nombre.isNotEmpty == true
        ? perfil!.nombre
        : widget.informacionPersonal.nombre;
    final username = perfil?.username ?? '';

    return RefreshIndicator(
      onRefresh: _cargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Cabecera de Usuaria
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (username.isNotEmpty)
                        Text(
                          '@$username',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Tarjeta Principal de Nivel y Progreso
            if (progreso != null) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🌱', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  progreso.nivel?.nombre ?? 'Nivel Semilla',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${progreso.puntosTotales} puntos totales',
                                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progreso.fraccionHaciaSiguiente,
                          minHeight: 10,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        progreso.siguienteNivel != null
                            ? 'Te faltan ${progreso.siguienteNivel!.puntosMinimos - progreso.puntosTotales} puntos para ${progreso.siguienteNivel!.nombre}'
                            : '¡Has alcanzado el nivel máximo!',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Tarjeta de Rachas
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 8),
                            const Text('Racha actual', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '${progreso.rachaActual} días',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('🏆', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 8),
                            const Text('Mejor racha', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '${progreso.rachaMaxima} días',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Sección 'Historial de Puntos'
              const Text(
                'Historial de puntos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              progreso.historial.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Aún no tienes movimientos de puntos registrados.'),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: progreso.historial.length,
                      itemBuilder: (context, index) {
                        final item = progreso.historial[index];
                        final fechaStr = '${item.fecha.day}/${item.fecha.month}/${item.fecha.year}';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: item.puntos >= 0 ? Colors.green[100] : Colors.red[100],
                              child: Text(
                                item.puntos >= 0 ? '+${item.puntos}' : '${item.puntos}',
                                style: TextStyle(
                                  color: item.puntos >= 0 ? Colors.green[800] : Colors.red[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(item.motivo, style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text(fechaStr, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 24),
            ],

            // 5. Tarjeta Guía '¿Cómo ganar puntos y su propósito?'
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Cómo ganar puntos?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildGuiaItem(
                      icon: '📝',
                      titulo: 'Registrar síntoma/ánimo (+5 pts)',
                      proposito: 'Detecta patrones para tu especialista.',
                    ),
                    const Divider(height: 24),
                    _buildGuiaItem(
                      icon: '✍️',
                      titulo: 'Crear publicación (+10 pts)',
                      proposito: 'Visibiliza y comparte tu experiencia.',
                    ),
                    const Divider(height: 24),
                    _buildGuiaItem(
                      icon: '💬',
                      titulo: 'Comentar o apoyar (+5 pts)',
                      proposito: 'Brinda contención a la comunidad.',
                    ),
                    const Divider(height: 24),
                    _buildGuiaItem(
                      icon: '📚',
                      titulo: 'Completar lección (+10 pts)',
                      proposito: 'Empodera tu salud con conocimiento.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuiaItem({required String icon, required String titulo, required String proposito}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                proposito,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
