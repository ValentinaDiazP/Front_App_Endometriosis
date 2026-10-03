import 'package:flutter/material.dart';
import '../../data/educativo_repository.dart';
import '../../data/modulos_psicoeducativos_mock.dart';
import '../../models/ejercicio_psicoeducativo.dart';
import '../../educativo_routes.dart';
import '../widgets/aviso_pendiente_card.dart';
import '../widgets/progreso_modulo_mini.dart';

/// Lista de ejercicios psicoeducativos, agrupados por enfoque
/// (Psicoeducación / TCC / ACT y Mindfulness).
class EjerciciosScreen extends StatefulWidget {
  const EjerciciosScreen({super.key});

  @override
  State<EjerciciosScreen> createState() => _EjerciciosScreenState();
}

class _EjerciciosScreenState extends State<EjerciciosScreen> {
  Future<void> _abrir(EjercicioPsicoeducativo ejercicio) async {
    await Navigator.pushNamed(
      context,
      EducativoRoutes.ejercicioDetalle,
      arguments: ejercicio,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final porTipo = <TipoEjercicio, List<EjercicioPsicoeducativo>>{};
    for (final ej in EducativoRepository.ejercicios) {
      porTipo.putIfAbsent(ej.tipo, () => []).add(ej);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const AvisoPendienteCard(),
        const SizedBox(height: 8),
        for (final tipo in porTipo.keys) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(tipo.label, style: Theme.of(context).textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final ejercicio in porTipo[tipo]!)
                  Builder(builder: (context) {
                    final completado = EducativoRepository.ejercicioCompletado(ejercicio.idEjercicio);
                    final modulo = ModulosPsicoeducativosMock.deEjercicio(ejercicio.idEjercicio);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: completado ? Colors.green.shade100 : const Color(0xFFF1EAFB),
                          child: Icon(
                            completado ? Icons.check : Icons.self_improvement,
                            color: completado ? Colors.green : const Color(0xFF8E6BBF),
                          ),
                        ),
                        title: Text(ejercicio.nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${ejercicio.minutosEstimados} min · ${ejercicio.descripcion}'),
                            if (modulo != null) ...[
                              const SizedBox(height: 6),
                              ProgresoModuloMini(
                                pasosAlcanzados: EducativoRepository.pasosAlcanzadosModulo(
                                    ejercicio.idEjercicio),
                                totalPasos: modulo.totalPasos,
                                completado: completado,
                              ),
                            ],
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () => _abrir(ejercicio),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
