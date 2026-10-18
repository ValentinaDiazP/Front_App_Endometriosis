import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/sintomas_service.dart';
import '../../models/historial_sintoma.dart';
import '../../models/registro_emocional.dart';

// Colores semánticos de los gráficos (dolor: verde → rojo; ánimo: morado → verde azulado).
const _colorLeve = Color(0xFF81C784);
const _colorModerado = Color(0xFFFFB74D);
const _colorIntenso = Color(0xFFE57373);
const _colorSinDato = Color(0xFFEEEEEE);

Color _colorDolor(num v) {
  final r = v.round();
  if (r <= 3) return _colorLeve;
  if (r <= 6) return _colorModerado;
  return _colorIntenso;
}

String _nivelDolor(num v) {
  final r = v.round();
  if (r <= 3) return 'Leve';
  if (r <= 6) return 'Moderado';
  return 'Intenso';
}

Color _colorAnimo(int v) {
  if (v <= 2) return const Color(0xFF9575CD);
  if (v == 3) return const Color(0xFFB0BEC5);
  return const Color(0xFF4DB6AC);
}

/// Pestaña Reportes: resumen del periodo, dolor y ánimo por día, apoyo
/// cuando hay varios días de ánimo bajo, análisis Premium (hallazgos y
/// calendario mensual), zonas y síntomas frecuentes, e historial.
class ReportesScreen extends StatefulWidget {
  final String token;

  const ReportesScreen({super.key, required this.token});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  int _dias = 7;
  List<HistorialSintoma> _sintomas = [];
  List<RegistroEmocional> _animos = [];
  bool _esPremium = false;
  bool _cargando = true;
  String? _error;

  // Mes que muestra el calendario Premium (siempre el día 1).
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final sintomas =
          await SintomasService.obtenerHistorialSintomas(widget.token);
      final animos = await SintomasService.obtenerCheckIns(widget.token);

      // El plan se consulta aparte: si falla, la usuaria se trata como
      // gratuita y los reportes básicos siguen funcionando.
      var esPremium = false;
      try {
        final perfil = await AuthService.obtenerPerfil(widget.token);
        esPremium = perfil.esPremium;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _sintomas = sintomas;
        _animos = animos;
        _esPremium = esPremium;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  // ---------- Fechas del rango ----------

  DateTime get _hoy {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  DateTime get _inicio => _hoy.subtract(Duration(days: _dias - 1));

  bool _enRango(DateTime fecha) {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    return !dia.isBefore(_inicio) && !dia.isAfter(_hoy);
  }

  int _indiceDia(DateTime fecha) {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    return dia.difference(_inicio).inDays;
  }

  int _clave(DateTime f) => f.year * 10000 + f.month * 100 + f.day;

  String _fechaCorta(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}';

  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  static const _nombresMes = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  String _fechaLarga(DateTime f) => '${f.day} ${_meses[f.month - 1]}';

  String _hora(DateTime f) {
    final h = f.hour % 12 == 0 ? 12 : f.hour % 12;
    final m = f.minute.toString().padLeft(2, '0');
    return '$h:$m ${f.hour < 12 ? 'a. m.' : 'p. m.'}';
  }

  // ---------- Agregación por día ----------

  /// Dolor más alto registrado cada día (índice del día → dolor).
  Map<int, int> _dolorPorDia(List<HistorialSintoma> enRango) {
    final m = <int, int>{};
    for (final r in enRango) {
      final i = _indiceDia(r.fechaHora);
      final actual = m[i];
      if (actual == null || r.intensidadDolor > actual) {
        m[i] = r.intensidadDolor;
      }
    }
    return m;
  }

  Map<int, int> _animoPorDia(List<RegistroEmocional> enRango) {
    final m = <int, int>{};
    for (final r in enRango) {
      m[_indiceDia(r.fecha)] = r.estadoAnimo;
    }
    return m;
  }

  /// Igual que _dolorPorDia pero con todo el historial, indexado por fecha
  /// (aaaammdd). Lo usa el calendario mensual.
  Map<int, int> _dolorPorClave(List<HistorialSintoma> todos) {
    final m = <int, int>{};
    for (final r in todos) {
      final k = _clave(r.fechaHora);
      final actual = m[k];
      if (actual == null || r.intensidadDolor > actual) {
        m[k] = r.intensidadDolor;
      }
    }
    return m;
  }

  Map<int, int> _animoPorClave(List<RegistroEmocional> todos) {
    final m = <int, int>{};
    for (final r in todos) {
      m[_clave(r.fecha)] = r.estadoAnimo;
    }
    return m;
  }

  Map<String, int> _frecuencias(Iterable<List<String>> listas) {
    final conteo = <String, int>{};
    for (final lista in listas) {
      for (final nombre in lista) {
        conteo[nombre] = (conteo[nombre] ?? 0) + 1;
      }
    }
    return conteo;
  }

  // ---------- Piezas visuales ----------

  Widget _tarjetaSimple({
    required String titulo,
    String? subtitulo,
    required Widget hijo,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            if (subtitulo != null) ...[
              const SizedBox(height: 4),
              Text(subtitulo, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            hijo,
          ],
        ),
      ),
    );
  }

  Widget _vacio(String mensaje) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(child: Text(mensaje, textAlign: TextAlign.center)),
      );

  Widget _leyenda(List<(Color, String)> items) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final (color, texto) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(texto, style: const TextStyle(fontSize: 12)),
            ],
          ),
      ],
    );
  }

  Widget _tileResumen({
    required String titulo,
    required String valor,
    required String detalle,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(detalle, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  /// Gráfico de barras con un grupo por cada día del rango (los días sin
  /// registro quedan vacíos, para que las fechas del eje coincidan).
  Widget _graficoBarras({
    required Map<int, int> valores,
    required double maxY,
    required double intervaloY,
    required Color Function(int) colorDe,
    required String tituloEjeY,
    required Widget Function(double) etiquetaY,
    bool valorCeroVisible = false,
  }) {
    final intervaloX = _dias <= 7 ? 1.0 : 5.0;
    final ancho = _dias <= 7 ? 22.0 : 6.0;

    final grupos = <BarChartGroupData>[
      for (var i = 0; i < _dias; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            if (valores.containsKey(i))
              BarChartRodData(
                // Un 0 se dibuja como una barrita para que se vea que sí hubo registro.
                toY: (valores[i] == 0 && valorCeroVisible)
                    ? 0.25
                    : valores[i]!.toDouble(),
                color: colorDe(valores[i]!),
                width: ancho,
                borderRadius: BorderRadius.circular(4),
              )
            else
              BarChartRodData(
                toY: 0,
                color: Colors.transparent,
                width: ancho,
              ),
          ],
        ),
    ];

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 8, top: 8),
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: intervaloY,
            ),
            barGroups: grupos,
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                axisNameWidget: Text(
                  tituloEjeY,
                  style: const TextStyle(fontSize: 11),
                ),
                axisNameSize: 20,
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: intervaloY,
                  getTitlesWidget: (valor, meta) => etiquetaY(valor),
                ),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: const Text(
                  'Día (día/mes)',
                  style: TextStyle(fontSize: 11),
                ),
                axisNameSize: 20,
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  interval: intervaloX,
                  getTitlesWidget: (valor, meta) {
                    final fecha = _inicio.add(Duration(days: valor.toInt()));
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _fechaCorta(fecha),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tarjetaFrecuencia({
    required String titulo,
    required Map<String, int> conteo,
    required Color color,
  }) {
    final ordenado = conteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ordenado.take(5).toList();
    final maximo = top.isEmpty ? 1 : top.first.value;

    return _tarjetaSimple(
      titulo: titulo,
      subtitulo: 'Número de registros en el periodo en que aparece cada uno.',
      hijo: top.isEmpty
          ? _vacio('Aún no hay registros en este periodo.')
          : Column(
              children: top
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              e.key,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: e.value / maximo,
                                minHeight: 14,
                                color: color,
                                backgroundColor: color.withOpacity(0.15),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${e.value}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  /// Aviso amable (disponible para todas las usuarias, sin importar el plan)
  /// cuando hay varios días de ánimo bajo en el periodo.
  Widget _tarjetaApoyo() {
    return Card(
      color: const Color(0xFFEDE7F6),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.favorite_border, color: Color(0xFF7E57C2)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Has registrado varios días con ánimo bajo. No tienes que '
                'pasarlo sola: hablar con una profesional puede ayudarte. '
                'Encuentra apoyo en Bienestar → Profesionales.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Bloque Premium ----------

  Widget _tarjetaBloqueada() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline),
                const SizedBox(width: 8),
                Text(
                  'Análisis Premium',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Con Premium ves hallazgos sobre tu dolor y tu ánimo (tu día más '
              'difícil, tu racha sin dolor intenso, cómo vas frente al periodo '
              'anterior) y un calendario mensual para llevar a tu consulta.',
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Los planes Premium llegan pronto.')),
                );
              },
              child: const Text('Conocer Premium'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tileHallazgo({
    required IconData icono,
    required String titulo,
    required String valor,
    required String detalle,
    required Color color,
    required String info,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icono, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      titulo,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    tooltip: '¿Cómo se calcula?',
                    icon: const Icon(Icons.info_outline),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(titulo),
                        content: Text(info),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Entendido'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(detalle, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  /// Sección Premium: encabezado, 4 tarjetas de hallazgos y calendario mensual.
  Widget _seccionPremium(
    Map<int, int> dolor,
    Map<int, int> animo,
    List<HistorialSintoma> enRango,
  ) {
    // 1) Ánimo en días de dolor intenso vs el resto.
    final ambos = dolor.keys.where(animo.containsKey).toList();
    final animoIntensos = [
      for (final i in ambos)
        if (dolor[i]! >= 7) animo[i]!
    ];
    final animoOtros = [
      for (final i in ambos)
        if (dolor[i]! < 7) animo[i]!
    ];
    String h1Valor = '—';
    String h1Detalle = 'Faltan días con dolor intenso y con ánimo para comparar.';
    Color h1Color = Colors.grey;
    if (animoIntensos.isNotEmpty && animoOtros.isNotEmpty) {
      final a = animoIntensos.reduce((x, y) => x + y) / animoIntensos.length;
      final b = animoOtros.reduce((x, y) => x + y) / animoOtros.length;
      h1Valor = '${a.toStringAsFixed(1)} vs ${b.toStringAsFixed(1)}';
      h1Detalle = 'Ánimo (1-5) en días de dolor intenso vs el resto de días.';
      h1Color = a < b - 0.5
          ? _colorIntenso
          : (a > b + 0.5 ? _colorLeve : Theme.of(context).colorScheme.primary);
    }

    // 2) Día más difícil (mayor dolor; en empate, el de ánimo más bajo).
    String h2Valor = '—';
    String h2Detalle = 'Aún sin registros de dolor.';
    Color h2Color = Colors.grey;
    if (dolor.isNotEmpty) {
      var mejor = dolor.keys.first;
      for (final i in dolor.keys) {
        final d = dolor[i]!;
        final dm = dolor[mejor]!;
        final a = animo[i] ?? 3;
        final am = animo[mejor] ?? 3;
        if (d > dm || (d == dm && a < am)) mejor = i;
      }
      final fecha = _inicio.add(Duration(days: mejor));
      h2Valor = _fechaLarga(fecha);
      final emoji = animo[mejor] == null
          ? ''
          : ' · ánimo ${RegistroEmocional.emojis[animo[mejor]! - 1]}';
      h2Detalle = 'Dolor ${dolor[mejor]}/10$emoji';
      h2Color = _colorDolor(dolor[mejor]!);
    }

    // 3) Racha de días sin dolor intenso.
    String h3Valor = '—';
    String h3Detalle = 'Aún sin registros de dolor.';
    Color h3Color = Colors.grey;
    if (dolor.isNotEmpty) {
      final hoyIdx = _dias - 1;
      final intensos = [
        for (final e in dolor.entries)
          if (e.value >= 7) e.key
      ];
      int racha;
      if (intensos.isEmpty) {
        final primero = dolor.keys.reduce((a, b) => a < b ? a : b);
        racha = hoyIdx - primero + 1;
        h3Detalle = 'Sin dolor intenso desde tu primer registro del periodo.';
      } else {
        final ultimo = intensos.reduce((a, b) => a > b ? a : b);
        racha = hoyIdx - ultimo;
        h3Detalle = racha == 0
            ? 'Hoy tuviste dolor intenso.'
            : 'Desde tu último día de dolor intenso.';
      }
      h3Valor = racha == 1 ? '1 día' : '$racha días';
      h3Color = racha >= 3
          ? _colorLeve
          : (racha == 0 ? _colorIntenso : _colorModerado);
    }

    // 4) Cambio frente al periodo anterior (mismo número de días).
    final inicioPrevio = _inicio.subtract(Duration(days: _dias));
    final previos = _sintomas.where((r) {
      final d = DateTime(r.fechaHora.year, r.fechaHora.month, r.fechaHora.day);
      return !d.isBefore(inicioPrevio) && d.isBefore(_inicio);
    }).toList();
    double prom(List<HistorialSintoma> l) =>
        l.map((r) => r.intensidadDolor).reduce((a, b) => a + b) / l.length;
    String h4Valor = '—';
    String h4Detalle = 'Sin registros en los $_dias días previos para comparar.';
    Color h4Color = Colors.grey;
    IconData h4Icono = Icons.compare_arrows;
    if (enRango.isNotEmpty && previos.isNotEmpty) {
      final dif = prom(enRango) - prom(previos);
      h4Detalle = 'Dolor promedio frente a los $_dias días previos.';
      if (dif.abs() < 0.3) {
        h4Valor = 'Igual';
        h4Color = Theme.of(context).colorScheme.primary;
        h4Icono = Icons.trending_flat;
      } else if (dif < 0) {
        h4Valor = '↓ ${(-dif).toStringAsFixed(1)}';
        h4Color = _colorLeve;
        h4Icono = Icons.trending_down;
      } else {
        h4Valor = '↑ ${dif.toStringAsFixed(1)}';
        h4Color = _colorIntenso;
        h4Icono = Icons.trending_up;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Análisis Premium',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _colorModerado.withOpacity(0.25),
                border: Border.all(color: _colorModerado),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'PREMIUM',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Hallazgos de tus últimos $_dias días.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tileHallazgo(
                icono: Icons.mood_bad_outlined,
                titulo: 'Ánimo con dolor intenso',
                info:
                    'Compara tu ánimo promedio (escala 1 a 5) en los días en que '
                    'tu dolor llegó a 7 o más, frente al resto de los días. Solo '
                    'cuenta los días que tienen dolor y ánimo registrados. Si el '
                    'primer número es mucho más bajo, tu ánimo tiende a caer '
                    'cuando el dolor es intenso.',
                valor: h1Valor,
                detalle: h1Detalle,
                color: h1Color,
              ),
              _tileHallazgo(
                icono: Icons.event_busy_outlined,
                titulo: 'Tu día más difícil',
                info:
                    'Es el día del periodo con el dolor más alto que registraste. '
                    'Si hay empate, se muestra el día con el ánimo más bajo.',
                valor: h2Valor,
                detalle: h2Detalle,
                color: h2Color,
              ),
            ],
          ),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tileHallazgo(
                icono: Icons.local_fire_department_outlined,
                titulo: 'Racha sin dolor intenso',
                info:
                    'Días seguidos, contados hasta hoy, sin dolor de 7 o más. Si '
                    'no tuviste dolor intenso en el periodo, cuenta desde tu '
                    'primer registro. "0 días" significa que hoy tuviste dolor '
                    'intenso.',
                valor: h3Valor,
                detalle: h3Detalle,
                color: h3Color,
              ),
              _tileHallazgo(
                icono: h4Icono,
                titulo: 'Cambio frente a antes',
                info:
                    'Compara tu dolor promedio de este periodo con el de los '
                    '$_dias días inmediatamente anteriores. ↓ significa que bajó '
                    '(mejoría) y ↑ que subió. "Igual" es una diferencia menor a '
                    '0.3 puntos. Necesita registros en ambos periodos.',
                valor: h4Valor,
                detalle: h4Detalle,
                color: h4Color,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _tarjetaCalendario(),
      ],
    );
  }

  Widget _tarjetaCalendario() {
    final dolor = _dolorPorClave(_sintomas);
    final animo = _animoPorClave(_animos);
    final hoy = _hoy;
    final diasMes = DateTime(_mes.year, _mes.month + 1, 0).day;
    final offset = DateTime(_mes.year, _mes.month, 1).weekday - 1; // lunes = 0
    final esMesActual = _mes.year == hoy.year && _mes.month == hoy.month;
    final nombre = _nombresMes[_mes.month - 1];
    final titulo = '${nombre[0].toUpperCase()}${nombre.substring(1)} ${_mes.year}';
    final primario = Theme.of(context).colorScheme.primary;

    final celdas = <Widget>[
      for (var i = 0; i < offset; i++) const SizedBox.shrink(),
    ];
    for (var d = 1; d <= diasMes; d++) {
      final fecha = DateTime(_mes.year, _mes.month, d);
      final k = _clave(fecha);
      final dv = dolor[k];
      final av = animo[k];
      final esHoy = fecha == hoy;
      final futuro = fecha.isAfter(hoy);
      celdas.add(
        Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: dv == null
                ? Colors.grey.withOpacity(0.08)
                : _colorDolor(dv).withOpacity(0.65),
            borderRadius: BorderRadius.circular(10),
            border: esHoy ? Border.all(color: primario, width: 2) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$d',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: (esHoy || dv != null)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: futuro ? Colors.grey.shade400 : null,
                ),
              ),
              if (av != null)
                Text(
                  RegistroEmocional.emojis[av - 1],
                  style: const TextStyle(fontSize: 16),
                ),
            ],
          ),
        ),
      );
    }

    const diasSemana = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return _tarjetaSimple(
      titulo: 'Calendario de dolor y ánimo',
      subtitulo:
          'El color es tu dolor más alto del día y la carita es tu ánimo.',
      hijo: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Mes anterior',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(
                      () => _mes = DateTime(_mes.year, _mes.month - 1),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Mes siguiente',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: esMesActual
                        ? null
                        : () => setState(
                              () => _mes = DateTime(_mes.year, _mes.month + 1),
                            ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (final s in diasSemana)
                    Expanded(
                      child: Center(
                        child: Text(
                          s,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: 52,
                ),
                children: celdas,
              ),
              const SizedBox(height: 12),
              _leyenda(const [
                (_colorLeve, 'Dolor leve (0-3)'),
                (_colorModerado, 'Moderado (4-6)'),
                (_colorIntenso, 'Intenso (7-10)'),
                (_colorSinDato, 'Sin registro'),
              ]),
              const SizedBox(height: 8),
              Text(
                'El contorno marca el día de hoy. Es una observación de tus '
                'propios registros, no un diagnóstico.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Pantalla ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y Métricas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _cargando ? null : _cargar,
          ),
        ],
      ),
      body: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final sintomasEnRango =
        _sintomas.where((r) => _enRango(r.fechaHora)).toList();
    final animosEnRango = _animos.where((r) => _enRango(r.fecha)).toList();

    final dolorPorDia = _dolorPorDia(sintomasEnRango);
    final animoPorDia = _animoPorDia(animosEnRango);

    // Resumen
    final diasConRegistro = {...dolorPorDia.keys, ...animoPorDia.keys}.length;

    String dolorProm = '—';
    String dolorNivel = 'Sin registros';
    Color dolorColor = Colors.grey;
    String dolorMax = '—';
    String dolorMaxFecha = 'Sin registros';
    Color dolorMaxColor = Colors.grey;
    if (sintomasEnRango.isNotEmpty) {
      final prom = sintomasEnRango
              .map((r) => r.intensidadDolor)
              .reduce((a, b) => a + b) /
          sintomasEnRango.length;
      dolorProm = prom.toStringAsFixed(1);
      dolorNivel = _nivelDolor(prom);
      dolorColor = _colorDolor(prom);

      final mayor = sintomasEnRango
          .reduce((a, b) => b.intensidadDolor > a.intensidadDolor ? b : a);
      dolorMax = '${mayor.intensidadDolor}/10';
      dolorMaxFecha = _fechaLarga(mayor.fechaHora);
      dolorMaxColor = _colorDolor(mayor.intensidadDolor);
    }

    String animoEmoji = '—';
    String animoEtiqueta = 'Sin registros';
    if (animosEnRango.isNotEmpty) {
      final prom = animosEnRango
              .map((r) => r.estadoAnimo)
              .reduce((a, b) => a + b) /
          animosEnRango.length;
      final idx = prom.round().clamp(1, 5).toInt();
      animoEmoji = RegistroEmocional.emojis[idx - 1];
      animoEtiqueta = RegistroEmocional.etiquetas[idx - 1];
    }

    final diasAnimoBajo = animoPorDia.values.where((v) => v <= 2).length;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7 días')),
              ButtonSegment(value: 30, label: Text('30 días')),
            ],
            selected: {_dias},
            onSelectionChanged: (s) => setState(() => _dias = s.first),
          ),
          const SizedBox(height: 12),

          // Resumen
          Row(
            children: [
              _tileResumen(
                titulo: 'Días con registro',
                valor: '$diasConRegistro/$_dias',
                detalle: 'en el periodo',
                color: Theme.of(context).colorScheme.primary,
              ),
              _tileResumen(
                titulo: 'Dolor promedio',
                valor: dolorProm,
                detalle: dolorNivel,
                color: dolorColor,
              ),
            ],
          ),
          Row(
            children: [
              _tileResumen(
                titulo: 'Dolor más alto',
                valor: dolorMax,
                detalle: dolorMaxFecha,
                color: dolorMaxColor,
              ),
              _tileResumen(
                titulo: 'Ánimo promedio',
                valor: animoEmoji,
                detalle: animoEtiqueta,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),

          if (diasAnimoBajo >= 3) ...[
            const SizedBox(height: 4),
            _tarjetaApoyo(),
          ],
          const SizedBox(height: 8),

          // Dolor por día
          _tarjetaSimple(
            titulo: 'Intensidad del dolor por día',
            subtitulo:
                'Si registras varias veces en un día, se muestra el valor más alto.',
            hijo: dolorPorDia.isEmpty
                ? _vacio('Aún no hay registros de dolor en este periodo.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _graficoBarras(
                        valores: dolorPorDia,
                        maxY: 10,
                        intervaloY: 2,
                        colorDe: _colorDolor,
                        tituloEjeY: 'Dolor (0-10)',
                        etiquetaY: (v) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(fontSize: 11),
                        ),
                        valorCeroVisible: true,
                      ),
                      const SizedBox(height: 8),
                      _leyenda(const [
                        (_colorLeve, 'Leve (0-3)'),
                        (_colorModerado, 'Moderado (4-6)'),
                        (_colorIntenso, 'Intenso (7-10)'),
                      ]),
                    ],
                  ),
          ),
          const SizedBox(height: 12),

          // Ánimo por día
          _tarjetaSimple(
            titulo: 'Estado de ánimo por día',
            subtitulo: 'Tu check-in diario, de 😣 muy bajo a 😊 muy bueno.',
            hijo: animoPorDia.isEmpty
                ? _vacio('Aún no hay check-ins en este periodo.')
                : _graficoBarras(
                    valores: animoPorDia,
                    maxY: 5,
                    intervaloY: 1,
                    colorDe: _colorAnimo,
                    tituloEjeY: 'Ánimo',
                    etiquetaY: (v) {
                      if (v < 1 || v > 5 || v != v.roundToDouble()) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        RegistroEmocional.emojis[v.toInt() - 1],
                        style: const TextStyle(fontSize: 16),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),

          // Premium: hallazgos + calendario mensual
          if (_esPremium)
            _seccionPremium(dolorPorDia, animoPorDia, sintomasEnRango)
          else
            _tarjetaBloqueada(),
          const SizedBox(height: 12),

          // Zonas y síntomas frecuentes
          _tarjetaFrecuencia(
            titulo: 'Zonas de dolor más frecuentes',
            conteo: _frecuencias(sintomasEnRango.map((r) => r.localizaciones)),
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _tarjetaFrecuencia(
            titulo: 'Síntomas asociados más frecuentes',
            conteo:
                _frecuencias(sintomasEnRango.map((r) => r.sintomasAsociados)),
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 24),

          // Historial
          Text('Registros de síntomas',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _leyenda(const [
            (_colorLeve, 'Dolor leve (0-3)'),
            (_colorModerado, 'Moderado (4-6)'),
            (_colorIntenso, 'Intenso (7-10)'),
          ]),
          const SizedBox(height: 8),
          if (sintomasEnRango.isEmpty)
            const Text('Sin registros en este periodo.')
          else
            ...sintomasEnRango.reversed.map(_itemSintoma),
          const SizedBox(height: 24),
          Text('Check-ins de ánimo',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (animosEnRango.isEmpty)
            const Text('Sin check-ins en este periodo.')
          else
            ...animosEnRango.reversed.map(_itemAnimo),

          // Espacio para que el botón flotante "Agente" no tape el final.
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _itemSintoma(HistorialSintoma r) {
    final zonas = r.localizaciones.isEmpty
        ? 'Sin zona de dolor'
        : r.localizaciones.join(', ');
    final color = _colorDolor(r.intensidadDolor);
    final nivel =
        r.intensidadDolor == 0 ? 'Sin dolor' : _nivelDolor(r.intensidadDolor);
    final tieneNota =
        r.observacion != null && r.observacion!.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    zonas,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.25),
                    border: Border.all(color: color),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${r.intensidadDolor}/10 · $nivel',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_fechaLarga(r.fechaHora)} · ${_hora(r.fechaHora)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (r.sintomasAsociados.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Síntomas: ${r.sintomasAsociados.join(', ')}'),
            ],
            if (tieneNota) ...[
              const SizedBox(height: 4),
              Text('Nota: ${r.observacion!.trim()}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _itemAnimo(RegistroEmocional r) {
    final tieneNota = r.notaLibre != null && r.notaLibre!.trim().isNotEmpty;
    return Card(
      child: ListTile(
        leading: Text(r.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(r.etiqueta),
        subtitle: Text(
          tieneNota
              ? '${_fechaLarga(r.fecha)}\n${r.notaLibre!.trim()}'
              : _fechaLarga(r.fecha),
        ),
        isThreeLine: tieneNota,
      ),
    );
  }
}