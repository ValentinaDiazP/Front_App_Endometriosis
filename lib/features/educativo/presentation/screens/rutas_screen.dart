import 'package:flutter/material.dart';
import '../../data/mock_educativo_data.dart';
import '../../educativo_routes.dart';
import '../../../../core/theme/app_theme.dart';

/// Rutas de aprendizaje: secuencias curadas de contenidos de la biblioteca.
/// Corresponde conceptualmente a "Personalización de contenido" (Semana 3)
/// y se apoya en las mismas tarjetas de ContenidoEducativo.
class RutasScreen extends StatelessWidget {
  const RutasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rutas = MockEducativoData.rutas;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: rutas.length,
      itemBuilder: (context, index) {
        final ruta = rutas[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.pushNamed(
              context,
              EducativoRoutes.rutaDetalle,
              arguments: ruta,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ruta.nombre, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(ruta.descripcion, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: ruta.progreso,
                      minHeight: 8,
                      backgroundColor: AppTheme.primaryLight,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${ruta.contenidosCompletados} de ${ruta.contenidos.length} completados',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
