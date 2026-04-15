class Producto {
  final int id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final double precioVenta;
  final double costo;
  final int stock;
  final int stockMinimo;
  final String categoria;
  final String marca;
  final String unidadMedida;
  final bool activo;

  Producto({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.precioVenta,
    required this.costo,
    required this.stock,
    required this.stockMinimo,
    required this.categoria,
    required this.marca,
    required this.unidadMedida,
    required this.activo,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      precioVenta: (json['precio_venta'] ?? 0).toDouble(),
      costo: (json['costo'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      stockMinimo: json['stock_minimo'] ?? 0,
      categoria: json['categoria'] ?? '',
      marca: json['marca'] ?? '',
      unidadMedida: json['unidad_medida'] ?? '',
      activo: json['activo'] ?? false,
    );
  }
}
