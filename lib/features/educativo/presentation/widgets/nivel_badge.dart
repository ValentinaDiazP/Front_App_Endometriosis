import 'package:flutter/material.dart';
import '../../models/contenido_educativo.dart';
import '../../../../core/theme/app_theme.dart';

class NivelBadge extends StatelessWidget {
  final NivelContenido nivel;
  const NivelBadge({super.key, required this.nivel});

  String get _label {
    switch (nivel) {
      case NivelContenido.basico:
        return 'Básico';
      case NivelContenido.intermedio:
        return 'Intermedio';
      case NivelContenido.avanzado:
        return 'Avanzado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
