import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'core/navigation/app_router.dart';
import 'features/educativo/presentation/screens/educativo_home_screen.dart';
import 'features/educativo/presentation/screens/preferencias_screen.dart';
import 'core/services/auth_service.dart';
import 'features/seguimiento/models/informacion_personal.dart';
import 'features/seguimiento/presentation/screens/seguimiento_home_screen.dart';
import 'features/comunidad/presentation/screens/comunidad_feed_screen.dart'; // Ajusta la ruta exacta según tu estructura de carpetas
void main() {
  runApp(const FlorecerApp());
}

// --- CONFIGURACIÓN GLOBAL ---

class AppColors {
  static const Color primary = Color(0xFFF48FB1); // Rosa Salmón
  static const Color secondary = Color(0xFF81C784); // Verde Menta
  static const Color background = Color(0xFFFAF9F6); // Crema Suave
  static const Color textDark = Color(0xFF212121);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color danger = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFCC80);
}

class FlorecerApp extends StatelessWidget {
  const FlorecerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Florecer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        fontFamily: 'Inter',
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          titleTextStyle: TextStyle(
            color: AppColors.textLight,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: AppColors.textLight),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            elevation: 5,
          ),
        ),
      ),
      home: const AuthScreen(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

// --- 1. MÓDULO DE INICIO Y AUTENTICACIÓN ---

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _ingresando = false;

  Future<void> _handleLogin() async {
    final username = _userController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa usuario y contraseña para continuar.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _ingresando = true);
    try {
      final loginExitoso = await AuthService.login(username: username, password: password);
      final perfil = await AuthService.obtenerPerfil(loginExitoso.token);

      final informacionPersonal = InformacionPersonal(
        usuarioId: perfil.usuarioId.toString(),
        nombre: perfil.nombre,
        fechaNacimiento: perfil.fechaNacimiento,
        fechaDiagnostico: perfil.fechaDiagnostico,
      );

      if (!mounted) return;

      if (perfil.onboardingCompletado) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainNavigationHub(
              informacionPersonal: informacionPersonal,
              token: loginExitoso.token,
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DiagnosisScreen(
              informacionPersonal: informacionPersonal,
              token: loginExitoso.token,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final mensaje = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _ingresando = false);
    }
  }

  void _irARegistro() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegistroScreen()),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(Icons.spa, size: 100, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Bienvenida a Florecer',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu camino hacia el equilibrio y la comprensión.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textDark),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _userController,
                enabled: !_ingresando,
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  hintText: 'Ingresa tu nombre de usuario',
                  prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                enabled: !_ingresando,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  hintText: 'Ingresa tu contraseña',
                  prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _ingresando ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.textLight,
                ),
                child: _ingresando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Ingresar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _ingresando ? null : _irARegistro,
                child: const Text('¿No tienes cuenta? Regístrate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Registro de una nueva usuaria. Al terminar, guarda la cuenta en el
/// backend y regresa a AuthScreen para que inicie sesión normalmente
/// (no entra directo a la app).
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _diagnosticoController = TextEditingController();

  DateTime? _fechaNacimiento;
  DateTime? _fechaDiagnostico;
  bool _enviando = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _diagnosticoController.dispose();
    super.dispose();
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar fecha';
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  Future<void> _seleccionarFecha({
    required DateTime? fechaActual,
    required ValueChanged<DateTime> onFechaSeleccionada,
  }) async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaActual ?? DateTime(ahora.year - 20),
      firstDate: DateTime(1930),
      lastDate: ahora,
    );
    if (fecha != null) onFechaSeleccionada(fecha);
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tu fecha de nacimiento')),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      await AuthService.registrar(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        nombre: _nombreController.text.trim(),
        fechaNacimiento: _fechaNacimiento!,
        diagnostico: _diagnosticoController.text,
        fechaDiagnostico: _fechaDiagnostico,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Cuenta creada! Ya puedes iniciar sesión.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final mensaje = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                enabled: !_enviando,
                decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _enviando
                    ? null
                    : () => _seleccionarFecha(
                          fechaActual: _fechaNacimiento,
                          onFechaSeleccionada: (f) => setState(() => _fechaNacimiento = f),
                        ),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de nacimiento',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(_formatearFecha(_fechaNacimiento)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _diagnosticoController,
                enabled: !_enviando,
                decoration: const InputDecoration(
                  labelText: 'Diagnóstico (opcional)',
                  hintText: 'Ej: Endometriosis',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _enviando
                    ? null
                    : () => _seleccionarFecha(
                          fechaActual: _fechaDiagnostico,
                          onFechaSeleccionada: (f) => setState(() => _fechaDiagnostico = f),
                        ),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de diagnóstico (opcional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(_formatearFecha(_fechaDiagnostico)),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                enabled: !_enviando,
                decoration: const InputDecoration(labelText: 'Nombre de usuario', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Elige un usuario' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                enabled: !_enviando,
                decoration: const InputDecoration(
                  labelText: 'Contraseña (mínimo 6 caracteres)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Crea una contraseña';
                  if (v.length < 6) return 'Debe tener al menos 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _enviando ? null : _registrar,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _enviando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Crear cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. MÓDULO DE DIAGNÓSTICO ---

class DiagnosisScreen extends StatelessWidget {
  final InformacionPersonal informacionPersonal;
  final String token;

  const DiagnosisScreen({
    super.key,
    required this.informacionPersonal,
    required this.token,
  });

  Future<void> _navigateToNext(BuildContext context, String diagnosis) async {
    if (diagnosis == 'Endometriosis') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuestionnaireScreen(
            informacionPersonal: informacionPersonal,
            token: token,
          ),
        ),
      );
    } else {
      // Se salta el cuestionario, pero igual marca el onboarding como
      // completo para no repetir ni siquiera esta pantalla la próxima vez.
      await AuthService.completarOnboarding(token);
      if (!context.mounted) return;
      // Paso de preferencias del módulo Educativo antes de entrar al menú.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (preferenciasContext) => PreferenciasScreen(
            token: token,
            onFinalizar: () => Navigator.of(preferenciasContext).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MainNavigationHub(
                  informacionPersonal: informacionPersonal,
                  token: token,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDiagnosisCard(BuildContext context, String title, IconData icon) {
    return Card(
      color: Colors.white,
      elevation: 6,
      child: InkWell(
        onTap: () => _navigateToNext(context, title),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Viaje de Bienestar'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SafetyNoticeCard(),
            const SizedBox(height: 24),
            const Text(
              "Selecciona tu enfoque principal:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                _buildDiagnosisCard(context, 'Endometriosis', Icons.healing),
                _buildDiagnosisCard(context, 'Trackear Periodo', Icons.calendar_today),
                _buildDiagnosisCard(context, 'SOP', Icons.pregnant_woman),
                _buildDiagnosisCard(context, 'Miomas', Icons.local_hospital),
                _buildDiagnosisCard(context, 'Menopausia', Icons.thermostat),
                _buildDiagnosisCard(context, 'Otros/General', Icons.monitor_heart),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class SafetyNoticeCard extends StatelessWidget {
  const SafetyNoticeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.warning.withOpacity(0.2),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.warning),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber, color: AppColors.warning, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "ADVERTENCIA: Debes tener un diagnóstico médico. Esta aplicación es para acompañamiento, no para diagnóstico. Confirma tu diagnóstico médico antes de continuar.",
                style: TextStyle(color: AppColors.textDark.withOpacity(0.9), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. MÓDULO DE CUESTIONARIO ---

class QuestionnaireScreen extends StatefulWidget {
  final InformacionPersonal informacionPersonal;
  final String token;

  const QuestionnaireScreen({
    super.key,
    required this.informacionPersonal,
    required this.token,
  });

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  double _dolorFrecuencia = 0.5;
  bool _fatiga = true;
  bool _migranas = false;
  bool _problemasDigestivos = true;
  bool _infertilidad = false;

  bool _dietaAntiinflamatoria = true;
  bool _terapiaHormonal = false;
  bool _fisioterapiaPelvica = true;
  bool _terapiaPsicologica = false;

  double _ansiedadFrecuencia = 0.7;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

    Future<void> _nextPage() async {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Termina el cuestionario por primera vez: se marca el onboarding
      // como completo para que el próximo login vaya directo al menú.
      await AuthService.completarOnboarding(widget.token);
      if (!mounted) return;
      // Paso de preferencias del módulo Educativo antes de entrar al menú.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (preferenciasContext) => PreferenciasScreen(
            token: widget.token,
            onFinalizar: () => Navigator.of(preferenciasContext).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MainNavigationHub(
                  informacionPersonal: widget.informacionPersonal,
                  token: widget.token,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildQuestionBlock(int index, String title, List<Widget> questions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const Divider(color: AppColors.secondary, thickness: 2),
          const SizedBox(height: 16),
          ...questions,
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildQuestionBlock(
        0,
        'Bloque 1: Datos Generales',
        [
          const Text('1. Altura (cm):'),
          const TextField(keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          const Text('2. País de residencia:'),
          const DropdownMenu(
            dropdownMenuEntries: [
              DropdownMenuEntry(value: 'mexico', label: 'México'),
              DropdownMenuEntry(value: 'colombia', label: 'Colombia'),
              DropdownMenuEntry(value: 'espana', label: 'España'),
              DropdownMenuEntry(value: 'usa', label: 'Estados Unidos'),
            ],
            hintText: 'Seleccionar...',
          ),
        ],
      ),
      _buildQuestionBlock(
        1,
        'Bloque 2: Síntomas Físicos',
        [
          const Text('3. Frecuencia del dolor pélvico (1=Raro, 10=Diario):', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Frecuencia actual: ${(_dolorFrecuencia * 10).round()}/10',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
          Slider(
            value: _dolorFrecuencia,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (double value) => setState(() => _dolorFrecuencia = value),
            activeColor: AppColors.primary,
          ),
          const SizedBox(height: 24),
          const Text('4. Marca otros síntomas de chequeo que presentes:', style: TextStyle(fontWeight: FontWeight.w600)),
          _buildSymptomCheckbox('Fatiga crónica', _fatiga, (val) => _fatiga = val),
          _buildSymptomCheckbox('Migrañas frecuentes', _migranas, (val) => _migranas = val),
          _buildSymptomCheckbox('Problemas digestivos', _problemasDigestivos, (val) => _problemasDigestivos = val),
          _buildSymptomCheckbox('Dificultad para concebir', _infertilidad, (val) => _infertilidad = val),
        ],
      ),
      _buildQuestionBlock(
        2,
        'Bloque 3: Tratamiento y Gestión',
        [
          const Text('5. Selecciona las recomendaciones médicas recibidas:', style: TextStyle(fontWeight: FontWeight.w600)),
          _buildSymptomCheckbox('Dieta antiinflamatoria', _dietaAntiinflamatoria, (val) => _dietaAntiinflamatoria = val),
          _buildSymptomCheckbox('Terapia hormonal', _terapiaHormonal, (val) => _terapiaHormonal = val),
          _buildSymptomCheckbox('Fisioterapia pélvica', _fisioterapiaPelvica, (val) => _fisioterapiaPelvica = val),
          _buildSymptomCheckbox('Terapia psicológica', _terapiaPsicologica, (val) => _terapiaPsicologica = val),
        ],
      ),
      _buildQuestionBlock(
        3,
        'Bloque 4: Aspectos Emocionales',
        [
          const Text('7. Describe el impacto de tus síntomas:', style: TextStyle(fontWeight: FontWeight.w600)),
          const TextField(maxLines: 4, decoration: InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 20),
          const Text('8. Frecuencia de ansiedad (1-10):', style: TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _ansiedadFrecuencia,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (double value) => setState(() => _ansiedadFrecuencia = value),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Cuestionario Endometriosis (${_currentPage + 1}/4)'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: pages,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textLight,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(_currentPage < 3 ? 'Siguiente Bloque' : 'Finalizar y Entrar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomCheckbox(String title, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: (bool? newValue) => setState(() => onChanged(newValue ?? false)),
      activeColor: AppColors.secondary,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

// --- 4. HUB DE NAVEGACIÓN PRINCIPAL ---

class MainNavigationHub extends StatefulWidget {
  final InformacionPersonal informacionPersonal;
  final String token;

  const MainNavigationHub({
    super.key,
    required this.informacionPersonal,
    required this.token,
  });

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions = <Widget>[
    const WellnessModule(), // Módulo Bienestar
    const ComunidadFeedScreen(), // Módulo Comunidad
    SeguimientoHomeScreen(
      informacionPersonal: widget.informacionPersonal,
      token: widget.token,
    ), // Módulo Registro (Seguimiento)
    const ReportsModule(), // Módulo Reportes
    EducativoHomeScreen(token: widget.token), // Módulo Educativo
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Bienestar'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Comunidad'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'Registro'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'Educativo'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textDark.withOpacity(0.6),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }
}
// --- 5. MÓDULO BIENESTAR (ACTUALIZADO CON PESTAÑAS Y DJANGO) ---

class WellnessModule extends StatelessWidget {
  const WellnessModule({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bienestar Integral'),
          bottom: const TabBar(
            indicatorColor: AppColors.textLight,
            labelColor: AppColors.textLight,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.storefront), text: 'Tienda'),
              Tab(icon: Icon(Icons.medical_services), text: 'Profesionales'),
              Tab(icon: Icon(Icons.people), text: 'Comunidad'), // Se mantiene el nombre 'Comunidad'
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            StoreTab(),
            ProfessionalsTab(),
            ComunidadFeedScreen(), // Se carga la vista del feed de la comunidad
          ],
        ),
      ),
    );
  }
}

// SUB-PESTAÑA 1: TIENDA VIRTUAL
class StoreTab extends StatelessWidget {
  const StoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CommercialAdCard(),
        const SizedBox(height: 16),
        const Text(
          'Productos de Bienestar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.local_fire_department, color: AppColors.primary, size: 36),
            title: const Text('Bolsa Térmica de Alivio'),
            subtitle: const Text('Calor enfocado para dolor pélvico.'),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CommercialAdScreen()),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              child: const Text('Ver'),
            ),
          ),
        ),
      ],
    );
  }
}

// SUB-PESTAÑA 2: PROFESIONALES (CONECTADO A DJANGO)
class ProfessionalsTab extends StatefulWidget {
  const ProfessionalsTab({super.key});

  @override
  State<ProfessionalsTab> createState() => _ProfessionalsTabState();
}

class _ProfessionalsTabState extends State<ProfessionalsTab> {
  // Usa 127.0.0.1 para Chrome web o 10.0.2.2 para emulador Android
  final String apiUrl = 'http://10.0.2.2:8000/api/bienestar/professionals/';
  Future<List<dynamic>> fetchProfessionals() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al conectar con la API de Django');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: fetchProfessionals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error de conexión con Backend Django:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay profesionales registrados aún.'));
        }

        final professionals = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: professionals.length,
          itemBuilder: (context, index) {
            final item = professionals[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(item['name'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${item['specialty'] ?? ''}\nTarifa: ${item['rate'] ?? ''}'),
                isThreeLine: true,
                trailing: Text(
                  item['availability'] ?? '',
                  style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// SUB-PESTAÑA 3: HERRAMIENTAS Y EJERCICIOS TCC
class ToolsTab extends StatelessWidget {
  const ToolsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Herramientas de Apoyo Emocional', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          SizedBox(height: 12),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Respiración 4-7-8 (TCC)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  SizedBox(height: 8),
                  Text('Controla la ansiedad y el dolor mediante este ejercicio.'),
                  SizedBox(height: 16),
                  BreathingExerciseGame(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGETS AUXILIARES Y OTROS MÓDULOS ---

class CommercialAdCard extends StatelessWidget {
  const CommercialAdCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CommercialAdScreen()));
      },
      child: Card(
        elevation: 6,
        color: AppColors.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const ListTile(
          leading: Icon(Icons.local_fire_department, color: Colors.white, size: 30),
          title: Text('¡Tienda Florecer!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: Text('Encuentra tu Bolsa Térmica de alivio.', style: TextStyle(color: Colors.white)),
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
        ),
      ),
    );
  }
}

class CommercialAdScreen extends StatelessWidget {
  const CommercialAdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tienda Florecer')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department, color: AppColors.primary, size: 80),
                  const SizedBox(height: 16),
                  const Text('Bolsa Térmica de Alivio', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('Tu aliada contra el dolor. Calor enfocado y alivio instantáneo.', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                    child: const Text('Comprar Ahora'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BreathingExerciseGame extends StatefulWidget {
  const BreathingExerciseGame({super.key});

  @override
  State<BreathingExerciseGame> createState() => _BreathingExerciseGameState();
}

class _BreathingExerciseGameState extends State<BreathingExerciseGame> {
  Timer? _timer;
  int _seconds = 0;
  String _phase = 'Comenzar';
  double _scale = 1.0;

  void _startTimer() {
    _seconds = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _seconds++;
        if (_seconds <= 40) {
          _phase = 'Inhala (4s)';
          _scale = 1.0 + (_seconds / 40.0) * 0.5;
        } else if (_seconds <= 110) {
          _phase = 'Sostén (7s)';
          _scale = 1.5;
        } else if (_seconds <= 190) {
          _phase = 'Exhala (8s)';
          _scale = 1.5 - ((_seconds - 110.0) / 80.0) * 0.5;
        } else {
          _seconds = 0;
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      _phase = 'Comenzar';
      _scale = 1.0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isActive = _timer != null && _timer!.isActive;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 100 * _scale,
          height: 100 * _scale,
          decoration: BoxDecoration(
            color: isActive ? AppColors.secondary : AppColors.primary.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            isActive ? _phase.split(' ')[0] : 'Inicia',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: isActive ? _stopTimer : _startTimer,
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? AppColors.danger : AppColors.secondary,
          ),
          child: Text(isActive ? 'Detener' : 'Iniciar Respiración'),
        ),
      ],
    );
  }
}

// MÓDULOS SECUNDARIOS DEL EQUIPO (COMUNIDAD, REGISTRO, REPORTES)
class CommunityForumModule extends StatelessWidget {
  const CommunityForumModule({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Foro Comunitario')),
      body: const Center(child: Text('Módulo de Comunidad')),
    );
  }
}

class SymptomLogModule extends StatelessWidget {
  const SymptomLogModule({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro Diario')),
      body: const Center(child: Text('Módulo de Registro de Síntomas')),
    );
  }
}

class ReportsModule extends StatelessWidget {
  const ReportsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes y Métricas')),
      body: const Center(child: Text('Módulo de Reportes')),
    );
  }
}