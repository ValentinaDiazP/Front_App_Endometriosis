import 'package:flutter/material.dart';
import '../../data/mock_educativo_data.dart';
import '../../models/categoria_contenido.dart';
import '../../models/contenido_educativo.dart';
import '../../educativo_routes.dart';
import '../widgets/categoria_chip.dart';
import '../widgets/contenido_card.dart';

/// Biblioteca básica de contenido (Semana 2 del cronograma).
/// Aquí SOLO hay UI + datos mock: filtra en memoria, no llama a ningún API.
class BibliotecaScreen extends StatefulWidget {
  const BibliotecaScreen({super.key});

  @override
  State<BibliotecaScreen> createState() => _BibliotecaScreenState();
}

class _BibliotecaScreenState extends State<BibliotecaScreen> {
  String? _categoriaSeleccionada; // null = "Todas"

  List<ContenidoEducativo> get _contenidosFiltrados {
    if (_categoriaSeleccionada == null) return MockEducativoData.contenidos;
    return MockEducativoData.contenidos
        .where((c) => c.idCategoriaFK == _categoriaSeleccionada)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        _CategoriasBar(
          seleccionada: _categoriaSeleccionada,
          onSeleccionar: (id) => setState(() => _categoriaSeleccionada = id),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: _contenidosFiltrados.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final contenido = _contenidosFiltrados[index];
              return ContenidoCard(
                contenido: contenido,
                onTap: () => Navigator.pushNamed(
                  context,
                  EducativoRoutes.contenidoDetalle,
                  arguments: contenido,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoriasBar extends StatelessWidget {
  final String? seleccionada;
  final ValueChanged<String?> onSeleccionar;

  const _CategoriasBar({required this.seleccionada, required this.onSeleccionar});

  @override
  Widget build(BuildContext context) {
    final categorias = MockEducativoData.categorias;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ChoiceChip(
            label: const Text('Todas'),
            selected: seleccionada == null,
            onSelected: (_) => onSeleccionar(null),
          ),
          const SizedBox(width: 8),
          ...categorias.map(
            (CategoriaContenido cat) => CategoriaChip(
              categoria: cat,
              seleccionada: seleccionada == cat.idCategoria,
              onTap: () => onSeleccionar(cat.idCategoria),
            ),
          ),
        ],
      ),
    );
  }
}
