import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Control deslizante para registrar la intensidad de dolor en escala 0-10,
/// según el campo `intensidadDolor` de la tabla `RegistroSintoma`.
///
/// Se muestra siempre con una etiqueta descriptiva (no solo el número) para
/// que la escala sea más fácil de interpretar para la usuaria.
class DolorScaleSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const DolorScaleSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  String get _etiqueta {
    if (value == 0) return 'Sin dolor';
    if (value <= 3) return 'Dolor leve';
    if (value <= 6) return 'Dolor moderado';
    if (value <= 8) return 'Dolor intenso';
    return 'Dolor extremo';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Intensidad de dolor',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '$value / 10 · $_etiqueta',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: AppTheme.primary,
          label: value.toString(),
          onChanged: (nuevoValor) => onChanged(nuevoValor.round()),
        ),
      ],
    );
  }
}
