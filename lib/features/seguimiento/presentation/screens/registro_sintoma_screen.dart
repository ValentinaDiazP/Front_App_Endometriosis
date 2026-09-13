import 'package:flutter/material.dart';
import '../../data/mock_seguimiento_data.dart';
import '../../models/informacion_personal.dart';
import '../../models/localizacion_dolor.dart';
import '../../models/registro_sintoma.dart';
import '../../models/sintoma_asociado.dart';
import '../widgets/dolor_scale_slider.dart';
import '../widgets/localizacion_selector.dart';
import '../widgets/sintoma_chip.dart';

/// Segunda pantalla del flujo de Seguimiento: registra intensidad de dolor,
/// localización y síntomas asociados en un solo formulario con scroll.
///
/// Recibe `informacionPersonal` como parámetro del constructor (mismo
/// patrón que usa Educativo en ContenidoDetailScreen/EjercicioDetailScreen),
/// en vez de leerlo de `ModalRoute.of(context)`. Esto evita depender de que
/// `AppRouter._page()` reenvíe los `RouteSettings` originales, y hace que
/// el compilador garantice que este dato siempre esté disponible.
class RegistroSintomaScreen extends StatefulWidget {
  final InformacionPersonal informacionPersonal;

  /// Callback opcional para cuando la usuaria elige "Volver al inicio".
  /// Se usa en vez de Navigator.pop() porque, al vivir esta pantalla como
  /// una pestaña dentro de MainNavigationHub (no como ruta empujada), no
  /// siempre hay una pantalla anterior a la cual regresar.
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
  LocalizacionDolor? _localizacionSeleccionada;
  final Set<SintomaAsociado> _sintomasSeleccionados = {};
  final _observacionController = TextEditingController();

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
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
    if (_localizacionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la localización del dolor'),
        ),
      );
      return;
    }

    final registro = RegistroSintoma(
      // TODO(backend): generar el id real al persistir en el servidor.
      id: 'registro_demo',
      usuarioId: widget.informacionPersonal.usuarioId,
      fechaHora: DateTime.now(),
      intensidadDolor: _intensidadDolor,
      localizacion: _localizacionSeleccionada!,
      sintomasAsociados: _sintomasSeleccionados.toList(),
      observacion: _observacionController.text.trim().isEmpty
          ? null
          : _observacionController.text.trim(),
    );

    // TODO(backend): enviar `registro` a la API en vez de solo mostrarlo.
    _mostrarConfirmacion(registro);
  }

  /// Diálogo mostrado tras guardar un registro. Ofrece dos caminos: seguir
  /// registrando (útil si la usuaria quiere anotar varios síntomas seguidos)
  /// o volver a la pantalla anterior, en vez de dejarla "varada" aquí.
  void _mostrarConfirmacion(RegistroSintoma registro) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('¡Registro guardado!'),
          content: Text(
            'Dolor ${registro.intensidadDolor}/10 en '
            '${registro.localizacion.nombre}.',
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
              child: const Text('Volver al inicio'),
            ),
          ],
        );
      },
    );
  }

  /// Limpia el formulario para permitir un nuevo registro sin salir de
  /// la pantalla.
  void _reiniciarFormulario() {
    setState(() {
      _intensidadDolor = 0;
      _localizacionSeleccionada = null;
      _sintomasSeleccionados.clear();
      _observacionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de síntomas')),
      body: Padding(
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
            DolorScaleSlider(
              value: _intensidadDolor,
              onChanged: (nuevoValor) {
                setState(() => _intensidadDolor = nuevoValor);
              },
            ),
            const SizedBox(height: 24),
            LocalizacionSelector(
              localizaciones: MockSeguimientoData.localizaciones,
              seleccionada: _localizacionSeleccionada,
              onSelected: (localizacion) {
                setState(() => _localizacionSeleccionada = localizacion);
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
      ),
    );
  }
}