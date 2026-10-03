import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Indicador pequeño de progreso de un módulo, para listas y para la
/// pantalla de detalle: "5 pasos", "2 de 5 pasos" con barra, o "Completado".
class ProgresoModuloMini extends StatelessWidget {
  final int pasosAlcanzados;
  final int totalPasos;
  final bool completado;

  const ProgresoModuloMini({
    super.key,
    required this.pasosAlcanzados,
    required this.totalPasos,
    required this.completado,
  });

  @override
  Widget build(BuildContext context) {
    if (completado) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: Colors.green),
          SizedBox(width: 4),
          Text('Completado',
              style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
        ],
      );
    }

    if (pasosAlcanzados <= 0) {
      return Text('$totalPasos pasos',
          style: const TextStyle(fontSize: 12, color: Colors.black54));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$pasosAlcanzados de $totalPasos pasos',
            style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pasosAlcanzados / totalPasos,
            minHeight: 5,
            backgroundColor: AppTheme.primaryLight,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
          ),
        ),
      ],
    );
  }
}
