class Usuario {
  final String id;
  final String nombre;
  final String usuario;
  final String rol;
  final String token;

  Usuario({
    required this.id,
    required this.nombre,
    required this.usuario,
    required this.rol,
    required this.token,
  });

  factory Usuario.fromLoginResponse(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;

    return Usuario(
      id: (user['id'] ?? '').toString(),
      nombre: (user['nombre'] ?? '').toString(),
      usuario: (user['usuario'] ?? '').toString(),
      rol: (user['rol'] ?? '').toString(),
      token: (json['token'] ?? '').toString(),
    );
  }
}