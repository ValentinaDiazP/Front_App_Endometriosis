import 'package:flutter/material.dart';
import '../../models/modulo_psicoeducativo.dart';
import '../../../../core/theme/app_theme.dart';

/// Contenido de un paso del módulo: título, párrafos y la "idea clave"
/// resaltada. Se usa dentro del PageView de [ModuloGuiadoScreen].
class PasoModuloView extends StatelessWidget {
  final PasoModulo paso;
  final int numero; // 1-based

  const PasoModuloView({super.key, required this.paso, required this.numero});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryLight,
            child: Text(
              '$numero',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 14),
          Text(paso.titulo, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          for (final parrafo in paso.parrafos) ...[
            Text(parrafo, style: const TextStyle(fontSize: 15.5, height: 1.5)),
            const SizedBox(height: 12),
          ],
          if (paso.puntoClave != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 20, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Idea clave',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          paso.puntoClave!,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
