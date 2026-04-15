import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/session_service.dart';
 
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
 
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}
 
class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _sesion;
  Map<String, dynamic>? _datosCompletos;
  bool _cargando = true;
 
  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }
 
  Future<void> _cargarPerfil() async {
    final sesion = await SessionService.obtenerSesion();
    if (sesion == null) {
      if (mounted) setState(() => _cargando = false);
      return;
    }
 
    // Obtener datos completos del cliente desde el backend
    try {
      final headers = await SessionService.headersConToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.clientes}/${sesion['id']}'),
        headers: headers,
      );
 
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _sesion = sesion;
            _datosCompletos = data;
            _cargando = false;
          });
        }
      } else {
        // Si falla, usar solo datos de sesión
        if (mounted) {
          setState(() {
            _sesion = sesion;
            _cargando = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sesion = sesion;
          _cargando = false;
        });
      }
    }
  }
 
  Future<void> _editarPerfil() async {
    if (_sesion == null) return;
 
    final nombreCtrl = TextEditingController(
        text: _datosCompletos?['nombre'] ?? _sesion!['nombre'] ?? '');
    final telefonoCtrl =
        TextEditingController(text: _datosCompletos?['telefono'] ?? '');
    final direccionCtrl =
        TextEditingController(text: _datosCompletos?['direccion'] ?? '');
    final formKey = GlobalKey<FormState>();
 
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar perfil'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _campo(nombreCtrl, 'Nombre completo', Icons.person_outline,
                      requerido: true),
                  const SizedBox(height: 12),
                  _campo(telefonoCtrl, 'Teléfono', Icons.phone_outlined,
                      tipo: TextInputType.phone),
                  const SizedBox(height: 12),
                  _campo(
                      direccionCtrl, 'Dirección', Icons.location_on_outlined),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              await _guardarCambios(
                nombre: nombreCtrl.text.trim(),
                telefono: telefonoCtrl.text.trim(),
                direccion: direccionCtrl.text.trim(),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
 
  Future<void> _guardarCambios({
    required String nombre,
    required String telefono,
    required String direccion,
  }) async {
    try {
      final headers = await SessionService.headersConToken();
      final id = _sesion!['id'];
 
      final response = await http.put(
        Uri.parse('${ApiConstants.clientes}/$id'),
        headers: headers,
        body: jsonEncode({
          'nombre': nombre,
          'telefono': telefono,
          'direccion': direccion,
        }),
      );
 
      if (response.statusCode == 200) {
        // Actualizar sesión local con el nuevo nombre
        final nuevaSesion = Map<String, dynamic>.from(_sesion!);
        nuevaSesion['nombre'] = nombre;
        await SessionService.guardarSesionDesdeMap(nuevaSesion);
 
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Perfil actualizado'),
              backgroundColor: AppTheme.success),
        );
        _cargarPerfil();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error al actualizar perfil'),
              backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    }
  }
 
  Widget _campo(
    TextEditingController ctrl,
    String label,
    IconData icono, {
    TextInputType tipo = TextInputType.text,
    bool requerido = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: tipo,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono),
        border: const OutlineInputBorder(),
      ),
      validator: requerido
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
          : null,
    );
  }
 
  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
 
    final nombre =
        _datosCompletos?['nombre'] ?? _sesion?['nombre'] ?? 'Usuario';
    final correo = _sesion?['usuario'] ?? '';
    final usuario = _sesion?['usuario'] ?? '';
    final telefono = _datosCompletos?['telefono'] ?? '';
    final direccion = _datosCompletos?['direccion'] ?? '';
    final rol = (_sesion?['rol'] ?? '').toString().toLowerCase();
 
    String etiquetaRol;
    switch (rol) {
      case 'admin':
        etiquetaRol = 'Administrador';
        break;
      case 'vendedor':
        etiquetaRol = 'Vendedor';
        break;
      default:
        etiquetaRol = 'Cliente registrado';
    }
 
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    // ── Avatar ────────────────────────────────────────
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(
                        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
 
                    // ── Nombre y badge ────────────────────────────────
                    Text(
                      nombre,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    AppTheme.statusBadge(etiquetaRol, AppTheme.primary),
                    const SizedBox(height: 24),
 
                    // ── Datos del perfil ──────────────────────────────
                    _DatoItem(
                      icono: Icons.person_outline,
                      titulo: 'Usuario',
                      valor: usuario.isNotEmpty ? usuario : '—',
                    ),
                    _DatoItem(
                      icono: Icons.email_outlined,
                      titulo: 'Correo',
                      valor: correo.isNotEmpty ? correo : '—',
                    ),
                    _DatoItem(
                      icono: Icons.phone_outlined,
                      titulo: 'Teléfono',
                      valor: telefono.isNotEmpty ? telefono : 'No registrado',
                    ),
                    _DatoItem(
                      icono: Icons.location_on_outlined,
                      titulo: 'Dirección',
                      valor: direccion.isNotEmpty ? direccion : 'No registrada',
                    ),
 
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
 
                    // ── Botón editar ──────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _editarPerfil,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar perfil'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
 
class _DatoItem extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
 
  const _DatoItem({
    required this.icono,
    required this.titulo,
    required this.valor,
  });
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary.withOpacity(0.08),
            child: Icon(icono, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600)),
                Text(valor,
                    style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}