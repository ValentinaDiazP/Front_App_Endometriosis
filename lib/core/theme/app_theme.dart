import 'package:flutter/material.dart';

/// Tema visual compartido. Centralizarlo aquí evita que cada pantalla
/// invente sus propios colores y facilita que luego se reemplace por el
/// theme oficial de marca de Florecer (colores, tipografía) sin tocar
/// las pantallas.
class AppTheme {
  AppTheme._();

  // Paleta provisional (rosa/lila suave, coherente con bienestar femenino).
  static const Color primary = Color(0xFF8E6BBF);
  static const Color primaryLight = Color(0xFFF1EAFB);
  static const Color accent = Color(0xFFE98BA0);
  static const Color background = Color(0xFFFCFAFF);
  static const Color textDark = Color(0xFF2E2A38);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryLight,
        selectedColor: primary,
        labelStyle: const TextStyle(fontSize: 12.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: primary,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: textDark),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: textDark),
        bodyMedium: TextStyle(color: textDark),
      ),
    );
  }
}
