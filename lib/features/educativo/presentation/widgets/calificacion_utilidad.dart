import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// "¿Qué tan útil te resultó?" de 1 a 5. Se guarda en el campo `utilidad`
/// de RegistroEjercicio.
class CalificacionUtilidad extends StatelessWidget {
  final int? valor;
  final ValueChanged<int> onCambio;

  const CalificacionUtilidad({super.key, required this.valor, required this.onCambio});

  static const _etiquetas = ['Nada útil', 'Poco útil', 'Algo útil', 'Útil', 'Muy útil'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('¿Qué tan útil te resultó?', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 1; i <= 5; i++)
              IconButton(
                tooltip: _etiquetas[i - 1],
                onPressed: () => onCambio(i),
                icon: Icon(
                  valor != null && i <= valor! ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppTheme.primary,
                  size: 34,
                ),
              ),
          ],
        ),
        Text(
          valor == null ? 'Toca una estrella' : _etiquetas[valor! - 1],
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }
}
