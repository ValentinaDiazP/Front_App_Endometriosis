class Producto {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String marca;
  final String categoria;
  final String imagenUrl;
  final bool disponible;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.marca,
    required this.categoria,
    required this.imagenUrl,
    required this.disponible,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      precio: double.tryParse(json['precio'].toString()) ?? 0.0,
      marca: json['marca'] ?? 'Vital',
      categoria: json['categoria'] ?? '',
      imagenUrl: json['imagen_url'] ?? '',
      disponible: json['disponible'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'marca': marca,
      'categoria': categoria,
      'imagen_url': imagenUrl,
      'disponible': disponible,
    };
  }
}

class ItemCarrito {
  final int id;
  final int productoId;
  final Producto? productoDetalle;
  int cantidad;

  ItemCarrito({
    required this.id,
    required this.productoId,
    this.productoDetalle,
    required this.cantidad,
  });

  factory ItemCarrito.fromJson(Map<String, dynamic> json) {
    return ItemCarrito(
      id: json['id'],
      productoId: json['producto'] is int ? json['producto'] : (json['producto_detalle'] != null ? json['producto_detalle']['id'] : 0),
      productoDetalle: json['producto_detalle'] != null ? Producto.fromJson(json['producto_detalle']) : null,
      cantidad: json['cantidad'] ?? 1,
    );
  }
}
