import 'package:flutter/material.dart';
import '../../data/educativo_repository.dart';
import '../../data/modulos_psicoeducativos_mock.dart';
import '../../models/ejercicio_psicoeducativo.dart';
import '../../models/modulo_psicoeducativo.dart';
import '../widgets/boton_recurso_externo.dart';
import '../widgets/progreso_modulo_mini.dart';
import '../../../../core/theme/app_theme.dart';
import 'ejercicio_tcc_screen.dart';
import 'modulo_guiado_screen.dart';
import 'practica_guiada_screen.dart';

/// Formas en que se presenta un ejercicio según su tipo.
enum _Formato { modulo, tcc, practica, simple }

/// Pantalla de un ejercicio (portada). Según el tipo:
///
///  - Psicoeducación con módulo guiado: muestra qué se va a ver, el
///    progreso y un botón para comenzar, continuar o repasar.
///  - TCC: abre el registro de pensamientos (EjercicioTccScreen).
///  - ACT/Mindfulness: abre la práctica guiada con temporizador
///    (PracticaGuiadaScreen).
///  - Psicoeducación sin módulo: instrucciones y un botón de completar.
///
/// Si el ejercicio tiene un audio o video externo (`urlRecurso`), se
/// muestra un botón para abrirlo.
class EjercicioDetailScreen extends StatefulWidget {
  final EjercicioPsicoeducativo ejercicio;
  const EjercicioDetailScreen({super.key, required this.ejercicio});

  @override
  State<EjercicioDetailScreen> createState() => _EjercicioDetailScreenState();
}

class _EjercicioDetailScreenState extends State<EjercicioDetailScreen> {
  late final ModuloPsicoeducativo? _modulo =
      ModulosPsicoeducativosMock.deEjercicio(widget.ejercicio.idEjercicio);

  bool get _completado =>
      EducativoRepository.ejercicioCompletado(widget.ejercicio.idEjercicio);

  int get _pasosAlcanzados =>
      EducativoRepository.pasosAlcanzadosModulo(widget.ejercicio.idEjercicio);

  Future<void> _abrirModulo() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModuloGuiadoScreen(ejercicio: widget.ejercicio),
      ),
    );
    if (mounted) setState(() {}); // el progreso y el completado pudieron cambiar
  }

  bool _guardando = false;

  Future<void> _completarSimple() async {
    setState(() => _guardando = true);
    try {
      // Crea el RegistroEjercicio en el backend.
      // TODO: pedir respuestas y percepción de utilidad (el backend ya los
      // acepta como opcionales) y sumar puntos de gamificación.
      await EducativoRepository.marcarEjercicioCompletado(widget.ejercicio.idEjercicio);
      if (!mounted) return;
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

  String get _textoBotonModulo {
    if (_completado) return 'Repasar módulo';
    if (_pasosAlcanzados > 0) {
      return 'Continuar (paso $_pasosAlcanzados de ${_modulo!.totalPasos})';
    }
    return 'Comenzar módulo';
  }

  @override
  Widget build(BuildContext context) {
    final ejercicio = widget.ejercicio;
    final modulo = _modulo;

    return Scaffold(
      appBar: AppBar(title: Text(ejercicio.nombre)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(label: Text(ejercicio.tipo.label)),
                    const SizedBox(height: 16),
                    Text(ejercicio.descripcion,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${ejercicio.minutosEstimados} min',
                            style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (ejercicio.urlRecurso != null) ...[
                      BotonRecursoExterno(
                        url: ejercicio.urlRecurso!,
                        esAudio: ejercicio.tipo == TipoEjercicio.actMindfulness,
                      ),
                      const SizedBox(height: 16),
                    ],
                    ...switch (_formato) {
                      _Formato.modulo => _contenidoModulo(modulo!),
                      _Formato.tcc => _contenidoInteractivo(ejercicio, const [
                          'Describes una situación difícil reciente.',
                          'Escribes el pensamiento que apareció y cuánto te lo crees.',
                          'Revisas qué lo apoya y qué no encaja con él.',
                          'Escribes una versión más balanceada.',
                        ]),
                      _Formato.practica => _contenidoInteractivo(ejercicio, [
                          'Un temporizador de ${ejercicio.minutosEstimados} minutos.',
                          'Indicaciones que van cambiando para guiarte.',
                          'Puedes pausar o terminar cuando quieras.',
                          'Al final nos cuentas qué tan útil te resultó.',
                        ]),
                      _Formato.simple => _contenidoSimple(ejercicio),
                    },
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: _botonPrincipal()),
          ],
        ),
      ),
    );
  }

  _Formato get _formato {
    if (_modulo != null) return _Formato.modulo;
    switch (widget.ejercicio.tipo) {
      case TipoEjercicio.tcc:
        return _Formato.tcc;
      case TipoEjercicio.actMindfulness:
        return _Formato.practica;
      case TipoEjercicio.psicoeducacion:
        return _Formato.simple;
    }
  }

  Future<void> _abrir(Widget pantalla) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
    if (mounted) setState(() {}); // el completado pudo cambiar
  }

  Widget _botonPrincipal() {
    final ejercicio = widget.ejercicio;
    switch (_formato) {
      case _Formato.modulo:
        return FilledButton.icon(
          onPressed: _abrirModulo,
          icon: Icon(_completado ? Icons.replay : Icons.play_arrow_rounded),
          label: Text(_textoBotonModulo),
        );
      case _Formato.tcc:
        return FilledButton.icon(
          onPressed: () => _abrir(EjercicioTccScreen(ejercicio: ejercicio)),
          icon: Icon(_completado ? Icons.replay : Icons.edit_note_rounded),
          label: Text(_completado ? 'Hacer de nuevo' : 'Comenzar ejercicio'),
        );
      case _Formato.practica:
        return FilledButton.icon(
          onPressed: () => _abrir(PracticaGuiadaScreen(ejercicio: ejercicio)),
          icon: Icon(_completado ? Icons.replay : Icons.self_improvement),
          label: Text(_completado ? 'Practicar de nuevo' : 'Comenzar práctica'),
        );
      case _Formato.simple:
        return FilledButton(
          onPressed: _completado || _guardando ? null : _completarSimple,
          child: Text(_completado ? 'Ya completado' : 'Completar ejercicio'),
        );
    }
  }

  /// Portada de los ejercicios interactivos (TCC y ACT/Mindfulness).
  List<Widget> _contenidoInteractivo(EjercicioPsicoeducativo ejercicio, List<String> comoFunciona) {
    return [
      if (_completado) ...[
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle, size: 18, color: Colors.green),
            SizedBox(width: 6),
            Expanded(
              child: Text('Ya lo hiciste al menos una vez. Puedes repetirlo cuando quieras.',
                  style: TextStyle(fontSize: 13, color: Colors.green)),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
      const Text('Cómo funciona', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      for (int i = 0; i < comoFunciona.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: AppTheme.primaryLight,
                child: Text('${i + 1}', style: const TextStyle(fontSize: 11, color: AppTheme.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(comoFunciona[i])),
            ],
          ),
        ),
      const SizedBox(height: 12),
      const Text('Instrucciones', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(ejercicio.instrucciones),
      const SizedBox(height: 12),
      const Text(
        'Este ejercicio no reemplaza la atención de tu profesional de salud.',
        style: TextStyle(fontSize: 12, color: Colors.black45),
      ),
    ];
  }

  List<Widget> _contenidoSimple(EjercicioPsicoeducativo ejercicio) {
    return [
      const Text('Instrucciones', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(ejercicio.instrucciones),
    ];
  }

  List<Widget> _contenidoModulo(ModuloPsicoeducativo modulo) {
    return [
      ProgresoModuloMini(
        pasosAlcanzados: _pasosAlcanzados,
        totalPasos: modulo.totalPasos,
        completado: _completado,
      ),
      const SizedBox(height: 20),
      const Text('Qué vas a ver', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      for (int i = 0; i < modulo.totalPasos; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: (_completado || i < _pasosAlcanzados)
                    ? AppTheme.primary
                    : AppTheme.primaryLight,
                child: (_completado || i < _pasosAlcanzados)
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : Text('${i + 1}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(modulo.pasos[i].titulo)),
            ],
          ),
        ),
      const SizedBox(height: 12),
      const Text(
        'Este contenido es informativo y no reemplaza la atención de tu '
        'profesional de salud.',
        style: TextStyle(fontSize: 12, color: Colors.black45),
      ),
    ];
  }
}
