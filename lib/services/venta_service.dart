import 'dart:convert';
import 'package:http/http.dart' as http;
 
import '../core/constants/api_constants.dart';
import '../models/compra.dart';
import 'session_service.dart';
 
class VentaItemPayload {
  final int idProducto;
  final int cantidad;
 
  VentaItemPayload({required this.idProducto, required this.cantidad});
 
  Map<String, dynamic> toJson() => {
        'id_producto': idProducto,
        'cantidad': cantidad,
      };
}
 
class VentaService {
  /// Obtiene TODAS las ventas — uso exclusivo del admin y vendedor.
  static Future<List<Compra>> obtenerVentas() async {
    final headers = await SessionService.headersConToken();
    final response = await http.get(
      Uri.parse(ApiConstants.ventas),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Compra.fromJson(e)).toList();
    }
    throw Exception('Error al obtener ventas: ${response.body}');
  }
 
  /// Obtiene solo las ventas del cliente en sesión filtrando por su nombre.
  static Future<List<Compra>> obtenerMisCompras() async {
    final sesion = await SessionService.obtenerSesion();
    final nombreCliente = sesion?['nombre'] ?? '';
    final headers = await SessionService.headersConToken();
 
    final uri = Uri.parse(ApiConstants.ventas)
        .replace(queryParameters: {'cliente': nombreCliente});
 
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Compra.fromJson(e)).toList();
    }
    throw Exception('Error al obtener compras: ${response.body}');
  }
 
  static Future<void> registrarVenta({
    required String vendedor,
    required String cliente,
    required String metodoPago,
    required List<VentaItemPayload> items,
  }) async {
    final headers = await SessionService.headersConToken();
    final response = await http.post(
      Uri.parse(ApiConstants.ventas),
      headers: headers,
      body: jsonEncode({
        'vendedor': vendedor,
        'cliente': cliente,
        'metodo_pago': metodoPago,
        'items': items.map((e) => e.toJson()).toList(),
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al registrar venta: ${response.body}');
    }
  }
}
 