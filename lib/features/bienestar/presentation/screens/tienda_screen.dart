import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../services/bienestar_service.dart';
import 'carrito_screen.dart';

class TiendaScreen extends StatefulWidget {
  const TiendaScreen({Key? key}) : super(key: key);

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  List<Producto> _productos = [];
  bool _isLoading = true;
  String _categoriaSeleccionada = 'TODOS';

  final List<Map<String, String>> _categorias = [
    {'key': 'TODOS', 'label': 'Todos'},
    {'key': 'CUIDADO_MENSTRUAL', 'label': 'Cuidado Menstrual'},
    {'key': 'ALIVIO_TERMICO', 'label': 'Alivio Térmico'},
  ];

  final List<Producto> _productosMock = [
    Producto(
      id: 1,
      nombre: 'Bolsa Térmica de Alivio',
      descripcion: 'Calor enfocado para dolor pélvico.',
      precio: 45000.0,
      categoria: 'ALIVIO_TERMICO',
      marca: 'Florecer',
      imagenUrl: 'https://th.bing.com/th/id/R.a43d8cf66a9d4c22c1f46fc5f8a04a3f?rik=pEuCeoiBuf0fUA&pid=ImgRaw&r=0',
      disponible: true,
    ),
    Producto(
      id: 2,
      nombre: 'Peluche Térmico para Cólicos',
      descripcion: 'Suave y reconfortante para calmar dolores menstruales.',
      precio: 55000.0,
      categoria: 'ALIVIO_TERMICO',
      marca: 'Florecer',
      imagenUrl: 'https://th.bing.com/th/id/R.ef2b7d3e18217215248c329d97993838?rik=hQvFQp08oOpkqg&pid=ImgRaw&r=0',
      disponible: true,
    ),
    Producto(
      id: 3,
      nombre: 'Parches Térmicos Lumbares',
      descripcion: 'Parches térmicos de larga duración.',
      precio: 25000.0,
      categoria: 'ALIVIO_TERMICO',
      marca: 'Bienestar',
      imagenUrl: 'https://tse4.mm.bing.net/th/id/OIP.8i04m1AoAjrQD4Lxpqv3mgHaHa?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
      disponible: true,
    ),
    Producto(
      id: 4,
      nombre: 'Copa Menstrual Ecológica',
      descripcion: 'Silicona médica hipoalergénica.',
      precio: 60000.0,
      categoria: 'CUIDADO_MENSTRUAL',
      marca: 'Luna',
      imagenUrl: 'https://m.media-amazon.com/images/I/61p7JcB4u6L._AC_SL1500_.jpg',
      disponible: true,
    ),
    Producto(
      id: 5,
      nombre: 'Disco Menstrual Reutilizable',
      descripcion: 'Mayor comodidad y protección durante el ciclo.',
      precio: 65000.0,
      categoria: 'CUIDADO_MENSTRUAL',
      marca: 'Luna',
      imagenUrl: 'https://th.bing.com/th/id/R.48e771b0152953ce28b214347a9e9284?rik=q5ABHHB7m7zMrQ&pid=ImgRaw&r=0',
      disponible: true,
    ),
    Producto(
      id: 6,
      nombre: 'Kit Bienestar Femenino',
      descripcion: 'Incluye aceites esenciales, té e infusión.',
      precio: 80000.0,
      categoria: 'CUIDADO_MENSTRUAL',
      marca: 'Florecer',
      imagenUrl: 'https://www.sensi2live.com/media/catalog/product/cache/eec48ab0b6fb28750d7cc7bb3f0d50b1/p/a/pack_bienestar_femenino_700x700.png',
      disponible: true,
    ),
    Producto(
      id: 7,
      nombre: 'Infusión / Té de Alivio',
      descripcion: 'Hierbas naturales para relajar el útero.',
      precio: 20000.0,
      categoria: 'ALIVIO_TERMICO',
      marca: 'Herbal',
      imagenUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500',
      disponible: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() => _isLoading = true);
    try {
      final productos = await BienestarService.obtenerProductos();
      setState(() {
        _productos = productos.isNotEmpty ? productos : _productosMock;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _productos = _productosMock;
        _isLoading = false;
      });
    }
  }

  void _agregarAlCarrito(Producto producto) async {
    try {
      await BienestarService.agregarAlCarrito(productoId: producto.id, cantidad: 1, token: 'mock_token');
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto añadido al carrito'),
          backgroundColor: Color(0xFFF48FB1),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productosFiltrados = _categoriaSeleccionada == 'TODOS'
        ? _productos
        : _productos.where((p) => p.categoria == _categoriaSeleccionada).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tienda Virtual de Bienestar'),
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CarritoScreen()),
                );
              },
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF48FB1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Banner Verde Superior
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            color: Colors.green.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
              leading: Icon(Icons.local_fire_department, color: Colors.white, size: 30),
              title: Text('Productos Destacados', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text('Encuentra tu Bolsa Térmica de alivio y más.', style: TextStyle(color: Colors.white)),
            ),
          ),
          // Categorias Horizontal Filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final cat = _categorias[index];
                final isSelected = _categoriaSeleccionada == cat['key'];
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 16 : 8,
                    right: index == _categorias.length - 1 ? 16 : 0,
                  ),
                  child: ChoiceChip(
                    label: Text(cat['label']!),
                    selected: isSelected,
                    selectedColor: const Color(0xFFF48FB1),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFF48FB1) : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _categoriaSeleccionada = cat['key']!;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          // Grid of products
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : productosFiltrados.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay productos disponibles en esta categoría.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.62,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: productosFiltrados.length,
                        itemBuilder: (context, index) {
                          final producto = productosFiltrados[index];
                          return Card(
                            elevation: 3,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.network(
                                    producto.imagenUrl,
                                    height: 110,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 110,
                                      color: Colors.pink.shade50,
                                      child: const Icon(Icons.image_not_supported, color: Colors.pink),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Por [${producto.marca}]',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFF48FB1),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        producto.nombre,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${producto.precio.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.pink.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 30,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFF48FB1),
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () => _agregarAlCarrito(producto),
                                          child: const Text(
                                            'Agregar al Carrito',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
