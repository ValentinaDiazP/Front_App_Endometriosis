import 'package:flutter/material.dart';
import '../../models/informacion_personal.dart';
import '../../seguimiento_routes.dart';

/// Primera pantalla del flujo de Seguimiento: captura los datos personales
/// básicos (nombre, fecha de nacimiento, fecha de diagnóstico) antes de
/// pasar al registro de síntomas.
///
/// Es `StatefulWidget` porque maneja el estado del formulario (controlador
/// de texto y fechas seleccionadas) mientras la usuaria lo diligencia.
class InformacionPersonalScreen extends StatefulWidget {
  /// Callback opcional ejecutado al presionar "Continuar", con los datos
  /// ya validados. Si es null, se usa el comportamiento por defecto
  /// (navegar a SeguimientoRoutes.registroSintoma). Se usa un callback en
  /// vez de una navegación fija para que esta pantalla se pueda reutilizar
  /// desde fuera del módulo (por ejemplo, desde el flujo de onboarding en
  /// main.dart) sin que este archivo tenga que importar pantallas ajenas
  /// al módulo de Seguimiento.
  final void Function(BuildContext context, InformacionPersonal informacionPersonal)?
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

  void _continuar() {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tu fecha de nacimiento')),
      );
      return;
    }

    final informacionPersonal = InformacionPersonal(
      // TODO(backend): reemplazar por el id real de la usuaria autenticada.
      usuarioId: 'usuario_demo',
      nombre: _nombreController.text.trim(),
      fechaNacimiento: _fechaNacimiento!,
      fechaDiagnostico: _fechaDiagnostico,
    );

    if (widget.onContinuar != null) {
      widget.onContinuar!(context,informacionPersonal);
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
                onTap: () => _seleccionarFecha(
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
                onTap: () => _seleccionarFecha(
                  context: context,
                  fechaActual: _fechaDiagnostico,
                  onFechaSeleccionada: (fecha) {
                    setState(() => _fechaDiagnostico = fecha);
                  },
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _continuar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo de solo lectura que abre un selector de fecha al tocarlo. Se
/// extrae como widget privado porque se repite dos veces en esta pantalla
/// (fecha de nacimiento y fecha de diagnóstico) con el mismo comportamiento.
class _CampoFecha extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final VoidCallback onTap;

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