import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../models/usuario.dart';

class AuthService {
  static Future<Usuario> iniciarSesion({
    required String usuario,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'usuario': usuario,
        'correo': usuario,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Usuario.fromLoginResponse(data);
    } else {
      String mensaje = 'No se pudo iniciar sesión';

      try {
        final data = jsonDecode(response.body);
        if (data['detail'] != null) {
          mensaje = data['detail'].toString();
        } else if (data['msg'] != null) {
          mensaje = data['msg'].toString();
        }
      } catch (_) {}

      throw Exception(mensaje);
    }
  }

  static Future<void> registrarUsuario({
    required String nombre,
    required String correo,
    required String password,
    String telefono = '',
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.clientes),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'password': password,
        'telefono': telefono,
        'direccion': '',
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String mensaje = 'No se pudo registrar la cuenta';

      try {
        final data = jsonDecode(response.body);
        if (data['detail'] != null) {
          mensaje = data['detail'].toString();
        } else if (data['msg'] != null) {
          mensaje = data['msg'].toString();
        }
      } catch (_) {}

      throw Exception(mensaje);
    }
  }
}