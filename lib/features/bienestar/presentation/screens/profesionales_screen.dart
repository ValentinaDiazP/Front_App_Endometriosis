import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/profesional.dart';
import '../../services/bienestar_service.dart';
import 'detalle_profesional_screen.dart';
import 'mis_citas_screen.dart';

class ProfesionalesScreen extends StatefulWidget {
  final String? token;

  const ProfesionalesScreen({super.key, this.token});

  @override
  State<ProfesionalesScreen> createState() => _ProfesionalesScreenState();
}

class _ProfesionalesScreenState extends State<ProfesionalesScreen> {
  late Future<List<Profesional>> _futureProfesionales;
  String _filtroBusqueda = '';
  String _categoriaSeleccionada = 'Todos';
  late final ScrollController _scrollController;

  final List<String> _categorias = [
    'Todos',
    'Ginecología',
    'Nutrición',
    'Psicología',
    'Suelo Pélvico',
    'Virtual',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _futureProfesionales = BienestarService.obtenerProfesionales(
      token: widget.token,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _desplazarCategorias(double delta) {
    final nuevoOffset = (_scrollController.offset + delta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      nuevoOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _contactar(Profesional profesional) async {
    final token = widget.token;
    if (token != null && token.isNotEmpty) {
      await BienestarService.registrarSolicitudContacto(
        profesionalId: profesional.id,
        token: token,
      );
    }

    final numeroRaw = profesional.whatsapp.replaceAll(RegExp(r'[^\d]'), '');
    final numero = numeroRaw.isNotEmpty ? numeroRaw : '573000000000';

    final mensaje =
        'Hola, quisiera agendar una consulta con ${profesional.nombre} desde la app Florecer.';
    final uri = Uri.parse(
      'https://wa.me/$numero?text=${Uri.encodeComponent(mensaje)}',
    );

    final abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abierto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }

  String _normalizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profesionales de Bienestar', style: TextStyle(fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFFD81B60),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: Colors.white),
            tooltip: 'Mis Citas',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MisCitasScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y Filtros por Categoría con Botones de Navegación Lateral
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o especialidad...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (valor) {
                    setState(() {
                      _filtroBusqueda = _normalizar(valor);
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.chevron_left, size: 20, color: Color(0xFF8E24AA)),
                        onPressed: () => _desplazarCategorias(-150),
                        tooltip: 'Desplazar a la izquierda',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _categorias.length,
                          itemBuilder: (context, index) {
                            final categoria = _categorias[index];
                            final seleccionada = _categoriaSeleccionada == categoria;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(categoria),
                                selected: seleccionada,
                                selectedColor: const Color(0xFFD81B60),
                                labelStyle: TextStyle(
                                  color: seleccionada ? Colors.white : Colors.black87,
                                  fontWeight: seleccionada ? FontWeight.bold : FontWeight.normal,
                                ),
                                backgroundColor: Colors.grey.shade200,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _categoriaSeleccionada = categoria;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF8E24AA)),
                        onPressed: () => _desplazarCategorias(150),
                        tooltip: 'Desplazar a la derecha',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Profesional>>(
              future: _futureProfesionales,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Error de conexión con Backend Django:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No hay profesionales registrados aún.'),
                  );
                }

                final todosProfesionales = snapshot.data!;
                final profesionales = todosProfesionales.where((p) {
                  final nombreNorm = _normalizar(p.nombre);
                  final espNorm = _normalizar(p.especialidad);
                  
                  final coincideBusqueda = nombreNorm.contains(_filtroBusqueda) ||
                      espNorm.contains(_filtroBusqueda);

                  if (_categoriaSeleccionada == 'Todos') {
                    return coincideBusqueda;
                  }

                  String keyword = _normalizar(_categoriaSeleccionada);
                  if (keyword == 'ginecologia') keyword = 'ginec';
                  if (keyword == 'nutricion') keyword = 'nutri';
                  if (keyword == 'psicologia') keyword = 'psic';
                  if (keyword == 'suelo pelvico') keyword = 'pelv';
                  if (keyword == 'virtual') keyword = 'virtual';

                  final coincideCategoria = espNorm.contains(keyword) ||
                      nombreNorm.contains(keyword);

                  return coincideBusqueda && coincideCategoria;
                }).toList();

                if (profesionales.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron profesionales con esos criterios.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: profesionales.length,
                  itemBuilder: (context, index) {
                    final profesional = profesionales[index];
                    return _TarjetaProfesional(
                      profesional: profesional,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DetalleProfesionalScreen(
                              profesional: profesional,
                              onContactar: () => _contactar(profesional),
                            ),
                          ),
                        );
                      },
                      onWhatsApp: () => _contactar(profesional),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaProfesional extends StatelessWidget {
  final Profesional profesional;
  final VoidCallback onTap;
  final VoidCallback onWhatsApp;

  const _TarjetaProfesional({
    required this.profesional,
    required this.onTap,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final disponible = profesional.disponibleHoy;
    final colorBadge = disponible ? const Color(0xFF81C784) : const Color(0xFFFFCC80);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFF8BBD0),
                    child: Text(
                      profesional.nombre.isNotEmpty ? profesional.nombre[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD81B60),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profesional.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profesional.especialidad,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: const [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '4.9',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '(18 opiniones)',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorBadge.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorBadge),
                    ),
                    child: Text(
                      profesional.etiquetaDisponibilidad,
                      style: TextStyle(
                        color: disponible ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Text(
                    'Tarifa: ${profesional.tarifa}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E24AA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Ver Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onWhatsApp,
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
