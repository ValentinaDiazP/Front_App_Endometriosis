import 'package:flutter/material.dart';
import '../../../../core/services/sintomas_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/informacion_personal.dart';
import '../../models/localizacion_dolor.dart';
import '../../models/registro_sintoma.dart';
import '../../models/sintoma_asociado.dart';
import '../widgets/dolor_scale_slider.dart';
import '../widgets/localizacion_selector.dart';
import '../widgets/sintoma_chip.dart';

/// Segunda pestaña de Seguimiento: registra localización(es) del dolor,
/// intensidad, síntomas asociados y observación, contra la API real.
///
/// Si hay dolor (alguna zona distinta de "Ninguno") se muestran además
/// "Otros tipos de dolor" (texto abierto) y la medicación. Si no hay dolor,
/// esas preguntas se ocultan y la intensidad queda deshabilitada.
///
/// Los catálogos (localizaciones, síntomas) se cargan desde el backend al
/// abrir la pantalla. "Otro" y "Ninguno" son un truco del frontend (no
/// existen en la base de datos), así que se agregan a mano después.
class RegistroSintomaScreen extends StatefulWidget {
  final InformacionPersonal informacionPersonal;
  final String token;

  /// Callback opcional para "Regresar" (ver seguimiento_home_screen.dart).
  final VoidCallback? onFinalizado;

  const RegistroSintomaScreen({
    super.key,
    required this.informacionPersonal,
    required this.token,
    this.onFinalizado,
  });

  @override
  State<RegistroSintomaScreen> createState() => _RegistroSintomaScreenState();
}

class _RegistroSintomaScreenState extends State<RegistroSintomaScreen> {
  int _intensidadDolor = 0;
  final Set<LocalizacionDolor> _localizacionesSeleccionadas = {};
  final Set<SintomaAsociado> _sintomasSeleccionados = {};
  final _observacionController = TextEditingController();
  final _otroController = TextEditingController();
  final _otrosTiposController = TextEditingController();
  final _medicacionController = TextEditingController();
  bool? _tomoMedicacion; // null = no respondió
  String? _alivio; // nada | algo | mucho

  List<LocalizacionDolor> _localizacionesCatalogo = [];
  List<SintomaAsociado> _sintomasCatalogo = [];
  bool _cargando = true;
  String? _errorCarga;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    try {
      final localizaciones =
          await SintomasService.obtenerLocalizaciones(widget.token);
      final sintomas = await SintomasService.obtenerSintomas(widget.token);
      if (!mounted) return;
      setState(() {
        _localizacionesCatalogo = [
          ...localizaciones,
          const LocalizacionDolor(id: LocalizacionDolor.idOtro, nombre: 'Otro'),
          const LocalizacionDolor(id: LocalizacionDolor.idNinguno, nombre: 'Ninguno'),
        ];
        _sintomasCatalogo = sintomas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCarga = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  @override
  void dispose() {
    _observacionController.dispose();
    _otroController.dispose();
    _otrosTiposController.dispose();
    _medicacionController.dispose();
    super.dispose();
  }

  bool get _dolorHabilitado =>
      _localizacionesSeleccionadas.any((l) => !l.esNinguno);

  bool get _marcoNinguno =>
      _localizacionesSeleccionadas.any((l) => l.esNinguno);

  void _toggleLocalizacion(LocalizacionDolor localizacion) {
    setState(() {
      if (localizacion.esNinguno) {
        if (_localizacionesSeleccionadas.contains(localizacion)) {
          _localizacionesSeleccionadas.remove(localizacion);
        } else {
          _localizacionesSeleccionadas
            ..clear()
            ..add(localizacion);
          _otroController.clear();
        }
      } else {
        _localizacionesSeleccionadas.removeWhere((l) => l.esNinguno);
        if (_localizacionesSeleccionadas.contains(localizacion)) {
          _localizacionesSeleccionadas.remove(localizacion);
          if (localizacion.esOtro) _otroController.clear();
        } else {
          _localizacionesSeleccionadas.add(localizacion);
        }
      }

      if (!_dolorHabilitado) {
        _intensidadDolor = 0;
      }
    });
  }

  void _toggleSintoma(SintomaAsociado sintoma, bool seleccionado) {
    setState(() {
      if (seleccionado) {
        _sintomasSeleccionados.add(sintoma);
      } else {
        _sintomasSeleccionados.remove(sintoma);
      }
    });
  }

  String? _textoONull(String texto) {
    final limpio = texto.trim();
    return limpio.isEmpty ? null : limpio;
  }

  Future<void> _guardarRegistro() async {
    if (_localizacionesSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una localización (o "Ninguno")'),
        ),
      );
      return;
    }

    final incluyeOtro = _localizacionesSeleccionadas.any((l) => l.esOtro);
    if (incluyeOtro && _otroController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Especifica la zona en "Otro"')),
      );
      return;
    }

    // Otros tipos de dolor y medicación solo aplican si hubo dolor.
    final hayDolor = _dolorHabilitado;
    final tomo = hayDolor ? _tomoMedicacion : null;

    final registro = RegistroSintoma(
      id: 'pendiente', // el id real lo asigna el backend al guardar
      usuarioId: widget.informacionPersonal.usuarioId,
      fechaHora: DateTime.now(),
      intensidadDolor: _intensidadDolor,
      localizaciones: _localizacionesSeleccionadas.toList(),
      localizacionOtroDetalle:
          incluyeOtro ? _otroController.text.trim() : null,
      sintomasAsociados: _sintomasSeleccionados.toList(),
      observacion: _textoONull(_observacionController.text),
      otrosTiposDolor:
          hayDolor ? _textoONull(_otrosTiposController.text) : null,
      tomoMedicacion: tomo,
      medicacionDetalle:
          tomo == true ? _textoONull(_medicacionController.text) : null,
      alivioMedicacion: tomo == true ? _alivio : null,
    );

    setState(() => _guardando = true);
    try {
      await SintomasService.guardarRegistro(token: widget.token, registro: registro);
      if (!mounted) return;
      _mostrarConfirmacion(registro);
    } catch (e) {
      if (!mounted) return;
      final mensaje = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mostrarConfirmacion(RegistroSintoma registro) {
    final nombresLocalizaciones = registro.localizaciones
        .map((l) => l.esOtro
            ? (registro.localizacionOtroDetalle ?? 'Otro')
            : l.nombre)
        .join(', ');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('¡Registro guardado!'),
          content: Text(
            'Dolor ${registro.intensidadDolor}/10 en $nombresLocalizaciones.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _reiniciarFormulario();
              },
              child: const Text('Registrar otro'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (widget.onFinalizado != null) {
                  widget.onFinalizado!();
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Regresar'),
            ),
          ],
        );
      },
    );
  }

  void _reiniciarFormulario() {
    setState(() {
      _intensidadDolor = 0;
      _localizacionesSeleccionadas.clear();
      _sintomasSeleccionados.clear();
      _observacionController.clear();
      _otroController.clear();
      _otrosTiposController.clear();
      _medicacionController.clear();
      _tomoMedicacion = null;
      _alivio = null;
    });
  }

  Widget _seccionDolor(BuildContext context) {
    final titulo = Theme.of(context).textTheme.titleMedium;
    final ayuda = Theme.of(context).textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Otros tipos de dolor', style: titulo),
        const SizedBox(height: 4),
        Text(
          'Escribe los que sentiste. Le ayudan a tu médica a entender tu caso. '
          '(Ejemplo: al orinar, al tener relaciones sexuales, …)',
          style: ayuda,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _otrosTiposController,
          maxLength: 300,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Opcional',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text('¿Tomaste algo para el dolor?', style: titulo),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          emptySelectionAllowed: true,
          segments: const [
            ButtonSegment(value: true, label: Text('Sí')),
            ButtonSegment(value: false, label: Text('No')),
          ],
          selected: _tomoMedicacion == null ? <bool>{} : {_tomoMedicacion!},
          onSelectionChanged: (s) =>
              setState(() => _tomoMedicacion = s.isEmpty ? null : s.first),
        ),
        if (_tomoMedicacion == true) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _medicacionController,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: '¿Qué tomaste? (por ejemplo: ibuprofeno)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text('¿Te ayudó?', style: titulo),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            emptySelectionAllowed: true,
            segments: const [
              ButtonSegment(value: 'nada', label: Text('Nada')),
              ButtonSegment(value: 'algo', label: Text('Algo')),
              ButtonSegment(value: 'mucho', label: Text('Mucho')),
            ],
            selected: _alivio == null ? <String>{} : {_alivio!},
            onSelectionChanged: (s) =>
                setState(() => _alivio = s.isEmpty ? null : s.first),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Solo anotamos lo que tomaste. No es una recomendación: '
          'consulta con tu médica antes de cambiar algo.',
          style: ayuda,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorCarga != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorCarga!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargarCatalogos,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final incluyeOtro = _localizacionesSeleccionadas.any((l) => l.esOtro);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Text(
            'Hola, ${widget.informacionPersonal.nombre}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '¿Cómo te sientes hoy?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          LocalizacionSelector(
            localizaciones: _localizacionesCatalogo,
            seleccionadas: _localizacionesSeleccionadas,
            onToggle: _toggleLocalizacion,
          ),
          if (incluyeOtro) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _otroController,
              decoration: const InputDecoration(
                labelText: 'Especifica la zona',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          DolorScaleSlider(
            value: _intensidadDolor,
            enabled: _dolorHabilitado,
            onChanged: (nuevoValor) {
              setState(() => _intensidadDolor = nuevoValor);
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Síntomas asociados',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sintomasCatalogo.map((sintoma) {
              return SintomaChip(
                sintoma: sintoma,
                seleccionado: _sintomasSeleccionados.contains(sintoma),
                onSelected: (seleccionado) =>
                    _toggleSintoma(sintoma, seleccionado),
              );
            }).toList(),
          ),
          if (_dolorHabilitado) _seccionDolor(context),
          if (_marcoNinguno) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Como hoy no tuviste dolor, te saltamos las preguntas sobre '
                'otros tipos de dolor y medicación.',
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _observacionController,
            decoration: const InputDecoration(
              labelText: 'Observación (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _guardando ? null : _guardarRegistro,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _guardando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Guardar registro'),
          ),
          const SizedBox(height: 10),
          Text(
            'Guardar un registro, también sin dolor, cuenta para tu racha.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}