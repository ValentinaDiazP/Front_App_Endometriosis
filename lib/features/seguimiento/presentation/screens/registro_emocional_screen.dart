import 'package:flutter/material.dart';
import '../../../../core/services/sintomas_service.dart';
import '../../models/registro_emocional.dart';

/// Check-in emocional diario: un registro por día, que se carga pre-lleno
/// si ya existe el de hoy (modo edición), o vacío si es la primera vez.
class RegistroEmocionalScreen extends StatefulWidget {
  final String token;

  const RegistroEmocionalScreen({super.key, required this.token});

  @override
  State<RegistroEmocionalScreen> createState() => _RegistroEmocionalScreenState();
}

class _RegistroEmocionalScreenState extends State<RegistroEmocionalScreen> {
  int? _estadoSeleccionado;
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

  Future<void> _guardar() async {
    if (_estadoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona cómo ha estado tu ánimo')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final registro = await SintomasService.guardarCheckIn(
        token: widget.token,
        estadoAnimo: _estadoSeleccionado!,
        notaLibre: _notaController.text,
      );
      if (!mounted) return;
      setState(() => _registroExistente = registro);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _registroExistente == null
                ? 'Check-in guardado'
                : 'Check-in actualizado',
          ),
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
            'Esto es solo para ti — no reemplaza el acompañamiento profesional.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_registroExistente != null) ...[
            const SizedBox(height: 12),
            Text(
              'Ya registraste tu ánimo hoy. Puedes actualizarlo si cambió.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 24),
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
          const SizedBox(height: 32),
          if (_registroExistente?.notaLibre != null &&
              _registroExistente!.notaLibre!.trim().isNotEmpty) ...[
            Text(
              'Hoy escribiste:',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '"${_registroExistente!.notaLibre}"',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _notaController,
            decoration: InputDecoration(
              labelText: _registroExistente?.notaLibre != null &&
                      _registroExistente!.notaLibre!.trim().isNotEmpty
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
        ],
      ),
    );
  }
}