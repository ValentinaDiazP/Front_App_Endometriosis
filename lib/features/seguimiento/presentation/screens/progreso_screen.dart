import 'package:flutter/material.dart';
import '../../../../core/services/sintomas_service.dart';
import '../../models/progreso_gamificacion.dart';

/// Pestaña "Progreso": nivel, puntos, racha e historial de puntos de la
/// usuaria. Los datos vienen del backend; las reglas de puntos y los
/// umbrales de nivel se configuran desde el panel /admin/ de Django.
class ProgresoScreen extends StatefulWidget {
  final String token;

  const ProgresoScreen({super.key, required this.token});

  @override
  State<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _ProgresoScreenState extends State<ProgresoScreen> {
  ProgresoGamificacion? _progreso;
  bool _cargando = true;
  String? _error;

  static const Map<String, String> _emojiPorNivel = {
    'Semilla': '🌱',
    'Brote': '🌿',
    'Capullo': '🌷',
    'Flor': '🌸',
    'Jardin': '🌺',
  };

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
      final progreso = await SintomasService.obtenerProgreso(widget.token);
      if (!mounted) return;
      setState(() {
        _progreso = progreso;
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

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _progreso == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'No se pudo cargar tu progreso.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final progreso = _progreso!;
    final colorPrimario = Theme.of(context).colorScheme.primary;
    final nombreNivel = progreso.nivel?.nombre ?? 'Semilla';
    final emoji = _emojiPorNivel[nombreNivel] ?? '🌱';
    final siguiente = progreso.siguienteNivel;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    'Nivel $nombreNivel',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${progreso.puntosTotales} puntos',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorPrimario,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progreso.fraccionHaciaSiguiente,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    siguiente == null
                        ? '¡Llegaste al nivel más alto!'
                        : 'Te faltan ${siguiente.puntosMinimos - progreso.puntosTotales} '
                            'puntos para ${siguiente.nombre}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _datoRacha(
                    context,
                    '🔥',
                    '${progreso.rachaActual}',
                    progreso.rachaActual == 1 ? 'día seguido' : 'días seguidos',
                  ),
                  _datoRacha(
                    context,
                    '🏆',
                    '${progreso.rachaMaxima}',
                    'mejor racha',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Historial de puntos',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (progreso.historial.isEmpty)
            const Text(
              'Aún no tienes movimientos. Registra tus síntomas, tu ciclo o '
              'tu ánimo para empezar a ganar puntos.',
            )
          else
            ...progreso.historial.map(
              (m) => Card(
                child: ListTile(
                  title: Text(m.motivo),
                  subtitle: Text(_formatearFecha(m.fecha)),
                  trailing: Text(
                    '+${m.puntos}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorPrimario,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _datoRacha(
      BuildContext context, String emoji, String valor, String etiqueta) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(valor,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}