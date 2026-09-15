import 'contenido_educativo.dart';

/// Espejo del frontend de `RutaAprendizaje` + `RutaAprendizaje_Contenido`.
///
/// `contenidos` representa la relación muchos-a-muchos ordenada con
/// ContenidoEducativo (el campo `idProceso` del diagrama define el orden
/// dentro de la ruta; aquí simplemente se respeta el orden de la lista).
///
/// El progreso de cada contenido NO se guarda aquí: se consulta en vivo a
/// MockEducativoData.contenidoCompletado(id), para que sea la misma fuente
/// de verdad que usa la Biblioteca (ver ProgresoBibliotecaBar).
class RutaAprendizaje {
  final String idRuta;
  final String nombre;
  final String descripcion;
  final List<ContenidoEducativo> contenidos;

  const RutaAprendizaje({
    required this.idRuta,
    required this.nombre,
    required this.descripcion,
    required this.contenidos,
  });
}
