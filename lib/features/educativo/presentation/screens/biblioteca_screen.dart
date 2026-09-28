import 'package:flutter/material.dart';
import '../../data/educativo_repository.dart';
import '../../models/categoria_contenido.dart';
import '../../models/contenido_educativo.dart';
import '../../educativo_routes.dart';
import '../widgets/categoria_chip.dart';
import '../widgets/contenido_card.dart';

/// Lista de contenidos de la biblioteca, con filtro por categoría.
/// Se llega aquí desde [CategoriasScreen] (con una categoría ya elegida,
/// o sin ninguna si la usuaria tocó "Ver todo").
///
/// Datos 100% mock: filtra en memoria, no llama a ningún API.
class BibliotecaScreen extends StatefulWidget {
  /// Id de la categoría con la que abrir la pantalla ya filtrada.
  /// Null = mostrar todas.
  final String? categoriaInicial;

  const BibliotecaScreen({super.key, this.categoriaInicial});

  @override
  State<BibliotecaScreen> createState() => _BibliotecaScreenState();
}

class _BibliotecaScreenState extends State<BibliotecaScreen> {
  late String? _categoriaSeleccionada = widget.categoriaInicial;

  List<ContenidoEducativo> get _contenidosFiltrados {
    if (_categoriaSeleccionada == null) return EducativoRepository.contenidos;
    return EducativoRepository.contenidos
        .where((c) => c.idCategoriaFK == _categoriaSeleccionada)
        .toList();
  }

  Future<void> _abrirDetalle(ContenidoEducativo contenido) async {
    await Navigator.pushNamed(
      context,
      EducativoRoutes.contenidoDetalle,
      arguments: contenido,
    );
    // Al volver, el estado de "completado" pudo haber cambiado dentro del
    // detalle (ver ContenidoDetailScreen) — refrescamos para mostrarlo.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Si se abrió desde "Ver todo" (sin Scaffold propio, dentro del tab),
    // no duplicamos AppBar. Si se abrió con una categoría (push aparte),
    // sí mostramos AppBar con back.
    final contenido = Column(
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
              final item = _contenidosFiltrados[index];
              return ContenidoCard(
                contenido: item,
                completado: EducativoRepository.contenidoCompletado(item.idContenido),
                onTap: () => _abrirDetalle(item),
              );
            },
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca')),
      body: contenido,
    );
  }
}

class _CategoriasBar extends StatelessWidget {
  final String? seleccionada;
  final ValueChanged<String?> onSeleccionar;

  const _CategoriasBar({required this.seleccionada, required this.onSeleccionar});

  @override
  Widget build(BuildContext context) {
    final categorias = EducativoRepository.categorias;
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
