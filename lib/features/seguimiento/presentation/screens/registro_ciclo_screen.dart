import 'package:flutter/material.dart';
import '../../data/mock_ciclo_data.dart';
import '../../models/informacion_personal.dart';
import '../../models/registro_ciclo.dart';
import '../widgets/abundancia_selector.dart';
import '../widgets/calendario_menstrual.dart';

/// Registro de ciclo y sangrado: calendario menstrual, formulario de nuevo
/// ciclo (o edición de uno existente), y lista de ciclos ya registrados con
/// opciones de editar/eliminar. Mantiene su propia lista en memoria
/// (sembrada con MockCicloData) porque todavía no hay backend conectado.
class RegistroCicloScreen extends StatefulWidget {
  final InformacionPersonal informacionPersonal;

  const RegistroCicloScreen({super.key, required this.informacionPersonal});

  @override
  State<RegistroCicloScreen> createState() => _RegistroCicloScreenState();
}

class _RegistroCicloScreenState extends State<RegistroCicloScreen> {
  late List<RegistroCiclo> _registros;
  DateTime _mesEnfocado = DateTime.now();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  AbundanciaSangrado? _abundancia;

  /// Id del registro en edición, o null si el formulario está creando uno
  /// nuevo. Reutiliza el mismo formulario para crear y editar, en vez de
  /// duplicar la UI en un diálogo aparte.
  String? _editandoId;

  @override
  void initState() {
    super.initState();
    _registros =
        MockCicloData.seedInicial(widget.informacionPersonal.usuarioId);
  }

  Future<void> _seleccionarFecha({
    required DateTime? fechaActual,
    required DateTime? primeraFechaValida,
    required ValueChanged<DateTime> onFechaSeleccionada,
  }) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaActual ?? DateTime.now(),
      firstDate: primeraFechaValida ?? DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );
    if (fecha != null) onFechaSeleccionada(fecha);
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar fecha';
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  void _limpiarFormulario() {
    _fechaInicio = null;
    _fechaFin = null;
    _abundancia = null;
    _editandoId = null;
  }

  void _guardarCiclo() {
    if (_fechaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de inicio')),
      );
      return;
    }
    if (_fechaFin != null && _fechaFin!.isBefore(_fechaInicio!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha de fin no puede ser anterior al inicio'),
        ),
      );
      return;
    }
    if (_abundancia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la abundancia del sangrado')),
      );
      return;
    }

    final editando = _editandoId != null;

    setState(() {
      if (editando) {
        final index = _registros.indexWhere((r) => r.id == _editandoId);
        if (index != -1) {
          _registros[index] = RegistroCiclo(
            id: _editandoId!,
            usuarioId: widget.informacionPersonal.usuarioId,
            fechaInicio: _fechaInicio!,
            fechaFin: _fechaFin,
            abundancia: _abundancia!,
          );
        }
      } else {
        _registros.add(RegistroCiclo(
          // TODO(backend): generar el id real al persistir en el servidor.
          id: 'ciclo_${DateTime.now().microsecondsSinceEpoch}',
          usuarioId: widget.informacionPersonal.usuarioId,
          fechaInicio: _fechaInicio!,
          fechaFin: _fechaFin,
          abundancia: _abundancia!,
        ));
      }
      _limpiarFormulario();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(editando ? 'Ciclo actualizado' : 'Ciclo registrado')),
    );
  }

  void _editarRegistro(RegistroCiclo registro) {
    setState(() {
      _fechaInicio = registro.fechaInicio;
      _fechaFin = registro.fechaFin;
      _abundancia = registro.abundancia;
      _editandoId = registro.id;
    });
  }

  Future<void> _eliminarRegistro(RegistroCiclo registro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar este ciclo?'),
        content: Text(
          'Del ${_formatearFecha(registro.fechaInicio)} al '
          '${_formatearFecha(registro.fechaFin)}. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        _registros.removeWhere((r) => r.id == registro.id);
        if (_editandoId == registro.id) _limpiarFormulario();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrosOrdenados = [..._registros]
      ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calendario menstrual',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          CalendarioMenstrual(
            registros: _registros,
            mesEnfocado: _mesEnfocado,
            onMesCambiado: (nuevoMes) {
              setState(() => _mesEnfocado = nuevoMes);
            },
          ),
          const SizedBox(height: 24),
          Text(
            _editandoId != null ? 'Editando ciclo' : 'Registrar nuevo ciclo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _CampoFecha(
            etiqueta: 'Fecha de inicio',
            valor: _formatearFecha(_fechaInicio),
            tieneValor: _fechaInicio != null,
            onTap: () => _seleccionarFecha(
              fechaActual: _fechaInicio,
              primeraFechaValida: null,
              onFechaSeleccionada: (fecha) {
                setState(() => _fechaInicio = fecha);
              },
            ),
            onClear: () => setState(() => _fechaInicio = null),
          ),
          const SizedBox(height: 16),
          _CampoFecha(
            etiqueta: 'Fecha de fin (opcional, si el ciclo terminó)',
            valor: _formatearFecha(_fechaFin),
            tieneValor: _fechaFin != null,
            onTap: () => _seleccionarFecha(
              fechaActual: _fechaFin,
              primeraFechaValida: _fechaInicio,
              onFechaSeleccionada: (fecha) {
                setState(() => _fechaFin = fecha);
              },
            ),
            onClear: () => setState(() => _fechaFin = null),
          ),
          const SizedBox(height: 16),
          AbundanciaSelector(
            seleccionada: _abundancia,
            onSelected: (abundancia) {
              setState(() => _abundancia = abundancia);
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _guardarCiclo,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    _editandoId != null ? 'Actualizar ciclo' : 'Guardar ciclo',
                  ),
                ),
              ),
              if (_editandoId != null) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => setState(_limpiarFormulario),
                  child: const Text('Cancelar'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),
          Text('Ciclos registrados',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (registrosOrdenados.isEmpty)
            const Text('Todavía no has registrado ningún ciclo.')
          else
            ...registrosOrdenados.map(
              (registro) => Card(
                child: ListTile(
                  title: Text(
                    '${_formatearFecha(registro.fechaInicio)} - '
                    '${_formatearFecha(registro.fechaFin)}',
                  ),
                  subtitle: Text(registro.abundancia.etiqueta),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar',
                        onPressed: () => _editarRegistro(registro),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Eliminar',
                        onPressed: () => _eliminarRegistro(registro),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Campo de solo lectura que abre un selector de fecha al tocarlo. Cuando
/// ya tiene un valor, muestra un botón "✕" para borrarlo (volver a
/// "Seleccionar fecha") en vez del ícono de calendario.
class _CampoFecha extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool tieneValor;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _CampoFecha({
    required this.etiqueta,
    required this.valor,
    required this.tieneValor,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
          suffixIcon: tieneValor && onClear != null
              ? IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Borrar fecha',
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today),
        ),
        child: Text(valor),
      ),
    );
  }
}