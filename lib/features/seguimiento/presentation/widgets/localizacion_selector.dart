import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/localizacion_dolor.dart';

/// Selector de zonas corporales afectadas por el dolor. Permite selección
/// MÚLTIPLE (la usuaria puede tener dolor en varias zonas a la vez),
/// incluyendo las opciones especiales "Otro" y "Ninguno". El comportamiento
/// particular de esas dos opciones (mutuamente excluyentes entre sí y con
/// el resto, campo de texto libre para "Otro") lo controla la pantalla que
/// usa este widget, no el widget en sí — este solo dibuja los chips y
/// avisa qué se tocó.
class LocalizacionSelector extends StatelessWidget {
  final List<LocalizacionDolor> localizaciones;
  final Set<LocalizacionDolor> seleccionadas;
  final ValueChanged<LocalizacionDolor> onToggle;

  const LocalizacionSelector({
    super.key,
    required this.localizaciones,
    required this.seleccionadas,
    required this.onToggle,
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
            final estaSeleccionada = seleccionadas.contains(localizacion);
            return FilterChip(
              label: Text(localizacion.nombre),
              selected: estaSeleccionada,
              onSelected: (_) => onToggle(localizacion),
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