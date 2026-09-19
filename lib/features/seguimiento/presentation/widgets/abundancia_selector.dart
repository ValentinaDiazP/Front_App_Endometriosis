import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/registro_ciclo.dart';

/// Selector de abundancia del sangrado (leve, moderada, abundante).
/// Selección única, por eso usa `ChoiceChip`.
class AbundanciaSelector extends StatelessWidget {
  final AbundanciaSangrado? seleccionada;
  final ValueChanged<AbundanciaSangrado> onSelected;

  const AbundanciaSelector({
    super.key,
    required this.seleccionada,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Abundancia del sangrado',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: AbundanciaSangrado.values.map((abundancia) {
            final estaSeleccionada = seleccionada == abundancia;
            return ChoiceChip(
              label: Text(abundancia.etiqueta),
              selected: estaSeleccionada,
              onSelected: (_) => onSelected(abundancia),
              backgroundColor: AppTheme.primaryLight,
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: estaSeleccionada ? Colors.white : AppTheme.textDark,
                fontWeight:
                    estaSeleccionada ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}