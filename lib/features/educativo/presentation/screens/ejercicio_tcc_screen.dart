import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/educativo_repository.dart';
import '../../models/ejercicio_psicoeducativo.dart';
import '../widgets/calificacion_utilidad.dart';
import '../widgets/modulo_progreso_header.dart';
import '../../../../core/theme/app_theme.dart';

/// Ejercicio interactivo de TCC: registro de pensamientos en 4 pasos
/// (situación → pensamiento → evidencias → versión balanceada).
///
/// Al guardar crea un RegistroEjercicio con lo que escribió la usuaria en
/// `respuestas` (JSON) y su calificación en `utilidad`.
class EjercicioTccScreen extends StatefulWidget {
  final EjercicioPsicoeducativo ejercicio;
  const EjercicioTccScreen({super.key, required this.ejercicio});

  @override
  State<EjercicioTccScreen> createState() => _EjercicioTccScreenState();
}

class _EjercicioTccScreenState extends State<EjercicioTccScreen> {
  static const _totalPasos = 4;

  final _controller = PageController();
  final _situacion = TextEditingController();
  final _pensamiento = TextEditingController();
  final _aFavor = TextEditingController();
  final _enContra = TextEditingController();
  final _balanceado = TextEditingController();

  int _indice = 0;
  double _creenciaInicial = 80;
  double _creenciaFinal = 50;
  bool _enResumen = false;
  int? _utilidad;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_situacion, _pensamiento, _aFavor, _enContra, _balanceado]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final c in [_situacion, _pensamiento, _aFavor, _enContra, _balanceado]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Los pasos 2 y 4 (el pensamiento y su versión balanceada) son el
  /// corazón del ejercicio, así que no se puede avanzar con ellos vacíos.
  bool get _puedeAvanzar {
    if (_indice == 1) return _pensamiento.text.trim().isNotEmpty;
    if (_indice == 3) return _balanceado.text.trim().isNotEmpty;
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
      'situacion': _situacion.text.trim(),
      'pensamiento': _pensamiento.text.trim(),
      'creencia_inicial': _creenciaInicial.round(),
      'evidencia_a_favor': _aFavor.text.trim(),
      'evidencia_en_contra': _enContra.text.trim(),
      'pensamiento_balanceado': _balanceado.text.trim(),
      'creencia_final': _creenciaFinal.round(),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ejercicio guardado')),
    );
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
              _Paso(
                titulo: '¿Qué estaba pasando?',
                explicacion:
                    'Piensa en un momento reciente en que el dolor o la '
                    'endometriosis te hicieron sentir mal. Describe solo los '
                    'hechos, como si lo contara una cámara.',
                children: [
                  _Campo(
                    controller: _situacion,
                    pista: 'Ej: Me despertó el dolor y tuve que cancelar un plan.',
                  ),
                ],
              ),
              _Paso(
                titulo: '¿Qué pensaste en ese momento?',
                explicacion:
                    'Escribe el pensamiento tal como apareció. Los pensamientos '
                    'catastróficos suelen sonar a "siempre", "nunca" o "no voy a poder".',
                children: [
                  _Campo(controller: _pensamiento, pista: 'Ej: Esto nunca va a mejorar.'),
                  const SizedBox(height: 20),
                  _SliderCreencia(
                    titulo: '¿Cuánto te lo crees?',
                    valor: _creenciaInicial,
                    onCambio: (v) => setState(() => _creenciaInicial = v),
                  ),
                ],
              ),
              _Paso(
                titulo: 'Revisa las evidencias',
                explicacion:
                    'Mira el pensamiento como lo haría una amiga. No se trata de '
                    'negar lo difícil, sino de ver el cuadro completo.',
                children: [
                  const Text('¿Qué apoya ese pensamiento?',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _Campo(controller: _aFavor, pista: 'Ej: Esta semana el dolor ha sido fuerte.'),
                  const SizedBox(height: 16),
                  const Text('¿Qué no encaja con él?',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _Campo(
                    controller: _enContra,
                    pista: 'Ej: El mes pasado tuve varios días buenos.',
                  ),
                ],
              ),
              _Paso(
                titulo: 'Una forma más balanceada de verlo',
                explicacion:
                    'Con lo que revisaste, escribe una versión más justa contigo. '
                    'No tiene que ser positiva, solo más realista.',
                children: [
                  _Campo(
                    controller: _balanceado,
                    pista: 'Ej: Hoy es un día difícil, pero he tenido días mejores '
                        'y tengo herramientas para cuidarme.',
                  ),
                  const SizedBox(height: 20),
                  _SliderCreencia(
                    titulo: 'Ahora, ¿cuánto te crees el pensamiento original?',
                    valor: _creenciaFinal,
                    onCambio: (v) => setState(() => _creenciaFinal = v),
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
    final bajo = _creenciaInicial.round() - _creenciaFinal.round();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tu registro', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _Tarjeta(etiqueta: 'Pensamiento original', texto: _pensamiento.text.trim()),
          const SizedBox(height: 10),
          _Tarjeta(
            etiqueta: 'Versión balanceada',
            texto: _balanceado.text.trim(),
            destacada: true,
          ),
          const SizedBox(height: 14),
          Text(
            bajo > 0
                ? 'Tu creencia en el pensamiento original bajó de '
                    '${_creenciaInicial.round()}% a ${_creenciaFinal.round()}%.'
                : 'Tu creencia en el pensamiento original pasó de '
                    '${_creenciaInicial.round()}% a ${_creenciaFinal.round()}%. '
                    'Está bien: a veces cambiar la mirada toma práctica.',
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

class _Paso extends StatelessWidget {
  final String titulo;
  final String explicacion;
  final List<Widget> children;

  const _Paso({required this.titulo, required this.explicacion, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(explicacion, style: const TextStyle(color: Colors.black54, fontSize: 14.5)),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String pista;

  const _Campo({required this.controller, required this.pista});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 6,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: pista,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SliderCreencia extends StatelessWidget {
  final String titulo;
  final double valor;
  final ValueChanged<double> onCambio;

  const _SliderCreencia({required this.titulo, required this.valor, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600))),
            Text('${valor.round()}%',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ],
        ),
        Slider(value: valor, min: 0, max: 100, divisions: 20, onChanged: onCambio),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final String etiqueta;
  final String texto;
  final bool destacada;

  const _Tarjeta({required this.etiqueta, required this.texto, this.destacada = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: destacada ? AppTheme.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: destacada ? AppTheme.primary : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta.toUpperCase(),
              style: const TextStyle(fontSize: 11, letterSpacing: 0.6, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(texto, style: const TextStyle(fontSize: 15.5)),
        ],
      ),
    );
  }
}
