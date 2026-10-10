import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/sintomas_service.dart';
import '../../models/historial_sintoma.dart';
import '../../models/registro_emocional.dart';

/// Pestaña Reportes: tendencia de dolor y de ánimo en los últimos 7 o 30
/// días, relación dolor-ánimo, zonas y síntomas más frecuentes, y el
/// historial de registros. Todo viene de la API real.
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
  bool _cargando = true;
  String? _error;

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
      if (!mounted) return;
      setState(() {
        _sintomas = sintomas;
        _animos = animos;
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

  // Primer día del rango (a medianoche) y día de hoy.
  DateTime get _hoy {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  DateTime get _inicio => _hoy.subtract(Duration(days: _dias - 1));

  bool _enRango(DateTime fecha) {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    return !dia.isBefore(_inicio) && !dia.isAfter(_hoy);
  }

  double _posicionX(DateTime fecha) {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    return dia.difference(_inicio).inDays.toDouble();
  }

  String _fechaCorta(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}';

  /// Un punto por día: el dolor más alto registrado ese día.
  List<FlSpot> _puntosDolor(List<HistorialSintoma> enRango) {
    final maximoPorDia = <double, int>{};
    for (final r in enRango) {
      final x = _posicionX(r.fechaHora);
      final actual = maximoPorDia[x];
      if (actual == null || r.intensidadDolor > actual) {
        maximoPorDia[x] = r.intensidadDolor;
      }
    }
    final puntos = maximoPorDia.entries
        .map((e) => FlSpot(e.key, e.value.toDouble()))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
    return puntos;
  }

  List<FlSpot> _puntosAnimo(List<RegistroEmocional> enRango) {
    final puntos = enRango
        .map((r) => FlSpot(_posicionX(r.fecha), r.estadoAnimo.toDouble()))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
    return puntos;
  }

  Widget _grafico({
    required List<FlSpot> puntos,
    required double minY,
    required double maxY,
    required double intervaloY,
    required Color color,
  }) {
    final intervaloX = _dias <= 7 ? 1.0 : 5.0;
    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (_dias - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: intervaloY,
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: intervaloY,
                  getTitlesWidget: (valor, meta) => Text(
                    valor.toInt().toString(),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
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
            lineBarsData: [
              LineChartBarData(
                spots: puntos,
                isCurved: true,
                color: color,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withOpacity(0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaGrafico({
    required String titulo,
    required String promedio,
    required List<FlSpot> puntos,
    required double minY,
    required double maxY,
    required double intervaloY,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(promedio, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            if (puntos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('Aún no hay registros en este periodo.'),
                ),
              )
            else
              _grafico(
                puntos: puntos,
                minY: minY,
                maxY: maxY,
                intervaloY: intervaloY,
                color: color,
              ),
          ],
        ),
      ),
    );
  }

  /// Cuenta cuántas veces aparece cada nombre en las listas dadas.
  Map<String, int> _frecuencias(Iterable<List<String>> listas) {
    final conteo = <String, int>{};
    for (final lista in listas) {
      for (final nombre in lista) {
        conteo[nombre] = (conteo[nombre] ?? 0) + 1;
      }
    }
    return conteo;
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (top.isEmpty)
              const Text('Aún no hay registros en este periodo.')
            else
              ...top.map(
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
                      Text('${e.value}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Un punto por día que tenga síntoma Y check-in: x = ánimo, y = dolor.
  Widget _tarjetaDispersion({
    required List<FlSpot> dolor,
    required List<FlSpot> animo,
    required Color color,
  }) {
    final animoPorDia = {for (final p in animo) p.x: p.y};
    final puntos = <ScatterSpot>[
      for (final p in dolor)
        if (animoPorDia.containsKey(p.x))
          ScatterSpot(
            animoPorDia[p.x]!,
            p.y,
            dotPainter: FlDotCirclePainter(color: color, radius: 7),
          ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dolor y ánimo',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Cada punto es un día con síntoma y check-in registrados.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (puntos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Registra síntomas y ánimo el mismo día para ver la relación.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              SizedBox(
                height: 220,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8),
                  child: ScatterChart(
                    ScatterChartData(
                      scatterSpots: puntos,
                      minX: 0.5,
                      maxX: 5.5,
                      minY: 0,
                      maxY: 10,
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: const Text('Dolor (0-10)',
                              style: TextStyle(fontSize: 11)),
                          axisNameSize: 20,
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 2,
                            getTitlesWidget: (valor, meta) => Text(
                              valor.toInt().toString(),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: const Text(
                              'Ánimo (1 = muy bajo, 5 = muy bueno)',
                              style: TextStyle(fontSize: 11)),
                          axisNameSize: 22,
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: 1,
                            getTitlesWidget: (valor, meta) {
                              if (valor < 1 || valor > 5) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  valor.toInt().toString(),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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

    final puntosDolor = _puntosDolor(sintomasEnRango);
    final puntosAnimo = _puntosAnimo(animosEnRango);

    final promedioDolor = sintomasEnRango.isEmpty
        ? '—'
        : (sintomasEnRango
                    .map((r) => r.intensidadDolor)
                    .reduce((a, b) => a + b) /
                sintomasEnRango.length)
            .toStringAsFixed(1);
    final promedioAnimo = animosEnRango.isEmpty
        ? '—'
        : (animosEnRango.map((r) => r.estadoAnimo).reduce((a, b) => a + b) /
                animosEnRango.length)
            .toStringAsFixed(1);

    final colores = Theme.of(context).colorScheme;

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
            onSelectionChanged: (seleccion) =>
                setState(() => _dias = seleccion.first),
          ),
          const SizedBox(height: 16),
          _tarjetaGrafico(
            titulo: 'Intensidad del dolor',
            promedio: 'Promedio del periodo: $promedioDolor / 10',
            puntos: puntosDolor,
            minY: 0,
            maxY: 10,
            intervaloY: 2,
            color: colores.primary,
          ),
          const SizedBox(height: 12),
          _tarjetaGrafico(
            titulo: 'Estado de ánimo',
            promedio: 'Promedio del periodo: $promedioAnimo / 5',
            puntos: puntosAnimo,
            minY: 1,
            maxY: 5,
            intervaloY: 1,
            color: colores.secondary,
          ),
          const SizedBox(height: 12),
          _tarjetaDispersion(
            dolor: puntosDolor,
            animo: puntosAnimo,
            color: colores.tertiary,
          ),
          const SizedBox(height: 12),
          _tarjetaFrecuencia(
            titulo: 'Zonas de dolor más frecuentes',
            conteo: _frecuencias(sintomasEnRango.map((r) => r.localizaciones)),
            color: colores.primary,
          ),
          const SizedBox(height: 12),
          _tarjetaFrecuencia(
            titulo: 'Síntomas asociados más frecuentes',
            conteo:
                _frecuencias(sintomasEnRango.map((r) => r.sintomasAsociados)),
            color: colores.secondary,
          ),
          const SizedBox(height: 24),
          Text('Registros de síntomas',
              style: Theme.of(context).textTheme.titleMedium),
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
        ],
      ),
    );
  }

  Widget _itemSintoma(HistorialSintoma r) {
    final zonas = r.localizaciones.isEmpty
        ? 'Sin zona de dolor'
        : r.localizaciones.join(', ');
    final extras = r.sintomasAsociados.isEmpty
        ? ''
        : '\n${r.sintomasAsociados.join(', ')}';
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('${r.intensidadDolor}')),
        title: Text(zonas),
        subtitle: Text('${_fechaCorta(r.fechaHora)}$extras'),
        isThreeLine: extras.isNotEmpty,
      ),
    );
  }

  Widget _itemAnimo(RegistroEmocional r) {
    final nota = (r.notaLibre == null || r.notaLibre!.trim().isEmpty)
        ? ''
        : '\n${r.notaLibre}';
    return Card(
      child: ListTile(
        leading: Text(r.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(r.etiqueta),
        subtitle: Text('${_fechaCorta(r.fecha)}$nota'),
        isThreeLine: nota.isNotEmpty,
      ),
    );
  }
}