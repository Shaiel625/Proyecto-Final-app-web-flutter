import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
 
class SessionService {
  static Future<void> guardarSesion(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', usuario.id);
    await prefs.setString('user_nombre', usuario.nombre);
    await prefs.setString('user_usuario', usuario.usuario);
    await prefs.setString('user_rol', usuario.rol);
    await prefs.setString('user_token', usuario.token);
  }
 
  static Future<Map<String, dynamic>?> obtenerSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');
    if (token == null || token.isEmpty) return null;
 
    return {
      'id': prefs.getString('user_id') ?? '',
      'nombre': prefs.getString('user_nombre') ?? '',
      'usuario': prefs.getString('user_usuario') ?? '',
      'rol': prefs.getString('user_rol') ?? '',
      'token': token,
    };
  }
 
  /// Devuelve solo el token, o null si no hay sesión activa.
  /// Útil para construir headers de autorización.
  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');
    return (token == null || token.isEmpty) ? null : token;
  }
 
  /// Headers con Authorization listo para usar en http.get / http.post.
  static Future<Map<String, String>> headersConToken() async {
    final token = await obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
 
  /// Actualiza campos individuales de la sesión sin necesitar el objeto Usuario.
  static Future<void> guardarSesionDesdeMap(Map<String, dynamic> datos) async {
    final prefs = await SharedPreferences.getInstance();
    if (datos['id'] != null) await prefs.setString('user_id', datos['id']);
    if (datos['nombre'] != null) await prefs.setString('user_nombre', datos['nombre']);
    if (datos['usuario'] != null) await prefs.setString('user_usuario', datos['usuario']);
    if (datos['rol'] != null) await prefs.setString('user_rol', datos['rol']);
    if (datos['token'] != null) await prefs.setString('user_token', datos['token']);
  }
 
  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_nombre');
    await prefs.remove('user_usuario');
    await prefs.remove('user_rol');
    await prefs.remove('user_token');
  }
}