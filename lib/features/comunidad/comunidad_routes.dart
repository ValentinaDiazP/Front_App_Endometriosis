import 'package:flutter/material.dart';
import 'presentation/screens/comunidad_feed_screen.dart';

class ComunidadRoutes {
  static const String comunidad = '/comunidad';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      comunidad: (context) => const ComunidadFeedScreen(),
    };
  }
}