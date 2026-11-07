import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/auth_service.dart';
import '../../models/cita_medica.dart';
import '../../services/bienestar_service.dart';

class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({Key? key}) : super(key: key);

  @override
  State<MisCitasScreen> createState() => _MisCitasScreenState();
}

class _MisCitasScreenState extends State<MisCitasScreen> {
  bool _cargando = true;
  List<CitaMedica> _citas = [];

  @override
  void initState() {
    super.initState();
    _cargarCitas();
  }

  Future<void> _cargarCitas() async {
    try {
      final token = AuthService.token ?? '';
      final citas = await BienestarService.obtenerCitas(token: token);
      setState(() {
        _citas = citas;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _cargando = false;
        _citas = [
          CitaMedica(
            id: 1,
            nombreEspecialista: 'Dra. Sofía Martínez',
            especialidad: 'Ginecología y Obstetricia',
            fechaHora: DateTime.now().add(const Duration(days: 2, hours: 3)),
            lugarOLink: 'Consultorio 402 - Clínica Bienestar',
            estado: 'PROGRAMADA',
            notas: 'Revisión general y síntomas de ciclo.',
            puntosOtorgados: false,
          ),
          CitaMedica(
            id: 2,
            nombreEspecialista: 'Dr. Carlos Gómez',
            especialidad: 'Endocrinología',
            fechaHora: DateTime.now().add(const Duration(days: 5, hours: 1)),
            lugarOLink: 'https://meet.google.com/abc-defg-hij',
            estado: 'CONFIRMADA',
            notas: 'Resultados de exámenes hormonales.',
            puntosOtorgados: false,
          ),
        ];
      });
    }
  }

  Color _obtenerColorCardFondo(String estado) {
    switch (estado) {
      case 'PROGRAMADA':
        return const Color(0xFFF8BBD0).withOpacity(0.15); // Rosado Claro
      case 'CONFIRMADA':
        return const Color(0xFFFCE4EC); 
      case 'COMPLETADA':
        return const Color(0xFFE1BEE7); // Morado claro
      case 'CANCELADA':
        return Colors.grey.shade100;
      default:
        return Colors.white;
    }
  }

  Color _obtenerColorBorde(String estado) {
    switch (estado) {
      case 'PROGRAMADA':
        return const Color(0xFFD81B60); // Rosado de marca
      case 'CONFIRMADA':
        return const Color(0xFF8E24AA); // Morado de marca
      case 'COMPLETADA':
        return const Color(0xFF8E24AA);
      case 'CANCELADA':
        return Colors.grey;
      default:
        return const Color(0xFFD81B60);
    }
  }

  IconData _obtenerIconoEstado(String estado) {
    switch (estado) {
      case 'PROGRAMADA':
        return Icons.schedule;
      case 'CONFIRMADA':
        return Icons.verified;
      case 'COMPLETADA':
        return Icons.task_alt;
      case 'CANCELADA':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _reprogramarCita(CitaMedica cita) async {
    final DateTime? nuevaFecha = await showDatePicker(
      context: context,
      initialDate: cita.fechaHora,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('es', 'ES'),
    );

    if (nuevaFecha == null) return;

    if (!mounted) return;
    final TimeOfDay? nuevaHora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(cita.fechaHora),
    );

    if (nuevaHora == null) return;

    final fechaHoraActualizada = DateTime(
      nuevaFecha.year,
      nuevaFecha.month,
      nuevaFecha.day,
      nuevaHora.hour,
      nuevaHora.minute,
    );

    try {
      final token = AuthService.token ?? '';
      await BienestarService.actualizarCita(
        cita.id,
        {
          'fecha_hora': fechaHoraActualizada.toIso8601String(),
          'estado': 'PROGRAMADA',
        },
        token: token,
      );
    } catch (e) {
      // Ignorar error si es simulación mock
    }

    setState(() {
      _citas = _citas.map((c) {
        if (c.id == cita.id) {
          return CitaMedica(
            id: c.id,
            especialista: c.especialista,
            especialistaNombre: c.especialistaNombre,
            nombreEspecialista: c.nombreEspecialista,
            especialidad: c.especialidad,
            fechaHora: fechaHoraActualizada,
            lugarOLink: c.lugarOLink,
            estado: 'PROGRAMADA',
            notas: c.notas,
            puntosOtorgados: c.puntosOtorgados,
          );
        }
        return c;
      }).toList();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cita reprogramada exitosamente'),
        backgroundColor: Color(0xFF8E24AA),
      ),
    );
  }

  void _establecerRecordatorio(CitaMedica cita) {
    final formato = DateFormat('dd/MM/yyyy hh:mm a').format(cita.fechaHora);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recordatorio fijado para tu cita con ${cita.nombreEspecialista} el $formato.'),
        backgroundColor: const Color(0xFFD81B60),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _eliminarCita(CitaMedica cita) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar / Eliminar Cita'),
        content: Text('¿Estás segura de que deseas eliminar tu cita con ${cita.nombreEspecialista}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conservar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60)),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final token = AuthService.token ?? '';
      await BienestarService.eliminarCita(cita.id, token: token);
    } catch (e) {
      // Ignorar en mock
    }

    setState(() {
      _citas.removeWhere((c) => c.id == cita.id);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cita eliminada de la lista'),
        backgroundColor: Color(0xFFD81B60),
      ),
    );
  }

  Future<void> _marcarCompletada(CitaMedica cita) async {
    try {
      final token = AuthService.token ?? '';
      await BienestarService.actualizarEstadoCita(cita.id, 'COMPLETADA', token: token);
      
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.military_tech, color: Color(0xFFD81B60), size: 32),
              SizedBox(width: 8),
              Text('¡Felicitaciones!'),
            ],
          ),
          content: const Text(
            '¡Has completado tu cita médica exitosamente!\n\nHas ganado +50 Puntos de Gamificación por cuidar de tu salud y bienestar.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cargarCitas();
              },
              child: const Text('Genial'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _citas = _citas.map((c) {
          if (c.id == cita.id) {
            return CitaMedica(
              id: c.id,
              especialista: c.especialista,
              especialistaNombre: c.especialistaNombre,
              nombreEspecialista: c.nombreEspecialista,
              especialidad: c.especialidad,
              fechaHora: c.fechaHora,
              lugarOLink: c.lugarOLink,
              estado: 'COMPLETADA',
              notas: c.notas,
              puntosOtorgados: true,
            );
          }
          return c;
        }).toList();
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.military_tech, color: Color(0xFFD81B60), size: 32),
              SizedBox(width: 8),
              Text('¡Felicitaciones!'),
            ],
          ),
          content: const Text(
            '¡Has completado tu cita médica exitosamente!\n\nHas ganado +50 Puntos de Gamificación por cuidar de tu salud y bienestar.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Genial'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas Médicas'),
        backgroundColor: const Color(0xFFD81B60),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _citas.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_note, size: 72, color: Color(0xFFF8BBD0)),
                        const SizedBox(height: 16),
                        const Text(
                          'No tienes citas agendadas',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agenda una cita con nuestros profesionales para recibir acompañamiento personalizado.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Agendar una cita'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8E24AA),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _citas.length,
                  itemBuilder: (context, index) {
                    final cita = _citas[index];
                    final colorFondo = _obtenerColorCardFondo(cita.estado);
                    final colorBorde = _obtenerColorBorde(cita.estado);
                    final iconoEstado = _obtenerIconoEstado(cita.estado);
                    final fechaFormateada = DateFormat('dd/MM/yyyy hh:mm a').format(cita.fechaHora);

                    return Card(
                      color: colorFondo,
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorBorde, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(iconoEstado, color: colorBorde, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      cita.estado,
                                      style: TextStyle(
                                        color: colorBorde,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  fechaFormateada,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Text(
                              cita.especialidad,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Especialista: ${cita.nombreEspecialista}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF8E24AA)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lugar / Link: ${cita.lugarOLink}',
                              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                            ),
                            if (cita.notas.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Notas: ${cita.notas}',
                                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey[700]),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (cita.estado != 'COMPLETADA' && cita.estado != 'CANCELADA') ...[
                                  OutlinedButton.icon(
                                    onPressed: () => _reprogramarCita(cita),
                                    icon: const Icon(Icons.edit_calendar, size: 16, color: Color(0xFF8E24AA)),
                                    label: const Text('Reprogramar'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF8E24AA),
                                      side: const BorderSide(color: Color(0xFF8E24AA)),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _establecerRecordatorio(cita),
                                    icon: const Icon(Icons.notifications_active, size: 16, color: Color(0xFFD81B60)),
                                    label: const Text('Recordatorio'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFD81B60),
                                      side: const BorderSide(color: Color(0xFFD81B60)),
                                    ),
                                  ),
                                ],
                                IconButton(
                                  onPressed: () => _eliminarCita(cita),
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFD81B60)),
                                  tooltip: 'Cancelar y eliminar cita',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
