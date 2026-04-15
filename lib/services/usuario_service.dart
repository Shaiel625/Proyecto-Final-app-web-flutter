import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'session_service.dart';
 
class UsuarioCompleto {
  final String id;
  final String nombre;
  final String correo;
  final String telefono;
  final String rol;
  final bool activo;
  final bool esCliente; // true = viene de /clientes, false = viene de /usuarios
 
  UsuarioCompleto({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.rol,
    required this.activo,
    this.esCliente = false,
  });
 
  factory UsuarioCompleto.fromJson(Map<String, dynamic> json,
      {bool esCliente = false}) {
    return UsuarioCompleto(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      correo: (json['correo'] ?? '').toString(),
      telefono: (json['telefono'] ?? '').toString(),
      rol: (json['rol'] ?? (esCliente ? 'cliente' : '')).toString(),
      activo: json['activo'] ?? true,
      esCliente: esCliente,
    );
  }
}
 
class UsuarioService {
  /// Obtiene usuarios (admins/vendedores) + clientes combinados.
  static Future<List<UsuarioCompleto>> obtenerUsuarios() async {
    final headers = await SessionService.headersConToken();
 
    // Peticiones en paralelo
    final results = await Future.wait([
      http.get(Uri.parse(ApiConstants.usuarios), headers: headers),
      http.get(Uri.parse(ApiConstants.clientes), headers: headers),
    ]);
 
    final respUsuarios = results[0];
    final respClientes = results[1];
 
    final List<UsuarioCompleto> todos = [];
 
    if (respUsuarios.statusCode == 200) {
      final List data = jsonDecode(respUsuarios.body);
      todos.addAll(data.map((e) => UsuarioCompleto.fromJson(e)));
    }
 
    if (respClientes.statusCode == 200) {
      final List data = jsonDecode(respClientes.body);
      todos.addAll(
          data.map((e) => UsuarioCompleto.fromJson(e, esCliente: true)));
    }
 
    return todos;
  }
 
  static Future<void> crearUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String rol,
    String telefono = '',
  }) async {
    final headers = await SessionService.headersConToken();
    // Si el rol es CLIENTE, crear en /clientes, si no en /usuarios
    final url = rol.toUpperCase() == 'CLIENTE'
        ? ApiConstants.clientes
        : ApiConstants.usuarios;
 
    final response = await http.post(
      Uri.parse(url),
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
      throw Exception(data['detail'] ?? data['msg'] ?? 'Error al crear usuario');
    }
  }
 
  static Future<void> actualizarUsuario({
    required String id,
    required String nombre,
    required String correo,
    required String rol,
    bool esCliente = false,
  }) async {
    final headers = await SessionService.headersConToken();
    final url = esCliente
        ? '${ApiConstants.clientes}/$id'
        : '${ApiConstants.usuarios}/$id';
 
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({'nombre': nombre, 'correo': correo, 'rol': rol}),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? data['msg'] ?? 'Error al actualizar');
    }
  }
 
  static Future<void> cambiarEstado({
    required String id,
    required bool activo,
    bool esCliente = false,
  }) async {
    final headers = await SessionService.headersConToken();
 
    if (esCliente) {
      // Clientes usan PUT con campo activo
      final response = await http.put(
        Uri.parse('${ApiConstants.clientes}/$id'),
        headers: headers,
        body: jsonEncode({'activo': activo}),
      );
      if (response.statusCode != 200) {
        throw Exception('Error al cambiar estado del cliente');
      }
    } else {
      final response = await http.patch(
        Uri.parse('${ApiConstants.usuarios}/$id/estado'),
        headers: headers,
        body: jsonEncode({'activo': activo}),
      );
      if (response.statusCode != 200) {
        throw Exception('Error al cambiar estado del usuario');
      }
    }
  }
 
  static Future<void> eliminarUsuario(String id,
      {bool esCliente = false}) async {
    final headers = await SessionService.headersConToken();
    final url = esCliente
        ? '${ApiConstants.clientes}/$id'
        : '${ApiConstants.usuarios}/$id';
 
    final response = await http.delete(Uri.parse(url), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar usuario');
    }
  }
}