import 'package:flutter/material.dart';
import '../../models/informacion_personal.dart';
import '../../seguimiento_routes.dart';

/// Primera pantalla del flujo de Seguimiento: captura los datos personales
/// básicos (nombre, fecha de nacimiento, fecha de diagnóstico) antes de
/// pasar al registro de síntomas.
class InformacionPersonalScreen extends StatefulWidget {
  /// Callback ejecutado al presionar "Continuar". Devuelve un `Future`
  /// porque, cuando se usa desde el onboarding real, aquí es donde se
  /// hace la llamada HTTP de registro contra el backend — esta pantalla
  /// espera esa respuesta para mostrar un error si falla (por ejemplo,
  /// "usuario ya existe"), en vez de avanzar a ciegas.
  final Future<void> Function(BuildContext context, InformacionPersonal informacionPersonal)?
      onContinuar;

  const InformacionPersonalScreen({super.key, this.onContinuar});

  @override
  State<InformacionPersonalScreen> createState() =>
      _InformacionPersonalScreenState();
}

class _InformacionPersonalScreenState
    extends State<InformacionPersonalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();

  DateTime? _fechaNacimiento;
  DateTime? _fechaDiagnostico;
  bool _enviando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha({
    required BuildContext context,
    required DateTime? fechaActual,
    required ValueChanged<DateTime> onFechaSeleccionada,
  }) async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaActual ?? DateTime(ahora.year - 20),
      firstDate: DateTime(1930),
      lastDate: ahora,
    );
    if (fecha != null) {
      onFechaSeleccionada(fecha);
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar fecha';
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  Future<void> _continuar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tu fecha de nacimiento')),
      );
      return;
    }

    final informacionPersonal = InformacionPersonal(
      // Se reemplaza por el id real que devuelva el backend tras
      // registrar exitosamente (ver DiagnosisScreen._navigateToNext).
      usuarioId: 'usuario_demo',
      nombre: _nombreController.text.trim(),
      fechaNacimiento: _fechaNacimiento!,
      fechaDiagnostico: _fechaDiagnostico,
    );

    if (widget.onContinuar != null) {
      setState(() => _enviando = true);
      try {
        await widget.onContinuar!(context, informacionPersonal);
      } catch (e) {
        if (!mounted) return;
        final mensaje = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje)),
        );
      } finally {
        if (mounted) setState(() => _enviando = false);
      }
    } else {
      Navigator.pushNamed(
        context,
        SeguimientoRoutes.registroSintoma,
        arguments: informacionPersonal,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Información personal')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Cuéntanos un poco sobre ti',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Esta información nos ayuda a personalizar tu seguimiento.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nombreController,
                enabled: !_enviando,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Por favor ingresa tu nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _CampoFecha(
                etiqueta: 'Fecha de nacimiento',
                valor: _formatearFecha(_fechaNacimiento),
                onTap: _enviando
                    ? null
                    : () => _seleccionarFecha(
                          context: context,
                          fechaActual: _fechaNacimiento,
                          onFechaSeleccionada: (fecha) {
                            setState(() => _fechaNacimiento = fecha);
                          },
                        ),
              ),
              const SizedBox(height: 20),
              _CampoFecha(
                etiqueta: 'Fecha de diagnóstico (opcional)',
                valor: _formatearFecha(_fechaDiagnostico),
                onTap: _enviando
                    ? null
                    : () => _seleccionarFecha(
                          context: context,
                          fechaActual: _fechaDiagnostico,
                          onFechaSeleccionada: (fecha) {
                            setState(() => _fechaDiagnostico = fecha);
                          },
                        ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _enviando ? null : _continuar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _enviando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo de solo lectura que abre un selector de fecha al tocarlo.
class _CampoFecha extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final VoidCallback? onTap;

  const _CampoFecha({
    required this.etiqueta,
    required this.valor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(valor),
      ),
    );
  }
}