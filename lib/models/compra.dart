class CompraItem {
  final int idProducto;
  final String codigo;
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  CompraItem({
    required this.idProducto,
    required this.codigo,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory CompraItem.fromJson(Map<String, dynamic> json) {
    return CompraItem(
      idProducto: json['id_producto'] ?? 0,
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      cantidad: json['cantidad'] ?? 0,
      precioUnitario: (json['precio_unitario'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }
}

class Compra {
  final String id;
  final String folio;
  final String fecha;
  final double total;
  final String cliente;
  final String metodoPago;
  final String vendedor;
  final String estado;
  final List<CompraItem> items;

  Compra({
    required this.id,
    required this.folio,
    required this.fecha,
    required this.total,
    required this.cliente,
    required this.metodoPago,
    required this.vendedor,
    required this.estado,
    required this.items,
  });

  factory Compra.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final List<CompraItem> itemsParseados =
        rawItems is List
            ? rawItems
                .map((e) => CompraItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : [];

    return Compra(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      folio: json['folio']?.toString() ?? 'Sin folio',
      fecha: json['fecha']?.toString() ?? '',
      total: (json['total'] ?? 0).toDouble(),
      cliente: json['cliente']?.toString() ?? 'Cliente mostrador',
      metodoPago: json['metodo_pago']?.toString() ?? '',
      vendedor: json['vendedor']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      items: itemsParseados,
    );
  }

  DateTime? get fechaDate {
    try {
      return DateTime.parse(fecha);
    } catch (_) {
      return null;
    }
  }

  String get fechaFormateada {
    final f = fechaDate;
    if (f == null) return fecha;

    final dia = f.day.toString().padLeft(2, '0');
    final mes = f.month.toString().padLeft(2, '0');
    final anio = f.year.toString();
    final hora = f.hour.toString().padLeft(2, '0');
    final minuto = f.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
    }
}