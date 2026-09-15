import 'package:flutter/material.dart';
import '../../data/mock_educativo_data.dart';
import '../../models/ejercicio_psicoeducativo.dart';

/// Pantalla de instrucciones de un ejercicio. En sprints futuros esto se
/// vuelve un flujo guiado paso a paso (según su tipo); por ahora es un
/// wireframe con las instrucciones y un botón de completar que sí guarda
/// el estado en MockEducativoData.
class EjercicioDetailScreen extends StatefulWidget {
  final EjercicioPsicoeducativo ejercicio;
  const EjercicioDetailScreen({super.key, required this.ejercicio});

  @override
  State<EjercicioDetailScreen> createState() => _EjercicioDetailScreenState();
}

class _EjercicioDetailScreenState extends State<EjercicioDetailScreen> {
  late bool _completado =
      MockEducativoData.ejercicioCompletado(widget.ejercicio.idEjercicio);

  void _completar() {
    setState(() {
      MockEducativoData.marcarEjercicioCompletado(widget.ejercicio.idEjercicio);
      _completado = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ejercicio completado')),
    );
    // TODO(backend): crear RegistroEjercicio con fecha, respuestas y
    // percepción de utilidad, y sumar puntos de gamificación.
  }

  @override
  Widget build(BuildContext context) {
    final ejercicio = widget.ejercicio;
    return Scaffold(
      appBar: AppBar(title: Text(ejercicio.nombre)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(label: Text(ejercicio.tipo.label)),
            const SizedBox(height: 16),
            Text(ejercicio.descripcion, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const Text('Instrucciones', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(ejercicio.instrucciones),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _completado ? null : _completar,
                child: Text(_completado ? 'Ya completado' : 'Completar ejercicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
