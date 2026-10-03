import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Indicador de progreso de un módulo guiado: "Paso 2 de 5" y una barra
/// segmentada (una pastilla por paso). Las pastillas hasta el paso actual
/// aparecen llenas.
class ModuloProgresoHeader extends StatelessWidget {
  final int pasoActual; // 1-based
  final int totalPasos;

  const ModuloProgresoHeader({
    super.key,
    required this.pasoActual,
    required this.totalPasos,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paso $pasoActual de $totalPasos',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                '${((pasoActual / totalPasos) * 100).round()}%',
                style: const TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 0; i < totalPasos; i++)
                Expanded(
                  child: Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i < pasoActual ? AppTheme.primary : AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
