class Producto {
  final int id;
  final String nombre;
  final String descripcion;
  final String composicion;
  final double precio;
  final String marca;
  final String categoria;
  final String imagenFinal;
  final String imagenUrl;
  final double rating;
  final int reviewsCount;
  final bool disponible;
  final List<Producto> productosRelacionados;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.composicion = '',
    required this.precio,
    required this.marca,
    required this.categoria,
    this.imagenFinal = '',
    required this.imagenUrl,
    required this.rating,
    required this.reviewsCount,
    required this.disponible,
    this.productosRelacionados = const [],
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    var relList = json['productos_relacionados'] as List? ?? [];
    List<Producto> relacionados = relList.map((i) => Producto.fromJson(i)).toList();

    String imgUrl = json['imagen_url'] ?? '';
    String imgFinal = json['imagen_final'] ?? json['imagen_url'] ?? '';
    if (imgFinal.startsWith('/media/')) {
      imgFinal = 'http://10.0.2.2:8000$imgFinal';
    }
    if (imgUrl.startsWith('/media/')) {
      imgUrl = 'http://10.0.2.2:8000$imgUrl';
    }

    return Producto(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      composicion: json['composicion'] ?? '',
      precio: double.tryParse(json['precio'].toString()) ?? 0.0,
      marca: json['marca'] ?? 'Vital',
      categoria: json['categoria'] ?? '',
      imagenFinal: imgFinal,
      imagenUrl: imgUrl.isNotEmpty ? imgUrl : imgFinal,
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      reviewsCount: json['reviews_count'] ?? 0,
      disponible: json['disponible'] ?? true,
      productosRelacionados: relacionados,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'composicion': composicion,
      'precio': precio,
      'marca': marca,
      'categoria': categoria,
      'imagen_final': imagenFinal,
      'imagen_url': imagenUrl,
      'rating': rating,
      'reviews_count': reviewsCount,
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
