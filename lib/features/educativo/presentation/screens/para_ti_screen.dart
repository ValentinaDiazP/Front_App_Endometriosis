import 'package:flutter/material.dart';
import '../../data/gestor_contenido.dart';
import '../../data/educativo_repository.dart';
import '../../educativo_routes.dart';
import '../../models/contenido_educativo.dart';
import '../../models/ejercicio_psicoeducativo.dart';
import '../../models/recomendaciones_educativas.dart';
import '../widgets/aviso_pendiente_card.dart';
import '../widgets/contenido_card.dart';
import '../widgets/resumen_progreso_card.dart';
import '../widgets/tarjeta_premium.dart';
import '../../../../core/theme/app_theme.dart';
import 'preferencias_screen.dart';

/// Vista de contenido personalizado ("Para ti").
///
/// Las recomendaciones las calcula el backend (GET /recomendaciones/) con
/// las preferencias de la usuaria, su progreso y sus datos de Seguimiento de
/// los últimos 7 días (dolor, ánimo y ciclo). Cada tarjeta explica por qué se
/// recomienda. Si el backend no responde, se usa el orden local por
/// preferencias de [GestorContenidoEducativo].
///
/// Se vuelve a consultar cuando la usuaria completa algo, cuando regresa a
/// esta pestaña (por ejemplo, después de registrar dolor en Seguimiento) y al
/// deslizar hacia abajo.
class ParaTiScreen extends StatefulWidget {
  const ParaTiScreen({super.key});

  @override
  State<ParaTiScreen> createState() => _ParaTiScreenState();
}

class _ParaTiScreenState extends State<ParaTiScreen> {
  static const _maxEjercicios = 2;

  bool _soloMisIntereses = false;
  RecomendacionesEducativas? _recomendaciones;
  bool _cargando = true;
  bool _fallo = false;
  bool? _visible;

  @override
  void initState() {
    super.initState();
    EducativoRepository.cambiosProgreso.addListener(_cargar);
    _cargar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se vuelve a consultar cuando esta pantalla reaparece: el menú principal
    // oculta las pestañas con IndexedStack (Visibility.of lo detecta) y una
    // ruta encima la deja sin animaciones (TickerMode). Así, al volver de
    // registrar dolor o ánimo en Seguimiento, las recomendaciones ya cambian.
    final visible = Visibility.of(context) && TickerMode.valuesOf(context).enabled;
    if (_visible == false && visible) _cargar();
    _visible = visible;
  }

  @override
  void dispose() {
    EducativoRepository.cambiosProgreso.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    if (mounted) setState(() => _cargando = true);
    try {
      final datos = await EducativoRepository.obtenerRecomendaciones();
      if (!mounted) return;
      setState(() {
        _recomendaciones = datos;
        _fallo = false;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fallo = true;
        _cargando = false;
      });
    }
  }

  Future<void> _editarPreferencias() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PreferenciasScreen()),
    );
    await _cargar(); // las preferencias pudieron cambiar
  }

  Future<void> _abrirContenido(ContenidoEducativo contenido) async {
    await Navigator.pushNamed(context, EducativoRoutes.contenidoDetalle, arguments: contenido);
    if (mounted) setState(() {}); // el "completado" pudo cambiar
  }

  Future<void> _abrirEjercicio(EjercicioPsicoeducativo ejercicio) async {
    await Navigator.pushNamed(context, EducativoRoutes.ejercicioDetalle, arguments: ejercicio);
    if (mounted) setState(() {});
  }

  /// Contenidos a mostrar, con su motivo, en el orden del backend (o el
  /// respaldo local si falló).
  List<({ContenidoEducativo contenido, String? motivo})> get _contenidos {
    final preferidas = EducativoRepository.categoriasPreferidas;
    final recomendaciones = _recomendaciones;

    final lista = <({ContenidoEducativo contenido, String? motivo})>[];
    if (recomendaciones != null) {
      for (final r in recomendaciones.contenidos) {
        final contenido = EducativoRepository.contenidoPorId(r.id);
        if (contenido != null) lista.add((contenido: contenido, motivo: r.motivo));
      }
    } else {
      for (final p in GestorContenidoEducativo.contenidosPriorizados()) {
        lista.add((contenido: p.contenido, motivo: p.motivo));
      }
    }
    if (_soloMisIntereses && preferidas.isNotEmpty) {
      return lista.where((i) => preferidas.contains(i.contenido.idCategoriaFK)).toList();
    }
    return lista;
  }

  /// Los ejercicios que el backend recomienda por una señal concreta (con
  /// motivo), sin repetir los ya hechos.
  List<({EjercicioPsicoeducativo ejercicio, Recomendacion recomendacion})> get _ejercicios {
    final recomendaciones = _recomendaciones;
    if (recomendaciones == null) return const [];
    final lista = <({EjercicioPsicoeducativo ejercicio, Recomendacion recomendacion})>[];
    for (final r in recomendaciones.ejercicios) {
      if (r.motivo == null || r.completado) continue;
      final ejercicio = EducativoRepository.ejercicioPorId(r.id);
      if (ejercicio != null) lista.add((ejercicio: ejercicio, recomendacion: r));
      if (lista.length == _maxEjercicios) break;
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final tienePreferencias = EducativoRepository.tienePreferencias;
    final contenidos = _contenidos;
    final ejercicios = _ejercicios;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const ResumenProgresoCard(),
          const AvisoPendienteCard(),
          _SenalesCard(
            senales: _recomendaciones?.senales,
            cargando: _cargando && _recomendaciones == null,
            fallo: _fallo,
          ),
          if (!tienePreferencias)
            _SinPreferenciasCard(onElegir: _editarPreferencias)
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Solo mis intereses',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Switch(
                    value: _soloMisIntereses,
                    onChanged: (v) => setState(() => _soloMisIntereses = v),
                  ),
                  IconButton(
                    tooltip: 'Editar preferencias',
                    icon: const Icon(Icons.tune),
                    onPressed: _editarPreferencias,
                  ),
                ],
              ),
            ),
          if (ejercicios.isNotEmpty) ...[
            const _Titulo('Ejercicios para ti'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final item in ejercicios)
                    _EjercicioRecomendadoCard(
                      ejercicio: item.ejercicio,
                      motivo: item.recomendacion.motivo!,
                      onTap: () => _abrirEjercicio(item.ejercicio),
                    ),
                ],
              ),
            ),
          ],
          _Titulo(_soloMisIntereses ? 'De tus temas elegidos' : 'Recomendado para ti'),
          if (contenidos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No hay contenido para estos temas todavía.')),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final item in contenidos)
                    ContenidoCard(
                      contenido: item.contenido,
                      motivo: item.motivo,
                      completado: EducativoRepository.contenidoCompletado(
                          item.contenido.idContenido),
                      onTap: () => _abrirContenido(item.contenido),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;
  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}

/// Qué sabe la app de Seguimiento esta semana y que usó para recomendar.
class _SenalesCard extends StatelessWidget {
  final SenalesSeguimiento? senales;
  final bool cargando;
  final bool fallo;

  const _SenalesCard({required this.senales, required this.cargando, required this.fallo});

  String get _texto {
    if (cargando) return 'Revisando tu seguimiento…';
    final s = senales;
    if (s == null || fallo) {
      return 'No pudimos consultar tu seguimiento; te mostramos el contenido según tus temas.';
    }
    if (!s.hayDatos) {
      return 'Aún no tienes registros de dolor o ánimo en los últimos ${s.diasVentana} días. '
          'Regístralos en Registro y adaptaremos estas recomendaciones.';
    }
    return 'Según tu seguimiento (últimos ${s.diasVentana} días): ${s.resumen}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.monitor_heart_outlined, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_texto, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}

class _EjercicioRecomendadoCard extends StatelessWidget {
  final EjercicioPsicoeducativo ejercicio;
  final String motivo;
  final VoidCallback onTap;

  const _EjercicioRecomendadoCard({
    required this.ejercicio,
    required this.motivo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF1EAFB),
          child: Icon(Icons.self_improvement, color: Color(0xFF8E6BBF)),
        ),
        title: Text(ejercicio.nombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 13, color: Color(0xFF8E6BBF)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    motivo,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF8E6BBF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text('${ejercicio.minutosEstimados} min · ${ejercicio.tipo.label}'),
            if (ejercicio.esPremium) ...[
              const SizedBox(height: 4),
              EtiquetaPremium(bloqueado: ejercicio.bloqueado),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _SinPreferenciasCard extends StatelessWidget {
  final VoidCallback onElegir;
  const _SinPreferenciasCard({required this.onElegir});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        color: AppTheme.primaryLight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cuéntanos qué te interesa',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text(
                'Elige tus temas y ordenaremos el contenido para ti.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              FilledButton(onPressed: onElegir, child: const Text('Elegir temas')),
            ],
          ),
        ),
      ),
    );
  }
}
