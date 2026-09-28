import 'package:flutter/material.dart';
import '../../data/mock_educativo_data.dart';
import '../../../../core/theme/app_theme.dart';

/// Pantalla de preferencias de contenido (paso del onboarding).
///
/// La usuaria elige los temas que le interesan (categorías). Esa elección
/// se guarda en [MockEducativoData] y luego se usa para priorizar el
/// contenido en la pestaña "Para ti" (ver GestorContenidoEducativo).
///
/// Se usa de dos formas:
///  - ONBOARDING: se pasa [onFinalizar]; al terminar (o al omitir) se llama
///    ese callback para que el flujo de onboarding continúe. No muestra
///    flecha de volver.
///  - EDICIÓN: sin [onFinalizar]; al guardar hace pop con `true`.
class PreferenciasScreen extends StatefulWidget {
  final VoidCallback? onFinalizar;

  const PreferenciasScreen({super.key, this.onFinalizar});

  @override
  State<PreferenciasScreen> createState() => _PreferenciasScreenState();
}

class _PreferenciasScreenState extends State<PreferenciasScreen> {
  late final Set<String> _seleccion =
      Set<String>.from(MockEducativoData.categoriasPreferidas);

  bool get _esOnboarding => widget.onFinalizar != null;

  void _alternar(String idCategoria) {
    setState(() {
      if (!_seleccion.remove(idCategoria)) _seleccion.add(idCategoria);
    });
  }

  void _guardar() {
    // TODO(backend): POST /api/educativo/preferencias/ con las categorías
    // elegidas (tabla PreferenciaUsuario).
    MockEducativoData.guardarPreferencias(_seleccion);
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
    final categorias = MockEducativoData.categorias;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esOnboarding ? 'Personaliza tu contenido' : 'Mis preferencias'),
        automaticallyImplyLeading: !_esOnboarding,
      ),
      body: SafeArea(
        child: Padding(
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
                        onTap: () => _alternar(categoria.idCategoria),
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
                  onPressed: _seleccion.isEmpty ? null : _guardar,
                  child: Text(_esOnboarding ? 'Continuar' : 'Guardar'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: _omitir,
                  child: Text(_esOnboarding ? 'Omitir por ahora' : 'Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
