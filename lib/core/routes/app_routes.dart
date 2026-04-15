import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_products_screen.dart';
import '../../screens/admin/admin_inventory_screen.dart';
import '../../screens/admin/admin_users_screen.dart';
import '../../screens/admin/admin_sales_screen.dart';
import '../../screens/vendedor/vendedor_dashboard_screen.dart';
import '../../screens/vendedor/pos_screen.dart';
import '../../screens/vendedor/clientes_screen.dart';
import '../../screens/vendedor/vendedor_sales_screen.dart';
import '../../screens/cliente/cliente_home_screen.dart';
import '../../screens/cliente/cliente_catalogo_screen.dart';
import '../../screens/cliente/cliente_compras_screen.dart';
import '../../screens/cliente/perfil_screen.dart';
import '../../screens/cliente/carrito_screen.dart';
import 'route_guard.dart';
 
class AppRoutes {
  static const String login = '/login';
 
  static const String adminDashboard = '/admin';
  static const String adminProducts = '/admin/products';
  static const String adminInventory = '/admin/inventory';
  static const String adminUsers = '/admin/users';
  static const String adminSales = '/admin/sales';
 
  static const String vendedorDashboard = '/vendedor';
  static const String pos = '/vendedor/pos';
  static const String vendedorClientes = '/vendedor/clientes';
  static const String vendedorSales = '/vendedor/sales';
 
  static const String clienteHome = '/cliente';
  static const String clienteCatalogo = '/cliente/catalogo';
  static const String clienteCompras = '/cliente/compras';
  static const String clientePerfil = '/cliente/perfil';
  static const String carrito = '/cliente/carrito';
 
  static Map<String, WidgetBuilder> get routes {
    return {
      login: (_) => const LoginScreen(),
 
      adminDashboard: (_) => const RouteGuard(
            rolesPermitidos: ['admin'],
            child: AdminDashboardScreen(),
          ),
      adminProducts: (_) => const RouteGuard(
            rolesPermitidos: ['admin'],
            child: AdminProductsScreen(),
          ),
      adminInventory: (_) => const RouteGuard(
            rolesPermitidos: ['admin'],
            child: AdminInventoryScreen(),
          ),
      adminUsers: (_) => const RouteGuard(
            rolesPermitidos: ['admin'],
            child: AdminUsersScreen(),
          ),
      adminSales: (_) => const RouteGuard(
            rolesPermitidos: ['admin'],
            child: AdminSalesScreen(),
          ),
 
      vendedorDashboard: (_) => const RouteGuard(
            rolesPermitidos: ['vendedor'],
            child: VendedorDashboardScreen(),
          ),
      pos: (_) => const RouteGuard(
            rolesPermitidos: ['vendedor'],
            child: PosScreen(),
          ),
      vendedorClientes: (_) => const RouteGuard(
            rolesPermitidos: ['vendedor'],
            child: VendedorClientesScreen(),
          ),
      vendedorSales: (_) => const RouteGuard(
            rolesPermitidos: ['vendedor'],
            child: VendedorSalesScreen(),
          ),
 
      clienteHome: (_) => const RouteGuard(
            rolesPermitidos: ['cliente'],
            child: ClienteHomeScreen(),
          ),
      clienteCatalogo: (_) => const RouteGuard(
            rolesPermitidos: ['cliente'],
            child: ClienteCatalogoScreen(),
          ),
      clienteCompras: (_) => const RouteGuard(
            rolesPermitidos: ['cliente'],
            child: ClienteComprasScreen(),
          ),
      clientePerfil: (_) => const RouteGuard(
            rolesPermitidos: ['cliente'],
            child: PerfilScreen(),
          ),
      carrito: (_) => const RouteGuard(
            rolesPermitidos: ['cliente'],
            child: CarritoScreen(),
          ),
    };
  }
}
 