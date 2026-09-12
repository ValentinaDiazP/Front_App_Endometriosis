import 'package:flutter/material.dart';
import '../../models/ruta_aprendizaje.dart';
import '../../educativo_routes.dart';
import '../widgets/contenido_card.dart';

/// Detalle de una ruta: lista ordenada de contenidos que la componen.
/// Reutiliza ContenidoCard para no duplicar UI con la Biblioteca.
class RutaDetailScreen extends StatelessWidget {
  final RutaAprendizaje ruta;
  const RutaDetailScreen({super.key, required this.ruta});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ruta.nombre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(ruta.descripcion, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          for (int i = 0; i < ruta.contenidos.length; i++) ...[
            Row(
              children: [
                CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                const SizedBox(width: 8),
                Text('Paso ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            ContenidoCard(
              contenido: ruta.contenidos[i],
              onTap: () => Navigator.pushNamed(
                context,
                EducativoRoutes.contenidoDetalle,
                arguments: ruta.contenidos[i],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
