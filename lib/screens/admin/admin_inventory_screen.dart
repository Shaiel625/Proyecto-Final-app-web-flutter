import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../services/producto_service.dart';
import '../../widgets/loading_view.dart';
import '../../core/theme/app_theme.dart';
 
class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});
 
  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}
 
class _AdminInventoryScreenState extends State<AdminInventoryScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Producto>> _futureProductos;
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  late TabController _tabController;
 
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _futureProductos = ProductoService.obtenerProductos();
  }
 
  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }
 
  void _recargar() {
    setState(() => _futureProductos = ProductoService.obtenerProductos());
  }
 
  List<Producto> _filtrar(List<Producto> productos, {bool soloStockBajo = false}) {
    var lista = soloStockBajo
        ? productos.where((p) => p.stock <= p.stockMinimo).toList()
        : productos;
 
    if (_search.trim().isNotEmpty) {
      final texto = _search.toLowerCase();
      lista = lista.where((p) =>
          p.nombre.toLowerCase().contains(texto) ||
          p.codigo.toLowerCase().contains(texto) ||
          p.categoria.toLowerCase().contains(texto)).toList();
    }
    return lista;
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(onPressed: _recargar, icon: const Icon(Icons.refresh), tooltip: 'Recargar'),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Todos'),
            Tab(icon: Icon(Icons.warning_amber_rounded), text: 'Stock bajo'),
          ],
        ),
      ),
      body: FutureBuilder<List<Producto>>(
        future: _futureProductos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(mensaje: 'Cargando inventario...');
          }
          if (snapshot.hasError) {
            return ErrorView(mensaje: '${snapshot.error}', onReintentar: _recargar);
          }
 
          final todos = snapshot.data ?? [];
          final stockBajoList = todos.where((p) => p.stock <= p.stockMinimo).toList();
 
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Tarjetas resumen ─────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: _InfoCard(titulo: 'Total productos', valor: todos.length.toString(), color: AppTheme.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: _InfoCard(titulo: 'Stock bajo', valor: stockBajoList.length.toString(), color: AppTheme.error)),
                  ],
                ),
                const SizedBox(height: 12),
 
                // ── Buscador ─────────────────────────────────────────────
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Buscar en inventario',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 12),
 
                // ── Tabs ─────────────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ListaInventario(productos: _filtrar(todos)),
                      _ListaInventario(
                        productos: _filtrar(todos, soloStockBajo: true),
                        mensajeVacio: '¡Sin productos con stock bajo!',
                        iconoVacio: Icons.check_circle_outline,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
 
class _ListaInventario extends StatelessWidget {
  final List<Producto> productos;
  final String mensajeVacio;
  final IconData iconoVacio;
 
  const _ListaInventario({
    required this.productos,
    this.mensajeVacio = 'No se encontraron productos',
    this.iconoVacio = Icons.inventory_2_outlined,
  });
 
  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return EmptyView(mensaje: mensajeVacio, icono: iconoVacio);
    }
 
    return ListView.builder(
      itemCount: productos.length,
      itemBuilder: (context, index) {
        final p = productos[index];
        final stockBajo = p.stock <= p.stockMinimo;
        final sinStock = p.stock == 0;
 
        Color color = AppTheme.success;
        String etiqueta = 'OK';
        if (sinStock) { color = AppTheme.error; etiqueta = 'Sin stock'; }
        else if (stockBajo) { color = AppTheme.warning; etiqueta = 'Stock bajo'; }
 
        return Card(
          color: sinStock
              ? AppTheme.error.withOpacity(0.05)
              : stockBajo
                  ? AppTheme.warning.withOpacity(0.05)
                  : null,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(
                sinStock ? Icons.remove_circle_outline
                    : stockBajo ? Icons.warning_amber_rounded
                    : Icons.inventory_2_outlined,
                color: color,
              ),
            ),
            title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Código: ${p.codigo}\n'
              'Stock: ${p.stock}  |  Mínimo: ${p.stockMinimo}\n'
              'Unidad: ${p.unidadMedida}  |  Categoría: ${p.categoria}',
            ),
            trailing: AppTheme.statusBadge(etiqueta, color),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
 
class _InfoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
 
  const _InfoCard({required this.titulo, required this.valor, required this.color});
 
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(titulo, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Text(valor, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}