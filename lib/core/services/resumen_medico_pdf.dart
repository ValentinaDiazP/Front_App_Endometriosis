import 'dart:typed_data';
 
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
 
import '../../features/seguimiento/models/historial_sintoma.dart';
import '../../features/seguimiento/models/registro_emocional.dart';
 
/// Genera el "Resumen de mi seguimiento" en PDF a partir de los registros de la
/// usuaria. Solo organiza lo que ella anotó: no interpreta ni diagnostica, y
/// nunca recomienda medicamentos ni dosis.
class ResumenMedicoPdf {
  ResumenMedicoPdf._();
 
  static const _rosa = PdfColor.fromInt(0xFFB5496F);
  static const _verde = PdfColor.fromInt(0xFF81C784);
  static const _naranja = PdfColor.fromInt(0xFFFFB74D);
  static const _rojo = PdfColor.fromInt(0xFFE57373);
  static const _gris = PdfColors.grey700;
 
  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
 
  // ---------- API pública ----------
 
  /// Construye el PDF. `sintomas` y `checkins` ya deben venir filtrados al
  /// periodo [inicio, fin].
  static Future<Uint8List> generar({
    required List<HistorialSintoma> sintomas,
    required List<RegistroEmocional> checkins,
    required DateTime inicio,
    required DateTime fin,
    String? nombre,
    String? medica,
    String? institucion,
    bool incluirNotas = false,
  }) async {
    final tema = await _tema();
    final doc = pw.Document(title: 'Resumen de mi seguimiento', author: 'Florecer');
    final hoy = DateTime.now();
    final totalDias = fin.difference(inicio).inDays + 1;
 
    // ----- Cifras del periodo -----
    final diasConDolor = <int>{for (final r in sintomas) _clave(r.fechaHora)};
    final diasConAnimo = <int>{for (final r in checkins) _clave(r.fecha)};
    final diasConRegistro = {...diasConDolor, ...diasConAnimo}.length;
    final diasIntensos = <int>{
      for (final r in sintomas)
        if (r.intensidadDolor >= 7) _clave(r.fechaHora)
    }.length;
 
    final dolorProm = sintomas.isEmpty
        ? null
        : _media(sintomas.map((r) => r.intensidadDolor));
    final mayor = sintomas.isEmpty
        ? null
        : sintomas.reduce((a, b) => b.intensidadDolor > a.intensidadDolor ? b : a);
    final animoProm =
        checkins.isEmpty ? null : _media(checkins.map((r) => r.estadoAnimo));
    final diasAnimoBajo = <int>{
      for (final r in checkins)
        if (r.estadoAnimo <= 2) _clave(r.fecha)
    }.length;
    final animoIntenso = _animoSegunDolor(sintomas, checkins);
 
    final zonas = _top(_frecuencias(sintomas.map((r) => r.localizaciones)), 3);
    final sintomasFrec =
        _top(_frecuencias(sintomas.map((r) => r.sintomasAsociados)), 3);
    final otros = _top(_otrosTipos(sintomas), 6);
    final meds = _medicaciones(sintomas);
    final conRespuestaMed = sintomas.where((r) => r.tomoMedicacion != null).length;
    final dijeronSi = sintomas.where((r) => r.tomoMedicacion == true).length;
 
    final cSueno = _cruce(
      sintomas, checkins,
      (c) => c.horasSueno == null ? null : c.horasSueno! < 6,
    );
    final cEstres = _cruce(
      sintomas, checkins,
      (c) => c.estres == null ? null : c.estres! >= 4,
    );
    final cEnergia = _cruce(
      sintomas, checkins,
      (c) => c.energia == null ? null : c.energia! <= 2,
    );
    final cCapacidad = _cruce(
      sintomas, checkins,
      (c) => c.capacidadDia == null
          ? null
          : (c.capacidadDia == 'poco' || c.capacidadDia == 'no_pude'),
    );
 
    final conCapacidad = checkins.where((r) => r.capacidadDia != null).toList();
    final horas = checkins.where((r) => r.horasSueno != null).toList();
    final descansos = checkins.where((r) => r.descanso != null).toList();
    final energias = checkins.where((r) => r.energia != null).toList();
    final estreses = checkins.where((r) => r.estres != null).toList();
 
    final registros = [...sintomas]
      ..sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
    const maxFilas = 40;
 
    // ----- Texto del resumen -----
    final resumen = StringBuffer(
      'Entre el ${_f(inicio)} y el ${_f(fin)} ${fin.year} ($totalDias días), '
      'la usuaria registró información en **${_dias(diasConRegistro)}**.',
    );
    if (dolorProm != null && mayor != null) {
      resumen.write(
        ' Su dolor promedio fue de **${dolorProm.toStringAsFixed(1)} sobre 10** '
        '(nivel ${_nivel(dolorProm)}) y el valor más alto fue '
        '**${mayor.intensidadDolor} sobre 10**, el ${_f(mayor.fechaHora)}.',
      );
      resumen.write(
        diasIntensos > 0
            ? ' En **${_dias(diasIntensos)}** el dolor fue intenso (7 o más).'
            : ' No hubo días con dolor intenso (7 o más).',
      );
    }
    if (animoProm != null) {
      resumen.write(
        ' Su ánimo promedio fue de **${animoProm.toStringAsFixed(1)} sobre 5** '
        '(${RegistroEmocional.etiquetas[animoProm.round().clamp(1, 5) - 1].toLowerCase()}).',
      );
      if (diasAnimoBajo > 0) {
        resumen.write(
          ' En **${_dias(diasAnimoBajo)}** el ánimo fue bajo o muy bajo (1 o 2 de 5).',
        );
      }
    }
 
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
        theme: tema,
        footer: (ctx) => _pie(ctx, hoy),
        build: (ctx) => [
          // ----- Encabezado -----
          pw.Text(
            'Resumen de mi seguimiento',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: _rosa,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Periodo: ${_f(inicio)} - ${_f(fin)} ${fin.year}  ($totalDias días)',
            style: const pw.TextStyle(fontSize: 10.5),
          ),
          if (nombre != null && nombre.isNotEmpty)
            pw.Text('Nombre: $nombre', style: const pw.TextStyle(fontSize: 10.5)),
          if (medica != null && medica.isNotEmpty)
            pw.Text('Dirigido a: $medica', style: const pw.TextStyle(fontSize: 10.5)),
          if (institucion != null && institucion.isNotEmpty)
            pw.Text('Institución: $institucion', style: const pw.TextStyle(fontSize: 10.5)),
          pw.Text(
            'Generado con Florecer el ${_f(hoy)} ${hoy.year}. Datos anotados por la usuaria.',
            style: pw.TextStyle(fontSize: 8.5, color: _gris),
          ),
 
          // ----- Resumen -----
          _titulo('Resumen del periodo'),
          pw.Row(
            children: [
              _kpi('Días con registro', '$diasConRegistro', 'de $totalDias días'),
              _kpi(
                'Dolor promedio',
                dolorProm == null ? '-' : dolorProm.toStringAsFixed(1),
                '/10',
              ),
              _kpi(
                'Dolor más alto',
                mayor == null ? '-' : '${mayor.intensidadDolor}/10',
                mayor == null ? '' : _f(mayor.fechaHora),
              ),
              _kpi('Días con dolor intenso', '$diasIntensos', '(7 o más)'),
              _kpi(
                'Ánimo promedio',
                animoProm == null ? '-' : animoProm.toStringAsFixed(1),
                animoProm == null
                    ? ''
                    : '/5 · ${RegistroEmocional.etiquetas[animoProm.round().clamp(1, 5) - 1]}',
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          _p(resumen.toString()),
          if (animoIntenso != null)
            _p(
              'Los días de dolor intenso, el ánimo promedio fue de '
              '**${animoIntenso.$1.toStringAsFixed(1)}** (${_dias(animoIntenso.$2)} '
              'con ambos datos), frente a **${animoIntenso.$3.toStringAsFixed(1)}** '
              '(${_dias(animoIntenso.$4)}) en los demás días.',
            ),
 
          // ----- Gráfica -----
          _titulo('Dolor en el periodo'),
          if (sintomas.isEmpty)
            _p('Sin registros de dolor en este periodo.')
          else ...[
            _graficaLinea(sintomas, inicio, totalDias),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                _punto(_verde, 'Leve (0-3)'),
                pw.SizedBox(width: 12),
                _punto(_naranja, 'Moderado (4-6)'),
                pw.SizedBox(width: 12),
                _punto(_rojo, 'Intenso (7-10)'),
              ],
            ),
            pw.SizedBox(height: 5),
            _p(
              'Eje vertical: dolor más alto anotado cada día (0 a 10). Eje horizontal: '
              'fecha. La curva une los días con registro, así que muestra la tendencia '
              'del dolor; los puntos de color indican el nivel de cada día.'
              '${mayor == null ? '' : ' El punto más alto fue **${mayor.intensidadDolor}/10** el ${_f(mayor.fechaHora)}.'}',
              size: 9,
            ),
          ],
 
          // ----- Zonas y síntomas -----
          if (zonas.isNotEmpty || sintomasFrec.isNotEmpty) ...[
            _titulo('Lo que más se repite'),
            if (zonas.isNotEmpty)
              _p(_fraseTop(
                'La zona de dolor más mencionada fue',
                zonas,
                sintomas.length,
              )),
            if (sintomasFrec.isNotEmpty)
              _p(_fraseTop(
                'El síntoma asociado más frecuente fue',
                sintomasFrec,
                sintomas.length,
              )),
          ],
 
          if (otros.isNotEmpty) ...[
            _titulo('Otros tipos de dolor (en palabras de la usuaria)'),
            _p(
              'La usuaria anotó, con sus propias palabras, otros tipos de dolor: '
              '${_enumerar([for (final e in otros) '**${e.key}** (${_veces(e.value)})'])}.',
            ),
          ],
 
          // ----- Medicación -----
          if (conRespuestaMed > 0) ...[
            _titulo('Medicación anotada y alivio percibido'),
            _p(
              'De los ${_registros(conRespuestaMed)} en los que respondió si tomó algo '
              'para el dolor, ${dijeronSi == 0 ? 'en ninguno indicó que sí.' : 'en **$dijeronSi** indicó que sí.'}',
            ),
            for (final m in meds.take(5)) _p(_fraseMedicacion(m)),
            _nota('Información anotada por la usuaria. No es una indicación de tratamiento.'),
          ],
 
          // ----- Asociaciones -----
          if (_hay(cSueno) || _hay(cEstres) || _hay(cEnergia) || _hay(cCapacidad)) ...[
            _titulo('Dolor según sueño, estrés, energía y actividades'),
            if (_hay(cSueno))
              _p(_fraseCruce(
                'Sueño.',
                'durmió menos de 6 horas',
                'durmió 6 horas o más',
                cSueno,
              )),
            if (_hay(cEstres))
              _p(_fraseCruce(
                'Estrés.',
                'tuvo estrés alto (4-5)',
                'tuvo estrés bajo (1-3)',
                cEstres,
              )),
            if (_hay(cEnergia))
              _p(_fraseCruce(
                'Energía.',
                'tuvo energía baja (1-2)',
                'tuvo energía normal o alta (3-5)',
                cEnergia,
              )),
            if (_hay(cCapacidad))
              _p(_fraseCruce(
                'Actividades.',
                'pudo hacer poco o no pudo hacer sus actividades',
                'pudo hacer todo o casi todo',
                cCapacidad,
              )),
            _nota(
              'Son asociaciones observadas en los registros de la usuaria, con pocos '
              'días por grupo; no indican causa.',
            ),
          ],
 
          // ----- Día a día -----
          if (conCapacidad.isNotEmpty ||
              horas.isNotEmpty ||
              descansos.isNotEmpty ||
              energias.isNotEmpty ||
              estreses.isNotEmpty) ...[
            _titulo('Día a día'),
            if (conCapacidad.isNotEmpty) _p(_fraseCapacidad(conCapacidad)),
            if (horas.isNotEmpty)
              _p(
                'Durmió en promedio **${_media(horas.map((r) => r.horasSueno!)).toStringAsFixed(1)} horas** '
                '(${_dias(horas.length)} con dato).',
              ),
            if (descansos.isNotEmpty)
              _p(
                'Su sensación de descanso fue de **${_media(descansos.map((r) => r.descanso!)).toStringAsFixed(1)} sobre 5** '
                '(${_dias(descansos.length)} con dato).',
              ),
            if (energias.isNotEmpty)
              _p(
                'Su energía promedio fue de **${_media(energias.map((r) => r.energia!)).toStringAsFixed(1)} sobre 5** '
                '(${_dias(energias.length)} con dato).',
              ),
            if (estreses.isNotEmpty)
              _p(
                'Su estrés promedio fue de **${_media(estreses.map((r) => r.estres!)).toStringAsFixed(1)} sobre 5** '
                '(${_dias(estreses.length)} con dato).',
              ),
          ],
 
          // ----- Registros -----
          _titulo('Registros de síntomas'),
          if (registros.isEmpty)
            _p('Sin registros en este periodo.')
          else ...[
            if (registros.length > maxFilas)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  'Se muestran los $maxFilas registros más recientes de ${registros.length}.',
                  style: pw.TextStyle(fontSize: 8, color: _gris),
                ),
              ),
            _encabezadoTabla(),
            for (final r in registros.take(maxFilas)) _filaRegistro(r, incluirNotas),
          ],
          pw.SizedBox(height: 8),
        ],
      ),
    );
 
    return doc.save();
  }
 
  /// Muestra la vista previa / diálogo de impresión (en web permite guardar
  /// como PDF).
  static Future<void> vistaPrevia(Uint8List bytes, String nombreArchivo) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat formato) async => bytes,
      name: nombreArchivo,
    );
  }
 
  /// Comparte el PDF (hoja de compartir en el celular; descarga en web).
  static Future<void> compartir(Uint8List bytes, String nombreArchivo) async {
    await Printing.sharePdf(bytes: bytes, filename: nombreArchivo);
  }
 
  // ---------- Tema y tipografía ----------
 
  static Future<pw.ThemeData> _tema() async {
    try {
      final base = await PdfGoogleFonts.robotoRegular();
      final bold = await PdfGoogleFonts.robotoBold();
      final italic = await PdfGoogleFonts.robotoItalic();
      return pw.ThemeData.withFont(base: base, bold: bold, italic: italic);
    } catch (_) {
      // Sin internet: tipografía estándar del PDF.
      return pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
      );
    }
  }
 
  // ---------- Piezas visuales ----------
 
  static pw.Widget _pie(pw.Context ctx, DateTime hoy) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400, thickness: 0.5),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                'Generado por Florecer con datos anotados por la usuaria. No es un '
                'diagnóstico ni reemplaza la valoración de un profesional de la salud.',
                style: pw.TextStyle(fontSize: 7.5, color: _gris),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Text(
              'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 7.5, color: _gris),
            ),
          ],
        ),
      ],
    );
  }
 
  static pw.Widget _titulo(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: 12.5,
          fontWeight: pw.FontWeight.bold,
          color: _rosa,
        ),
      ),
    );
  }
 
  static pw.Widget _kpi(String etiqueta, String valor, String detalle) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 5),
        padding: const pw.EdgeInsets.all(7),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(etiqueta, style: pw.TextStyle(fontSize: 7.5, color: _gris)),
            pw.SizedBox(height: 2),
            pw.Text(
              valor,
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
            if (detalle.isNotEmpty)
              pw.Text(detalle, style: const pw.TextStyle(fontSize: 7.5)),
          ],
        ),
      ),
    );
  }
 
  /// Párrafo con negritas: el texto entre `**` sale en negrita.
  static pw.Widget _p(String texto, {double size = 9.8}) {
    final partes = texto.split('**');
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.RichText(
        text: pw.TextSpan(
          style: pw.TextStyle(fontSize: size, lineSpacing: 2),
          children: [
            for (var i = 0; i < partes.length; i++)
              pw.TextSpan(
                text: partes[i],
                style: i.isOdd ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
              ),
          ],
        ),
      ),
    );
  }
 
  static pw.Widget _nota(String texto) {
    return pw.Text(texto, style: pw.TextStyle(fontSize: 8, color: _gris));
  }
 
  static pw.Widget _punto(PdfColor color, String texto) {
    return pw.Row(
      children: [
        pw.Container(width: 7, height: 7, color: color),
        pw.SizedBox(width: 4),
        pw.Text(texto, style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }
 
  /// Curva con el dolor más alto de cada día. Puntos del color de su nivel,
  /// eje vertical de 0 a 10 y fechas reales en el eje horizontal.
  static pw.Widget _graficaLinea(
    List<HistorialSintoma> sintomas,
    DateTime inicio,
    int totalDias,
  ) {
    final base = DateTime(inicio.year, inicio.month, inicio.day);
    final maximos = <int, int>{};
    for (final r in sintomas) {
      final dia = DateTime(r.fechaHora.year, r.fechaHora.month, r.fechaHora.day);
      final i = dia.difference(base).inDays;
      if (i < 0 || i >= totalDias) continue;
      final actual = maximos[i];
      if (actual == null || r.intensidadDolor > actual) {
        maximos[i] = r.intensidadDolor;
      }
    }
    final dias = maximos.keys.toList()..sort();
    if (dias.isEmpty) return _p('Sin registros de dolor en este periodo.');
 
    // Marcas del eje horizontal: cada 1, 2, 7 o 14 días según el periodo.
    final paso = totalDias <= 8 ? 1 : (totalDias <= 16 ? 2 : (totalDias <= 35 ? 7 : 14));
    final normales = <int>[for (var i = 0; i < totalDias; i += paso) i];
    final ultimo = totalDias - 1;
    final marcas = <double>[for (final i in normales) i.toDouble()];
    var mostrarUltimo = true;
    if (normales.last != ultimo) {
      mostrarUltimo = (ultimo - normales.last) > paso * 0.6;
      marcas.add(ultimo.toDouble());
    }
    if (marcas.length < 2) marcas.add(marcas.last + 1);
 
    String etiquetaX(num v) {
      final i = v.toInt();
      if (i == ultimo && !normales.contains(i) && !mostrarUltimo) return '';
      return _f(base.add(Duration(days: i)));
    }
 
    List<pw.PointChartValue> puntosDe(bool Function(int) cumple) => [
          for (final d in dias)
            if (cumple(maximos[d]!))
              pw.PointChartValue(d.toDouble(), maximos[d]!.toDouble()),
        ];
 
    final todos = puntosDe((_) => true);
    final leves = puntosDe((v) => v <= 3);
    final medios = puntosDe((v) => v > 3 && v <= 6);
    final altos = puntosDe((v) => v >= 7);
 
    const estiloEje = pw.TextStyle(fontSize: 8, color: PdfColors.grey800);
 
    return pw.SizedBox(
      height: 175,
      child: pw.Chart(
        grid: pw.CartesianGrid(
          xAxis: pw.FixedAxis<double>(
            marcas,
            format: etiquetaX,
            divisions: true,
            divisionsDashed: true,
            divisionsColor: PdfColors.grey400,
            textStyle: estiloEje,
            margin: 6,
          ),
          yAxis: pw.FixedAxis<double>(
            const [0, 2, 4, 6, 8, 10],
            format: (v) => v.toInt().toString(),
            divisions: true,
            divisionsDashed: true,
            divisionsColor: PdfColors.grey400,
            textStyle: estiloEje,
            margin: 6,
          ),
        ),
        datasets: [
          if (todos.length >= 2)
            pw.LineDataSet(
              data: todos,
              color: _rosa,
              lineWidth: 1.6,
              isCurved: todos.length >= 3,
              drawPoints: false,
            ),
          if (leves.isNotEmpty) _puntos(leves, _verde),
          if (medios.isNotEmpty) _puntos(medios, _naranja),
          if (altos.isNotEmpty) _puntos(altos, _rojo),
        ],
      ),
    );
  }
 
  static pw.LineDataSet _puntos(List<pw.PointChartValue> datos, PdfColor color) {
    return pw.LineDataSet(
      data: datos,
      drawLine: false,
      drawPoints: true,
      pointSize: 3.2,
      pointColor: color,
      color: color,
    );
  }
 
  static pw.Widget _encabezadoTabla() {
    final estilo = pw.TextStyle(
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: _gris,
    );
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.8),
        ),
      ),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 80, child: pw.Text('Fecha', style: estilo)),
          pw.SizedBox(width: 34, child: pw.Text('Dolor', style: estilo)),
          pw.Expanded(flex: 2, child: pw.Text('Zonas', style: estilo)),
          pw.Expanded(flex: 3, child: pw.Text('Síntomas y otros dolores', style: estilo)),
          pw.Expanded(flex: 2, child: pw.Text('Medicación', style: estilo)),
        ],
      ),
    );
  }
 
  static pw.Widget _filaRegistro(HistorialSintoma r, bool incluirNotas) {
    final zonas = r.localizaciones.isEmpty ? '-' : r.localizaciones.join(', ');
    final extra = <String>[
      if (r.sintomasAsociados.isNotEmpty) r.sintomasAsociados.join(', '),
      if ((r.otrosTiposDolor ?? '').trim().isNotEmpty)
        'Otros: ${r.otrosTiposDolor!.trim()}',
    ];
 
    String med = '-';
    if (r.tomoMedicacion == true) {
      final d = (r.medicacionDetalle ?? '').trim();
      med = '${d.isEmpty ? 'Sí' : d}'
          '${r.alivioMedicacion != null ? ' (alivio: ${r.alivioMedicacion})' : ''}';
    }
 
    final nota = incluirNotas ? (r.observacion ?? '').trim() : '';
    const t = pw.TextStyle(fontSize: 8.5);
 
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 80,
                child: pw.Text('${_f(r.fechaHora)} ${_hora(r.fechaHora)}', style: t),
              ),
              pw.SizedBox(
                width: 34,
                child: pw.Text(
                  '${r.intensidadDolor}/10',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _colorDolor(r.intensidadDolor),
                  ),
                ),
              ),
              pw.Expanded(flex: 2, child: pw.Text(zonas, style: t)),
              pw.Expanded(
                flex: 3,
                child: pw.Text(extra.isEmpty ? '-' : extra.join(' | '), style: t),
              ),
              pw.Expanded(flex: 2, child: pw.Text(med, style: t)),
            ],
          ),
          if (nota.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 80, top: 2),
              child: pw.Text(
                'Nota: $nota',
                style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
 
  // ---------- Frases ----------
 
  static String _fraseTop(
    String inicio,
    List<MapEntry<String, int>> top,
    int totalRegistros,
  ) {
    final primero = top.first;
    final resto = top.skip(1).toList();
    final b = StringBuffer(
      '$inicio **${primero.key}** (en ${primero.value} de '
      '${_registros(totalRegistros)})',
    );
    if (resto.isNotEmpty) {
      b.write(
        ', seguido${primero.key.endsWith('a') ? '' : ''} de '
        '${_enumerar([for (final e in resto) '**${e.key}** (${e.value})'])}',
      );
    }
    b.write('.');
    return b.toString();
  }
 
  static String _fraseMedicacion(_Medicacion m) {
    final sinNombre = m.nombre == 'Sin nombre';
    final sujeto = sinNombre
        ? 'En ${_registros(m.registros)} no anotó qué tomó'
        : 'Con **${m.nombre.toLowerCase()}** (${_registros(m.registros)})';
    final alivio = m.alivioFrecuente;
    if (alivio == null) {
      return sinNombre ? '$sujeto.' : '$sujeto no indicó el alivio.';
    }
    return '$sujeto, el alivio que más veces indicó fue **"$alivio"**.';
  }
 
  static String _fraseCruce(
    String titulo,
    String condA,
    String condB,
    (double?, int, double?, int) c,
  ) {
    final a = c.$1;
    final b = c.$3;
    final partes = StringBuffer('**$titulo** ');
    if (a != null) {
      partes.write(
        'Los días en que $condA, el dolor promedio fue de '
        '**${a.toStringAsFixed(1)} sobre 10** (${_dias(c.$2)} con dato)',
      );
    }
    if (b != null) {
      partes.write(
        a != null
            ? '; los días en que $condB, fue de **${b.toStringAsFixed(1)}** '
                '(${_dias(c.$4)} con dato)'
            : 'Los días en que $condB, el dolor promedio fue de '
                '**${b.toStringAsFixed(1)} sobre 10** (${_dias(c.$4)} con dato)',
      );
    }
    partes.write('.');
    if (a != null && b != null) {
      partes.write(' Diferencia: ${(a - b).abs().toStringAsFixed(1)} puntos.');
    } else {
      partes.write(' No hay días de ambos grupos para comparar.');
    }
    return partes.toString();
  }
 
  static String _fraseCapacidad(List<RegistroEmocional> lista) {
    final conteo = <String, int>{};
    for (final r in lista) {
      final c = r.capacidadDia;
      if (c != null) conteo[c] = (conteo[c] ?? 0) + 1;
    }
    const frases = {
      'todo': 'pudo hacer **todo**',
      'casi_todo': 'pudo hacer **casi todo**',
      'poco': 'pudo hacer **poco**',
      'no_pude': '**no pudo** hacer sus actividades',
    };
    final items = <String>[
      for (final e in frases.entries)
        if ((conteo[e.key] ?? 0) > 0) '${e.value} en ${conteo[e.key]}',
    ];
    return 'En los ${_dias(lista.length)} en que respondió sobre sus actividades, '
        '${_enumerar(items)}.';
  }
 
  static String _enumerar(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    return '${items.sublist(0, items.length - 1).join(', ')} y ${items.last}';
  }
 
  static String _nivel(double v) {
    if (v <= 3) return 'leve';
    if (v <= 6) return 'moderado';
    return 'intenso';
  }
 
  static String _dias(int n) => '$n ${n == 1 ? 'día' : 'días'}';
 
  static String _registros(int n) => '$n ${n == 1 ? 'registro' : 'registros'}';
 
  // ---------- Cálculos ----------
 
  static PdfColor _colorDolor(int v) {
    if (v <= 3) return _verde;
    if (v <= 6) return _naranja;
    return _rojo;
  }
 
  static int _clave(DateTime f) => f.year * 10000 + f.month * 100 + f.day;
 
  static String _f(DateTime d) => '${d.day} ${_meses[d.month - 1]}';
 
  static String _hora(DateTime f) {
    final h = f.hour % 12 == 0 ? 12 : f.hour % 12;
    final m = f.minute.toString().padLeft(2, '0');
    return '$h:$m ${f.hour < 12 ? 'a. m.' : 'p. m.'}';
  }
 
  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
 
  static String _veces(int n) => n == 1 ? '1 vez' : '$n veces';
 
  static double _media(Iterable<num> v) =>
      v.fold<double>(0, (suma, x) => suma + x) / v.length;
 
  static Map<String, int> _frecuencias(Iterable<List<String>> listas) {
    final conteo = <String, int>{};
    for (final lista in listas) {
      for (final nombre in lista) {
        conteo[nombre] = (conteo[nombre] ?? 0) + 1;
      }
    }
    return conteo;
  }
 
  static List<MapEntry<String, int>> _top(Map<String, int> conteo, int n) {
    final ordenado = conteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ordenado.take(n).toList();
  }
 
  static Map<String, int> _otrosTipos(List<HistorialSintoma> lista) {
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
 
  static List<_Medicacion> _medicaciones(List<HistorialSintoma> lista) {
    final m = <String, _Medicacion>{};
    for (final r in lista) {
      if (r.tomoMedicacion != true) continue;
      final det = (r.medicacionDetalle ?? '').trim();
      final clave = det.isEmpty ? 'sin nombre' : det.toLowerCase();
      final item = m.putIfAbsent(
        clave,
        () => _Medicacion(det.isEmpty ? 'Sin nombre' : _cap(det)),
      );
      item.registros++;
      final a = r.alivioMedicacion;
      if (a != null) item.alivios[a] = (item.alivios[a] ?? 0) + 1;
    }
    return m.values.toList()..sort((a, b) => b.registros.compareTo(a.registros));
  }
 
  /// Dolor más alto de cada día.
  static Map<int, int> _dolorPorDia(List<HistorialSintoma> sintomas) {
    final m = <int, int>{};
    for (final r in sintomas) {
      final k = _clave(r.fechaHora);
      final actual = m[k];
      if (actual == null || r.intensidadDolor > actual) {
        m[k] = r.intensidadDolor;
      }
    }
    return m;
  }
 
  /// Dolor promedio de los días que tienen dolor y check-in, separados en dos
  /// grupos según `grupo` (true = A, false = B, null = no aplica).
  static (double?, int, double?, int) _cruce(
    List<HistorialSintoma> sintomas,
    List<RegistroEmocional> checkins,
    bool? Function(RegistroEmocional) grupo,
  ) {
    final dolorPorDia = _dolorPorDia(sintomas);
    final checkPorDia = {for (final c in checkins) _clave(c.fecha): c};
 
    final a = <int>[];
    final b = <int>[];
    for (final e in dolorPorDia.entries) {
      final c = checkPorDia[e.key];
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
 
  static bool _hay((double?, int, double?, int) c) => c.$1 != null || c.$3 != null;
 
  /// Ánimo promedio en días de dolor intenso (7 o más) frente al resto, solo
  /// con días que tienen ambos datos. Devuelve null si falta alguno de los
  /// dos grupos.
  static (double, int, double, int)? _animoSegunDolor(
    List<HistorialSintoma> sintomas,
    List<RegistroEmocional> checkins,
  ) {
    final dolorPorDia = _dolorPorDia(sintomas);
    final animoPorDia = {for (final c in checkins) _clave(c.fecha): c.estadoAnimo};
    final intensos = <int>[];
    final otros = <int>[];
    for (final e in dolorPorDia.entries) {
      final animo = animoPorDia[e.key];
      if (animo == null) continue;
      (e.value >= 7 ? intensos : otros).add(animo);
    }
    if (intensos.isEmpty || otros.isEmpty) return null;
    return (_media(intensos), intensos.length, _media(otros), otros.length);
  }
}
 
class _Medicacion {
  final String nombre;
  int registros = 0;
  final Map<String, int> alivios = {};
 
  _Medicacion(this.nombre);
 
  String? get alivioFrecuente {
    if (alivios.isEmpty) return null;
    return alivios.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }
}