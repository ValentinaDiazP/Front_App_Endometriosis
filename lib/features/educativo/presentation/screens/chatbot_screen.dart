import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/contenido_educativo.dart';
import '../../services/educativo_service.dart';
import '../screens/contenido_detail_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final ContenidoEducativo? articuloRelacionado;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.articuloRelacionado,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatbotScreen extends StatefulWidget {
  final String? token;

  const ChatbotScreen({super.key, this.token});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  static const List<String> _preguntasFijas = [
    "¿Qué hacer en un brote de dolor?",
    "Alimentos antiinflamatorios",
    "Manejo de la fatiga crónica",
    "Fisioterapia pélvica",
    "¿Cómo gestionar la ansiedad?",
  ];
  List<String> _preguntasSugeridas = [
    "¿Qué hacer en un brote de dolor?",
    "Alimentos antiinflamatorios",
    "Manejo de la fatiga crónica",
    "Fisioterapia pélvica",
    "¿Cómo gestionar la ansiedad?",
  ];
  bool _isLoading = false;

  static String get _baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/educativo/chatbot/';
    }
    return 'http://127.0.0.1:8000/api/educativo/chatbot/';
  }

  @override
  void initState() {
    super.initState();
    _cargarChatbotInicial();
  }

  Future<void> _cargarChatbotInicial() async {
    if (widget.token == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.token}',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          if (data['preguntas_frecuentes'] != null && (data['preguntas_frecuentes'] as List).isNotEmpty) {
            _preguntasSugeridas = (data['preguntas_frecuentes'] as List)
                .map((item) => (item['pregunta'] ?? '').toString())
                .where((p) => p.isNotEmpty)
                .toList();
          }
          _messages.add(ChatMessage(
            text: '¡Hola! Soy tu asistente experta en endometriosis. Estoy aquí para ayudarte con el manejo del dolor, brotes, nutrición antiinflamatoria, fisioterapia y bienestar posterior al diagnóstico. ¿Qué te gustaría consultar hoy?',
            isUser: false,
          ));
        });
      }
    } catch (_) {
      setState(() {
        _messages.add(ChatMessage(
          text: '¡Hola! Soy tu asistente experta en endometriosis. ¿En qué puedo ayudarte hoy?',
          isUser: false,
        ));
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _enviarPregunta(String texto) async {
    final preguntaLimpia = texto.trim();
    if (preguntaLimpia.isEmpty || widget.token == null) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: preguntaLimpia, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.token}',
        },
        body: jsonEncode({'pregunta': preguntaLimpia}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final respuestaBot = data['respuesta'] ?? 'No hay respuesta disponible.';
        final articuloJson = data['articulo_relacionado'];
        
        // Como el Future de arriba puede tardar un pelín o podemos parsearlo directo:
        ContenidoEducativo? articuloParsed;
        if (articuloJson != null) {
          try {
            articuloParsed = ContenidoEducativo(
              idContenido: articuloJson['id'] ?? '',
              idCategoriaFK: articuloJson['categoria'] ?? '',
              titulo: articuloJson['titulo'] ?? '',
              tipo: TipoContenido.values.byName(articuloJson['tipo'] ?? 'texto'),
              nivel: NivelContenido.values.byName(articuloJson['nivel'] ?? 'basico'),
              esPremium: articuloJson['es_premium'] ?? false,
              fechaPublicacion: DateTime.tryParse(articuloJson['fecha_publicacion'] ?? '') ?? DateTime.now(),
              resumen: articuloJson['resumen'] ?? '',
              cuerpo: articuloJson['cuerpo'] ?? '',
              minutosEstimados: articuloJson['minutos_estimados'] ?? 5,
              urlRecurso: articuloJson['url_recurso'],
            );
          } catch (_) {}
        }

        setState(() {
          if (data['preguntas_sugeridas'] != null && (data['preguntas_sugeridas'] as List).isNotEmpty) {
            final nuevasSugerencias = (data['preguntas_sugeridas'] as List)
                .map((item) => (item['pregunta'] ?? '').toString())
                .where((p) => p.isNotEmpty)
                .toList();
            if (nuevasSugerencias.length < 3) {
              _preguntasSugeridas = _preguntasFijas.toList();
            } else {
              _preguntasSugeridas = nuevasSugerencias;
            }
          }
          _messages.add(ChatMessage(
            text: respuestaBot,
            isUser: false,
            articuloRelacionado: articuloParsed,
          ));
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Lo siento, ha ocurrido un error al procesar tu consulta. Por favor intenta de nuevo.',
            isUser: false,
          ));
        });
      }
    } catch (_) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error de conexión con el servidor. Verifica tu red.',
          isUser: false,
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente Endometriosis'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
          if (_preguntasSugeridas.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _preguntasSugeridas.length,
                itemBuilder: (context, index) {
                  final preguntaTexto = _preguntasSugeridas[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 4, bottom: 4),
                    child: ActionChip(
                      avatar: const Icon(Icons.support_agent, size: 16, color: Color(0xFF8E44AD)),
                      label: Text(
                        preguntaTexto,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: Colors.white,
                      elevation: 1,
                      onPressed: () => _enviarPregunta(preguntaTexto),
                    ),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu consulta sobre endometriosis...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (val) => _enviarPregunta(val),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                  onPressed: () => _enviarPregunta(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    const primaryColor = Color(0xFF8E44AD); // Tono morado representativo de endometriosis
    const userBubbleColor = Color(0xFFE8DAEF);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? userBubbleColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            if (msg.articuloRelacionado != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.article, size: 16, color: primaryColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            msg.articuloRelacionado!.titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      msg.articuloRelacionado!.resumen,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContenidoDetailScreen(
                                contenido: msg.articuloRelacionado!,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Leer artículo completo →',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
