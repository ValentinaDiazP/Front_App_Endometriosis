import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../services/bienestar_service.dart';
import 'package:flutter_application/core/services/auth_service.dart';

class ProductoDetalleScreen extends StatefulWidget {
  final int? productoId;
  final Producto? producto;

  const ProductoDetalleScreen({Key? key, this.productoId, this.producto}) : super(key: key);

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  bool _isLoading = true;
  Producto? _producto;

  @override
  void initState() {
    super.initState();
    if (widget.producto != null) {
      _producto = widget.producto;
      _isLoading = false;
    }
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    if (widget.productoId == null) {
      setState(() => _isLoading = false);
      return;
    }
    if (_producto == null) {
      setState(() => _isLoading = true);
    }
    try {
      final prod = await BienestarService.obtenerProductoDetalle(productoId: widget.productoId!);
      setState(() {
        _producto = prod;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _agregarAlCarrito(Producto producto) async {
    try {
      final token = AuthService.token ?? 'mock_token';
      await BienestarService.agregarAlCarrito(productoId: producto.id, cantidad: 1, token: token);
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Agregado: ${producto.nombre}'),
          backgroundColor: const Color(0xFFF48FB1),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Detalle de Producto'),
          backgroundColor: const Color(0xFFEC407A),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFEC407A))),
      );
    }

    if (_producto == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Detalle de Producto'),
          backgroundColor: const Color(0xFFEC407A),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No se pudo cargar el producto.', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    }

    final prod = _producto!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(prod.nombre),
        backgroundColor: const Color(0xFFEC407A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con errorBuilder elegante
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  prod.imagenUrl,
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 240,
                    width: double.infinity,
                    color: Colors.pink.shade50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.image_not_supported_outlined, size: 50, color: Color(0xFFEC407A)),
                        SizedBox(height: 8),
                        Text(
                          'Imagen no disponible',
                          style: TextStyle(color: Color(0xFFEC407A), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    prod.nombre,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                Text(
                  '\$${prod.precio.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFEC407A)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Categoría: ${prod.categoria}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            // Reseñas & Rating
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${prod.rating} (${prod.reviewsCount} opiniones)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Botón Agregar al Carrito
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC407A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Agregar al Carrito', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => _agregarAlCarrito(prod),
              ),
            ),
            const SizedBox(height: 24),
            // Descripción
            const Text(
              'Descripción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEC407A)),
            ),
            const SizedBox(height: 8),
            Text(
              prod.descripcion,
              style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 20),
            // Composición
            const Text(
              'Composición',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEC407A)),
            ),
            const SizedBox(height: 8),
            Text(
              prod.composicion,
              style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 24),
            // Productos Relacionados
            if (prod.productosRelacionados.isNotEmpty) ...[
              const Text(
                'Productos Relacionados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEC407A)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: prod.productosRelacionados.length,
                  itemBuilder: (context, index) {
                    final rel = prod.productosRelacionados[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductoDetalleScreen(productoId: rel.id),
                          ),
                        );
                      },
                      child: Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(
                                rel.imagenUrl,
                                height: 110,
                                width: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  height: 110,
                                  color: Colors.pink.shade50,
                                  child: const Icon(Icons.image, color: Color(0xFFEC407A)),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rel.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${rel.precio.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Color(0xFFEC407A), fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
