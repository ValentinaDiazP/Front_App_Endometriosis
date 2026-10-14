import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/educativo_repository.dart';
import '../../models/ejercicio_psicoeducativo.dart';
import '../widgets/calificacion_utilidad.dart';
import '../widgets/modulo_progreso_header.dart';
import '../widgets/pasos_ejercicio.dart';

/// Ejercicio de ACT sobre valores personales, en 4 pasos:
/// elegir hasta 3 valores → calificar su importancia → una acción pequeña
/// → resumen.
///
/// Al guardar crea un RegistroEjercicio con las respuestas (JSON).
class EjercicioValoresScreen extends StatefulWidget {
  final EjercicioPsicoeducativo ejercicio;
  const EjercicioValoresScreen({super.key, required this.ejercicio});

  @override
  State<EjercicioValoresScreen> createState() => _EjercicioValoresScreenState();
}

class _EjercicioValoresScreenState extends State<EjercicioValoresScreen> {
  static const _totalPasos = 3;
  static const _maxValores = 3;

  static const _valores = <String, String>{
    'familia': 'Familia',
    'amistad': 'Amistad',
    'pareja': 'Pareja y afecto',
    'salud': 'Cuidar mi salud',
    'creatividad': 'Creatividad',
    'aprender': 'Aprender',
    'trabajo': 'Trabajo / propósito',
    'naturaleza': 'Naturaleza',
    'descanso': 'Descanso y calma',
    'comunidad': 'Comunidad y ayudar',
    'espiritualidad': 'Espiritualidad',
    'diversion': 'Diversión',
  };

  final _controller = PageController();
  final _accion = TextEditingController();

  final List<String> _elegidos = [];
  final Map<String, double> _importancia = {};
  int _indice = 0;
  bool _enResumen = false;
  int? _utilidad;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _accion.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _accion.dispose();
    super.dispose();
  }

  bool get _puedeAvanzar {
    if (_indice == 0) return _elegidos.isNotEmpty;
    if (_indice == 2) return _accion.text.trim().isNotEmpty;
    return true;
  }

  void _alternar(String id) {
    setState(() {
      if (_elegidos.contains(id)) {
        _elegidos.remove(id);
        _importancia.remove(id);
      } else if (_elegidos.length < _maxValores) {
        _elegidos.add(id);
        _importancia[id] = 80;
      }
    });
  }

  void _siguiente() {
    FocusScope.of(context).unfocus();
    if (_indice == _totalPasos - 1) {
      setState(() => _enResumen = true);
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _anterior() {
    FocusScope.of(context).unfocus();
    _controller.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final respuestas = jsonEncode({
      'valores': [
        for (final id in _elegidos)
          {'valor': _valores[id], 'importancia': (_importancia[id] ?? 0).round()},
      ],
      'accion_pequena': _accion.text.trim(),
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
        const SnackBar(content: Text('No se pudo guardar el ejercicio. Intenta de nuevo.')),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ejercicio guardado')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ejercicio.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(child: _enResumen ? _buildResumen() : _buildPasos()),
    );
  }

  Widget _buildPasos() {
    return Column(
      children: [
        ModuloProgresoHeader(pasoActual: _indice + 1, totalPasos: _totalPasos),
        Expanded(
          child: PageView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _indice = i),
            children: [
              PasoEjercicio(
                titulo: '¿Qué es importante para ti?',
                explicacion:
                    'Los valores son la dirección que quieres darle a tu vida, aun con '
                    'dolor. Elige hasta $_maxValores que sientas cercanos.',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in _valores.entries)
                        FilterChip(
                          label: Text(e.value),
                          selected: _elegidos.contains(e.key),
                          selectedColor: AppTheme.primaryLight,
                          onSelected: (_) => _alternar(e.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('${_elegidos.length} de $_maxValores elegidos',
                      style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
              PasoEjercicio(
                titulo: '¿Cuánto te importan hoy?',
                explicacion:
                    'Califica qué tan importante es cada valor en este momento de tu vida.',
                children: [
                  for (final id in _elegidos)
                    SliderPorcentaje(
                      titulo: _valores[id] ?? id,
                      valor: _importancia[id] ?? 0,
                      onCambio: (v) => setState(() => _importancia[id] = v),
                    ),
                ],
              ),
              PasoEjercicio(
                titulo: 'Un paso pequeño esta semana',
                explicacion:
                    'Piensa en una acción pequeña y realista que te acerque a tus valores, '
                    'incluso en un día con dolor.',
                children: [
                  CampoTexto(
                    controller: _accion,
                    pista: 'Ej: Llamar a una amiga 10 minutos o dar un paseo corto.',
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Row(
            children: [
              if (_indice > 0) ...[
                Expanded(
                  child: OutlinedButton(onPressed: _anterior, child: const Text('Anterior')),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _puedeAvanzar ? _siguiente : null,
                  child: Text(_indice == _totalPasos - 1 ? 'Ver resumen' : 'Siguiente'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tus valores', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          for (final id in _elegidos) ...[
            TarjetaResumen(
              etiqueta: 'Importancia ${(_importancia[id] ?? 0).round()}%',
              texto: _valores[id] ?? id,
            ),
            const SizedBox(height: 10),
          ],
          TarjetaResumen(
            etiqueta: 'Mi paso de esta semana',
            texto: _accion.text.trim(),
            destacada: true,
          ),
          const SizedBox(height: 24),
          CalificacionUtilidad(valor: _utilidad, onCambio: (v) => setState(() => _utilidad = v)),
          const SizedBox(height: 16),
          const Text(
            'Tus respuestas se guardan en tu cuenta de Florecer. Este ejercicio '
            'no reemplaza la atención de tu profesional de salud.',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 20),
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
                  : const Text('Guardar ejercicio'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _guardando ? null : () => setState(() => _enResumen = false),
              child: const Text('Volver a editar'),
            ),
          ),
        ],
      ),
    );
  }
}
