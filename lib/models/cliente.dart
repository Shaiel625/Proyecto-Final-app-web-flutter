class Cliente {
  final String id;
  final String nombre;
  final String correo;
  final String telefono;
  final String rol;
  final bool activo;

  Cliente({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.rol,
    required this.activo,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      correo: (json['correo'] ?? '').toString(),
      telefono: (json['telefono'] ?? '').toString(),
      rol: (json['rol'] ?? '').toString(),
      activo: json['activo'] ?? true,
    );
  }
}