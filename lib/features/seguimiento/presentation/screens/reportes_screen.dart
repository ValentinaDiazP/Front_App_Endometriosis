import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/resumen_medico_pdf.dart';
import '../../../../core/services/sintomas_service.dart';
import '../../models/historial_sintoma.dart';
import '../../models/registro_emocional.dart';
import 'premium_info_screen.dart';
 
// Colores semánticos del dolor: verde (leve) → naranja (moderado) → rojo (intenso).
const _colorLeve = Color(0xFF81C784);
const _colorLeveSuave = Color(0xFFC5E1A5);
const _colorModerado = Color(0xFFFFB74D);
const _colorIntenso = Color(0xFFE57373);
const _colorSinDato = Color(0xFFEEEEEE);
const _bordeSuave = Color(0xFFEBD3DA);
 
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
 
String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
 
double _media(Iterable<num> v) =>
    v.fold<double>(0, (suma, x) => suma + x) / v.length;
 
String _veces(int n) => n == 1 ? '1 vez' : '$n veces';
 
/// Resumen de una medicación mencionada en los registros.
class _MedicacionResumen {
  final String nombre;
  int registros = 0;
  final Map<String, int> alivios = {};
 
  _MedicacionResumen(this.nombre);
 
  String? get alivioFrecuente {
    if (alivios.isEmpty) return null;
    return alivios.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }
}
 
/// Opciones que elige la usuaria antes de exportar el PDF.
class _OpcionesPdf {
  final String nombre;
  final String medica;
  final String institucion;
  final bool incluirNotas;
  const _OpcionesPdf(
    this.nombre,
    this.medica,
    this.institucion,
    this.incluirNotas,
  );
}
 
/// Pestaña Reportes.
///
/// Plan básico: resumen, tendencia de dolor y ánimo, lo que más aparece y
/// los últimos registros. Premium suma: resumen de seguimiento, hallazgos,
/// calendario mensual, cruces (sueño, estrés, energía), capacidad del día,
/// medicación y alivio, y el periodo de 90 días.
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
  bool _generandoPdf = false;
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
        if (!esPremium && _dias > 30) _dias = 30;
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
 
  Map<int, RegistroEmocional> _checkinPorDia(List<RegistroEmocional> enRango) {
    final m = <int, RegistroEmocional>{};
    for (final r in enRango) {
      m[_indiceDia(r.fecha)] = r;
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
 
  List<MapEntry<String, int>> _top(Map<String, int> conteo, int n) {
    final ordenado = conteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ordenado.take(n).toList();
  }
 
  /// Otros tipos de dolor escritos por la usuaria, separados por coma,
  /// punto y coma o salto de línea, y contados por número de registros.
  Map<String, int> _otrosTipos(List<HistorialSintoma> lista) {
    final m = <String, int>{};
    for (final r in lista) {
      final t = r.otrosTiposDolor;
      if (t == null) continue;
      for (final parte in t.split(RegExp(r'[,;\n]'))) {
        final s = parte.trim().toLowerCase();
        if (s.isNotEmpty) m[s] = (m[s] ?? 0) + 1;
      }
    }
    return m;
  }
 
  List<_MedicacionResumen> _medicaciones(List<HistorialSintoma> lista) {
    final m = <String, _MedicacionResumen>{};
    for (final r in lista) {
      if (r.tomoMedicacion != true) continue;
      final det = r.medicacionDetalle?.trim() ?? '';
      final clave = det.isEmpty ? 'sin nombre' : det.toLowerCase();
      final item = m.putIfAbsent(
        clave,
        () => _MedicacionResumen(det.isEmpty ? 'Sin nombre' : _cap(det)),
      );
      item.registros++;
      final a = r.alivioMedicacion;
      if (a != null) item.alivios[a] = (item.alivios[a] ?? 0) + 1;
    }
    final resultado = m.values.toList()
      ..sort((a, b) => b.registros.compareTo(a.registros));
    return resultado;
  }
 
  /// Ánimo promedio (1-5) en días de dolor intenso (>= 7) vs el resto.
  /// Devuelve null si faltan días para comparar.
  (double, double)? _comparaAnimo(Map<int, int> dolor, Map<int, int> animo) {
    final ambos = dolor.keys.where(animo.containsKey).toList();
    final intensos = [
      for (final i in ambos)
        if (dolor[i]! >= 7) animo[i]!
    ];
    final otros = [
      for (final i in ambos)
        if (dolor[i]! < 7) animo[i]!
    ];
    if (intensos.isEmpty || otros.isEmpty) return null;
    return (_media(intensos), _media(otros));
  }
 
  /// Dolor promedio de los días con check-in según un criterio. `grupo`
  /// devuelve true (grupo A), false (grupo B) o null (no aplica ese día).
  (double?, int, double?, int) _cruce(
    Map<int, int> dolor,
    Map<int, RegistroEmocional> checkins,
    bool? Function(RegistroEmocional) grupo,
  ) {
    final a = <int>[];
    final b = <int>[];
    for (final e in dolor.entries) {
      final c = checkins[e.key];
      if (c == null) continue;
      final g = grupo(c);
      if (g == null) continue;
      (g ? a : b).add(e.value);
    }
    return (
      a.isEmpty ? null : _media(a),
      a.length,
      b.isEmpty ? null : _media(b),
      b.length,
    );
  }
 
  // ---------- Piezas visuales ----------
 
  Widget _tarjetaSimple({
    required String titulo,
    String? subtitulo,
    required Widget hijo,
  }) {
    return Card(
      margin: EdgeInsets.zero,
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
        padding: const EdgeInsets.symmetric(vertical: 24),
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
 
  Widget _insigniaPremium() {
    return Container(
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
    );
  }
 
  Widget _etiquetaNivel(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
 
  Widget _chipFrecuencia(String nombre, int cantidad) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text.rich(
        TextSpan(
          text: '${_cap(nombre)} · ',
          style: const TextStyle(fontSize: 13),
          children: [
            TextSpan(
              text: '$cantidad',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _tileMini({
    required String titulo,
    required String valor,
    required String detalle,
    required Color color,
    double tamanoValor = 24,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _bordeSuave),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                fontSize: tamanoValor,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(detalle, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
 
  /// Aviso amable (para todas las usuarias, sin importar el plan) cuando
  /// hay varios días de ánimo bajo en el periodo.
  Widget _tarjetaApoyo() {
    return const Card(
      margin: EdgeInsets.zero,
      color: Color(0xFFEDE7F6),
      child: Padding(
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
 
  void _avisoProximamente(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }
 
  // ---------- Exportar PDF ----------
 
  Future<_OpcionesPdf?> _pedirOpcionesPdf({required bool compartir}) {
    final nombreCtrl = TextEditingController();
    final medicaCtrl = TextEditingController();
    final institucionCtrl = TextEditingController();
    var incluirNotas = false;
    return showModalBottomSheet<_OpcionesPdf>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de mi seguimiento',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Incluye tus registros de los últimos $_dias días.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nombreCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Tu nombre (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: medicaCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Dirigido a: profesional de la salud (opcional)',
                  hintText: 'Ej.: Dra. Carolina Pérez, o déjalo vacío si es para ti',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: institucionCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Institución (opcional)',
                  hintText: 'Ej.: Clínica o hospital',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Incluir mis notas personales'),
                subtitle: const Text(
                  'Observaciones de síntomas. Por defecto no se incluyen.',
                ),
                value: incluirNotas,
                onChanged: (v) => setSheet(() => incluirNotas = v),
              ),
              const SizedBox(height: 4),
              Text(
                'Este PDF contiene información de salud. Compártelo solo con '
                'quien tú quieras.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(
                    _OpcionesPdf(
                      nombreCtrl.text.trim(),
                      medicaCtrl.text.trim(),
                      institucionCtrl.text.trim(),
                      incluirNotas,
                    ),
                  ),
                  child: Text(compartir ? 'Generar y compartir' : 'Generar PDF'),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
 
  Future<void> _exportarPdf({
    required bool compartir,
    required List<HistorialSintoma> enRango,
    required List<RegistroEmocional> animosEnRango,
  }) async {
    if (enRango.isEmpty && animosEnRango.isEmpty) {
      _avisoProximamente('Aún no hay registros en este periodo para exportar.');
      return;
    }
    final opciones = await _pedirOpcionesPdf(compartir: compartir);
    if (opciones == null || !mounted) return;
 
    setState(() => _generandoPdf = true);
    try {
      final bytes = await ResumenMedicoPdf.generar(
        sintomas: enRango,
        checkins: animosEnRango,
        inicio: _inicio,
        fin: _hoy,
        nombre: opciones.nombre,
        medica: opciones.medica,
        institucion: opciones.institucion,
        incluirNotas: opciones.incluirNotas,
      );
      final archivo = 'resumen_florecer_${_clave(_hoy)}.pdf';
      if (compartir) {
        await ResumenMedicoPdf.compartir(bytes, archivo);
      } else {
        await ResumenMedicoPdf.vistaPrevia(bytes, archivo);
      }
    } catch (e) {
      if (!mounted) return;
      _avisoProximamente('No se pudo generar el PDF. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _generandoPdf = false);
    }
  }
 
  // ---------- Bloques comunes (todos los planes) ----------
 
  Widget _tarjetaResumen({
    required int diasConRegistro,
    required String dolorProm,
    required String dolorNivel,
    required Color dolorColor,
    required String animoEmoji,
    required String animoEtiqueta,
  }) {
    final primario = Theme.of(context).colorScheme.primary;
    final periodo = 'los últimos $_dias días';
 
    final Widget frase = diasConRegistro == 0
        ? const Text(
            'Aún no hay registros en este periodo. Cuando guardes el primero, '
            'aquí verás cómo vas.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          )
        : Text.rich(
            TextSpan(
              text: 'En $periodo registraste ',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              children: [
                TextSpan(
                  text: diasConRegistro == 1
                      ? '1 día'
                      : '$diasConRegistro días',
                  style: TextStyle(
                    color: primario,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          );
 
    String? detalle;
    if (dolorProm != '—' && animoEmoji != '—') {
      detalle = 'Tu dolor promedio fue ${dolorNivel.toLowerCase()} y tu '
          'ánimo, ${animoEtiqueta.toLowerCase()}.';
    } else if (dolorProm != '—') {
      detalle = 'Tu dolor promedio fue ${dolorNivel.toLowerCase()}.';
    } else if (animoEmoji != '—') {
      detalle = 'Tu ánimo promedio fue ${animoEtiqueta.toLowerCase()}.';
    }
 
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            frase,
            if (detalle != null) ...[
              const SizedBox(height: 4),
              Text(detalle, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                _tileMini(
                  titulo: 'Días con registro',
                  valor: '$diasConRegistro/$_dias',
                  detalle: 'en el periodo',
                  color: primario,
                ),
                const SizedBox(width: 8),
                _tileMini(
                  titulo: 'Dolor promedio',
                  valor: dolorProm,
                  detalle: dolorNivel,
                  color: dolorColor,
                ),
                const SizedBox(width: 8),
                _tileMini(
                  titulo: 'Ánimo promedio',
                  valor: animoEmoji,
                  detalle: animoEtiqueta,
                  color: Theme.of(context).colorScheme.secondary,
                  tamanoValor: 26,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
 
  /// Una sola gráfica: línea del dolor con puntos de color según la
  /// intensidad. Con 7 días, una fila de caritas debajo muestra el ánimo.
  Widget _tarjetaTendencia(Map<int, int> dolor, Map<int, int> animo) {
    final primario = Theme.of(context).colorScheme.primary;
    final titulo = _dias == 7
        ? 'Cómo te fue esta semana'
        : (_dias == 30 ? 'Cómo te fue este mes' : 'Cómo te fue en $_dias días');
 
    final claves = dolor.keys.toList()..sort();
    final spots = [
      for (final i in claves) FlSpot(i.toDouble(), dolor[i]!.toDouble()),
    ];
 
    final intervaloX = _dias <= 7 ? 1.0 : (_dias <= 30 ? 5.0 : 15.0);
    const margenIzq = 28.0;
 
    Widget grafico;
    if (spots.isEmpty) {
      grafico = _vacio('Aún no hay registros de dolor en este periodo.');
    } else {
      grafico = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: LineChart(
                LineChartData(
                  minX: -0.5,
                  maxX: _dias - 0.5,
                  minY: 0,
                  maxY: 10,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 7,
                        color: _colorIntenso.withOpacity(0.6),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ],
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
                        reservedSize: margenIzq,
                        interval: 5,
                        getTitlesWidget: (v, meta) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: intervaloX,
                        getTitlesWidget: (v, meta) {
                          if (v != v.roundToDouble() || v < 0 || v > _dias - 1) {
                            return const SizedBox.shrink();
                          }
                          final f = _inicio.add(Duration(days: v.toInt()));
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${f.day}/${f.month}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (puntos) => puntos.map((p) {
                        final f = _inicio.add(Duration(days: p.x.round()));
                        return LineTooltipItem(
                          '${_fechaLarga(f)}: ${p.y.toInt()}/10',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: primario,
                      barWidth: 2.5,
                      belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: _dias <= 7 ? 6 : 3.5,
                          color: _colorDolor(spot.y),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_dias == 7)
            Padding(
              // Mismo margen izquierdo que el eje del gráfico para que cada
              // carita quede debajo de su día.
              padding: const EdgeInsets.only(left: margenIzq, right: 8, top: 4),
              child: Row(
                children: [
                  for (var i = 0; i < _dias; i++)
                    Expanded(
                      child: Center(
                        child: animo[i] == null
                            ? Text(
                                '–',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              )
                            : Text(
                                RegistroEmocional.emojis[animo[i]! - 1],
                                style: const TextStyle(fontSize: 20),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          _leyenda(const [
            (_colorLeve, 'Leve (0-3)'),
            (_colorModerado, 'Moderado (4-6)'),
            (_colorIntenso, 'Intenso (7-10)'),
          ]),
          const SizedBox(height: 6),
          Text(
            _dias == 7
                ? 'Toca un punto para ver el valor. Debajo, tu ánimo de cada día.'
                : 'Toca un punto para ver el valor de ese día.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }
 
    return _tarjetaSimple(
      titulo: titulo,
      subtitulo: 'Tu dolor día a día (0 a 10).',
      hijo: grafico,
    );
  }
 
  Widget _tarjetaMasAparece(List<HistorialSintoma> enRango) {
    final n = _esPremium ? 5 : 3;
    final zonas = _top(_frecuencias(enRango.map((r) => r.localizaciones)), n);
    final sintomas =
        _top(_frecuencias(enRango.map((r) => r.sintomasAsociados)), n);
 
    Widget bloque(String titulo, List<MapEntry<String, int>> items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              'Sin datos en este periodo.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final e in items) _chipFrecuencia(e.key, e.value)],
            ),
        ],
      );
    }
 
    return _tarjetaSimple(
      titulo: 'Lo que más aparece',
      subtitulo: 'En los últimos $_dias días, por número de registros.',
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bloque('Zonas de dolor', zonas),
          const SizedBox(height: 14),
          bloque('Síntomas asociados', sintomas),
        ],
      ),
    );
  }
 
  Widget _filaRegistro(HistorialSintoma r, {required bool ultima}) {
    final zonas = r.localizaciones.isEmpty
        ? 'Sin zona de dolor'
        : r.localizaciones.join(', ');
    final nivel =
        r.intensidadDolor == 0 ? 'Sin dolor' : _nivelDolor(r.intensidadDolor);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: ultima
            ? null
            : const Border(bottom: BorderSide(color: _bordeSuave)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zonas,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fechaLarga(r.fechaHora)} · ${_hora(r.fechaHora)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _etiquetaNivel(
            '${r.intensidadDolor}/10 · $nivel',
            _colorDolor(r.intensidadDolor),
          ),
        ],
      ),
    );
  }
 
  Widget _tarjetaUltimos(
    List<HistorialSintoma> enRango,
    List<RegistroEmocional> animosEnRango,
  ) {
    final recientes = enRango.reversed.take(3).toList();
    return _tarjetaSimple(
      titulo: 'Tus últimos registros',
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (recientes.isEmpty)
            const Text('Sin registros en este periodo.')
          else
            for (var i = 0; i < recientes.length; i++)
              _filaRegistro(recientes[i], ultima: i == recientes.length - 1),
          if (enRango.length > 3 || animosEnRango.isNotEmpty) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _abrirHistorialCompleto(enRango, animosEnRango),
              child: Text('Ver todos (${enRango.length})'),
            ),
          ],
        ],
      ),
    );
  }
 
  void _abrirHistorialCompleto(
    List<HistorialSintoma> enRango,
    List<RegistroEmocional> animosEnRango,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Tus registros · $_dias días')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Registros de síntomas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (enRango.isEmpty)
                const Text('Sin registros en este periodo.')
              else
                ...enRango.reversed.map(_itemSintoma),
              const SizedBox(height: 24),
              Text(
                'Check-ins de ánimo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (animosEnRango.isEmpty)
                const Text('Sin check-ins en este periodo.')
              else
                ...animosEnRango.reversed.map(_itemAnimo),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
 
  /// Invitación única al plan Premium (solo plan básico).
  Widget _tarjetaInvitacion() {
    final primario = Theme.of(context).colorScheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primario, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, color: primario),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Llévalo más lejos con Premium',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Resumen de tu seguimiento en PDF, hallazgos sobre tu dolor y tu '
              'ánimo, calendario mensual y cruces con sueño y estrés.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PremiumInfoScreen(),
                  ),
                ),
                child: const Text('Conocer Premium'),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  // ---------- Bloques Premium ----------
 
  Widget _dato(String titulo, String valor, String sufijo) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              text: valor,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: sufijo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _lineaMedica(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text.rich(
        TextSpan(
          text: '$etiqueta: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
          children: [
            TextSpan(
              text: valor,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  /// Resumen pensado para llevar a la consulta, con exportación a PDF.
  Widget _tarjetaMedica({
    required List<HistorialSintoma> enRango,
    required List<RegistroEmocional> animosEnRango,
    required Map<int, int> dolor,
    required Map<int, int> animo,
  }) {
    final primario = Theme.of(context).colorScheme.primary;
 
    String dolorProm = '—';
    String dolorMax = '—';
    String dolorMaxFecha = '';
    if (enRango.isNotEmpty) {
      dolorProm = _media(enRango.map((r) => r.intensidadDolor)).toStringAsFixed(1);
      final mayor = enRango
          .reduce((a, b) => b.intensidadDolor > a.intensidadDolor ? b : a);
      dolorMax = '${mayor.intensidadDolor}';
      dolorMaxFecha = '/10 · ${_fechaLarga(mayor.fechaHora)}';
    }
    final diasIntensos = dolor.values.where((v) => v >= 7).length;
 
    String animoProm = '—';
    String animoSufijo = '';
    if (animosEnRango.isNotEmpty) {
      final p = _media(animosEnRango.map((r) => r.estadoAnimo));
      animoProm = p.toStringAsFixed(1);
      animoSufijo =
          '/5 · ${RegistroEmocional.etiquetas[p.round().clamp(1, 5) - 1]}';
    }
 
    final zonas = _top(_frecuencias(enRango.map((r) => r.localizaciones)), 3);
    final sintomas =
        _top(_frecuencias(enRango.map((r) => r.sintomasAsociados)), 3);
    final compara = _comparaAnimo(dolor, animo);
    final otros = _top(_otrosTipos(enRango), 3);
    final meds = _medicaciones(enRango).take(2).toList();
 
    final conCapacidad =
        animosEnRango.where((r) => r.capacidadDia != null).toList();
    final limitadas = conCapacidad
        .where((r) => r.capacidadDia == 'poco' || r.capacidadDia == 'no_pude')
        .length;
 
    final horas = animosEnRango.where((r) => r.horasSueno != null).toList();
    final energias = animosEnRango.where((r) => r.energia != null).toList();
    final partesSueno = <String>[
      if (horas.isNotEmpty)
        '${_media(horas.map((r) => r.horasSueno!)).toStringAsFixed(1)} h de sueño en promedio',
      if (energias.isNotEmpty)
        'energía ${_media(energias.map((r) => r.energia!)).toStringAsFixed(1)}/5',
    ];
 
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primario, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Resumen de mi seguimiento',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                _insigniaPremium(),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Para llevar a una consulta, compartir con quien tú quieras o guardarlo para ti.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: _bordeSuave),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PERIODO',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          letterSpacing: 0.6,
                        ),
                  ),
                  Text(
                    '${_fechaLarga(_inicio)} – ${_fechaLarga(_hoy)} ${_hoy.year}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dato('Dolor promedio', dolorProm, '/10'),
                      _dato('Dolor más alto', dolorMax, dolorMaxFecha),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dato('Días con dolor intenso', '$diasIntensos', ' de $_dias'),
                      _dato('Ánimo promedio', animoProm, animoSufijo),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (zonas.isNotEmpty)
                    _lineaMedica(
                      'Zonas más frecuentes',
                      zonas.map((e) => _cap(e.key)).join(', '),
                    ),
                  if (sintomas.isNotEmpty)
                    _lineaMedica(
                      'Síntomas más frecuentes',
                      sintomas.map((e) => _cap(e.key)).join(', '),
                    ),
                  if (compara != null)
                    _lineaMedica(
                      'Ánimo y dolor',
                      'los días de dolor intenso tu ánimo fue '
                          '${compara.$1 < compara.$2 ? 'más bajo' : 'similar o mejor'} '
                          '(${compara.$1.toStringAsFixed(1)} frente a '
                          '${compara.$2.toStringAsFixed(1)})',
                    ),
                  if (otros.isNotEmpty)
                    _lineaMedica(
                      'Otros tipos de dolor',
                      otros.map((e) => '${e.key} (${_veces(e.value)})').join(', '),
                    ),
                  if (meds.isNotEmpty)
                    _lineaMedica(
                      'Medicación',
                      meds.map((m) {
                        final a = m.alivioFrecuente;
                        return '${m.nombre.toLowerCase()} en ${m.registros} '
                            '${m.registros == 1 ? 'registro' : 'registros'}'
                            '${a != null ? ' · alivio: $a' : ''}';
                      }).join('; '),
                    ),
                  if (conCapacidad.isNotEmpty)
                    _lineaMedica(
                      'Actividades limitadas',
                      '$limitadas de ${conCapacidad.length} días con respuesta',
                    ),
                  if (partesSueno.isNotEmpty)
                    _lineaMedica('Sueño y energía', partesSueno.join(' · ')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _generandoPdf
                        ? null
                        : () => _exportarPdf(
                              compartir: false,
                              enRango: enRango,
                              animosEnRango: animosEnRango,
                            ),
                    child: Text(_generandoPdf ? 'Generando…' : 'Exportar PDF'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _generandoPdf
                        ? null
                        : () => _exportarPdf(
                              compartir: true,
                              enRango: enRango,
                              animosEnRango: animosEnRango,
                            ),
                    child: const Text('Compartir'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Es un resumen de tus propios registros, no un diagnóstico.',
              style: Theme.of(context).textTheme.bodySmall,
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
      child: SizedBox(
        height: 176,
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
      ),
    );
  }
 
  /// Cuatro hallazgos con ⓘ que explica cómo se calcula cada uno.
  Widget _hallazgos(
    Map<int, int> dolor,
    Map<int, int> animo,
    List<HistorialSintoma> enRango,
  ) {
    // 1) Ánimo en días de dolor intenso vs el resto.
    String h1Valor = '—';
    String h1Detalle = 'Faltan días con dolor intenso y con ánimo para comparar.';
    Color h1Color = Colors.grey;
    final compara = _comparaAnimo(dolor, animo);
    if (compara != null) {
      final a = compara.$1;
      final b = compara.$2;
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
        Text(
          'Lo que encontramos en tus registros',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Toca la ⓘ para ver cómo se calcula cada dato.',
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
                (_colorLeve, 'Leve (0-3)'),
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
 
  /// Barra horizontal con un valor de dolor (0-10) y cuántos días lo respaldan.
  Widget _barraDolor(String etiqueta, double? valor, int dias) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(etiqueta, style: const TextStyle(fontSize: 13))),
              Text(
                valor == null ? '—' : valor.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: LinearProgressIndicator(
              value: valor == null ? 0 : (valor / 10).clamp(0.0, 1.0),
              minHeight: 14,
              color: valor == null ? Colors.grey : _colorDolor(valor),
              backgroundColor: (valor == null ? Colors.grey : _colorDolor(valor))
                  .withOpacity(0.18),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dias == 1 ? '1 día' : '$dias días',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
 
  /// Compara el dolor promedio entre dos grupos de días. Solo muestra la
  /// comparación si ambos grupos tienen al menos un día.
  Widget _tarjetaCruce({
    required String titulo,
    required String subtitulo,
    required String etiquetaA,
    required String etiquetaB,
    required (double?, int, double?, int) datos,
    required String faltante,
  }) {
    final (a, na, b, nb) = datos;
    final completo = a != null && b != null;
    final total = na + nb;
 
    String nota;
    if (completo) {
      nota = total < 7
          ? 'Hay pocos días con este dato; tómalo con calma, a medida que '
              'registres será más claro. No es un diagnóstico.'
          : 'Es una observación de tus propios registros, no un diagnóstico.';
    } else {
      final falta = a == null ? etiquetaA : etiquetaB;
      nota = 'Aún no se puede comparar: falta al menos un día con '
          '"$falta". Sigue registrando tu check-in y tu dolor.';
    }
 
    return _tarjetaSimple(
      titulo: titulo,
      subtitulo: subtitulo,
      hijo: (a == null && b == null)
          ? Text(faltante)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (a != null) _barraDolor(etiquetaA, a, na),
                if (b != null) _barraDolor(etiquetaB, b, nb),
                Text(nota, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
    );
  }
 
  Widget _tarjetaCapacidad(List<RegistroEmocional> animosEnRango) {
    const orden = ['todo', 'casi_todo', 'poco', 'no_pude'];
    const colores = [_colorLeve, _colorLeveSuave, _colorModerado, _colorIntenso];
    final conteo = {for (final k in orden) k: 0};
    for (final r in animosEnRango) {
      final c = r.capacidadDia;
      if (c != null && conteo.containsKey(c)) conteo[c] = conteo[c]! + 1;
    }
    final total = conteo.values.fold<int>(0, (a, b) => a + b);
 
    return _tarjetaSimple(
      titulo: 'Qué tanto pudiste hacer',
      subtitulo: total == 0
          ? 'Según tus check-ins.'
          : 'Según tus check-ins de estos $_dias días ($total ${total == 1 ? 'día' : 'días'}).',
      hijo: total == 0
          ? const Text(
              'Aún no hay respuestas. Puedes contarlo en tu check-in diario, '
              'en "¿Pudiste hacer tus actividades?".',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: SizedBox(
                    height: 22,
                    child: Row(
                      children: [
                        for (var i = 0; i < orden.length; i++)
                          if (conteo[orden[i]]! > 0)
                            Expanded(
                              flex: conteo[orden[i]]!,
                              child: Container(color: colores[i]),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _leyenda([
                  for (var i = 0; i < orden.length; i++)
                    (
                      colores[i],
                      '${RegistroEmocional.capacidades[orden[i]]} · ${conteo[orden[i]]}',
                    ),
                ]),
                const SizedBox(height: 10),
                Text(
                  'Muestra cuánto afectó el dolor tu día a día, sin medir '
                  '"productividad".',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
 
  Widget _tarjetaMedicacion(List<HistorialSintoma> enRango) {
    final meds = _medicaciones(enRango).take(5).toList();
 
    Color colorAlivio(String a) => a == 'mucho'
        ? _colorLeve
        : (a == 'algo' ? _colorModerado : _colorIntenso);
 
    return _tarjetaSimple(
      titulo: 'Medicación y alivio',
      subtitulo: 'Lo que tomaste para el dolor y qué tanto te ayudó.',
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (meds.isEmpty)
            const Text(
              'Aún no hay medicación anotada en este periodo. Puedes anotarla '
              'en Síntomas, cuando tengas dolor.',
            )
          else
            for (var i = 0; i < meds.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: i == meds.length - 1
                      ? null
                      : const Border(bottom: BorderSide(color: _bordeSuave)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meds[i].nombre,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            meds[i].registros == 1
                                ? '1 registro'
                                : '${meds[i].registros} registros',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (meds[i].alivioFrecuente != null)
                      _etiquetaNivel(
                        'Alivio: ${meds[i].alivioFrecuente}',
                        colorAlivio(meds[i].alivioFrecuente!),
                      ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          Text(
            'Solo anotamos lo que tomaste. No es una recomendación: consulta '
            'con un profesional de la salud antes de cambiar algo.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
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
    final checkins = _checkinPorDia(animosEnRango);
 
    final diasConRegistro = {...dolorPorDia.keys, ...animoPorDia.keys}.length;
 
    String dolorProm = '—';
    String dolorNivel = 'Sin registros';
    Color dolorColor = Colors.grey;
    if (sintomasEnRango.isNotEmpty) {
      final prom = _media(sintomasEnRango.map((r) => r.intensidadDolor));
      dolorProm = prom.toStringAsFixed(1);
      dolorNivel = _nivelDolor(prom);
      dolorColor = _colorDolor(prom);
    }
 
    String animoEmoji = '—';
    String animoEtiqueta = 'Sin registros';
    if (animosEnRango.isNotEmpty) {
      final prom = _media(animosEnRango.map((r) => r.estadoAnimo));
      final idx = prom.round().clamp(1, 5).toInt();
      animoEmoji = RegistroEmocional.emojis[idx - 1];
      animoEtiqueta = RegistroEmocional.etiquetas[idx - 1];
    }
 
    final diasAnimoBajo = animoPorDia.values.where((v) => v <= 2).length;
 
    final bloques = <Widget>[
      SegmentedButton<int>(
        segments: [
          const ButtonSegment(value: 7, label: Text('7 días')),
          const ButtonSegment(value: 30, label: Text('30 días')),
          if (_esPremium) const ButtonSegment(value: 90, label: Text('90 días')),
        ],
        selected: {_dias},
        onSelectionChanged: (s) => setState(() => _dias = s.first),
      ),
      _tarjetaResumen(
        diasConRegistro: diasConRegistro,
        dolorProm: dolorProm,
        dolorNivel: dolorNivel,
        dolorColor: dolorColor,
        animoEmoji: animoEmoji,
        animoEtiqueta: animoEtiqueta,
      ),
      if (diasAnimoBajo >= 3) _tarjetaApoyo(),
      if (_esPremium)
        _tarjetaMedica(
          enRango: sintomasEnRango,
          animosEnRango: animosEnRango,
          dolor: dolorPorDia,
          animo: animoPorDia,
        ),
      _tarjetaTendencia(dolorPorDia, animoPorDia),
      if (!_esPremium) _tarjetaInvitacion(),
      if (_esPremium) ...[
        _hallazgos(dolorPorDia, animoPorDia, sintomasEnRango),
        _tarjetaCalendario(),
        _tarjetaCruce(
          titulo: 'Tu dolor según el sueño',
          subtitulo: 'Dolor promedio (0-10) según las horas que dormiste.',
          etiquetaA: 'Menos de 6 h de sueño',
          etiquetaB: '6 h o más',
          datos: _cruce(
            dolorPorDia,
            checkins,
            (c) => c.horasSueno == null ? null : c.horasSueno! < 6,
          ),
          faltante:
              'Registra tus horas de sueño en el check-in para ver esta '
              'comparación. Necesitas días con sueño menor y mayor a 6 horas.',
        ),
        _tarjetaCruce(
          titulo: 'Tu dolor según el estrés',
          subtitulo: 'Dolor promedio (0-10) según cómo fue tu día.',
          etiquetaA: 'Estrés alto (4-5)',
          etiquetaB: 'Estrés bajo (1-3)',
          datos: _cruce(
            dolorPorDia,
            checkins,
            (c) => c.estres == null ? null : c.estres! >= 4,
          ),
          faltante:
              'Cuéntanos tu estrés en el check-in para ver esta comparación.',
        ),
        _tarjetaCruce(
          titulo: 'Tu dolor según la energía',
          subtitulo: 'Dolor promedio (0-10) según tu energía del día.',
          etiquetaA: 'Energía baja (1-2)',
          etiquetaB: 'Energía normal o alta (3-5)',
          datos: _cruce(
            dolorPorDia,
            checkins,
            (c) => c.energia == null ? null : c.energia! <= 2,
          ),
          faltante:
              'Cuéntanos tu energía en el check-in para ver esta comparación.',
        ),
        _tarjetaCapacidad(animosEnRango),
        _tarjetaMedicacion(sintomasEnRango),
      ],
      _tarjetaMasAparece(sintomasEnRango),
      _tarjetaUltimos(sintomasEnRango, animosEnRango),
    ];
 
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          for (final b in bloques)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: b),
          // Espacio para que el botón flotante "Agente" no tape el final.
          const SizedBox(height: 78),
        ],
      ),
    );
  }
 
  // ---------- Items del historial completo ----------
 
  Widget _itemSintoma(HistorialSintoma r) {
    final zonas = r.localizaciones.isEmpty
        ? 'Sin zona de dolor'
        : r.localizaciones.join(', ');
    final nivel =
        r.intensidadDolor == 0 ? 'Sin dolor' : _nivelDolor(r.intensidadDolor);
    final tieneNota =
        r.observacion != null && r.observacion!.trim().isNotEmpty;
    final otros = r.otrosTiposDolor?.trim() ?? '';
 
    String? medicacion;
    if (r.tomoMedicacion == true) {
      final det = r.medicacionDetalle?.trim() ?? '';
      medicacion = 'Tomaste: ${det.isEmpty ? 'algo para el dolor' : det}'
          '${r.alivioMedicacion != null ? ' · alivio: ${r.alivioMedicacion}' : ''}';
    } else if (r.tomoMedicacion == false) {
      medicacion = 'No tomaste medicación para el dolor.';
    }
 
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
                _etiquetaNivel(
                  '${r.intensidadDolor}/10 · $nivel',
                  _colorDolor(r.intensidadDolor),
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
            if (otros.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Otros tipos de dolor: $otros'),
            ],
            if (medicacion != null) ...[
              const SizedBox(height: 4),
              Text(medicacion),
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
    final extras = <String>[
      if (r.energia != null) 'Energía ${r.energia}/5',
      if (r.horasSueno != null) 'Sueño ${r.horasSueno} h',
      if (r.descanso != null) 'Descanso ${r.descanso}/5',
      if (r.estres != null) 'Estrés ${r.estres}/5',
      if (r.capacidadEtiqueta != null) 'Actividades: ${r.capacidadEtiqueta}',
    ];
 
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.etiqueta,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _fechaLarga(r.fecha),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (extras.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(extras.join(' · '), style: const TextStyle(fontSize: 13)),
                  ],
                  if (tieneNota) ...[
                    const SizedBox(height: 4),
                    Text(r.notaLibre!.trim()),
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