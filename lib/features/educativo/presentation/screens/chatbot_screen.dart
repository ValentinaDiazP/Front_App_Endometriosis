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
  final List<String> opcionesSugeridas;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.articuloRelacionado,
    this.opcionesSugeridas = const [],
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
  
  List<Map<String, dynamic>> _todasPreguntas = [];
  
  // Carrusel deslizable horizontal con exactamente las 3 preguntas solicitadas
  final List<Map<String, String>> _preguntasRapidas = [
    {
      "pregunta": "¿Cómo gestionar la ansiedad o el impacto emocional del diagnóstico?",
      "articulo": "¿Qué es la endometriosis?"
    },
    {
      "pregunta": "¿Cómo puedo manejar la fatiga crónica asociada a la endometriosis?",
      "articulo": "Endometriosis: más allá del dolor físico"
    },
    {
      "pregunta": "¿Qué puedo hacer durante un brote (flare-up) de dolor agudo?",
      "articulo": "Entendiendo el dolor crónico"
    },
  ];

  // Sugerencias en tiempo real mientras escribe
  List<String> _sugerenciasTiempoReal = [];
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
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _sugerenciasTiempoReal = [];
      });
      return;
    }

    final filtradas = _todasPreguntas
        .where((item) => (item['pregunta'] ?? '').toString().toLowerCase().contains(query))
        .map((item) => (item['pregunta'] ?? '').toString())
        .take(4)
        .toList();

    setState(() {
      _sugerenciasTiempoReal = filtradas;
    });
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
          if (data['preguntas_frecuentes'] != null) {
            _todasPreguntas = List<Map<String, dynamic>>.from(data['preguntas_frecuentes']);
          }
          _messages.add(ChatMessage(
            text: "¡Hola! Soy tu asistente educativo sobre Endometriosis 🌸. Puedo orientarte de forma segura en estos 5 temas:\n"
                  "1. Fisiopatología, síntomas y mecanismos del dolor\n"
                  "2. Salud mental y afrontamiento psicoemocional\n"
                  "3. Explicación de tratamientos médicos y quirúrgicos\n"
                  "4. Nutrición, estilo de vida y terapias complementarias\n"
                  "5. Autogestión del síntoma y comunicación médica\n\n"
                  "Selecciona un número del 1 al 5 abajo o escribe tu duda.",
            isUser: false,
            opcionesSugeridas: [
              "1. Fisiopatología, síntomas y mecanismos del dolor",
              "2. Salud mental y afrontamiento psicoemocional",
              "3. Explicación de tratamientos médicos y quirúrgicos",
              "4. Nutrición, estilo de vida y terapias complementarias",
              "5. Autogestión del síntoma y comunicación médica"
            ],
          ));
        });
      }
    } catch (_) {
      setState(() {
        _messages.add(ChatMessage(
          text: "¡Hola! Soy tu asistente educativo sobre Endometriosis 🌸. Puedo orientarte de forma segura en estos 5 temas:\n"
                "1. Fisiopatología, síntomas y mecanismos del dolor\n"
                "2. Salud mental y afrontamiento psicoemocional\n"
                "3. Explicación de tratamientos médicos y quirúrgicos\n"
                "4. Nutrición, estilo de vida y terapias complementarias\n"
                "5. Autogestión del síntoma y comunicación médica\n\n"
                "Selecciona un número del 1 al 5 abajo o escribe tu duda.",
          isUser: false,
          opcionesSugeridas: [
            "1. Fisiopatología, síntomas y mecanismos del dolor",
            "2. Salud mental y afrontamiento psicoemocional",
            "3. Explicación de tratamientos médicos y quirúrgicos",
            "4. Nutrición, estilo de vida y terapias complementarias",
            "5. Autogestión del síntoma y comunicación médica"
          ],
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
      _sugerenciasTiempoReal = [];
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
        final List<String> opcionesDevueltas = data['opciones_sugeridas'] != null
            ? List<String>.from(data['opciones_sugeridas'])
            : [];
        
        ContenidoEducativo? articuloParsed;
        
        // Asociar tarjetas CTA si corresponde
        if (preguntaLimpia.contains("ansiedad") || preguntaLimpia.contains("impacto emocional")) {
          articuloParsed = ContenidoEducativo(
            idContenido: 'c1',
            idCategoriaFK: 'cat_endometriosis',
            titulo: '¿Qué es la endometriosis?',
            tipo: TipoContenido.texto,
            nivel: NivelContenido.basico,
            esPremium: false,
            fechaPublicacion: DateTime.now(),
            resumen: 'Una introducción clara a qué le pasa a tu cuerpo.',
            cuerpo: 'La endometriosis es una condición en la que tejido similar al endometrio crece fuera del útero...',
            minutosEstimados: 5,
          );
        } else if (preguntaLimpia.contains("fatiga crónica")) {
          articuloParsed = ContenidoEducativo(
            idContenido: 'c3',
            idCategoriaFK: 'cat_autocuidado',
            titulo: 'Endometriosis: más allá del dolor físico',
            tipo: TipoContenido.video,
            nivel: NivelContenido.basico,
            esPremium: false,
            fechaPublicacion: DateTime.now(),
            resumen: 'Cómo la endometriosis también afecta el ánimo y qué ayuda a sobrellevarlo.',
            cuerpo: 'Guion del audio de ejemplo...',
            minutosEstimados: 5,
          );
        } else if (preguntaLimpia.contains("brote") || preguntaLimpia.contains("dolor agudo")) {
          articuloParsed = ContenidoEducativo(
            idContenido: 'c2',
            idCategoriaFK: 'cat_dolor',
            titulo: 'Entendiendo el dolor crónico',
            tipo: TipoContenido.video,
            nivel: NivelContenido.basico,
            esPremium: false,
            fechaPublicacion: DateTime.now(),
            resumen: 'Por qué el dolor persiste incluso sin daño activo.',
            cuerpo: 'Guion del video de ejemplo...',
            minutosEstimados: 5,
          );
        } else if (articuloJson != null) {
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
          if (data['preguntas_sugeridas'] != null) {
            _todasPreguntas = List<Map<String, dynamic>>.from(data['preguntas_sugeridas']);
          }
          _messages.add(ChatMessage(
            text: respuestaBot,
            isUser: false,
            articuloRelacionado: articuloParsed,
            opcionesSugeridas: opcionesDevueltas,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Asistente Endometriosis'),
        backgroundColor: const Color(0xFFF48FB1),
      ),
      body: Column(
        children: [
          // Historial del Chat
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
              child: LinearProgressIndicator(color: Color(0xFFF48FB1)),
            ),

          // Sugerencias en tiempo real mientras escribe
          if (_sugerenciasTiempoReal.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _sugerenciasTiempoReal.length,
                itemBuilder: (context, index) {
                  final sug = _sugerenciasTiempoReal[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.search, size: 18, color: Color(0xFFEC407A)),
                    title: Text(sug, style: const TextStyle(fontSize: 13)),
                    onTap: () => _enviarPregunta(sug),
                  );
                },
              ),
            ),

          // Carrusel Deslizable Inferior (Quick Questions) horizontal con las 3 preguntas exactas
          if (_sugerenciasTiempoReal.isEmpty)
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _preguntasRapidas.length,
                itemBuilder: (context, index) {
                  final item = _preguntasRapidas[index];
                  final preguntaTexto = item["pregunta"]!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 4, bottom: 4),
                    child: ActionChip(
                      avatar: const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFFEC407A)),
                      label: Text(
                        preguntaTexto,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
                      ),
                      backgroundColor: const Color(0xFFFCE4EC),
                      elevation: 0,
                      onPressed: () => _enviarPregunta(preguntaTexto),
                    ),
                  );
                },
              ),
            ),

          // Caja de texto inferior
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu consulta sobre endometriosis...',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (val) => _enviarPregunta(val),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: const Color(0xFFEC407A),
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
    const userBubbleColor = Color(0xFFFCE4EC); // Rosa pastel claro para usuaria
    const botBubbleColor = Color(0xFFF5F5F5);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: isUser ? userBubbleColor : botBubbleColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUser ? const Color(0xFFF48FB1).withOpacity(0.4) : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            // Chips interactivos de opciones del menú (2 niveles)
            if (!isUser && msg.opcionesSugeridas.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: msg.opcionesSugeridas.map((opcion) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFF48FB1)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _enviarPregunta(opcion),
                      child: Text(
                        opcion,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC2185B),
                          fontWeight: FontWeight.w600,
                        ),
                        softWrap: true,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            // Tarjeta de Redirección (CTA Card) con enlace al Módulo Educativo
            if (msg.articuloRelacionado != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF48FB1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 16, color: Color(0xFFEC407A)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            msg.articuloRelacionado!.titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFFC2185B),
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
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF48FB1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                          'Leer artículo completo en Módulo Educativo',
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
