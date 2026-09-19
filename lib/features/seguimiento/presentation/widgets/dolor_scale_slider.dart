import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Control deslizante para registrar la intensidad de dolor en escala 0-10,
/// según el campo `intensidadDolor` de la tabla `RegistroSintoma`.
///
/// Se muestra siempre visible (para no generar saltos de layout al
/// aparecer/desaparecer), pero queda deshabilitado y en gris cuando
/// `enabled` es false — esto ocurre cuando la usuaria no ha marcado
/// ninguna zona de dolor real (o marcó "Ninguno"), ya que no tiene sentido
/// calificar una intensidad de dolor que no existe.
class DolorScaleSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;

  const DolorScaleSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  static const List<String> _emojis = [
    '😊', '🙂', '🙂', '😐', '😕', '😣', '😣', '😖', '😖', '😭', '😭',
  ];

  static const List<Color> _colores = [
    Color(0xFF4CAF50),
    Color(0xFF8BC34A),
    Color(0xFFCDDC39),
    Color(0xFFFFEB3B),
    Color(0xFFFFC107),
    Color(0xFFFF9800),
    Color(0xFFFF7043),
    Color(0xFFFF5722),
    Color(0xFFF4511E),
    Color(0xFFE53935),
    Color(0xFFB71C1C),
  ];

  String get _etiqueta {
    if (value == 0) return 'Sin dolor';
    if (value <= 3) return 'Dolor leve';
    if (value <= 6) return 'Dolor moderado';
    if (value <= 8) return 'Dolor intenso';
    return 'Dolor extremo';
  }

  Color get _colorActual => enabled ? _colores[value] : Colors.grey.shade400;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Intensidad de dolor',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                children: [
                  Text(_emojis[value], style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 6),
                  Text(
                    '$value/10',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _colorActual,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            _etiqueta,
            style: TextStyle(color: _colorActual, fontWeight: FontWeight.w600),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 10,
              thumbColor: _colorActual,
              activeTrackColor: _colorActual,
              inactiveTrackColor: AppTheme.primaryLight,
              overlayColor: _colorActual.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: value.toString(),
              onChanged:
                  enabled ? (nuevoValor) => onChanged(nuevoValor.round()) : null,
            ),
          ),
          if (!enabled)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Selecciona una zona de dolor para calificar la intensidad',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}