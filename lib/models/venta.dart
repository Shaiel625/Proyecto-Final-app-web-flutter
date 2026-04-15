class Venta {
  final int id;
  final String fecha;
  final double total;
  final String? cliente;
  final String? vendedor;
  final String? metodoPago;

  Venta({
    required this.id,
    required this.fecha,
    required this.total,
    this.cliente,
    this.vendedor,
    this.metodoPago,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: _toInt(json['id']),
      fecha: _toStringValue(json['fecha']) ??
          _toStringValue(json['created_at']) ??
          _toStringValue(json['createdAt']) ??
          '',
      total: _toDouble(json['total']),
      cliente: _obtenerTexto(json, [
        'cliente',
        'cliente_nombre',
        'nombre_cliente',
        'customer',
        'usuario',
        'usuario_nombre',
      ]),
      vendedor: _obtenerTexto(json, [
        'vendedor',
        'vendedor_nombre',
        'nombre_vendedor',
        'seller',
      ]),
      metodoPago: _obtenerTexto(json, [
        'metodoPago',
        'metodo_pago',
        'paymentMethod',
        'payment_method',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha,
      'total': total,
      'cliente': cliente,
      'vendedor': vendedor,
      'metodoPago': metodoPago,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    if (value is num) return value.toDouble();
    return 0;
  }

  static String? _toStringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return null;
  }

  static String? _obtenerTexto(
    Map<String, dynamic> json,
    List<String> posiblesClaves,
  ) {
    for (final clave in posiblesClaves) {
      if (!json.containsKey(clave)) continue;

      final value = json[clave];

      if (value == null) continue;

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }

      if (value is num || value is bool) {
        return value.toString();
      }

      if (value is Map<String, dynamic>) {
        final nombre = _toStringValue(value['nombre']) ??
            _toStringValue(value['name']) ??
            _toStringValue(value['correo']) ??
            _toStringValue(value['email']) ??
            _toStringValue(value['id']);

        if (nombre != null && nombre.trim().isNotEmpty) {
          return nombre.trim();
        }
      }
    }

    return null;
  }
}