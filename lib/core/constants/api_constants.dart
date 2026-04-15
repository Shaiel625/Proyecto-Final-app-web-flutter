class ApiConstants {
  static const String _backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );

  static const String _productosBaseUrl = String.fromEnvironment(
    'PRODUCTOS_URL',
    defaultValue: 'http://127.0.0.1:8010',
  );

  static const String login = '$_backendBaseUrl/auth/login';
  static const String me = '$_backendBaseUrl/auth/me';
  static const String usuarios = '$_backendBaseUrl/usuarios';
  static const String clientes = '$_backendBaseUrl/clientes';
  static const String ventas = '$_backendBaseUrl/ventas';

  static const String productos = '$_productosBaseUrl/productos';
}