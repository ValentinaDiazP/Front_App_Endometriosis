import 'package:flutter/material.dart';
import '../../models/progreso_gamificacion.dart';

/// Tarjeta destacada de puntos, nivel y racha. Se usa en Perfil y puede
/// reutilizarse en otras pantallas que muestren el mismo resumen.
class TarjetaGamificacion extends StatelessWidget {
  final ProgresoGamificacion progreso;

  const TarjetaGamificacion({super.key, required this.progreso});

  static const Map<String, String> emojiPorNivel = {
    'Semilla': '🌱',
    'Brote': '🌿',
    'Capullo': '🌷',
    'Flor': '🌸',
    'Jardin': '🌺',
    'Jardín': '🌺',
  };

  String get _nombreNivel {
    final nombre = progreso.nivel?.nombre ?? 'Semilla';
    return nombre == 'Jardin' ? 'Jardín' : nombre;
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimario = Theme.of(context).colorScheme.primary;
    final emoji = emojiPorNivel[progreso.nivel?.nombre] ??
        emojiPorNivel[_nombreNivel] ??
        '🌱';

    return Card(
      elevation: 6,
      color: colorPrimario.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorPrimario.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            Text(
              'Nivel $_nombreNivel',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Dato(
                    etiqueta: 'Puntos totales',
                    valor: '${progreso.puntosTotales}',
                    color: colorPrimario,
                  ),
                ),
                Expanded(
                  child: _Dato(
                    etiqueta: 'Racha actual',
                    valor: progreso.rachaActual == 1
                        ? '1 día'
                        : '${progreso.rachaActual} días',
                    color: colorPrimario,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color color;

  const _Dato({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
