import 'package:flutter/material.dart';
import '../../models/progreso_aprendizaje.dart';
import '../../services/educativo_service.dart';

/// Sección "Mi aprendizaje" para la pantalla de Perfil: nivel y puntos del
/// módulo Educativo, racha de aprendizaje e insignias por ruta.
///
/// Carga sus propios datos con el [token] de la usuaria (GET
/// /api/educativo/progreso/), así que se puede poner en cualquier pantalla
/// sin que el módulo Educativo esté abierto.
class SeccionAprendizajePerfil extends StatefulWidget {
  final String token;
  const SeccionAprendizajePerfil({super.key, required this.token});

  @override
  State<SeccionAprendizajePerfil> createState() => _SeccionAprendizajePerfilState();
}

class _SeccionAprendizajePerfilState extends State<SeccionAprendizajePerfil> {
  late Future<ProgresoAprendizaje> _futuro = EducativoService.obtenerProgreso(widget.token);

  void _reintentar() {
    setState(() {
      _futuro = EducativoService.obtenerProgreso(widget.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Mi aprendizaje',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        FutureBuilder<ProgresoAprendizaje>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final datos = snapshot.data;
            if (snapshot.hasError || datos == null) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('No pudimos cargar tu progreso de aprendizaje.'),
                      ),
                      TextButton(onPressed: _reintentar, child: const Text('Reintentar')),
                    ],
                  ),
                ),
              );
            }
            return _Contenido(datos: datos);
          },
        ),
      ],
    );
  }
}

class _Contenido extends StatelessWidget {
  final ProgresoAprendizaje datos;
  const _Contenido({required this.datos});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final siguiente = datos.siguienteNivel;
    final racha = datos.rachaActual;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(datos.nivel.emoji.isEmpty ? '🧭' : datos.nivel.emoji,
                        style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nivel ${datos.nivel.nombre}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${datos.puntosTotales} puntos de aprendizaje',
                            style: TextStyle(color: Colors.grey[700], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: datos.progresoNivel,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  siguiente == null
                      ? '¡Has alcanzado el nivel máximo!'
                      : 'Te faltan ${datos.puntosParaSiguiente} puntos para ${siguiente.nombre}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DatoRacha(
                emoji: '🔥',
                etiqueta: 'Racha de aprendizaje',
                valor: '$racha ${racha == 1 ? 'día' : 'días'}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DatoRacha(
                emoji: '🏆',
                etiqueta: 'Mejor racha',
                valor: '${datos.rachaMaxima} ${datos.rachaMaxima == 1 ? 'día' : 'días'}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Insignias por ruta',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (datos.insignias.isEmpty)
          const Text('Aún no hay insignias disponibles.')
        else
          for (final insignia in datos.insignias) _FilaInsignia(insignia: insignia),
      ],
    );
  }
}

class _DatoRacha extends StatelessWidget {
  final String emoji;
  final String etiqueta;
  final String valor;

  const _DatoRacha({required this.emoji, required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(etiqueta,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _FilaInsignia extends StatelessWidget {
  final InsigniaRuta insignia;
  const _FilaInsignia({required this.insignia});

  @override
  Widget build(BuildContext context) {
    final obtenida = insignia.obtenida;
    final color = Theme.of(context).colorScheme.primary;
    final fraccion = insignia.contenidosTotal == 0
        ? 0.0
        : insignia.contenidosCompletados / insignia.contenidosTotal;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Opacity(
              opacity: obtenida ? 1 : 0.35,
              child: Text(insignia.emoji.isEmpty ? '🏅' : insignia.emoji,
                  style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insignia.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(insignia.rutaNombre,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
                  const SizedBox(height: 6),
                  if (obtenida)
                    Text('¡Conseguida!', style: TextStyle(fontSize: 13, color: color))
                  else ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: fraccion, minHeight: 6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${insignia.contenidosCompletados} de ${insignia.contenidosTotal} contenidos',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
