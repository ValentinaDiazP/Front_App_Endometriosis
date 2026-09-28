import 'package:flutter/material.dart';
import '../../data/educativo_repository.dart';
import '../widgets/carga_educativo.dart';
import '../../../../core/theme/app_theme.dart';

/// Pantalla de preferencias de contenido (paso del onboarding).
///
/// La usuaria elige los temas que le interesan (categorías). Esa elección
/// se guarda en el backend (PreferenciaUsuario, vía [EducativoRepository])
/// y luego se usa para priorizar el contenido en la pestaña "Para ti"
/// (ver GestorContenidoEducativo).
///
/// Se usa de dos formas:
///  - ONBOARDING: se pasan [token] y [onFinalizar]; al terminar (o al
///    omitir) se llama ese callback para que el flujo de onboarding
///    continúe. No muestra flecha de volver.
///  - EDICIÓN: sin [onFinalizar] (el módulo ya está cargado, no hace falta
///    [token]); al guardar hace pop con `true`.
class PreferenciasScreen extends StatelessWidget {
  final String? token;
  final VoidCallback? onFinalizar;

  const PreferenciasScreen({super.key, this.token, this.onFinalizar});

  @override
  Widget build(BuildContext context) {
    final esOnboarding = onFinalizar != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(esOnboarding ? 'Personaliza tu contenido' : 'Mis preferencias'),
        automaticallyImplyLeading: !esOnboarding,
      ),
      body: SafeArea(
        child: CargaEducativo(
          token: token,
          onOmitir: onFinalizar,
          builder: (_) => _FormularioPreferencias(onFinalizar: onFinalizar),
        ),
      ),
    );
  }
}

class _FormularioPreferencias extends StatefulWidget {
  final VoidCallback? onFinalizar;

  const _FormularioPreferencias({this.onFinalizar});

  @override
  State<_FormularioPreferencias> createState() => _FormularioPreferenciasState();
}

class _FormularioPreferenciasState extends State<_FormularioPreferencias> {
  late final Set<String> _seleccion =
      Set<String>.from(EducativoRepository.categoriasPreferidas);
  bool _guardando = false;

  bool get _esOnboarding => widget.onFinalizar != null;

  void _alternar(String idCategoria) {
    setState(() {
      if (!_seleccion.remove(idCategoria)) _seleccion.add(idCategoria);
    });
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await EducativoRepository.guardarPreferencias(_seleccion);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron guardar tus preferencias. Intenta de nuevo.')),
      );
      return;
    }
    if (!mounted) return;
    if (_esOnboarding) {
      widget.onFinalizar!();
    } else {
      Navigator.pop(context, true);
    }
  }

  void _omitir() {
    if (_esOnboarding) {
      widget.onFinalizar!();
    } else {
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categorias = EducativoRepository.categorias;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Qué te gustaría aprender?',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text(
            'Elige uno o más temas. Con eso te mostraremos primero el '
            'contenido que más te puede servir. Puedes cambiarlo cuando quieras.',
            style: TextStyle(color: Colors.black54, fontSize: 13.5),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: categorias.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final categoria = categorias[index];
                final elegida = _seleccion.contains(categoria.idCategoria);
                return Material(
                  color: elegida ? AppTheme.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _guardando ? null : () => _alternar(categoria.idCategoria),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: elegida ? AppTheme.primary : Colors.black12,
                          width: elegida ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(categoria.nombre,
                                    style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 2),
                                Text(categoria.descripcion,
                                    style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                              ],
                            ),
                          ),
                          Icon(
                            elegida ? Icons.check_circle : Icons.circle_outlined,
                            color: elegida ? AppTheme.primary : Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _seleccion.isEmpty || _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_esOnboarding ? 'Continuar' : 'Guardar'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _guardando ? null : _omitir,
              child: Text(_esOnboarding ? 'Omitir por ahora' : 'Cancelar'),
            ),
          ),
        ],
      ),
    );
  }
}
