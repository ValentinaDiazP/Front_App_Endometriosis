import 'package:flutter/material.dart';
import '../../../../core/services/sintomas_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/registro_emocional.dart';

/// Check-in diario: un registro por día, que se carga pre-lleno si ya
/// existe el de hoy (modo edición), o vacío si es la primera vez.
///
/// Solo el ánimo es obligatorio. Energía, sueño, estrés y capacidad del día
/// son opcionales: tocar de nuevo una opción ya elegida la desmarca.
class RegistroEmocionalScreen extends StatefulWidget {
  final String token;

  const RegistroEmocionalScreen({super.key, required this.token});

  @override
  State<RegistroEmocionalScreen> createState() => _RegistroEmocionalScreenState();
}

class _RegistroEmocionalScreenState extends State<RegistroEmocionalScreen> {
  int? _estadoSeleccionado;
  int? _energia;
  int? _horasSueno;
  int? _descanso;
  int? _estres;
  String? _capacidadDia;
  final _notaController = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;
  String? _error;
  RegistroEmocional? _registroExistente;

  @override
  void initState() {
    super.initState();
    _cargarCheckInHoy();
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  Future<void> _cargarCheckInHoy() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final registro = await SintomasService.obtenerCheckInHoy(widget.token);
      if (!mounted) return;
      setState(() {
        _registroExistente = registro;
        _estadoSeleccionado = registro?.estadoAnimo;
        _energia = registro?.energia;
        _horasSueno = registro?.horasSueno;
        _descanso = registro?.descanso;
        _estres = registro?.estres;
        _capacidadDia = registro?.capacidadDia;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  void _cambiarSueno(int delta) {
    setState(() {
      // Primer toque: arranca en 7 h (un valor típico) para no partir de 0.
      _horasSueno = _horasSueno == null
          ? 7
          : (_horasSueno! + delta).clamp(0, 24);
    });
  }

  Future<void> _guardar() async {
    if (_estadoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona cómo ha estado tu ánimo')),
      );
      return;
    }

    final eraNuevo = _registroExistente == null;
    setState(() => _guardando = true);
    try {
      final registro = await SintomasService.guardarCheckIn(
        token: widget.token,
        estadoAnimo: _estadoSeleccionado!,
        notaLibre: _notaController.text,
        energia: _energia,
        horasSueno: _horasSueno,
        descanso: _descanso,
        estres: _estres,
        capacidadDia: _capacidadDia,
      );
      if (!mounted) return;
      setState(() => _registroExistente = registro);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(eraNuevo ? 'Check-in guardado' : 'Check-in actualizado'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final mensaje = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargarCheckInHoy,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final titulo = Theme.of(context).textTheme.titleMedium;
    final notaPrevia = _registroExistente?.notaLibre;
    final tieneNotaPrevia = notaPrevia != null && notaPrevia.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Text(
            '¿Cómo ha estado tu ánimo hoy?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Responde solo lo que quieras. Esto es solo para ti — no reemplaza el acompañamiento profesional.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_registroExistente != null) ...[
            const SizedBox(height: 12),
            Text(
              'Ya registraste tu día. Puedes actualizarlo si cambió.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // --- Ánimo (obligatorio) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final valor = index + 1;
              final seleccionado = _estadoSeleccionado == valor;
              return GestureDetector(
                onTap: () => setState(() => _estadoSeleccionado = valor),
                child: Column(
                  children: [
                    AnimatedScale(
                      scale: seleccionado ? 1.3 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        RegistroEmocional.emojis[index],
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      RegistroEmocional.etiquetas[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          // --- Energía ---
          const SizedBox(height: 32),
          Text('¿Cuánta energía tienes?', style: titulo),
          const SizedBox(height: 12),
          _EscalaCircular(
            valor: _energia,
            izquierda: 'Muy baja',
            derecha: 'Muy alta',
            onChanged: (v) => setState(() => _energia = v),
          ),

          // --- Sueño ---
          const SizedBox(height: 32),
          Text('¿Cómo dormiste anoche?', style: titulo),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: 'Una hora menos',
                onPressed: () => _cambiarSueno(-1),
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 24),
              Column(
                children: [
                  Text(
                    _horasSueno == null ? '—' : '$_horasSueno h',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'horas dormidas',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 24),
              IconButton.filledTonal(
                tooltip: 'Una hora más',
                onPressed: () => _cambiarSueno(1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (_horasSueno != null)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _horasSueno = null),
                child: const Text('Quitar respuesta'),
              ),
            ),
          const SizedBox(height: 16),
          Text('¿Sientes que descansaste?'),
          const SizedBox(height: 12),
          _EscalaCircular(
            valor: _descanso,
            izquierda: 'Nada',
            derecha: 'Muy bien',
            onChanged: (v) => setState(() => _descanso = v),
          ),

          // --- Estrés ---
          const SizedBox(height: 32),
          Text('¿Qué tan estresada te sientes?', style: titulo),
          const SizedBox(height: 12),
          _EscalaCircular(
            valor: _estres,
            izquierda: 'Nada',
            derecha: 'Muchísimo',
            onChanged: (v) => setState(() => _estres = v),
          ),

          // --- Capacidad del día ---
          const SizedBox(height: 32),
          Text('¿Pudiste hacer tus actividades?', style: titulo),
          const SizedBox(height: 4),
          Text(
            'Trabajo, estudio, tareas de la casa o lo que tuvieras hoy.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RegistroEmocional.capacidades.entries.map((e) {
              final seleccionado = _capacidadDia == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: seleccionado,
                onSelected: (_) => setState(
                  () => _capacidadDia = seleccionado ? null : e.key,
                ),
                backgroundColor: AppTheme.primaryLight,
                selectedColor: AppTheme.primary,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: seleccionado ? Colors.white : AppTheme.textDark,
                  fontWeight: seleccionado ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide.none,
                ),
              );
            }).toList(),
          ),

          // --- Nota libre ---
          const SizedBox(height: 32),
          if (tieneNotaPrevia) ...[
            Text(
              'Hoy escribiste:',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '"$notaPrevia"',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _notaController,
            decoration: InputDecoration(
              labelText: tieneNotaPrevia
                  ? 'Actualizar lo que escribiste (opcional)'
                  : '¿Quieres contarme algo más sobre tu día? (opcional)',
              border: const OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _guardando ? null : _guardar,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _guardando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_registroExistente == null ? 'Guardar check-in' : 'Actualizar check-in'),
          ),
          const SizedBox(height: 10),
          Text(
            'Con guardar solo tu ánimo ya cuenta para tu racha. No es un diagnóstico.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Escala de 1 a 5 en círculos. Tocar el valor ya elegido lo desmarca
/// (las preguntas son opcionales).
class _EscalaCircular extends StatelessWidget {
  final int? valor;
  final String izquierda;
  final String derecha;
  final ValueChanged<int?> onChanged;

  const _EscalaCircular({
    required this.valor,
    required this.izquierda,
    required this.derecha,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final estiloExtremos = Theme.of(context).textTheme.bodySmall;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (i) {
            final v = i + 1;
            final seleccionado = valor == v;
            return Semantics(
              button: true,
              selected: seleccionado,
              label: '$v de 5',
              child: GestureDetector(
                onTap: () => onChanged(seleccionado ? null : v),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: seleccionado ? AppTheme.primary : AppTheme.primaryLight,
                  ),
                  child: Text(
                    '$v',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: seleccionado ? FontWeight.bold : FontWeight.w500,
                      color: seleccionado ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(izquierda, style: estiloExtremos),
            Text(derecha, style: estiloExtremos),
          ],
        ),
      ],
    );
  }
}