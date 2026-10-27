import 'package:flutter/material.dart';
import '../../data/educativo_repository.dart';
import '../../models/progreso_aprendizaje.dart';
import '../../../../core/theme/app_theme.dart';

/// "Mi progreso": nivel y puntos, racha de aprendizaje, insignias por ruta,
/// cómo ganar más puntos y movimientos recientes. Los datos los calcula el
/// backend (GET /api/educativo/progreso/); aquí solo se muestran.
class MiProgresoScreen extends StatefulWidget {
  const MiProgresoScreen({super.key});

  @override
  State<MiProgresoScreen> createState() => _MiProgresoScreenState();
}

class _MiProgresoScreenState extends State<MiProgresoScreen> {
  late Future<ProgresoAprendizaje> _futuro = EducativoRepository.obtenerProgreso();

  Future<void> _recargar() async {
    final nuevo = EducativoRepository.obtenerProgreso();
    setState(() {
      _futuro = nuevo;
    });
    try {
      await nuevo;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi progreso')),
      body: FutureBuilder<ProgresoAprendizaje>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final datos = snapshot.data;
          if (snapshot.hasError || datos == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No pudimos cargar tu progreso.', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _recargar, child: const Text('Reintentar')),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _recargar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _TarjetaNivel(datos: datos),
                const SizedBox(height: 12),
                _TarjetaRacha(datos: datos),
                const SizedBox(height: 20),
                Text('Insignias por ruta', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  'Se consiguen al leer todos los contenidos de una ruta.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                if (datos.insignias.isEmpty)
                  const Text('Aún no hay insignias disponibles.')
                else
                  for (final insignia in datos.insignias) _FilaInsignia(insignia: insignia),
                if (datos.reglas.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Cómo ganar puntos', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final regla in datos.reglas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.add_circle_outline, size: 18, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(regla.descripcion)),
                          Text('+${regla.puntos}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                ],
                if (datos.historial.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Movimientos recientes', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final m in datos.historial)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(m.motivo),
                      subtitle: Text(m.fecha),
                      trailing: Text('+${m.puntos}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaNivel extends StatelessWidget {
  final ProgresoAprendizaje datos;
  const _TarjetaNivel({required this.datos});

  @override
  Widget build(BuildContext context) {
    final siguiente = datos.siguienteNivel;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(datos.nivel.emoji.isEmpty ? '🧭' : datos.nivel.emoji,
              style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 6),
          Text('Nivel ${datos.nivel.nombre}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${datos.puntosTotales} puntos',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: datos.progresoNivel,
              minHeight: 10,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            siguiente == null
                ? '¡Llegaste al nivel más alto!'
                : 'Te faltan ${datos.puntosParaSiguiente} puntos para ${siguiente.nombre}',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _TarjetaRacha extends StatelessWidget {
  final ProgresoAprendizaje datos;
  const _TarjetaRacha({required this.datos});

  @override
  Widget build(BuildContext context) {
    final racha = datos.rachaActual;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  racha == 0
                      ? 'Sin racha por ahora'
                      : 'Racha de $racha ${racha == 1 ? 'día' : 'días'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  datos.activaHoy
                      ? 'Hoy ya aprendiste algo. ¡Bien!'
                      : 'Lee un contenido o haz un ejercicio hoy para sumar un día.',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text('Mejor racha: ${datos.rachaMaxima} ${datos.rachaMaxima == 1 ? 'día' : 'días'}',
                    style: const TextStyle(fontSize: 12.5, color: Colors.black45)),
              ],
            ),
          ),
        ],
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
    final fraccion = insignia.contenidosTotal == 0
        ? 0.0
        : insignia.contenidosCompletados / insignia.contenidosTotal;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: obtenida ? AppTheme.primaryLight : Colors.white,
        border: Border.all(color: obtenida ? AppTheme.primary : Colors.black12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: obtenida ? 1 : 0.35,
            child: Text(insignia.emoji.isEmpty ? '🏅' : insignia.emoji,
                style: const TextStyle(fontSize: 34)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insignia.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(insignia.rutaNombre,
                    style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                const SizedBox(height: 8),
                if (obtenida)
                  Text(
                    insignia.fechaObtenida == null
                        ? '¡Conseguida!'
                        : '¡Conseguida el ${insignia.fechaObtenida}!',
                    style: const TextStyle(fontSize: 13, color: AppTheme.primary),
                  )
                else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: fraccion, minHeight: 6),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${insignia.contenidosCompletados} de ${insignia.contenidosTotal} contenidos',
                    style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                  // La ruta tiene contenido premium y la usuaria es gratuita.
                  if (insignia.requierePremium) ...[
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.lock_outline, size: 14, color: Color(0xFFE98BA0)),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Incluye contenido Premium',
                            style: TextStyle(fontSize: 12, color: Color(0xFFE98BA0)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
