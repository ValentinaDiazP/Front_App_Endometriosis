import 'package:flutter/material.dart';
import '../../data/educativo_repository.dart';
import '../../educativo_routes.dart';

/// Rutas de aprendizaje: secuencias curadas de contenidos de la biblioteca.
///
/// Nota de diseño: aquí NO se muestra el progreso de contenido completado
/// (eso vive en Biblioteca, ver ProgresoBibliotecaBar) — una ruta es solo
/// un orden sugerido de lectura, no "otra barra de progreso" separada.
class RutasScreen extends StatelessWidget {
  const RutasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rutas = EducativoRepository.rutas;
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
                  const SizedBox(height: 8),
                  Text(
                    '${ruta.contenidos.length} contenidos',
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
