import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/cliente.dart';
import 'session_service.dart';
 
class ClienteService {
  static Future<List<Cliente>> obtenerClientes() async {
    final headers = await SessionService.headersConToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.clientes}?activo=true'),
      headers: headers,
    );
 
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Cliente.fromJson(item)).toList();
    } else {
      throw Exception('Error al obtener clientes: HTTP ${response.statusCode}');
    }
  }
}
 