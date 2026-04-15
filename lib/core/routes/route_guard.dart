import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../../services/session_service.dart';
 
/// Envuelve una pantalla y verifica, antes de mostrarla, que:
///   1. Hay una sesión activa (token válido).
///   2. El rol del usuario está en [rolesPermitidos] (si se especifica).
///
/// Si no se cumple, redirige a login o muestra una pantalla de acceso denegado.
///
/// Ejemplo de uso en app_routes.dart:
///   adminDashboard: (_) => const RouteGuard(
///     rolesPermitidos: ['admin'],
///     child: AdminDashboardScreen(),
///   ),
class RouteGuard extends StatelessWidget {
  final Widget child;
  final List<String> rolesPermitidos;
 
  const RouteGuard({
    super.key,
    required this.child,
    this.rolesPermitidos = const [],
  });
 
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: SessionService.obtenerSesion(),
      builder: (context, snapshot) {
        // Mientras carga la sesión desde SharedPreferences
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
 
        final sesion = snapshot.data;
 
        // Sin sesión → login
        if (sesion == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
 
        // Verificar rol si se especificaron restricciones
        if (rolesPermitidos.isNotEmpty) {
          final rol = (sesion['rol'] ?? '').toString().toLowerCase();
          final tieneAcceso = rolesPermitidos
              .map((r) => r.toLowerCase())
              .contains(rol);
 
          if (!tieneAcceso) {
            return const _AccesoDenegadoScreen();
          }
        }
 
        return child;
      },
    );
  }
}
 
class _AccesoDenegadoScreen extends StatelessWidget {
  const _AccesoDenegadoScreen();
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso denegado')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 72, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'No tienes permiso para ver esta pantalla.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}