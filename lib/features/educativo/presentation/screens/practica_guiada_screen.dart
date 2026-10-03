import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/educativo_repository.dart';
import '../../data/practicas_guiadas_mock.dart';
import '../../models/ejercicio_psicoeducativo.dart';
import '../widgets/boton_recurso_externo.dart';
import '../widgets/calificacion_utilidad.dart';
import '../../../../core/theme/app_theme.dart';

/// Práctica guiada de ACT o Mindfulness: un temporizador con la duración del
/// ejercicio y las indicaciones de [PracticasGuiadasMock] cambiando a lo
/// largo del tiempo. Si el ejercicio tiene audio guiado (`urlRecurso`), se
/// ofrece abrirlo.
///
/// Al guardar crea un RegistroEjercicio con el tiempo practicado y la nota
/// en `respuestas` (JSON) y la calificación en `utilidad`.
class PracticaGuiadaScreen extends StatefulWidget {
  final EjercicioPsicoeducativo ejercicio;
  const PracticaGuiadaScreen({super.key, required this.ejercicio});

  @override
  State<PracticaGuiadaScreen> createState() => _PracticaGuiadaScreenState();
}

class _PracticaGuiadaScreenState extends State<PracticaGuiadaScreen> {
  late final List<String> _indicaciones =
      PracticasGuiadasMock.deEjercicio(widget.ejercicio.idEjercicio);
  late final int _totalSegundos = widget.ejercicio.minutosEstimados * 60;

  final _nota = TextEditingController();
  Timer? _timer;
  int _segundos = 0;
  bool _terminada = false;
  int? _utilidad;
  bool _guardando = false;

  bool get _iniciada => _segundos > 0 || _timer != null;
  bool get _corriendo => _timer?.isActive ?? false;

  int get _indiceIndicacion {
    final porIndicacion = _totalSegundos / _indicaciones.length;
    final i = (_segundos / porIndicacion).floor();
    return i.clamp(0, _indicaciones.length - 1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nota.dispose();
    super.dispose();
  }

  void _iniciarOReanudar() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _segundos++);
      if (_segundos >= _totalSegundos) _terminar();
    });
    setState(() {});
  }

  void _pausar() {
    _timer?.cancel();
    setState(() {});
  }

  void _terminar() {
    _timer?.cancel();
    setState(() => _terminada = true);
  }

  String _formato(int segundos) {
    final m = (segundos ~/ 60).toString().padLeft(2, '0');
    final s = (segundos % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final respuestas = jsonEncode({
      'segundos_practicados': _segundos,
      'nota': _nota.text.trim(),
    });
    try {
      await EducativoRepository.marcarEjercicioCompletado(
        widget.ejercicio.idEjercicio,
        respuestas: respuestas,
        utilidad: _utilidad,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la práctica. Intenta de nuevo.')),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Práctica guardada')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ejercicio.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(child: _terminada ? _buildFinal() : _buildPractica()),
    );
  }

  Widget _buildPractica() {
    final restante = _totalSegundos - _segundos;
    final url = widget.ejercicio.urlRecurso;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: _segundos / _totalSegundos,
                    strokeWidth: 8,
                    backgroundColor: AppTheme.primaryLight,
                    color: AppTheme.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formato(restante),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      _corriendo ? 'en curso' : (_iniciada ? 'en pausa' : 'listo para empezar'),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 110),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _iniciada ? _indicaciones[_indiceIndicacion] : widget.ejercicio.instrucciones,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, height: 1.45),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_iniciada)
            Text('Indicación ${_indiceIndicacion + 1} de ${_indicaciones.length}',
                style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _corriendo ? _pausar : _iniciarOReanudar,
              icon: Icon(_corriendo ? Icons.pause_rounded : Icons.play_arrow_rounded),
              label: Text(_corriendo ? 'Pausar' : (_iniciada ? 'Continuar' : 'Comenzar práctica')),
            ),
          ),
          if (_iniciada)
            TextButton(onPressed: _terminar, child: const Text('Terminar práctica')),
          if (url != null) ...[
            const SizedBox(height: 16),
            const Text('¿Prefieres una voz que te guíe?',
                style: TextStyle(fontSize: 13.5, color: Colors.black54)),
            const SizedBox(height: 8),
            BotonRecursoExterno(url: url, esAudio: true),
          ],
          const SizedBox(height: 20),
          const Text(
            'Si el dolor aumenta o te sientes mal, detén la práctica. Este '
            'ejercicio no reemplaza la atención de tu profesional de salud.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildFinal() {
    final minutos = (_segundos / 60).ceil();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: CircleAvatar(
              radius: 34,
              backgroundColor: Color(0xFFE4F3E6),
              child: Icon(Icons.self_improvement, size: 40, color: Colors.green),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Práctica terminada', style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Te diste $minutos ${minutos == 1 ? 'minuto' : 'minutos'} para ti.',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 24),
          CalificacionUtilidad(valor: _utilidad, onCambio: (v) => setState(() => _utilidad = v)),
          const SizedBox(height: 20),
          const Text('¿Algo que quieras recordar? (opcional)',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _nota,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Ej: Me ayudó respirar más lento al final.',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar práctica'),
            ),
          ),
        ],
      ),
    );
  }
}
