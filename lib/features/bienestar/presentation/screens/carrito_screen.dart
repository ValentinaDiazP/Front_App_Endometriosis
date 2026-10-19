import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../services/bienestar_service.dart';
import 'package:flutter_application/core/services/auth_service.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({Key? key}) : super(key: key);

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  List<ItemCarrito> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarCarrito();
  }

  Future<void> _cargarCarrito() async {
    setState(() => _isLoading = true);
    try {
      final token = AuthService.token ?? 'mock_token';
      final items = await BienestarService.obtenerCarrito(token: token);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (_) {
      // Fallback mock items si falla la API
      setState(() {
        _items = [
          ItemCarrito(
            id: 1,
            productoId: 1,
            cantidad: 1,
            productoDetalle: Producto(
              id: 1,
              nombre: 'Bolsa Térmica de Alivio',
              descripcion: 'Calor enfocado para dolor pélvico.',
              precio: 45000.0,
              categoria: 'ALIVIO_TERMICO',
              marca: 'Florecer',
              imagenUrl: 'https://th.bing.com/th/id/R.a43d8cf66a9d4c22c1f46fc5f8a04a3f?rik=pEuCeoiBuf0fUA&pid=ImgRaw&r=0',
              disponible: true,
            ),
          )
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _eliminarItem(int itemId) async {
    try {
      final token = AuthService.token ?? 'mock_token';
      await BienestarService.eliminarItemCarrito(itemId: itemId, token: token);
    } catch (_) {}
    setState(() {
      _items.removeWhere((item) => item.id == itemId);
    });
  }

  Future<void> _confirmarCompra() async {
    try {
      final token = AuthService.token ?? 'mock_token';
      await BienestarService.confirmarCompra(token: token);
    } catch (_) {}

    setState(() {
      _items.clear();
    });

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: const [
              Icon(Icons.check_circle_outline, color: Color(0xFFEC407A), size: 50),
              SizedBox(height: 10),
              Text(
                '¡Gracias por tu compra!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFEC407A), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: const [
                    Text(
                      '+50 Puntos de Bienestar acreditados',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Insignia obtenida: Embajadora del Bienestar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEC407A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC407A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el modal de confirmación
                  Navigator.of(context).pop(); // Cierra CarritoScreen y vuelve a TiendaScreen
                },
                child: const Text('Aceptar'),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = 0;
    for (var item in _items) {
      if (item.productoDetalle != null) {
        subtotal += item.productoDetalle!.precio * item.cantidad;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mi Carrito de Compras'),
        backgroundColor: const Color(0xFFEC407A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'Tu carrito está vacío.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _items.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final prod = item.productoDetalle;
                          if (prod == null) return const SizedBox.shrink();

                          return Card(
                            elevation: 2,
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  prod.imagenUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.image),
                                ),
                              ),
                              title: Text(
                                prod.nombre,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                'Cant: ${item.cantidad} | \$${(prod.precio * item.cantidad).toStringAsFixed(0)}',
                                style: TextStyle(color: Colors.pink.shade900),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _eliminarItem(item.id),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal / Total:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '\$${subtotal.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEC407A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _items.isEmpty ? null : _confirmarCompra,
                            child: const Text(
                              'Confirmar Compra',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
