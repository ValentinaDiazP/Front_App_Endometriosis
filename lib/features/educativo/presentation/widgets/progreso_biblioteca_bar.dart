import 'package:flutter/material.dart';
import '../../data/educativo_repository.dart';
import '../../../../core/theme/app_theme.dart';

/// Resumen de progreso de la Biblioteca: "X de Y contenidos completados".
/// Vive aquí (y no en Rutas) porque el progreso es una propiedad del
/// contenido en sí, no de cómo la usuaria decida recorrerlo.
class ProgresoBibliotecaBar extends StatelessWidget {
  const ProgresoBibliotecaBar({super.key});

  @override
  Widget build(BuildContext context) {
    final completados = EducativoRepository.totalContenidosCompletados;
    final total = EducativoRepository.totalContenidos;
    final progreso = total == 0 ? 0.0 : completados / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tu progreso', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('$completados de $total', style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 8,
              backgroundColor: AppTheme.primaryLight,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
