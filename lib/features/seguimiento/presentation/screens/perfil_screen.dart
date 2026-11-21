import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/sintomas_service.dart';
import '../../models/informacion_personal.dart';
import '../../models/progreso_gamificacion.dart';
import '../../../educativo/presentation/widgets/seccion_aprendizaje_perfil.dart';
import '../../../seguimiento/presentation/screens/carrito_premium_screen.dart';
 
class PerfilScreen extends StatefulWidget {
  final InformacionPersonal informacionPersonal;
  final String token;
 
  const PerfilScreen({
    super.key,
    required this.informacionPersonal,
    required this.token,
  });
 
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}
 
class _PerfilScreenState extends State<PerfilScreen> {
  PerfilUsuaria? _perfil;
  ProgresoGamificacion? _progreso;
  bool _cargando = true;
  String? _error;
  int _version = 0; // al refrescar, también se recarga "Mi aprendizaje"
 
  @override
  void initState() {
    super.initState();
    _cargar();
    AuthService.premiumActivado.addListener(_cargar);
  }
 
  @override
  void dispose() {
    AuthService.premiumActivado.removeListener(_cargar);
    super.dispose();
  }
 
  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
      _version++;
    });
    try {
      final resultados = await Future.wait([
        AuthService.obtenerPerfil(widget.token),
        SintomasService.obtenerProgreso(widget.token),
      ]);
      if (!mounted) return;
      setState(() {
        _perfil = resultados[0] as PerfilUsuaria;
        _progreso = resultados[1] as ProgresoGamificacion;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _confirmarCerrarSesion,
          ),
        ],
      ),
      body: _construirCuerpo(),
    );
  }
 
  /// Vuelve a la pantalla de inicio de sesión (la ruta '/' es AuthScreen) y
  /// borra la navegación anterior, para que "atrás" no regrese a la cuenta.
  Future<void> _confirmarCerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres cerrar tu sesión en Florecer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/', (_) => false);
  }
 
  Widget _construirCuerpo() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
 
    final perfil = _perfil;
    final progreso = _progreso;
    final nombre = perfil?.nombre.isNotEmpty == true
        ? perfil!.nombre
        : widget.informacionPersonal.nombre;
    final username = perfil?.username ?? '';
 
    return RefreshIndicator(
      onRefresh: _cargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Cabecera de Usuaria
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (username.isNotEmpty)
                        Text(
                          '@$username',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
 
            // Plan: insignia Premium o invitación a pasarse a Premium
            _tarjetaPlan(perfil?.esPremium ?? false),
 
            // 2. Tarjeta Principal de Nivel y Progreso
            if (progreso != null) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🌱', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  progreso.nivel?.nombre ?? 'Nivel Semilla',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${progreso.puntosTotales} puntos totales',
                                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progreso.fraccionHaciaSiguiente,
                          minHeight: 10,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        progreso.siguienteNivel != null
                            ? 'Te faltan ${progreso.siguienteNivel!.puntosMinimos - progreso.puntosTotales} puntos para ${progreso.siguienteNivel!.nombre}'
                            : '¡Has alcanzado el nivel máximo!',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
 
              // 3. Tarjeta de Rachas
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 8),
                            const Text('Racha actual', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '${progreso.rachaActual} días',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('🏆', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 8),
                            const Text('Mejor racha', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '${progreso.rachaMaxima} días',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
 
              // 4. Sección 'Historial de Puntos'
              const Text(
                'Historial de puntos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              progreso.historial.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Aún no tienes movimientos de puntos registrados.'),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: progreso.historial.length,
                      itemBuilder: (context, index) {
                        final item = progreso.historial[index];
                        final fechaStr = '${item.fecha.day}/${item.fecha.month}/${item.fecha.year}';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: item.puntos >= 0 ? Colors.green[100] : Colors.red[100],
                              child: Text(
                                item.puntos >= 0 ? '+${item.puntos}' : '${item.puntos}',
                                style: TextStyle(
                                  color: item.puntos >= 0 ? Colors.green[800] : Colors.red[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(item.motivo, style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text(fechaStr, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 24),
            ],
 
            // 5. Progreso del módulo Educativo (puntos de aprendizaje, nivel,
            // racha e insignias por ruta).
            SeccionAprendizajePerfil(key: ValueKey(_version), token: widget.token),
            const SizedBox(height: 24),
 
            // 6. Tarjeta Guía '¿Cómo ganar puntos y su propósito?'
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Cómo ganar puntos?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildGuiaItem(
                      icon: '📝',
                      titulo: 'Registrar síntoma/ánimo (+5 pts)',
                      proposito: 'Detecta patrones para tu especialista.',
                    ),
                    const Divider(height: 24),
                    _buildGuiaItem(
                      icon: '✍️',
                      titulo: 'Crear publicación (+10 pts)',
                      proposito: 'Visibiliza y comparte tu experiencia.',
                    ),
                    const Divider(height: 24),
                    _buildGuiaItem(
                      icon: '💬',
                      titulo: 'Comentar o apoyar (+5 pts)',
                      proposito: 'Brinda contención a la comunidad.',
                    ),
                    const Divider(height: 24),
                    _buildGuiaItem(
                      icon: '📚',
                      titulo: 'Leer un contenido (+10) o hacer un ejercicio (+15)',
                      proposito: 'Suma puntos de aprendizaje y sube de nivel en Educativo.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _abrirPoliticaDatos,
              icon: const Icon(Icons.privacy_tip_outlined, color: Colors.pink),
              label: const Text('Política de Tratamiento de Datos Personales'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.pink),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _eliminarCuentaYDatos,
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: const Text('Eliminar cuenta y datos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  void _abrirPoliticaDatos() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Política de Tratamiento de Datos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                '1. Responsable y Finalidad',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Florecer Bienestar S.A.S. (en adelante "Florecer") es el responsable del tratamiento de sus datos personales y sensibles de salud. La finalidad de la recolección es la prestación de servicios de bienestar, seguimiento de ciclos y salud femenina, personalización de contenidos psicoeducativos, agendamiento de citas médicas y soporte en la plataforma.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              const Text(
                '2. Carácter Facultativo de Datos Sensibles de Salud',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'El usuario no está obligado a autorizar el tratamiento de datos sensibles (síntomas, diagnósticos, ciclo menstrual). Sin embargo, al tratarse de una aplicación especializada en salud femenina, dichos datos son indispensables para el funcionamiento y personalización de las funciones de seguimiento y bienestar.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              const Text(
                '3. Almacenamiento Seguro en la Nube',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sus datos son almacenados de forma segura en bases de datos PostgreSQL / Neon Cloud con cifrado robusto HTTPS/TLS en tránsito y en reposo. Contamos con autorización de transmisión internacional de datos conforme al Artículo 26 de la Ley 1581 de 2012 bajo estrictos estándares de seguridad y confidencialidad.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              const Text(
                '4. Canal de Contacto y Derechos ARCO',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Usted tiene derecho a conocer, actualizar, rectificar sus datos, suprimir información y revocar la autorización en cualquier momento. Para ejercer sus derechos ARCO o consultas, contáctenos en: soporte@florecerbienestar.com.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _eliminarCuentaYDatos() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta y datos'),
        content: const Text(
          '¿Estás segura de que deseas eliminar permanentemente tu cuenta y todos tus datos personales de salud? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar definitivamente'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await AuthService.eliminarCuenta(widget.token);
      AuthService.token = null;
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (e) {
      if (!mounted) return;
      final mensaje = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
      );
    }
  }


 
  Future<void> _irAPremium() async {
    final activado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const CarritoPremiumScreen()),
    );
    if (activado == true && mounted) _cargar();
  }
 
  Widget _tarjetaPlan(bool esPremium) {
    final color = Theme.of(context).colorScheme.primary;
    if (esPremium) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Card(
          elevation: 0,
          color: color.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.workspace_premium, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan Premium',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tienes todos los reportes desbloqueados.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.workspace_premium_outlined, color: color, size: 30),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pásate a Premium',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Desbloquea reportes completos, comparación de tu dolor en la '
                'regla y el resumen en PDF para tu consulta.',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _irAPremium,
                child: const Text('Quiero Premium'),
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _buildGuiaItem({required String icon, required String titulo, required String proposito}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                proposito,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}