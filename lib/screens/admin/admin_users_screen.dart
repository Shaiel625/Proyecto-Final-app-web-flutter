import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/password_validator.dart';
import '../../services/usuario_service.dart';
import '../../widgets/loading_view.dart';
 
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
 
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}
 
class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<UsuarioCompleto>> _futureUsuarios;
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
 
  @override
  void initState() {
    super.initState();
    _futureUsuarios = UsuarioService.obtenerUsuarios();
  }
 
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
 
  void _recargar() {
    setState(() => _futureUsuarios = UsuarioService.obtenerUsuarios());
  }
 
  List<UsuarioCompleto> _filtrar(List<UsuarioCompleto> lista) {
    if (_search.trim().isEmpty) return lista;
    final texto = _search.toLowerCase();
    return lista.where((u) =>
        u.nombre.toLowerCase().contains(texto) ||
        u.correo.toLowerCase().contains(texto) ||
        u.rol.toLowerCase().contains(texto)).toList();
  }
 
  String _etiquetaRol(String rol) {
    switch (rol.toUpperCase()) {
      case 'ADMIN': return 'Administrador';
      case 'VENDEDOR': return 'Vendedor';
      default: return 'Cliente';
    }
  }
 
  Future<void> _mostrarFormulario({UsuarioCompleto? usuario}) async {
    final esEdicion = usuario != null;
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: usuario?.nombre ?? '');
    final correoCtrl = TextEditingController(text: usuario?.correo ?? '');
    final telefonoCtrl = TextEditingController(text: usuario?.telefono ?? '');
    final passwordCtrl = TextEditingController();
    String rolSeleccionado = usuario?.rol.toUpperCase() == 'ADMIN'
        ? 'ADMIN'
        : usuario?.rol.toUpperCase() == 'VENDEDOR'
            ? 'VENDEDOR'
            : 'CLIENTE';
 
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text(esEdicion ? 'Editar usuario' : 'Nuevo usuario'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: correoCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder()),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Campo requerido';
                          if (!v.contains('@')) return 'Correo inválido';
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: telefonoCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Teléfono (opcional)', border: OutlineInputBorder()),
                      ),
                    ),
                    if (!esEdicion)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: passwordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                          validator: PasswordValidator.validar,
                        ),
                      ),
                    DropdownButtonFormField<String>(
                      value: rolSeleccionado,
                      decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                        DropdownMenuItem(value: 'VENDEDOR', child: Text('Vendedor')),
                        DropdownMenuItem(value: 'CLIENTE', child: Text('Cliente')),
                      ],
                      onChanged: (v) => setDlgState(() => rolSeleccionado = v ?? rolSeleccionado),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                try {
                  if (esEdicion) {
                    await UsuarioService.actualizarUsuario(
                      id: usuario.id,
                      nombre: nombreCtrl.text.trim(),
                      correo: correoCtrl.text.trim(),
                      rol: rolSeleccionado,
                    );
                  } else {
                    await UsuarioService.crearUsuario(
                      nombre: nombreCtrl.text.trim(),
                      correo: correoCtrl.text.trim(),
                      password: passwordCtrl.text,
                      rol: rolSeleccionado,
                      telefono: telefonoCtrl.text.trim(),
                    );
                  }
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(esEdicion ? 'Usuario actualizado' : 'Usuario creado'),
                    backgroundColor: AppTheme.success,
                  ));
                  _recargar();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppTheme.error,
                  ));
                }
              },
              child: Text(esEdicion ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }
 
  Future<void> _toggleEstado(UsuarioCompleto u) async {
    final accion = u.activo ? 'desactivar' : 'activar';
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿${accion[0].toUpperCase()}${accion.substring(1)} usuario?'),
        content: Text('¿Estás seguro de que quieres $accion a ${u.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: u.activo ? AppTheme.error : AppTheme.success),
            onPressed: () => Navigator.pop(context, true),
            child: Text(accion[0].toUpperCase() + accion.substring(1)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await UsuarioService.cambiarEstado(id: u.id, activo: !u.activo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Usuario ${u.activo ? 'desactivado' : 'activado'}'),
        backgroundColor: AppTheme.success,
      ));
      _recargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(onPressed: _recargar, icon: const Icon(Icons.refresh), tooltip: 'Recargar'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Agregar'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar usuario',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<UsuarioCompleto>>(
                future: _futureUsuarios,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingView(mensaje: 'Cargando usuarios...');
                  }
                  if (snapshot.hasError) {
                    return ErrorView(mensaje: '${snapshot.error}', onReintentar: _recargar);
                  }
 
                  final usuarios = _filtrar(snapshot.data ?? []);
                  if (usuarios.isEmpty) {
                    return const EmptyView(mensaje: 'No se encontraron usuarios', icono: Icons.people_outline);
                  }
 
                  return ListView.builder(
                    itemCount: usuarios.length,
                    itemBuilder: (context, index) {
                      final u = usuarios[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                backgroundColor: AppTheme.primary.withOpacity(0.1),
                                child: Text(
                                  u.nombre.isNotEmpty ? u.nombre[0].toUpperCase() : '?',
                                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Datos
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Text(u.correo, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        AppTheme.statusBadge(_etiquetaRol(u.rol), AppTheme.primary),
                                        const SizedBox(width: 8),
                                        AppTheme.statusBadge(
                                          u.activo ? 'Activo' : 'Inactivo',
                                          u.activo ? AppTheme.success : AppTheme.error,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Acciones
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
                                tooltip: 'Editar',
                                onPressed: () => _mostrarFormulario(usuario: u),
                              ),
                              IconButton(
                                icon: Icon(
                                  u.activo ? Icons.person_off_outlined : Icons.person_outlined,
                                  color: u.activo ? AppTheme.error : AppTheme.success,
                                ),
                                tooltip: u.activo ? 'Desactivar' : 'Activar',
                                onPressed: () => _toggleEstado(u),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}