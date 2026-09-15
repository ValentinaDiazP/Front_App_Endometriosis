import 'package:flutter/material.dart';
import '../../data/mock_educativo_data.dart';
import '../../models/contenido_educativo.dart';
import '../widgets/nivel_badge.dart';

/// Detalle de un ítem de la biblioteca. Recibe el [ContenidoEducativo] ya
/// cargado por argumento de navegación (no vuelve a pedirlo a ningún API,
/// porque en esta etapa no hay backend conectado).
///
/// El estado "completado" vive en [MockEducativoData] (in-memory): al
/// marcarlo aquí, se refleja también en la tarjeta de Biblioteca y en la
/// barra de progreso al volver.
class ContenidoDetailScreen extends StatefulWidget {
  final ContenidoEducativo contenido;
  const ContenidoDetailScreen({super.key, required this.contenido});

  @override
  State<ContenidoDetailScreen> createState() => _ContenidoDetailScreenState();
}

class _ContenidoDetailScreenState extends State<ContenidoDetailScreen> {
  late bool _completado =
      MockEducativoData.contenidoCompletado(widget.contenido.idContenido);

  void _marcarComoLeido() {
    setState(() {
      MockEducativoData.marcarContenidoCompletado(widget.contenido.idContenido);
      _completado = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marcado como leído')),
    );
    // TODO(backend): esto debe crear una InteraccionContenido
    // (completado = true) y sumar puntos de gamificación.
  }

  @override
  Widget build(BuildContext context) {
    final contenido = widget.contenido;
    return Scaffold(
      appBar: AppBar(title: Text(contenido.titulo)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_completado)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 6),
                    Text('Ya completaste este contenido',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12.5)),
                  ],
                ),
              ),
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
                onPressed: _completado ? null : _marcarComoLeido,
                icon: Icon(_completado ? Icons.check_circle : Icons.check_circle_outline),
                label: Text(_completado ? 'Ya completado' : 'Marcar como leído'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
