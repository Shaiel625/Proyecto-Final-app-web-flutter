import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/carrito_service.dart';
import '../../services/session_service.dart';
 
class VendedorDashboardScreen extends StatelessWidget {
  const VendedorDashboardScreen({super.key});
 
  Future<void> _cerrarSesion(BuildContext context) async {
    await SessionService.cerrarSesion();
    CarritoService.instance.limpiar();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendedor'),
        actions: [
          IconButton(
            onPressed: () => _cerrarSesion(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTheme.sectionTitle('Panel de vendedor'),
            const Text(
              'Accede al POS y administra tus ventas.',
              style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columnas = constraints.maxWidth >= 1000
                      ? 3
                      : constraints.maxWidth >= 650
                          ? 2
                          : 1;
 
                  final items = [
                    _DashboardCard(
                      icon: Icons.point_of_sale,
                      titulo: 'Punto de venta',
                      subtitulo: 'Registrar ventas y cobrar productos.',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.pos),
                    ),
                    _DashboardCard(
                      icon: Icons.people_outline,
                      titulo: 'Clientes',
                      subtitulo: 'Consultar clientes y compras.',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.vendedorClientes),
                    ),
                    _DashboardCard(
                      icon: Icons.receipt_long_outlined,
                      titulo: 'Mis ventas',
                      subtitulo: 'Ver historial de ventas realizadas.',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.vendedorSales),
                    ),
                  ];
 
                  return GridView.builder(
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnas,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 230,
                    ),
                    itemBuilder: (context, index) => items[index],
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
 
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
 
  const _DashboardCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primary.withOpacity(0.08),
                child: Icon(icon, size: 28, color: AppTheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                subtitulo,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              const Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}