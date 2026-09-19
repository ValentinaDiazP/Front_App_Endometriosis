import 'package:flutter/material.dart';
import '../../data/mock_seguimiento_data.dart';
import '../../models/informacion_personal.dart';
import '../../models/localizacion_dolor.dart';
import '../../models/registro_sintoma.dart';
import '../../models/sintoma_asociado.dart';
import '../widgets/dolor_scale_slider.dart';
import '../widgets/localizacion_selector.dart';
import '../widgets/sintoma_chip.dart';

/// Segunda pantalla del flujo de Seguimiento: registra localización(es) del
/// dolor, intensidad, síntomas asociados y observación en un formulario con
/// scroll.
///
/// La intensidad de dolor solo se habilita si hay al menos una zona real
/// seleccionada (ver `_dolorHabilitado`) — no tiene sentido calificar un
/// dolor que la usuaria no reportó. "Ninguno" es mutuamente excluyente con
/// cualquier otra zona; "Otro" habilita un campo de texto libre.
class RegistroSintomaScreen extends StatefulWidget {
  final InformacionPersonal informacionPersonal;

  /// Callback opcional para "Regresar". Se usa en vez de Navigator.pop()
  /// porque, al vivir esta pantalla como una pestaña dentro de
  /// MainNavigationHub (no como ruta empujada), no siempre hay una
  /// pantalla anterior a la cual regresar.
  final VoidCallback? onFinalizado;

  const RegistroSintomaScreen({
    super.key,
    required this.informacionPersonal,
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

  @override
  void dispose() {
    _observacionController.dispose();
    _otroController.dispose();
    super.dispose();
  }

  /// La intensidad de dolor solo aplica si hay al menos una zona real
  /// seleccionada (una zona concreta u "Otro"); "Ninguno" no cuenta.
  bool get _dolorHabilitado =>
      _localizacionesSeleccionadas.any((l) => !l.esNinguno);

  void _toggleLocalizacion(LocalizacionDolor localizacion) {
    setState(() {
      if (localizacion.esNinguno) {
        if (_localizacionesSeleccionadas.contains(localizacion)) {
          _localizacionesSeleccionadas.remove(localizacion);
        } else {
          // "Ninguno" reemplaza cualquier otra selección existente.
          _localizacionesSeleccionadas
            ..clear()
            ..add(localizacion);
          _otroController.clear();
        }
      } else {
        // Elegir una zona real (o "Otro") descarta "Ninguno" automáticamente.
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

  void _guardarRegistro() {
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
      // TODO(backend): generar el id real al persistir en el servidor.
      id: 'registro_demo',
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

    // TODO(backend): enviar `registro` a la API en vez de solo mostrarlo.
    _mostrarConfirmacion(registro);
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
    final incluyeOtro =
        _localizacionesSeleccionadas.any((l) => l.esOtro);

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
              localizaciones: MockSeguimientoData.localizaciones,
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
              children: MockSeguimientoData.sintomas.map((sintoma) {
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
              onPressed: _guardarRegistro,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Guardar registro'),
            ),
          ],
        ),
      );
  }
}