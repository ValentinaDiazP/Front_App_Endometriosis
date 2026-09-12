import 'package:flutter/material.dart';
import '../../models/categoria_contenido.dart';

class CategoriaChip extends StatelessWidget {
  final CategoriaContenido categoria;
  final bool seleccionada;
  final VoidCallback onTap;

  const CategoriaChip({
    super.key,
    required this.categoria,
    required this.seleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(categoria.nombre),
        selected: seleccionada,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
