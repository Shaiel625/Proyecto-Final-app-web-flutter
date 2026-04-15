import 'package:flutter/material.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../services/carrito_service.dart';
import '../services/session_service.dart';
 
/// Drawer de navegación lateral con menú según el rol del usuario.
///
/// Uso en cualquier Scaffold:
///   drawer: const AppDrawer()
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});
 
  Future<void> _cerrarSesion(BuildContext context) async {
    await SessionService.cerrarSesion();
    CarritoService.instance.limpiar();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
 
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: SessionService.obtenerSesion(),
      builder: (context, snapshot) {
        final sesion = snapshot.data;
        final nombre = sesion?['nombre'] ?? 'Usuario';
        final correo = sesion?['usuario'] ?? '';
        final rol = (sesion?['rol'] ?? '').toString().toLowerCase();
 
        return Drawer(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: AppTheme.primary),
                accountName: Text(
                  nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                accountEmail: Text(correo),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                otherAccountsPictures: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rol.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
 
              // ── Menú según rol ────────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (rol == 'admin') ..._menuAdmin(context),
                    if (rol == 'vendedor') ..._menuVendedor(context),
                    if (rol == 'cliente') ..._menuCliente(context),
                  ],
                ),
              ),
 
              // ── Cerrar sesión ─────────────────────────────────────────────
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.error),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: AppTheme.error),
                ),
                onTap: () => _cerrarSesion(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
 
  List<Widget> _menuAdmin(BuildContext context) => [
        _DrawerItem(
          icono: Icons.dashboard_outlined,
          titulo: 'Dashboard',
          ruta: AppRoutes.adminDashboard,
        ),
        _DrawerItem(
          icono: Icons.inventory_2_outlined,
          titulo: 'Productos',
          ruta: AppRoutes.adminProducts,
        ),
        _DrawerItem(
          icono: Icons.warehouse_outlined,
          titulo: 'Inventario',
          ruta: AppRoutes.adminInventory,
        ),
        _DrawerItem(
          icono: Icons.people_outline,
          titulo: 'Usuarios',
          ruta: AppRoutes.adminUsers,
        ),
        _DrawerItem(
          icono: Icons.receipt_long_outlined,
          titulo: 'Ventas',
          ruta: AppRoutes.adminSales,
        ),
      ];
 
  List<Widget> _menuVendedor(BuildContext context) => [
        _DrawerItem(
          icono: Icons.dashboard_outlined,
          titulo: 'Dashboard',
          ruta: AppRoutes.vendedorDashboard,
        ),
        _DrawerItem(
          icono: Icons.point_of_sale,
          titulo: 'Punto de venta',
          ruta: AppRoutes.pos,
        ),
        _DrawerItem(
          icono: Icons.people_outline,
          titulo: 'Clientes',
          ruta: AppRoutes.vendedorClientes,
        ),
        _DrawerItem(
          icono: Icons.receipt_long_outlined,
          titulo: 'Mis ventas',
          ruta: AppRoutes.vendedorSales,
        ),
      ];
 
  List<Widget> _menuCliente(BuildContext context) => [
        _DrawerItem(
          icono: Icons.home_outlined,
          titulo: 'Inicio',
          ruta: AppRoutes.clienteHome,
        ),
        _DrawerItem(
          icono: Icons.storefront_outlined,
          titulo: 'Catálogo',
          ruta: AppRoutes.clienteCatalogo,
        ),
        _DrawerItem(
          icono: Icons.shopping_bag_outlined,
          titulo: 'Mis compras',
          ruta: AppRoutes.clienteCompras,
        ),
        _DrawerItem(
          icono: Icons.person_outline,
          titulo: 'Perfil',
          ruta: AppRoutes.clientePerfil,
        ),
        ListenableBuilder(
          listenable: CarritoService.instance,
          builder: (context, _) {
            final total = CarritoService.instance.totalProductos;
            return _DrawerItem(
              icono: Icons.shopping_cart_outlined,
              titulo: 'Carrito${total > 0 ? ' ($total)' : ''}',
              ruta: AppRoutes.carrito,
            );
          },
        ),
      ];
}
 
class _DrawerItem extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String ruta;
 
  const _DrawerItem({
    required this.icono,
    required this.titulo,
    required this.ruta,
  });
 
  @override
  Widget build(BuildContext context) {
    final rutaActual = ModalRoute.of(context)?.settings.name ?? '';
    final activo = rutaActual == ruta;
 
    return ListTile(
      leading: Icon(
        icono,
        color: activo ? AppTheme.primary : AppTheme.textSecondary,
      ),
      title: Text(
        titulo,
        style: TextStyle(
          color: activo ? AppTheme.primary : AppTheme.textPrimary,
          fontWeight: activo ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: activo ? AppTheme.primary.withOpacity(0.07) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () {
        Navigator.pop(context); // cierra el drawer
        if (!activo) Navigator.pushReplacementNamed(context, ruta);
      },
    );
  }
}