import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Botón que abre un video o podcast externo (YouTube, Spotify, etc.) en
/// su propia app o en el navegador. El texto y el ícono dependen del sitio
/// del enlace; si no lo reconoce, usa [esAudio] para elegir entre "Ver" y
/// "Escuchar".
class BotonRecursoExterno extends StatelessWidget {
  final String url;
  final bool esAudio;

  const BotonRecursoExterno({super.key, required this.url, this.esAudio = false});

  ({String texto, IconData icono}) get _etiqueta {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return (texto: 'Ver en YouTube', icono: Icons.smart_display_outlined);
    }
    if (host.contains('spotify.com')) {
      return (texto: 'Escuchar en Spotify', icono: Icons.headphones_outlined);
    }
    if (host.contains('podcasts.apple.com')) {
      return (texto: 'Escuchar en Apple Podcasts', icono: Icons.podcasts_outlined);
    }
    return esAudio
        ? (texto: 'Escuchar audio', icono: Icons.headphones_outlined)
        : (texto: 'Ver video', icono: Icons.play_circle_outline);
  }

  Future<void> _abrir(BuildContext context) async {
    final uri = Uri.tryParse(url);
    var abierto = false;
    if (uri != null) {
      try {
        abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        abierto = false;
      }
    }
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace. Revisa tu conexión e intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final etiqueta = _etiqueta;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _abrir(context),
        icon: Icon(etiqueta.icono),
        label: Text(etiqueta.texto),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
      ),
    );
  }
}
