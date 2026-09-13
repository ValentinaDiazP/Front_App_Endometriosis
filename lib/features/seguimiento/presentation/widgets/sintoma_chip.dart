import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/sintoma_asociado.dart';

/// Chip seleccionable para marcar un síntoma asociado (náuseas, fatiga,
/// etc.) dentro del formulario de registro. Usa el mismo patrón visual que
/// `CategoriaChip` en el módulo Educativo, para mantener consistencia entre
/// módulos.
class SintomaChip extends StatelessWidget {
  final SintomaAsociado sintoma;
  final bool seleccionado;
  final ValueChanged<bool> onSelected;

  const SintomaChip({
    super.key,
    required this.sintoma,
    required this.seleccionado,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(sintoma.nombre),
      selected: seleccionado,
      onSelected: onSelected,
      backgroundColor: AppTheme.primaryLight,
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: seleccionado ? Colors.white : AppTheme.textDark,
        fontWeight: seleccionado ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }
}