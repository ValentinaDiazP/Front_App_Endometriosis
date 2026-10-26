import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
 
// Colores del dolor: verde (leve) → naranja (moderado) → rojo (intenso).
const _verde = Color(0xFF81C784);
const _verdeSuave = Color(0xFFC5E1A5);
const _naranja = Color(0xFFFFB74D);
const _rojo = Color(0xFFE57373);
const _borde = Color(0xFFEBD3DA);
 
/// Precio mostrado en la propuesta. Confirmar con el equipo antes de publicar.
const _precio = r'$18.000 COP al mes';
 
// Dolor más alto de cada día de un mes de EJEMPLO (null = sin registro).
// Datos inventados solo para mostrar cómo se vería la información.
const List<int?> _dolorMes = [
  null, null, 3, null, 4, null, null, 8, 6, null,
  null, 5, null, 5, null, 2, null, 1, null, 3,
  5, null, 8, null, 2, null, 2, 4, null, 3,
];
 
Color _colorDolor(num v) {
  final r = v.round();
  if (r <= 3) return _verde;
  if (r <= 6) return _naranja;
  return _rojo;
}
 
String _emojiDolor(int v) => v >= 7 ? '😣' : (v >= 4 ? '😐' : '🙂');
 
/// Pantalla que explica por qué conviene el plan Premium: problema,
/// comparación de planes, ejemplos visuales con datos simulados y para qué
/// sirve cada herramienta.
class PremiumInfoScreen extends StatelessWidget {
  const PremiumInfoScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Florecer Premium')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _hero(context),
                _seccion(context, child: _problemas(context)),
                _seccion(context, child: _comparacion(context)),
                _seccion(context, child: _introEjemplos(context)),
                _seccion(
                  context,
                  child: _demo(
                    context,
                    numero: '1',
                    titulo: 'Un resumen de tu seguimiento, listo para compartir',
                    gancho:
                        'Una página con tu dolor, tus zonas, tus síntomas y lo '
                        'que tomaste, lista para llevar a una consulta o guardar para ti.',
                    visual: _visualResumen(context),
                    utilidad:
                        'En una consulta corta, enseñarlo ayuda a explicar lo '
                        'que viviste entre una cita y otra, sin depender de la '
                        'memoria.',
                  ),
                ),
                _seccion(
                  context,
                  child: _demo(
                    context,
                    numero: '2',
                    titulo: 'Tu dolor en el tiempo',
                    gancho:
                        'Hasta 90 días en una sola gráfica, con un color por '
                        'cada nivel de dolor.',
                    visual: _visualTendencia(context),
                    utilidad:
                        'Ver si tus crisis se acercan, se alargan o se '
                        'espacian, y si algo cambió desde que empezaste un '
                        'tratamiento.',
                  ),
                ),
                _seccion(
                  context,
                  child: _demo(
                    context,
                    numero: '3',
                    titulo: 'Calendario de dolor y ánimo',
                    gancho:
                        'Cada día del mes con el color de tu dolor más alto y '
                        'una carita de tu ánimo.',
                    visual: _visualCalendario(context),
                    utilidad:
                        'Encontrar de un vistazo tus días más difíciles y '
                        'relacionarlos con tu ciclo.',
                  ),
                ),
                _seccion(
                  context,
                  child: _demo(
                    context,
                    numero: '4',
                    titulo: 'Qué se asocia con tu dolor',
                    gancho:
                        'Compara tu dolor según cuánto dormiste, tu estrés y tu '
                        'energía.',
                    visual: _visualCruces(context),
                    utilidad:
                        'Descubrir si los días de más dolor coinciden con poco '
                        'sueño o más estrés, para conversarlo con un profesional de la salud. Es '
                        'una asociación en tus datos, no una causa comprobada.',
                  ),
                ),
                _seccion(
                  context,
                  child: _demo(
                    context,
                    numero: '5',
                    titulo: 'Qué tanto pudiste hacer',
                    gancho:
                        'Cuántos días pudiste hacer todo, casi todo, poco o '
                        'nada de lo que tenías.',
                    visual: _visualCapacidad(context),
                    utilidad:
                        'Mostrar cuánto afecta la endometriosis tu día a día, '
                        'algo que a veces es difícil de explicar con palabras.',
                  ),
                ),
                _seccion(
                  context,
                  child: _demo(
                    context,
                    numero: '6',
                    titulo: 'Medicación y alivio',
                    gancho:
                        'Lo que anotaste que tomaste y qué tanto te ayudó cada '
                        'vez.',
                    visual: _visualMedicacion(context),
                    utilidad:
                        'Contarle a tu profesional de la salud qué tomas y cuánto te alivia. '
                        'Solo anotamos lo que tú registras: Florecer nunca '
                        'recomienda medicamentos ni dosis.',
                  ),
                ),
                _seccion(context, child: _paraQueSirve(context)),
                _seccion(context, child: _cierre(context)),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _barraInferior(context),
        ],
      ),
    );
  }
 
  // ---------- Estructura ----------
 
  Widget _seccion(BuildContext context, {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: child,
    );
  }
 
  Widget _hero(BuildContext context) {
    final primario = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primario, Color.lerp(primario, const Color(0xFF5E35B1), 0.55)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'FLORECER PREMIUM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Llega a tu consulta con datos, no solo con recuerdos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Premium convierte lo que ya registras en una historia clara de tu '
            'dolor, tu ánimo y tu día a día.',
            style: TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }
 
  Widget _titulo(BuildContext context, String texto, {String? sub}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texto,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(sub, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
 
  // ---------- 1. Problemas ----------
 
  Widget _problemas(BuildContext context) {
    Widget frase(String emoji, String texto) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo(context, '¿Te suena familiar?'),
        frase('🗓️', '"¿Cuándo fue la última vez que me dolió tanto?"'),
        frase('🩺', '"En la consulta se me olvida la mitad de lo que me pasó."'),
        frase('🔍', '"No sé qué hace que mi dolor empeore."'),
        const SizedBox(height: 12),
        Text(
          'Premium te ayuda a responderlas con tus propios registros.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
 
  // ---------- 2. Comparación de planes ----------
 
  Widget _comparacion(BuildContext context) {
    final primario = Theme.of(context).colorScheme.primary;
 
    Widget marca(bool si, {bool destacado = false}) {
      return SizedBox(
        width: 64,
        child: Center(
          child: si
              ? Icon(
                  Icons.check_circle,
                  color: destacado ? primario : Colors.grey.shade500,
                )
              : Icon(Icons.remove, color: Colors.grey.shade400),
        ),
      );
    }
 
    Widget fila(String texto, bool basico, {String? nota}) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _borde)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(texto, style: const TextStyle(fontSize: 14)),
                  if (nota != null)
                    Text(
                      nota,
                      style: TextStyle(
                        fontSize: 11,
                        color: primario,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            marca(basico),
            marca(true, destacado: true),
          ],
        ),
      );
    }
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo(context, 'Qué cambia con Premium'),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    const SizedBox(
                      width: 64,
                      child: Center(
                        child: Text(
                          'Básico',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Center(
                        child: Text(
                          'Premium',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primario,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                fila('Registrar síntomas, ciclo y ánimo', true),
                fila('Gráfica de tu dolor y ánimo', true),
                fila('Historial de 7 y 30 días', true),
                fila('Historial de 90 días', false),
                fila('Resumen de tu seguimiento en PDF', false),
                fila('Hallazgos sobre tu dolor y tu ánimo', false),
                fila('Calendario mensual de dolor y ánimo', false),
                fila('Cruces con sueño, estrés y energía', false),
                fila('Qué tanto pudiste hacer cada día', false),
                fila('Medicación y alivio', false),
              ],
            ),
          ),
        ),
      ],
    );
  }
 
  // ---------- 3. Ejemplos ----------
 
  Widget _introEjemplos(BuildContext context) {
    return _titulo(
      context,
      'Míralo en acción',
      sub: 'Estos ejemplos usan datos inventados para que veas cómo lucirían. '
          'Con Premium verás los tuyos.',
    );
  }
 
  Widget _etiquetaEjemplo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'EJEMPLO · datos simulados',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
 
  Widget _demo(
    BuildContext context, {
    required String numero,
    required String titulo,
    required String gancho,
    required Widget visual,
    required String utilidad,
  }) {
    final primario = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: primario,
              child: Text(
                numero,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                titulo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(gancho, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _etiquetaEjemplo(),
                const SizedBox(height: 12),
                visual,
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primario.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, size: 20, color: primario),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Para qué te sirve: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: utilidad,
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
 
  // ----- Visual 1: resumen de seguimiento -----
 
  Widget _visualResumen(BuildContext context) {
    final primario = Theme.of(context).colorScheme.primary;
    final gris = Theme.of(context).textTheme.bodySmall;
 
    Widget dato(String t, String v, String s) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t, style: gris),
              Text.rich(
                TextSpan(
                  text: v,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: s,
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
 
    Widget linea(String e, String v) => Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text.rich(
            TextSpan(
              text: '$e: ',
              style: gris?.copyWith(fontSize: 13),
              children: [
                TextSpan(
                  text: v,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        );
 
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: primario, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de mi seguimiento',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text('PERIODO · 1 – 30 sep', style: gris?.copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              dato('Dolor promedio', '4.1', '/10'),
              dato('Dolor más alto', '8', '/10 · 8 sep'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              dato('Días con dolor intenso', '2', ' de 30'),
              dato('Ánimo promedio', '3.2', '/5 · Estable'),
            ],
          ),
          const SizedBox(height: 6),
          linea('Zonas más frecuentes', 'Abdomen bajo, Lumbar, Pelvis'),
          linea('Síntomas más frecuentes', 'Fatiga, Náuseas'),
          linea('Otros tipos de dolor', 'al orinar (3 veces), al defecar (2 veces)'),
          linea('Medicación', 'ibuprofeno en 6 registros · alivio: algo'),
          linea('Actividades limitadas', '5 de 20 días con respuesta'),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: null,
                  child: Text('Exportar PDF'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: null,
                  child: Text('Compartir'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
 
  // ----- Visual 2: tendencia -----
 
  Widget _visualTendencia(BuildContext context) {
    final primario = Theme.of(context).colorScheme.primary;
    final spots = [
      for (var i = 0; i < _dolorMes.length; i++)
        if (_dolorMes[i] != null) FlSpot(i.toDouble(), _dolorMes[i]!.toDouble()),
    ];
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 190,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: LineChart(
              LineChartData(
                minX: -0.5,
                maxX: _dolorMes.length - 0.5,
                minY: 0,
                maxY: 10,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                ),
                lineTouchData: const LineTouchData(enabled: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 7,
                      color: _rojo.withOpacity(0.6),
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
                      reservedSize: 28,
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
                      interval: 5,
                      getTitlesWidget: (v, meta) {
                        if (v != v.roundToDouble() ||
                            v < 0 ||
                            v > _dolorMes.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${v.toInt() + 1}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
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
                        radius: 4.5,
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
        const SizedBox(height: 10),
        _leyenda(const [
          (_verde, 'Leve (0-3)'),
          (_naranja, 'Moderado (4-6)'),
          (_rojo, 'Intenso (7-10)'),
        ]),
      ],
    );
  }
 
  // ----- Visual 3: calendario -----
 
  Widget _visualCalendario(BuildContext context) {
    const diasSemana = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    const offset = 3; // el mes de ejemplo empieza un jueves
    final celdas = <Widget>[
      for (var i = 0; i < offset; i++) const SizedBox.shrink(),
      for (var d = 1; d <= _dolorMes.length; d++)
        Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _dolorMes[d - 1] == null
                ? Colors.grey.withOpacity(0.08)
                : _colorDolor(_dolorMes[d - 1]!).withOpacity(0.65),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$d',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: _dolorMes[d - 1] != null
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (_dolorMes[d - 1] != null)
                Text(
                  _emojiDolor(_dolorMes[d - 1]!),
                  style: const TextStyle(fontSize: 15),
                ),
            ],
          ),
        ),
    ];
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Text(
            'Septiembre (ejemplo)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final s in diasSemana)
              Expanded(
                child: Center(
                  child: Text(s, style: Theme.of(context).textTheme.bodySmall),
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
            mainAxisExtent: 48,
          ),
          children: celdas,
        ),
        const SizedBox(height: 10),
        _leyenda(const [
          (_verde, 'Leve'),
          (_naranja, 'Moderado'),
          (_rojo, 'Intenso'),
          (Color(0xFFE4DADD), 'Sin registro'),
        ]),
      ],
    );
  }
 
  // ----- Visual 4: cruces -----
 
  Widget _barra(String etiqueta, double valor) {
    final color = _colorDolor(valor);
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
                valor.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: LinearProgressIndicator(
              value: valor / 10,
              minHeight: 14,
              color: color,
              backgroundColor: color.withOpacity(0.18),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _visualCruces(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dolor promedio (0-10) según tu sueño',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        _barra('Menos de 6 h de sueño', 6.8),
        _barra('6 h o más', 3.2),
        const SizedBox(height: 4),
        Text(
          'Dolor promedio (0-10) según tu estrés',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        _barra('Estrés alto (4-5)', 6.5),
        _barra('Estrés bajo (1-3)', 3.4),
      ],
    );
  }
 
  // ----- Visual 5: capacidad del día -----
 
  Widget _visualCapacidad(BuildContext context) {
    const datos = [
      ('Todo', 6, _verde),
      ('Casi todo', 9, _verdeSuave),
      ('Poco', 5, _naranja),
      ('No pude', 2, _rojo),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: SizedBox(
            height: 24,
            child: Row(
              children: [
                for (final d in datos)
                  Expanded(flex: d.$2, child: Container(color: d.$3)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _leyenda([for (final d in datos) (d.$3, '${d.$1} · ${d.$2}')]),
        const SizedBox(height: 8),
        Text(
          'Ejemplo con 22 check-ins en el mes.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
 
  // ----- Visual 6: medicación -----
 
  Widget _visualMedicacion(BuildContext context) {
    Widget fila(String nombre, String detalle, String alivio, Color color,
        {bool ultima = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: ultima ? null : const Border(bottom: BorderSide(color: _borde)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(detalle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.25),
                border: Border.all(color: color),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Alivio: $alivio',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
 
    return Column(
      children: [
        fila('Ibuprofeno', '6 registros', 'algo', _naranja),
        fila('Paracetamol', '1 registro', 'nada', _rojo, ultima: true),
      ],
    );
  }
 
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
 
  // ---------- 4. Para qué sirve ----------
 
  Widget _paraQueSirve(BuildContext context) {
    final primario = Theme.of(context).colorScheme.primary;
 
    Widget item(IconData icono, String titulo, String texto) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primario.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: primario, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(texto, style: const TextStyle(fontSize: 14, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      );
    }
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo(context, 'En resumen, Premium te sirve para…'),
        item(
          Icons.medical_services_outlined,
          'Aprovechar mejor tu consulta',
          'Llevas un resumen claro en lugar de intentar recordarlo todo.',
        ),
        item(
          Icons.insights_outlined,
          'Entender tus patrones',
          'Ves cuándo duele más y qué se asocia: sueño, estrés, energía o ciclo.',
        ),
        item(
          Icons.fact_check_outlined,
          'Ver si algo te está ayudando',
          'Comparas tu dolor en el tiempo y lo que anotaste que tomaste.',
        ),
        item(
          Icons.favorite_border,
          'Sentirte acompañada',
          'Tus registros se convierten en una historia que tú puedes leer y compartir.',
        ),
      ],
    );
  }
 
  // ---------- 5. Cierre ----------
 
  Widget _cierre(BuildContext context) {
    final primario = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: primario, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Tus registros ya valen. Premium les saca el máximo.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _precio,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primario,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Florecer no reemplaza a un profesional de la salud y la información no es un '
            'diagnóstico. Premium organiza lo que tú registras para que lo '
            'conversen juntas.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
 
  Widget _barraInferior(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Florecer Premium',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_precio, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Los planes Premium llegan pronto. ¡Gracias por tu interés!',
                      ),
                    ),
                  );
                },
                child: const Text('Quiero Premium'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}