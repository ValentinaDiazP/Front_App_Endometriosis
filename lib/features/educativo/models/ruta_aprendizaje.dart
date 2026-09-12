import 'contenido_educativo.dart';

/// Espejo del frontend de `RutaAprendizaje` + `RutaAprendizaje_Contenido`.
///
/// `contenidos` representa la relación muchos-a-muchos ordenada con
/// ContenidoEducativo (el campo `idProceso` del diagrama define el orden
/// dentro de la ruta; aquí simplemente se respeta el orden de la lista).
class RutaAprendizaje {
  final String idRuta;
  final String nombre;
  final String descripcion;
  final List<ContenidoEducativo> contenidos;
  final int contenidosCompletados; // vendrá de InteraccionContenido en el back

  const RutaAprendizaje({
    required this.idRuta,
    required this.nombre,
    required this.descripcion,
    required this.contenidos,
    this.contenidosCompletados = 0,
  });

  double get progreso =>
      contenidos.isEmpty ? 0 : contenidosCompletados / contenidos.length;
}
