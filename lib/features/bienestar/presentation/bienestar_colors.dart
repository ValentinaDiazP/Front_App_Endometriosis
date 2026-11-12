import 'package:flutter/material.dart';

/// Paleta del módulo Bienestar (Profesionales, Citas y Tienda):
/// solo tonos rosados y blanco, alineada con el encabezado (rosa salmón)
/// y con el carrito / detalle de producto (rosa #EC407A).
class BienestarColors {
  BienestarColors._();

  /// Rosa principal: botones, íconos, chips seleccionados.
  static const Color rosa = Color(0xFFEC407A);

  /// Rosa oscuro: textos sobre fondos rosados claros (buen contraste).
  static const Color rosaOscuro = Color(0xFFC2185B);

  /// Rosa salmón: el mismo del encabezado de la app.
  static const Color rosaMedio = Color(0xFFF48FB1);

  /// Rosa muy claro: fondos de chips, buscador y avatares.
  static const Color rosaClaro = Color(0xFFFCE4EC);
}
