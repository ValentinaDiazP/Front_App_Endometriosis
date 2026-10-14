import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/educativo_repository.dart';
import '../../models/ejercicio_psicoeducativo.dart';
import '../widgets/calificacion_utilidad.dart';
import '../widgets/modulo_progreso_header.dart';
import '../widgets/pasos_ejercicio.dart';

/// Ejercicio de TCC para manejar la catastrofización del dolor, en 5 pasos:
/// miedo → peor / mejor / más probable → probabilidad → plan → resumen.
///
/// Al guardar crea un RegistroEjercicio con las respuestas (JSON) y la
/// calificación de utilidad, igual que EjercicioTccScreen.
class EjercicioCatastrofizacionScreen extends StatefulWidget {
  final EjercicioPsicoeducativo ejercicio;
  const EjercicioCatastrofizacionScreen({super.key, required this.ejercicio});

  @override
  State<EjercicioCatastrofizacionScreen> createState() =>
      _EjercicioCatastrofizacionScreenState();
}

class _EjercicioCatastrofizacionScreenState extends State<EjercicioCatastrofizacionScreen> {
  static const _totalPasos = 5;

  final _controller = PageController();
  final _miedo = TextEditingController();
  final _peor = TextEditingController();
  final _mejor = TextEditingController();
  final _probable = TextEditingController();
  final _plan = TextEditingController();

  int _indice = 0;
  double _probabilidadPeor = 50;
  double _angustiaInicial = 80;
  double _angustiaFinal = 50;
  bool _enResumen = false;
  int? _utilidad;
  bool _guardando = false;

  List<TextEditingController> get _campos => [_miedo, _peor, _mejor, _probable, _plan];

  @override
  void initState() {
    super.initState();
    for (final c in _campos) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final c in _campos) {
      c.dispose();
    }
    super.dispose();
  }

  /// Hay que escribir el miedo (paso 1) y el escenario más probable (paso 3)
  /// para avanzar; el resto es opcional.
  bool get _puedeAvanzar {
    if (_indice == 0) return _miedo.text.trim().isNotEmpty;
    if (_indice == 2) return _probable.text.trim().isNotEmpty;
    return true;
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
      'miedo': _miedo.text.trim(),
      'angustia_inicial': _angustiaInicial.round(),
      'peor_escenario': _peor.text.trim(),
      'mejor_escenario': _mejor.text.trim(),
      'escenario_probable': _probable.text.trim(),
      'probabilidad_peor': _probabilidadPeor.round(),
      'plan_afrontamiento': _plan.text.trim(),
      'angustia_final': _angustiaFinal.round(),
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
                titulo: '¿Qué te preocupa?',
                explicacion:
                    'Catastrofizar es imaginar lo peor ante el dolor y sentir que no '
                    'hay salida. Empieza escribiendo el miedo tal como aparece.',
                children: [
                  CampoTexto(
                    controller: _miedo,
                    pista: 'Ej: Si me duele así mañana, no podré trabajar y lo perderé todo.',
                  ),
                  const SizedBox(height: 20),
                  SliderPorcentaje(
                    titulo: '¿Cuánta angustia te genera?',
                    valor: _angustiaInicial,
                    onCambio: (v) => setState(() => _angustiaInicial = v),
                  ),
                ],
              ),
              PasoEjercicio(
                titulo: 'El peor y el mejor escenario',
                explicacion:
                    'Poner en palabras los extremos les quita fuerza. Escribe cómo '
                    'sería lo peor que imaginas y también lo mejor que podría pasar.',
                children: [
                  const Text('El peor escenario', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  CampoTexto(controller: _peor, pista: 'Ej: Pierdo mi empleo y nadie me apoya.'),
                  const SizedBox(height: 16),
                  const Text('El mejor escenario', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  CampoTexto(controller: _mejor, pista: 'Ej: El dolor baja con mi tratamiento.'),
                ],
              ),
              PasoEjercicio(
                titulo: 'El escenario más probable',
                explicacion:
                    'Entre los dos extremos suele estar lo que de verdad pasa. '
                    'Piensa en cómo han ido otras veces situaciones parecidas.',
                children: [
                  CampoTexto(
                    controller: _probable,
                    pista: 'Ej: Será un día difícil, pediré ajustes en el trabajo y descansaré.',
                  ),
                  const SizedBox(height: 20),
                  SliderPorcentaje(
                    titulo: '¿Qué tan probable es el peor escenario?',
                    valor: _probabilidadPeor,
                    onCambio: (v) => setState(() => _probabilidadPeor = v),
                  ),
                ],
              ),
              PasoEjercicio(
                titulo: 'Tu plan si pasa lo difícil',
                explicacion:
                    'Aunque lo difícil ocurra, no estás sin recursos. Anota qué harías '
                    'y a quién podrías pedir ayuda.',
                children: [
                  CampoTexto(
                    controller: _plan,
                    pista: 'Ej: Hablaría con mi jefa, tomaría mi medicación y llamaría a una amiga.',
                  ),
                ],
              ),
              PasoEjercicio(
                titulo: 'Cómo te sientes ahora',
                explicacion: 'Vuelve a mirar tu miedo después de este recorrido.',
                children: [
                  SliderPorcentaje(
                    titulo: '¿Cuánta angustia sientes ahora?',
                    valor: _angustiaFinal,
                    onCambio: (v) => setState(() => _angustiaFinal = v),
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
    final bajo = _angustiaInicial.round() - _angustiaFinal.round();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tu registro', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TarjetaResumen(etiqueta: 'Tu miedo', texto: _miedo.text.trim()),
          const SizedBox(height: 10),
          TarjetaResumen(
            etiqueta: 'Escenario más probable (peor: ${_probabilidadPeor.round()}%)',
            texto: _probable.text.trim(),
            destacada: true,
          ),
          const SizedBox(height: 10),
          TarjetaResumen(etiqueta: 'Mi plan', texto: _plan.text.trim()),
          const SizedBox(height: 14),
          Text(
            bajo > 0
                ? 'Tu angustia bajó de ${_angustiaInicial.round()}% a ${_angustiaFinal.round()}%.'
                : 'Tu angustia pasó de ${_angustiaInicial.round()}% a ${_angustiaFinal.round()}%. '
                    'Está bien: a veces calmarse toma práctica.',
            style: const TextStyle(fontSize: 14.5),
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
