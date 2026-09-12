import 'package:flutter/material.dart';
import '../../models/ejercicio_psicoeducativo.dart';

/// Pantalla de instrucciones de un ejercicio. En sprints futuros esto se
/// vuelve un flujo guiado paso a paso (según su tipo); por ahora es un
/// wireframe estático con las instrucciones y un botón de completar.
class EjercicioDetailScreen extends StatelessWidget {
  final EjercicioPsicoeducativo ejercicio;
  const EjercicioDetailScreen({super.key, required this.ejercicio});

  @override
  Widget build(BuildContext context) {
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
                // TODO(backend): esto debe crear un RegistroEjercicio con
                // fecha, respuestas y percepción de utilidad, y sumar
                // puntos de gamificación (Gamificación III).
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ejercicio completado (wireframe, sin backend aún)')),
                  );
                },
                child: const Text('Completar ejercicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
