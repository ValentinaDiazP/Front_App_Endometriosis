import 'package:flutter/material.dart';
import '../../models/contenido_educativo.dart';
import 'nivel_badge.dart';

class ContenidoCard extends StatelessWidget {
  final ContenidoEducativo contenido;
  final bool completado;
  final VoidCallback onTap;

  /// Motivo por el que se recomienda este contenido (personalización).
  /// Si es null no se muestra nada.
  final String? motivo;

  const ContenidoCard({
    super.key,
    required this.contenido,
    required this.onTap,
    this.completado = false,
    this.motivo,
  });

  IconData get _icono {
    switch (contenido.tipo) {
      case TipoContenido.texto:
        return Icons.article_outlined;
      case TipoContenido.video:
        return Icons.play_circle_outline;
      case TipoContenido.audio:
        return Icons.headphones_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: completado ? Colors.green.shade50 : const Color(0xFFF1EAFB),
                child: Icon(
                  completado ? Icons.check_circle : _icono,
                  color: completado ? Colors.green : const Color(0xFF8E6BBF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            contenido.titulo,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (contenido.esPremium)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.workspace_premium, size: 18, color: Color(0xFFE98BA0)),
                          ),
                      ],
                    ),
                    if (motivo != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 13, color: Color(0xFF8E6BBF)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              motivo!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF8E6BBF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      contenido.resumen,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        NivelBadge(nivel: contenido.nivel),
                        const SizedBox(width: 8),
                        Icon(Icons.timer_outlined, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Text('${contenido.minutosEstimados} min',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                        if (completado) ...[
                          const SizedBox(width: 8),
                          const Text('· Completado',
                              style: TextStyle(fontSize: 11.5, color: Colors.green, fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
