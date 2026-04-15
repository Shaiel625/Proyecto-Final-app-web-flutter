import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/producto.dart';
import '../../services/carrito_service.dart';
import '../../services/producto_service.dart';
import '../../services/session_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/product_card.dart';
 
class ClienteCatalogoScreen extends StatefulWidget {
  const ClienteCatalogoScreen({super.key});
 
  @override
  State<ClienteCatalogoScreen> createState() => _ClienteCatalogoScreenState();
}
 
class _ClienteCatalogoScreenState extends State<ClienteCatalogoScreen> {
  late Future<List<Producto>> _futureProductos;
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
 
  @override
  void initState() {
    super.initState();
    _futureProductos = ProductoService.obtenerProductos();
  }
 
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
 
  void _recargarProductos() {
    setState(() => _futureProductos = ProductoService.obtenerProductos());
  }
 
  Future<void> _cerrarSesion() async {
    await SessionService.cerrarSesion();
    CarritoService.instance.limpiar();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
 
  List<Producto> _filtrar(List<Producto> productos) {
    if (_search.trim().isEmpty) return productos;
    final texto = _search.toLowerCase();
    return productos.where((p) {
      return p.nombre.toLowerCase().contains(texto) ||
          p.codigo.toLowerCase().contains(texto) ||
          p.categoria.toLowerCase().contains(texto) ||
          p.marca.toLowerCase().contains(texto);
    }).toList();
  }
 
  Future<void> _seleccionarCantidad(Producto p) async {
    int cantidad = 1;
 
    final cantidadSeleccionada = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Agregar ${p.nombre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock disponible: ${p.stock}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: cantidad > 1
                        ? () => setStateDialog(() => cantidad--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Container(
                    width: 60,
                    alignment: Alignment.center,
                    child: Text(
                      '$cantidad',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: cantidad < p.stock
                        ? () => setStateDialog(() => cantidad++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, cantidad),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
 
    if (cantidadSeleccionada != null) {
      // ✅ Llamada correcta al nuevo CarritoService.instance
      CarritoService.instance.agregarProducto(p, cantidad: cantidadSeleccionada);
 
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${p.nombre} x$cantidadSeleccionada agregado al carrito'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: _cerrarSesion,
        ),
        actions: [
          // Badge reactivo del carrito
          ListenableBuilder(
            listenable: CarritoService.instance,
            builder: (context, _) {
              final total = CarritoService.instance.totalProductos;
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    tooltip: 'Ver carrito',
                    onPressed: () async {
                      final actualizado = await Navigator.pushNamed(
                          context, AppRoutes.carrito);
                      if (actualizado == true) _recargarProductos();
                    },
                  ),
                  if (total > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            tooltip: 'Mis compras',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.clienteCompras),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.clientePerfil),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar producto',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Producto>>(
                future: _futureProductos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingView(mensaje: 'Cargando catálogo...');
                  }
 
                  if (snapshot.hasError) {
                    return ErrorView(
                      mensaje: 'Error al cargar catálogo:\n${snapshot.error}',
                      onReintentar: _recargarProductos,
                    );
                  }
 
                  final productos = _filtrar(snapshot.data ?? []);
 
                  if (productos.isEmpty) {
                    return const EmptyView(
                      mensaje: 'No se encontraron productos',
                      icono: Icons.storefront_outlined,
                    );
                  }
 
                  return GridView.builder(
                    itemCount: productos.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 360,
                    ),
                    // ✅ Usa el widget reutilizable ProductCard
                    itemBuilder: (context, index) => ProductCard(
                      producto: productos[index],
                      onAgregar: () => _seleccionarCantidad(productos[index]),
                    ),
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