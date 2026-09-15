import 'package:flutter/material.dart';
import '../../data/mock_educativo_data.dart';
import '../../models/categoria_contenido.dart';
import '../widgets/aviso_pendiente_card.dart';
import '../widgets/progreso_biblioteca_bar.dart';
import 'biblioteca_screen.dart';

/// Pantalla de entrada a la Biblioteca: muestra las categorías de
/// contenido como tarjetas grandes. Corresponde a la tarea del cronograma
/// "Frontend - Biblioteca de contenido: Maquetar las pantallas de
/// categorías y tarjetas de contenido educativo, usando datos mock".
///
/// Al tocar una categoría, navega a [BibliotecaScreen] ya filtrada por
/// esa categoría. También hay una tarjeta "Ver todo" para entrar sin filtro.
class CategoriasScreen extends StatelessWidget {
  const CategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const AvisoPendienteCard(),
        const ProgresoBibliotecaBar(),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('Categorías', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final categoria in MockEducativoData.categorias)
                _CategoriaCard(
                  categoria: categoria,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BibliotecaScreen(categoriaInicial: categoria.idCategoria),
                    ),
                  ),
                ),
              _CategoriaCard(
                categoria: null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BibliotecaScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  final CategoriaContenido? categoria; // null = "Ver todo"
  final VoidCallback onTap;

  const _CategoriaCard({required this.categoria, required this.onTap});

  int get _cantidadContenidos {
    if (categoria == null) return MockEducativoData.contenidos.length;
    return MockEducativoData.contenidos
        .where((c) => c.idCategoriaFK == categoria!.idCategoria)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF1EAFB),
                child: Icon(
                  categoria == null ? Icons.grid_view_rounded : Icons.folder_outlined,
                  color: const Color(0xFF8E6BBF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoria?.nombre ?? 'Ver todo el contenido',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      categoria?.descripcion ?? 'Explora todas las categorías juntas.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Text('$_cantidadContenidos', style: const TextStyle(color: Colors.black45, fontSize: 12)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
