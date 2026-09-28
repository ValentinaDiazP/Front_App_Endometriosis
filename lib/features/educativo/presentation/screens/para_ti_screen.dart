import 'package:flutter/material.dart';
import '../../data/gestor_contenido.dart';
import '../../data/mock_educativo_data.dart';
import '../../data/senales_seguimiento_mock.dart';
import '../../educativo_routes.dart';
import '../../models/contenido_educativo.dart';
import '../widgets/aviso_pendiente_card.dart';
import '../widgets/contenido_card.dart';
import '../../../../core/theme/app_theme.dart';
import 'preferencias_screen.dart';

/// Vista de contenido personalizado ("Para ti").
///
/// Muestra el contenido priorizado por el [GestorContenidoEducativo] según
/// las preferencias que la usuaria eligió en el onboarding y las señales
/// (simuladas) del módulo de Seguimiento. Cada tarjeta explica por qué se
/// recomienda. El interruptor "Solo mis intereses" filtra por categorías
/// elegidas en vez de solo reordenar.
class ParaTiScreen extends StatefulWidget {
  const ParaTiScreen({super.key});

  @override
  State<ParaTiScreen> createState() => _ParaTiScreenState();
}

class _ParaTiScreenState extends State<ParaTiScreen> {
  bool _soloMisIntereses = false;

  Future<void> _editarPreferencias() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PreferenciasScreen()),
    );
    setState(() {}); // las preferencias pudieron cambiar
  }

  Future<void> _abrirDetalle(ContenidoEducativo contenido) async {
    await Navigator.pushNamed(
      context,
      EducativoRoutes.contenidoDetalle,
      arguments: contenido,
    );
    setState(() {}); // el "completado" pudo cambiar el orden
  }

  @override
  Widget build(BuildContext context) {
    final priorizados = GestorContenidoEducativo.contenidosPriorizados(
      soloPreferidos: _soloMisIntereses,
    );
    final tienePreferencias = MockEducativoData.tienePreferencias;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const AvisoPendienteCard(),
        _SenalesCard(),
        if (!tienePreferencias)
          _SinPreferenciasCard(onElegir: _editarPreferencias)
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Solo mis intereses',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: _soloMisIntereses,
                  onChanged: (v) => setState(() => _soloMisIntereses = v),
                ),
                IconButton(
                  tooltip: 'Editar preferencias',
                  icon: const Icon(Icons.tune),
                  onPressed: _editarPreferencias,
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            _soloMisIntereses ? 'De tus temas elegidos' : 'Recomendado para ti',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        if (priorizados.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No hay contenido para estos temas todavía.')),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final item in priorizados)
                  ContenidoCard(
                    contenido: item.contenido,
                    motivo: item.motivo,
                    completado: MockEducativoData.contenidoCompletado(
                        item.contenido.idContenido),
                    onTap: () => _abrirDetalle(item.contenido),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Muestra las señales simuladas de Seguimiento que influyen en el orden.
class _SenalesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.monitor_heart_outlined, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Según tu seguimiento: ${SenalesSeguimientoMock.resumen}',
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _SinPreferenciasCard extends StatelessWidget {
  final VoidCallback onElegir;
  const _SinPreferenciasCard({required this.onElegir});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        color: AppTheme.primaryLight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cuéntanos qué te interesa',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text(
                'Elige tus temas y ordenaremos el contenido para ti.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              FilledButton(onPressed: onElegir, child: const Text('Elegir temas')),
            ],
          ),
        ),
      ),
    );
  }
}
