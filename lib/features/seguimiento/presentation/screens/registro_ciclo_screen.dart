import 'package:flutter/material.dart';
import '../../../../core/services/sintomas_service.dart';
import '../../models/registro_ciclo.dart';
import '../widgets/abundancia_selector.dart';
import '../widgets/calendario_menstrual.dart';

/// Registro de ciclo y sangrado contra la API real: calendario, formulario
/// de nuevo ciclo (o edición de uno existente) y lista de ciclos guardados
/// con opciones de editar y eliminar.
class RegistroCicloScreen extends StatefulWidget {
  final String token;

  const RegistroCicloScreen({super.key, required this.token});

  @override
  State<RegistroCicloScreen> createState() => _RegistroCicloScreenState();
}

class _RegistroCicloScreenState extends State<RegistroCicloScreen> {
  List<RegistroCiclo> _registros = [];
  bool _cargando = true;
  String? _errorCarga;
  bool _guardando = false;
  DateTime _mesEnfocado = DateTime.now();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  AbundanciaSangrado? _abundancia;

  /// Id del ciclo en edición, o null si el formulario está creando uno
  /// nuevo (el mismo formulario sirve para crear y editar).
  String? _editandoId;

  @override
  void initState() {
    super.initState();
    _cargarInicial();
  }

  Future<void> _cargarInicial() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    try {
      final lista = await SintomasService.obtenerCiclos(widget.token);
      if (!mounted) return;
      setState(() {
        _registros = lista;
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

  /// Vuelve a pedir la lista sin mostrar el spinner de pantalla completa,
  /// para no perder lo que la usuaria tenga escrito en el formulario.
  Future<void> _recargarLista() async {
    final lista = await SintomasService.obtenerCiclos(widget.token);
    if (!mounted) return;
    setState(() => _registros = lista);
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

  Future<void> _guardarCiclo() async {
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
    setState(() => _guardando = true);
    try {
      if (editando) {
        await SintomasService.actualizarCiclo(
          token: widget.token,
          id: _editandoId!,
          inicio: _fechaInicio!,
          fin: _fechaFin,
          abundancia: _abundancia!,
        );
      } else {
        await SintomasService.crearCiclo(
          token: widget.token,
          inicio: _fechaInicio!,
          fin: _fechaFin,
          abundancia: _abundancia!,
        );
      }
      await _recargarLista();
      if (!mounted) return;
      setState(_limpiarFormulario);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(editando ? 'Ciclo actualizado' : 'Ciclo registrado')),
      );
    } catch (e) {
      if (!mounted) return;
      final mensaje = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
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

    if (confirmar != true) return;

    try {
      await SintomasService.eliminarCiclo(token: widget.token, id: registro.id);
      await _recargarLista();
      if (!mounted) return;
      if (_editandoId == registro.id) setState(_limpiarFormulario);
    } catch (e) {
      if (!mounted) return;
      final mensaje = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    }
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
                onPressed: _cargarInicial,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

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
                  onPressed: _guardando ? null : _guardarCiclo,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _editandoId != null ? 'Actualizar ciclo' : 'Guardar ciclo',
                        ),
                ),
              ),
              if (_editandoId != null) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _guardando ? null : () => setState(_limpiarFormulario),
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
/// ya tiene un valor, muestra un botón "✕" para borrarlo.
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