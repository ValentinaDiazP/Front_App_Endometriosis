import 'package:flutter/material.dart';
import '../../data/educativo_repository.dart';
import '../../data/modulos_psicoeducativos_mock.dart';
import '../../models/ejercicio_psicoeducativo.dart';
import '../../models/modulo_psicoeducativo.dart';
import '../widgets/modulo_progreso_header.dart';
import '../widgets/paso_modulo_view.dart';
import '../../../../core/theme/app_theme.dart';

/// Módulo informativo guiado (ejercicios de Psicoeducación).
///
/// Muestra el contenido paso a paso en un PageView, con indicador de
/// progreso arriba y botones Anterior / Siguiente abajo. El avance se
/// guarda en cada cambio de paso (para poder continuar donde se quedó) y
/// al terminar el último paso se marca el ejercicio como completado y se
/// muestra un resumen con las ideas clave.
///
/// Solo se debe abrir para ejercicios que tengan módulo; el llamador
/// (EjercicioDetailScreen) lo verifica con ModulosPsicoeducativosMock.
class ModuloGuiadoScreen extends StatefulWidget {
  final EjercicioPsicoeducativo ejercicio;

  const ModuloGuiadoScreen({super.key, required this.ejercicio});

  @override
  State<ModuloGuiadoScreen> createState() => _ModuloGuiadoScreenState();
}

class _ModuloGuiadoScreenState extends State<ModuloGuiadoScreen> {
  late final ModuloPsicoeducativo _modulo =
      ModulosPsicoeducativosMock.deEjercicio(widget.ejercicio.idEjercicio)!;

  late final PageController _controller;
  late int _indice; // 0-based
  bool _finalizado = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final yaCompletado =
        EducativoRepository.ejercicioCompletado(widget.ejercicio.idEjercicio);
    final alcanzados =
        EducativoRepository.pasosAlcanzadosModulo(widget.ejercicio.idEjercicio);

    // Si ya lo completó, "repasar" empieza desde el inicio. Si lo dejó a
    // medias, continúa en el último paso alcanzado.
    if (yaCompletado || alcanzados <= 0) {
      _indice = 0;
    } else {
      final ultimo = _modulo.totalPasos - 1;
      final candidato = alcanzados - 1;
      _indice = candidato > ultimo ? ultimo : candidato;
    }
    _controller = PageController(initialPage: _indice);
    EducativoRepository.guardarPasosAlcanzadosModulo(
        widget.ejercicio.idEjercicio, _indice + 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _esUltimoPaso => _indice == _modulo.totalPasos - 1;

  void _alCambiarPagina(int indice) {
    setState(() => _indice = indice);
    EducativoRepository.guardarPasosAlcanzadosModulo(
        widget.ejercicio.idEjercicio, indice + 1);
  }

  void _anterior() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _siguiente() {
    if (_esUltimoPaso) {
      _finalizar();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _finalizar() async {
    // Crea el RegistroEjercicio en el backend.
    // TODO(backend): sumar puntos de gamificación (Semana 7).
    setState(() => _guardando = true);
    try {
      await EducativoRepository.marcarEjercicioCompletado(widget.ejercicio.idEjercicio);
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el módulo. Intenta de nuevo.')),
      );
      return;
    }
    EducativoRepository.guardarPasosAlcanzadosModulo(
        widget.ejercicio.idEjercicio, _modulo.totalPasos);
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _finalizado = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.ejercicio.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: _finalizado ? _buildResumenFinal() : _buildPasos(),
      ),
    );
  }

  Widget _buildPasos() {
    return Column(
      children: [
        ModuloProgresoHeader(
          pasoActual: _indice + 1,
          totalPasos: _modulo.totalPasos,
        ),
        Expanded(
          child: PageView.builder(
            controller: _controller,
            onPageChanged: _alCambiarPagina,
            itemCount: _modulo.totalPasos,
            itemBuilder: (context, i) =>
                PasoModuloView(paso: _modulo.pasos[i], numero: i + 1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Row(
            children: [
              if (_indice > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _guardando ? null : _anterior,
                    child: const Text('Anterior'),
                  ),
                ),
              if (_indice > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _guardando ? null : _siguiente,
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_esUltimoPaso ? 'Finalizar' : 'Siguiente'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumenFinal() {
    final ideas = _modulo.pasos
        .map((p) => p.puntoClave)
        .whereType<String>()
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: CircleAvatar(
              radius: 34,
              backgroundColor: Color(0xFFE4F3E6),
              child: Icon(Icons.check_rounded, size: 40, color: Colors.green),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('¡Módulo completado!',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Esto es lo más importante que viste:',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 18),
          for (final idea in ideas)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(idea, style: const TextStyle(fontSize: 14.5))),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Este contenido es informativo y no reemplaza la atención de tu '
            'profesional de salud.',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver a los ejercicios'),
            ),
          ),
        ],
      ),
    );
  }
}
