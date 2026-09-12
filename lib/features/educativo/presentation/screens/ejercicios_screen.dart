import 'package:flutter/material.dart';
import '../../data/mock_educativo_data.dart';
import '../../models/ejercicio_psicoeducativo.dart';
import '../../educativo_routes.dart';

/// Lista de ejercicios psicoeducativos, agrupados por enfoque
/// (Psicoeducación / TCC / ACT y Mindfulness), tal como se construirán en
/// los sprints Semana 4, 5 y 6 del cronograma.
class EjerciciosScreen extends StatelessWidget {
  const EjerciciosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final porTipo = <TipoEjercicio, List<EjercicioPsicoeducativo>>{};
    for (final ej in MockEducativoData.ejercicios) {
      porTipo.putIfAbsent(ej.tipo, () => []).add(ej);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        for (final tipo in porTipo.keys) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text(tipo.label, style: Theme.of(context).textTheme.titleLarge),
          ),
          ...porTipo[tipo]!.map(
            (ejercicio) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: ejercicio.completadoPorUsuario
                      ? Colors.green.shade100
                      : const Color(0xFFF1EAFB),
                  child: Icon(
                    ejercicio.completadoPorUsuario ? Icons.check : Icons.self_improvement,
                    color: ejercicio.completadoPorUsuario ? Colors.green : const Color(0xFF8E6BBF),
                  ),
                ),
                title: Text(ejercicio.nombre),
                subtitle: Text('${ejercicio.minutosEstimados} min · ${ejercicio.descripcion}'),
                isThreeLine: true,
                onTap: () => Navigator.pushNamed(
                  context,
                  EducativoRoutes.ejercicioDetalle,
                  arguments: ejercicio,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
