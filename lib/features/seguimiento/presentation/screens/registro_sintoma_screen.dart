import 'package:flutter/material.dart';
import '../../../../core/services/sintomas_service.dart';
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
/// Los catálogos (localizaciones, síntomas) ya no vienen de mock — se
/// cargan desde el backend al abrir la pantalla. "Otro" y "Ninguno" siguen
/// siendo un truco del frontend (no existen en la base de datos), así que
/// se agregan a mano después de traer el catálogo real.
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
    super.dispose();
  }

  bool get _dolorHabilitado =>
      _localizacionesSeleccionadas.any((l) => !l.esNinguno);

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

    final registro = RegistroSintoma(
      id: 'pendiente', // el id real lo asigna el backend al guardar
      usuarioId: widget.informacionPersonal.usuarioId,
      fechaHora: DateTime.now(),
      intensidadDolor: _intensidadDolor,
      localizaciones: _localizacionesSeleccionadas.toList(),
      localizacionOtroDetalle:
          incluyeOtro ? _otroController.text.trim() : null,
      sintomasAsociados: _sintomasSeleccionados.toList(),
      observacion: _observacionController.text.trim().isEmpty
          ? null
          : _observacionController.text.trim(),
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
    });
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
        ],
      ),
    );
  }
}