import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/usuario.dart';
import 'session_service.dart';
 
class UsuarioCompleto {
  final String id;
  final String nombre;
  final String correo;
  final String telefono;
  final String rol;
  final bool activo;
 
  UsuarioCompleto({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.rol,
    required this.activo,
  });
 
  factory UsuarioCompleto.fromJson(Map<String, dynamic> json) {
    return UsuarioCompleto(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      correo: (json['correo'] ?? '').toString(),
      telefono: (json['telefono'] ?? '').toString(),
      rol: (json['rol'] ?? '').toString(),
      activo: json['activo'] ?? true,
    );
  }
}
 
class UsuarioService {
  static Future<List<UsuarioCompleto>> obtenerUsuarios() async {
    final headers = await SessionService.headersConToken();
    final response = await http.get(
      Uri.parse(ApiConstants.usuarios),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => UsuarioCompleto.fromJson(e)).toList();
    }
    throw Exception('Error al obtener usuarios: ${response.statusCode}');
  }
 
  static Future<void> crearUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String rol,
    String telefono = '',
  }) async {
    final headers = await SessionService.headersConToken();
    final response = await http.post(
      Uri.parse(ApiConstants.usuarios),
      headers: headers,
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'password': password,
        'rol': rol,
        'telefono': telefono,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['msg'] ?? 'Error al crear usuario');
    }
  }
 
  static Future<void> actualizarUsuario({
    required String id,
    required String nombre,
    required String correo,
    required String rol,
  }) async {
    final headers = await SessionService.headersConToken();
    final response = await http.put(
      Uri.parse('${ApiConstants.usuarios}/$id'),
      headers: headers,
      body: jsonEncode({'nombre': nombre, 'correo': correo, 'rol': rol}),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['msg'] ?? 'Error al actualizar usuario');
    }
  }
 
  static Future<void> cambiarEstado({
    required String id,
    required bool activo,
  }) async {
    final headers = await SessionService.headersConToken();
    final response = await http.patch(
      Uri.parse('${ApiConstants.usuarios}/$id/estado'),
      headers: headers,
      body: jsonEncode({'activo': activo}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al cambiar estado del usuario');
    }
  }
 
  static Future<void> eliminarUsuario(String id) async {
    final headers = await SessionService.headersConToken();
    final response = await http.delete(
      Uri.parse('${ApiConstants.usuarios}/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar usuario');
    }
  }
}