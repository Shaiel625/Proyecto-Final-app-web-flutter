import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/producto.dart';
import 'session_service.dart';
 
class ProductoService {
  static Future<List<Producto>> obtenerProductos() async {
    final headers = await SessionService.headersConToken();
    final response = await http.get(
      Uri.parse(ApiConstants.productos),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Producto.fromJson(item)).toList();
    }
    throw Exception('Error al obtener productos: HTTP ${response.statusCode}');
  }
 
  static Future<void> crearProducto({
    required String codigo,
    required String nombre,
    required String descripcion,
    required double precioVenta,
    required double costo,
    required int stock,
    required int stockMinimo,
    required int idCategoria,
    required int idMarca,
    required String unidadMedida,
  }) async {
    final headers = await SessionService.headersConToken();
    final response = await http.post(
      Uri.parse(ApiConstants.productos),
      headers: headers,
      body: jsonEncode({
        'codigo': codigo,
        'nombre': nombre,
        'descripcion': descripcion,
        'precio_venta': precioVenta,
        'costo': costo,
        'stock': stock,
        'stock_minimo': stockMinimo,
        'id_categoria': idCategoria,
        'id_marca': idMarca,
        'unidad_medida': unidadMedida,
        'activo': true,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al crear producto');
    }
  }
 
  static Future<void> agregarStock({
    required int idProducto,
    required int cantidad,
  }) async {
    final headers = await SessionService.headersConToken();
    // Obtenemos el producto actual para calcular el nuevo stock
    final resProducto = await http.get(
      Uri.parse('${ApiConstants.productos}/$idProducto'),
      headers: headers,
    );
    if (resProducto.statusCode != 200) {
      throw Exception('Producto no encontrado');
    }
    final productoActual = Producto.fromJson(jsonDecode(resProducto.body));
    final nuevoStock = productoActual.stock + cantidad;
 
    final response = await http.put(
      Uri.parse('${ApiConstants.productos}/$idProducto'),
      headers: headers,
      body: jsonEncode({'stock': nuevoStock}),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al agregar stock');
    }
  }
 
  static Future<void> descontarStock({
    required int idProducto,
    required int cantidad,
  }) async {
    final headers = await SessionService.headersConToken();
    final response = await http.put(
      Uri.parse('${ApiConstants.productos}/descontar/$idProducto'),
      headers: headers,
      body: jsonEncode({'cantidad': cantidad}),
    );
    if (response.statusCode != 200) {
      String mensaje = 'Error al descontar stock';
      try {
        final data = jsonDecode(response.body);
        if (data['detail'] != null) mensaje = data['detail'];
      } catch (_) {}
      throw Exception(mensaje);
    }
  }
}