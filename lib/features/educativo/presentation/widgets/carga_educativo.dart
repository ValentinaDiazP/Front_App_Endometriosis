import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/educativo_repository.dart';

/// Envuelve una pantalla de entrada al módulo Educativo: asegura que
/// [EducativoRepository] esté cargado para [token] y mientras tanto muestra
/// un indicador de carga, o un error con botón de reintentar.
class CargaEducativo extends StatefulWidget {
  final String? token;
  final WidgetBuilder builder;

  /// Si se pasa, el error también ofrece "Omitir por ahora" (para que un
  /// fallo del servidor nunca bloquee el onboarding).
  final VoidCallback? onOmitir;

  const CargaEducativo({
    super.key,
    required this.token,
    required this.builder,
    this.onOmitir,
  });

  @override
  State<CargaEducativo> createState() => _CargaEducativoState();
}

class _CargaEducativoState extends State<CargaEducativo> {
  late Future<void> _carga = EducativoRepository.asegurarCargado(widget.token);

  void _reintentar() {
    setState(() => _carga = EducativoRepository.asegurarCargado(widget.token));
  }

  String _mensaje(Object? error) {
    if (error is TimeoutException) {
      return 'El servidor tardó demasiado en responder.';
    }
    final texto = error.toString();
    if (error is Exception && texto.startsWith('Exception: ')) {
      return texto.replaceFirst('Exception: ', '');
    }
    return 'No pudimos conectarnos con el servidor.';
  }

  @override
  Widget build(BuildContext context) {
    if (EducativoRepository.cargadoPara(widget.token)) {
      return widget.builder(context);
    }
    return FutureBuilder<void>(
      future: _carga,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 48, color: Colors.black38),
                  const SizedBox(height: 12),
                  Text(_mensaje(snapshot.error), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _reintentar, child: const Text('Reintentar')),
                  if (widget.onOmitir != null)
                    TextButton(onPressed: widget.onOmitir, child: const Text('Omitir por ahora')),
                ],
              ),
            ),
          );
        }
        return widget.builder(context);
      },
    );
  }
}
