import 'package:flutter/material.dart';
import '../../models/progreso_aprendizaje.dart';

/// Aviso que se muestra cuando la usuaria gana puntos, mantiene su racha,
/// sube de nivel o consigue una insignia al leer un contenido o completar un
/// ejercicio.
void mostrarAvisoRecompensa(BuildContext context, ResultadoGamificacion r) {
  final lineas = <String>[];
  if (r.puntosGanados > 0) {
    lineas.add('+${r.puntosGanados} puntos');
  }
  if (r.rachaActual > 1) {
    lineas.add('Racha de aprendizaje: ${r.rachaActual} días 🔥');
  }
  for (final nombre in r.insigniasNuevas) {
    lineas.add('🏅 Nueva insignia: $nombre');
  }
  if (r.subioDeNivel != null) {
    lineas.add('⬆️ ¡Subiste al nivel ${r.subioDeNivel}!');
  }
  if (lineas.isEmpty) return;

  final celebracion = r.insigniasNuevas.isNotEmpty || r.subioDeNivel != null;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar(); // reemplaza el "Ejercicio guardado"
  messenger.showSnackBar(
    SnackBar(
      duration: Duration(seconds: celebracion ? 6 : 4),
      behavior: SnackBarBehavior.floating,
      content: Text(lineas.join('\n')),
    ),
  );
}
