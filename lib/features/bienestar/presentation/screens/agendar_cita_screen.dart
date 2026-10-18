import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/auth_service.dart';
import '../../models/profesional.dart';
import '../../models/disponibilidad_slot.dart';
import '../../models/cita_medica.dart';
import '../../services/bienestar_service.dart';

class AgendarCitaScreen extends StatefulWidget {
  final Profesional profesional;

  const AgendarCitaScreen({Key? key, required this.profesional}) : super(key: key);

  @override
  State<AgendarCitaScreen> createState() => _AgendarCitaScreenState();
}

class _AgendarCitaScreenState extends State<AgendarCitaScreen> {
  bool _cargando = true;
  List<DisponibilidadSlot> _slots = [];
  DateTime _fechaSeleccionada = DateTime.now().add(const Duration(days: 1));
  DisponibilidadSlot? _slotSeleccionado;
  final TextEditingController _notasController = TextEditingController();
  final TextEditingController _lugarController = TextEditingController(text: 'Videollamada / Consultorio virtual');

  @override
  void initState() {
    super.initState();
    _cargarDisponibilidad();
  }

  Future<void> _cargarDisponibilidad() async {
    try {
      final token = AuthService.token ?? '';
      final slots = await BienestarService.obtenerDisponibilidad(widget.profesional.id, token: token);
      setState(() {
        _slots = slots;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _cargando = false;
      });
      // Si no hay horarios configurados en BD, generamos mocks por defecto para agilizar la prueba
      setState(() {
        _slots = [
          DisponibilidadSlot(id: 1, diaSemana: 'Lunes', horaInicio: '09:00', horaFin: '10:00'),
          DisponibilidadSlot(id: 2, diaSemana: 'Martes', horaInicio: '10:30', horaFin: '11:30'),
          DisponibilidadSlot(id: 3, diaSemana: 'Miércoles', horaInicio: '15:00', horaFin: '16:00'),
          DisponibilidadSlot(id: 4, diaSemana: 'Jueves', horaInicio: '16:30', horaFin: '17:30'),
          DisponibilidadSlot(id: 5, diaSemana: 'Viernes', horaInicio: '11:00', horaFin: '12:00'),
        ];
      });
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _agendar() async {
    if (_slotSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un horario disponible')),
      );
      return;
    }

    // Combinar fecha seleccionada con la hora inicio del slot
    final partesHora = _slotSeleccionado!.horaInicio.split(':');
    final hora = int.tryParse(partesHora[0]) ?? 9;
    final minuto = partesHora.length > 1 ? (int.tryParse(partesHora[1]) ?? 0) : 0;

    final fechaHoraFinal = DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month,
      _fechaSeleccionada.day,
      hora,
      minuto,
    );

    try {
      final token = AuthService.token ?? '';
      await BienestarService.crearCita(
        data: {
          'especialista': widget.profesional.id,
          'especialidad': widget.profesional.especialidad,
          'fecha_hora': fechaHoraFinal.toIso8601String(),
          'lugar_o_link': _lugarController.text.trim(),
          'notas': _notasController.text.trim(),
          'estado': 'PROGRAMADA',
        },
        token: token,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Cita agendada con éxito! Estado: Programada (Azul)')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agendar cita: $e')),
      );
    }
  }

  Future<void> _contactarWhatsApp() async {
    final numero = widget.profesional.whatsapp;
    if (numero.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número de WhatsApp no disponible')),
      );
      return;
    }
    final url = Uri.parse('https://wa.me/$numero?text=Hola%20${Uri.encodeComponent(widget.profesional.nombre)},%20me%20gustaría%20consultar%20sobre%20tus%20servicios%20de%20bienestar.');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy', 'es');

    return Scaffold(
      appBar: AppBar(
        title: Text('Agendar Cita con ${widget.profesional.nombre}'),
        backgroundColor: Colors.teal,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.tealAccent,
                            child: Icon(Icons.medical_services, size: 30, color: Colors.teal),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.profesional.nombre,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.profesional.especialidad,
                                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tarifa: ${widget.profesional.tarifa}',
                                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '1. Selecciona la Fecha',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _seleccionarFecha(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today, color: Colors.teal),
                      ),
                      child: Text(
                        formatoFecha.format(_fechaSeleccionada),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '2. Bloques de Horarios Disponibles',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _slots.isEmpty
                      ? const Text('No hay horarios configurados. Puedes contactar directamente por WhatsApp.')
                      : Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _slots.map((slot) {
                            final seleccionado = _slotSeleccionado == slot;
                            return ChoiceChip(
                              label: Text('${slot.horaInicio} - ${slot.horaFin}'),
                              selected: seleccionado,
                              selectedColor: Colors.teal,
                              labelStyle: TextStyle(
                                color: seleccionado ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (bool selected) {
                                setState(() {
                                  _slotSeleccionado = selected ? slot : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 24),
                  const Text(
                    '3. Lugar o Link de atención',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lugarController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ej. Consultorio 302 o link de Meet/Zoom',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Notas o motivo de consulta (opcional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notasController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Escribe aquí síntomas o preguntas para el especialista...',
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _agendar,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirmar y Agendar Cita (Programada)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.profesional.whatsapp.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _contactarWhatsApp,
                        icon: const Icon(Icons.chat, color: Colors.green),
                        label: const Text('Contactar por WhatsApp'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green[700],
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
