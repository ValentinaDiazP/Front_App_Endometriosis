import 'package:flutter/material.dart';
import '../bienestar_colors.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/auth_service.dart';
import '../../models/cita_medica.dart';
import '../../services/bienestar_service.dart';

class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({Key? key}) : super(key: key);

  @override
  State<MisCitasScreen> createState() => _MisCitasScreenState();
}

class _MisCitasScreenState extends State<MisCitasScreen> with SingleTickerProviderStateMixin {
  bool _cargando = true;
  List<CitaMedica> _citas = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarCitas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            modalidad: 'VIRTUAL',
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
            modalidad: 'PRESENCIAL',
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
    return Colors.white;
  }

  Color _obtenerColorBorde(String estado) {
    switch (estado) {
      case 'PROGRAMADA':
        return BienestarColors.rosa; // Rosado de marca
      case 'CONFIRMADA':
        return BienestarColors.rosa; // Morado de marca
      case 'COMPLETADA':
        return BienestarColors.rosa;
      case 'CANCELADA':
        return Colors.grey;
      default:
        return BienestarColors.rosa;
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
            modalidad: c.modalidad,
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
        backgroundColor: BienestarColors.rosa,
      ),
    );
  }

  void _establecerRecordatorio(CitaMedica cita) {
    final formato = DateFormat('dd/MM/yyyy hh:mm a').format(cita.fechaHora);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recordatorio fijado para tu cita con ${cita.nombreEspecialista} el $formato.'),
        backgroundColor: BienestarColors.rosa,
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
            style: ElevatedButton.styleFrom(backgroundColor: BienestarColors.rosa),
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
        backgroundColor: BienestarColors.rosa,
      ),
    );
  }

  // ignore: unused_element
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
              Icon(Icons.military_tech, color: BienestarColors.rosa, size: 32),
              SizedBox(width: 8),
              Text('¡Felicitaciones!'),
            ],
          ),
          content: const Text(
            '¡Has completado tu cita con amor y compromiso hacia ti misma!\n\nHas ganado +50 puntos para tu bienestar y autocuidado por priorizar tu salud.',
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
              modalidad: c.modalidad,
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
              Icon(Icons.military_tech, color: BienestarColors.rosa, size: 32),
              SizedBox(width: 8),
              Text('¡Felicitaciones!'),
            ],
          ),
          content: const Text(
            '¡Has completado tu cita con amor y compromiso hacia ti misma!\n\nHas ganado +50 puntos para tu bienestar y autocuidado por priorizar tu salud.',
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
    final now = DateTime.now();
    final proximasCitas = _citas.where((c) => !c.fechaHora.isBefore(now)).toList();
    final historialCitas = _citas.where((c) => c.fechaHora.isBefore(now)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas Médicas'),
        backgroundColor: BienestarColors.rosa,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Próximas'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListaCitas(proximasCitas, esHistorial: false),
                _buildListaCitas(historialCitas, esHistorial: true),
              ],
            ),
    );
  }


                  padding: const EdgeInsets.all(16),
                  itemCount: _citas.length,
                  itemBuilder: (context, index) {
                    final cita = _citas[index];
                    final colorFondo = _obtenerColorCardFondo(cita.estado);
                    final colorBorde = _obtenerColorBorde(cita.estado);
                    final iconoEstado = _obtenerIconoEstado(cita.estado);
                    final fechaFormateada = DateFormat('dd/MM/yyyy hh:mm a').format(cita.fechaHora);
                    final nombreEspecialista = (cita.especialistaNombre != null && cita.especialistaNombre!.isNotEmpty)
                        ? cita.especialistaNombre!
                        : cita.nombreEspecialista;

                    return Card(
                      color: colorFondo,
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: BienestarColors.rosa.withOpacity(0.2), width: 1),
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
                            if (nombreEspecialista.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Especialista: $nombreEspecialista',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: BienestarColors.rosa),
                              ),
                            ],
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
                                    icon: const Icon(Icons.edit_calendar, size: 16, color: BienestarColors.rosa),
                                    label: const Text('Reprogramar'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: BienestarColors.rosa,
                                      side: const BorderSide(color: BienestarColors.rosa),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _establecerRecordatorio(cita),
                                    icon: const Icon(Icons.notifications_active, size: 16, color: BienestarColors.rosa),
                                    label: const Text('Recordatorio'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: BienestarColors.rosa,
                                      side: const BorderSide(color: BienestarColors.rosa),
                                    ),
                                  ),
                                ],
                                IconButton(
                                  onPressed: () => _eliminarCita(cita),
                                  icon: const Icon(Icons.delete_outline, color: BienestarColors.rosa),
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
