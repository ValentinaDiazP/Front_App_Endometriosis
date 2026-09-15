import 'package:flutter/material.dart';
import '../../data/gestor_contenido.dart';
import '../../educativo_routes.dart';
import '../../models/contenido_educativo.dart';
import '../../models/ejercicio_psicoeducativo.dart';
import '../../../../core/theme/app_theme.dart';

/// Aviso que muestra la recomendación del [GestorContenidoEducativo]:
/// "Tienes pendiente terminar: <actividad>". Al tocarlo, lleva directo a la
/// pantalla de esa actividad. Si no hay nada pendiente, no se muestra nada.
class AvisoPendienteCard extends StatelessWidget {
  const AvisoPendienteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final recomendacion = GestorContenidoEducativo.siguientePendiente();
    if (recomendacion == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (recomendacion.tipo == TipoRecomendacion.contenido) {
              Navigator.pushNamed(
                context,
                EducativoRoutes.contenidoDetalle,
                arguments: recomendacion.item as ContenidoEducativo,
              );
            } else {
              Navigator.pushNamed(
                context,
                EducativoRoutes.ejercicioDetalle,
                arguments: recomendacion.item as EjercicioPsicoeducativo,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_outlined, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tienes pendiente',
                        style: TextStyle(fontSize: 11.5, color: Colors.black54),
                      ),
                      Text(
                        'Terminar "${recomendacion.titulo}"',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
