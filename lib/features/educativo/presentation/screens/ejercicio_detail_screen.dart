import 'package:flutter/material.dart';
import '../../data/educativo_repository.dart';
import '../../models/ejercicio_psicoeducativo.dart';

/// Pantalla de instrucciones de un ejercicio. En sprints futuros esto se
/// vuelve un flujo guiado paso a paso (según su tipo); por ahora muestra
/// las instrucciones y un botón de completar que crea un RegistroEjercicio
/// en el backend (vía EducativoRepository).
class EjercicioDetailScreen extends StatefulWidget {
  final EjercicioPsicoeducativo ejercicio;
  const EjercicioDetailScreen({super.key, required this.ejercicio});

  @override
  State<EjercicioDetailScreen> createState() => _EjercicioDetailScreenState();
}

class _EjercicioDetailScreenState extends State<EjercicioDetailScreen> {
  late bool _completado =
      EducativoRepository.ejercicioCompletado(widget.ejercicio.idEjercicio);
  bool _guardando = false;

  Future<void> _completar() async {
    setState(() => _guardando = true);
    try {
      // TODO: pedir respuestas y percepción de utilidad (el backend ya los
      // acepta como opcionales) y sumar puntos de gamificación.
      await EducativoRepository.marcarEjercicioCompletado(widget.ejercicio.idEjercicio);
      if (!mounted) return;
      setState(() => _completado = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ejercicio completado')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el ejercicio. Intenta de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
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
                onPressed: _completado || _guardando ? null : _completar,
                child: Text(_completado ? 'Ya completado' : 'Completar ejercicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
