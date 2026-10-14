import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Piezas compartidas por los ejercicios interactivos (catastrofización y
/// valores): paso con título, campo de texto, slider con porcentaje y
/// tarjeta de resumen.
class PasoEjercicio extends StatelessWidget {
  final String titulo;
  final String explicacion;
  final List<Widget> children;

  const PasoEjercicio({
    super.key,
    required this.titulo,
    required this.explicacion,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(explicacion, style: const TextStyle(color: Colors.black54, fontSize: 14.5)),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String pista;
  final int minLines;

  const CampoTexto({
    super.key,
    required this.controller,
    required this.pista,
    this.minLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: 6,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: pista,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class SliderPorcentaje extends StatelessWidget {
  final String titulo;
  final double valor;
  final ValueChanged<double> onCambio;

  const SliderPorcentaje({
    super.key,
    required this.titulo,
    required this.valor,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600))),
            Text('${valor.round()}%',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ],
        ),
        Slider(value: valor, min: 0, max: 100, divisions: 20, onChanged: onCambio),
      ],
    );
  }
}

class TarjetaResumen extends StatelessWidget {
  final String etiqueta;
  final String texto;
  final bool destacada;

  const TarjetaResumen({
    super.key,
    required this.etiqueta,
    required this.texto,
    this.destacada = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: destacada ? AppTheme.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: destacada ? AppTheme.primary : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta.toUpperCase(),
              style: const TextStyle(fontSize: 11, letterSpacing: 0.6, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(texto.isEmpty ? '—' : texto, style: const TextStyle(fontSize: 15.5)),
        ],
      ),
    );
  }
}
