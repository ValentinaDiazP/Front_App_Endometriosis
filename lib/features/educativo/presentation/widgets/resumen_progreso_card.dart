import 'package:flutter/material.dart';
import '../../data/educativo_repository.dart';
import '../../models/progreso_aprendizaje.dart';
import '../screens/mi_progreso_screen.dart';
import '../../../../core/theme/app_theme.dart';

/// Tarjeta compacta de nivel, puntos y racha para la pestaña "Para ti".
/// Al tocarla abre la pantalla completa "Mi progreso". Si el progreso no se
/// puede cargar, no ocupa espacio (nunca debe estorbar al resto del módulo).
class ResumenProgresoCard extends StatefulWidget {
  const ResumenProgresoCard({super.key});

  @override
  State<ResumenProgresoCard> createState() => _ResumenProgresoCardState();
}

class _ResumenProgresoCardState extends State<ResumenProgresoCard> {
  late Future<ProgresoAprendizaje> _futuro = EducativoRepository.obtenerProgreso();

  @override
  void initState() {
    super.initState();
    EducativoRepository.cambiosProgreso.addListener(_actualizar);
  }

  @override
  void dispose() {
    EducativoRepository.cambiosProgreso.removeListener(_actualizar);
    super.dispose();
  }

  void _actualizar() {
    if (mounted) {
      setState(() {
        _futuro = EducativoRepository.obtenerProgreso();
      });
    }
  }

  Future<void> _abrir() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MiProgresoScreen()),
    );
    if (mounted) {
      setState(() {
        _futuro = EducativoRepository.obtenerProgreso();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProgresoAprendizaje>(
      future: _futuro,
      builder: (context, snapshot) {
        final p = snapshot.data;
        if (p == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _abrir,
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(p.nivel.emoji.isEmpty ? '🧭' : p.nivel.emoji,
                      style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nivel ${p.nivel.nombre}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          '${p.puntosTotales} puntos · racha ${p.rachaActual} '
                          '${p.rachaActual == 1 ? 'día' : 'días'} 🔥',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: p.progresoNivel,
                            minHeight: 6,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.primary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
