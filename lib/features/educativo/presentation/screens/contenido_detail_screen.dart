import 'package:flutter/material.dart';
import '../../models/contenido_educativo.dart';
import '../widgets/nivel_badge.dart';

/// Detalle de un ítem de la biblioteca. Recibe el [ContenidoEducativo] ya
/// cargado por argumento de navegación (no vuelve a pedirlo a ningún API,
/// porque en esta etapa no hay backend conectado).
class ContenidoDetailScreen extends StatelessWidget {
  final ContenidoEducativo contenido;
  const ContenidoDetailScreen({super.key, required this.contenido});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(contenido.titulo)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NivelBadge(nivel: contenido.nivel),
                const SizedBox(width: 8),
                Icon(Icons.timer_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${contenido.minutosEstimados} min de lectura/reproducción'),
                if (contenido.esPremium) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.workspace_premium, size: 18, color: Color(0xFFE98BA0)),
                  const Text(' Premium', style: TextStyle(color: Color(0xFFE98BA0))),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(contenido.resumen, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            // Placeholder: aquí luego irá el reproductor de audio/video o el
            // cuerpo de texto ya formateado (markdown/rich text), según
            // contenido.tipo. Por ahora solo se muestra como texto plano.
            Text(contenido.cuerpo),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                // TODO(backend): al conectar el API, este botón debe
                // disparar la creación de una InteraccionContenido
                // (completado = true) para sumar puntos de gamificación.
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marcado como leído (wireframe, sin backend aún)')),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Marcar como leído'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
