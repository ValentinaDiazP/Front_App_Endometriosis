import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Lo mismo que muestra Reportes mientras no existe la compra de planes.
void mostrarPlanesProximamente(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Los planes Premium llegan pronto.')),
  );
}

/// Bloque que reemplaza un contenido o ejercicio premium cuando la usuaria
/// tiene plan gratuito. Sigue el estilo de la tarjeta bloqueada de Reportes.
class TarjetaPremium extends StatelessWidget {
  /// Qué incluye este recurso, en una frase ("Este contenido profundiza…").
  final String descripcion;

  const TarjetaPremium({super.key, required this.descripcion});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text('Disponible con Premium', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(descripcion),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => mostrarPlanesProximamente(context),
            icon: const Icon(Icons.workspace_premium, size: 18),
            label: const Text('Conocer Premium'),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta pequeña con candado para tarjetas de listas.
class EtiquetaPremium extends StatelessWidget {
  final bool bloqueado;
  const EtiquetaPremium({super.key, required this.bloqueado});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFE98BA0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(bloqueado ? Icons.lock_outline : Icons.workspace_premium, size: 14, color: color),
        const SizedBox(width: 3),
        const Text('Premium',
            style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
