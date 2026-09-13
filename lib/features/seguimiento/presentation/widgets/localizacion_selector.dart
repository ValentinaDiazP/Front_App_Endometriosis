import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/localizacion_dolor.dart';

/// Selector de zona corporal afectada por el dolor. A diferencia de
/// `SintomaChip` (selección múltiple), aquí solo se puede elegir UNA
/// localización a la vez, por eso usa `ChoiceChip` en lugar de `FilterChip`.
class LocalizacionSelector extends StatelessWidget {
  final List<LocalizacionDolor> localizaciones;
  final LocalizacionDolor? seleccionada;
  final ValueChanged<LocalizacionDolor> onSelected;

  const LocalizacionSelector({
    super.key,
    required this.localizaciones,
    required this.seleccionada,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Localización del dolor',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: localizaciones.map((localizacion) {
            final estaSeleccionada = seleccionada?.id == localizacion.id;
            return ChoiceChip(
              label: Text(localizacion.nombre),
              selected: estaSeleccionada,
              onSelected: (_) => onSelected(localizacion),
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