import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';

/// Muestra un texto escrito en el admin de Django con un formato sencillo:
///
///  - una línea en blanco separa los párrafos
///  - `**texto**` = negrita, `__texto__` = subrayado
///  - `[texto](https://enlace)` = enlace (se abre fuera de la app)
///  - las líneas que empiezan con `- ` forman una lista
///  - una línea que empieza con `## ` es un subtítulo
///
/// Así quien edita el contenido no necesita tocar código ni conocer HTML.
class TextoEnriquecido extends StatefulWidget {
  final String texto;
  final TextStyle estilo;

  const TextoEnriquecido({
    super.key,
    required this.texto,
    this.estilo = const TextStyle(fontSize: 15.5, height: 1.5),
  });

  @override
  State<TextoEnriquecido> createState() => _TextoEnriquecidoState();
}

class _TextoEnriquecidoState extends State<TextoEnriquecido> {
  final List<TapGestureRecognizer> _toques = [];

  static final _inline = RegExp(
    r'\*\*(.+?)\*\*|__(.+?)__|\[([^\]]+)\]\((https?://[^)\s]+)\)',
    dotAll: true,
  );

  void _liberar() {
    for (final t in _toques) {
      t.dispose();
    }
    _toques.clear();
  }

  @override
  void dispose() {
    _liberar();
    super.dispose();
  }

  Future<void> _abrir(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Sin navegador disponible: no pasa nada.
    }
  }

  /// Convierte una línea o párrafo con marcas (**, __, [..](..)) en spans.
  List<InlineSpan> _spans(String texto, TextStyle base) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in _inline.allMatches(texto)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: texto.substring(cursor, m.start)));
      }
      if (m.group(1) != null) {
        spans.add(TextSpan(
          text: m.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ));
      } else if (m.group(2) != null) {
        spans.add(TextSpan(
          text: m.group(2),
          style: const TextStyle(decoration: TextDecoration.underline),
        ));
      } else {
        final url = m.group(4)!;
        final toque = TapGestureRecognizer()..onTap = () => _abrir(url);
        _toques.add(toque);
        spans.add(TextSpan(
          text: m.group(3),
          style: const TextStyle(
            color: AppTheme.primary,
            decoration: TextDecoration.underline,
          ),
          recognizer: toque,
        ));
      }
      cursor = m.end;
    }
    if (cursor < texto.length) {
      spans.add(TextSpan(text: texto.substring(cursor)));
    }
    return spans;
  }

  Widget _parrafo(String texto, TextStyle estilo) {
    return Text.rich(TextSpan(style: estilo, children: _spans(texto, estilo)));
  }

  Widget _lista(List<String> items, TextStyle estilo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: estilo),
                Expanded(child: _parrafo(item, estilo)),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _liberar();
    final estilo = widget.estilo;
    final bloques = widget.texto
        .split(RegExp(r'\n\s*\n'))
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();

    final hijos = <Widget>[];
    for (final bloque in bloques) {
      final lineas = bloque.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lineas.isEmpty) continue;
      if (lineas.length == 1 && lineas.first.startsWith('## ')) {
        hijos.add(_parrafo(
          lineas.first.substring(3),
          estilo.copyWith(fontWeight: FontWeight.w700, fontSize: (estilo.fontSize ?? 15) + 2),
        ));
      } else if (lineas.every((l) => l.startsWith('- '))) {
        hijos.add(_lista(lineas.map((l) => l.substring(2)).toList(), estilo));
      } else {
        hijos.add(_parrafo(lineas.join('\n'), estilo));
      }
      hijos.add(const SizedBox(height: 12));
    }
    if (hijos.isNotEmpty) hijos.removeLast();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: hijos);
  }
}
