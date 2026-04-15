import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/compra.dart';
import '../../services/venta_service.dart';
import '../../widgets/loading_view.dart';
 
class AdminSalesScreen extends StatefulWidget {
  const AdminSalesScreen({super.key});
 
  @override
  State<AdminSalesScreen> createState() => _AdminSalesScreenState();
}
 
class _AdminSalesScreenState extends State<AdminSalesScreen> {
  late Future<List<Compra>> _futureVentas;
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  String _filtroMetodo = 'Todos';
 
  @override
  void initState() {
    super.initState();
    _futureVentas = VentaService.obtenerVentas();
  }
 
  void _recargar() {
    setState(() => _futureVentas = VentaService.obtenerVentas());
  }
 
  List<Compra> _filtrar(List<Compra> ventas) {
    var lista = ventas;
 
    if (_filtroMetodo != 'Todos') {
      lista = lista.where((v) => v.metodoPago == _filtroMetodo).toList();
    }
 
    if (_search.trim().isNotEmpty) {
      final texto = _search.toLowerCase();
      lista = lista.where((v) =>
          v.folio.toLowerCase().contains(texto) ||
          v.cliente.toLowerCase().contains(texto) ||
          v.vendedor.toLowerCase().contains(texto) ||
          v.metodoPago.toLowerCase().contains(texto)).toList();
    }
 
    return lista;
  }
 
  double _totalGeneral(List<Compra> ventas) =>
      ventas.fold(0, (sum, v) => sum + v.total);
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        actions: [
          IconButton(onPressed: _recargar, icon: const Icon(Icons.refresh), tooltip: 'Recargar'),
        ],
      ),
      body: FutureBuilder<List<Compra>>(
        future: _futureVentas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(mensaje: 'Cargando ventas...');
          }
          if (snapshot.hasError) {
            return ErrorView(mensaje: '${snapshot.error}', onReintentar: _recargar);
          }
 
          final todasVentas = snapshot.data ?? [];
          final ventas = _filtrar(todasVentas);
          final metodosPago = ['Todos', ...{...todasVentas.map((v) => v.metodoPago).where((m) => m.isNotEmpty)}];
 
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Tarjeta resumen total ───────────────────────────────
                Card(
                  color: AppTheme.primary.withOpacity(0.06),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total ventas', style: TextStyle(color: AppTheme.textSecondary)),
                            Text(
                              '${ventas.length}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Monto total', style: TextStyle(color: AppTheme.textSecondary)),
                            Text(
                              '\$${_totalGeneral(ventas).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
 
                // ── Filtros ─────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Buscar por folio, cliente o vendedor',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _filtroMetodo,
                        decoration: const InputDecoration(
                          labelText: 'Método de pago',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: metodosPago
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) => setState(() => _filtroMetodo = v ?? 'Todos'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
 
                // ── Lista de ventas ─────────────────────────────────────
                Expanded(
                  child: ventas.isEmpty
                      ? const EmptyView(mensaje: 'No hay ventas que coincidan', icono: Icons.receipt_long_outlined)
                      : ListView.builder(
                          itemCount: ventas.length,
                          itemBuilder: (context, index) {
                            final v = ventas[index];
                            return _VentaCard(venta: v);
                          },
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
 
class _VentaCard extends StatefulWidget {
  final Compra venta;
  const _VentaCard({required this.venta});
 
  @override
  State<_VentaCard> createState() => _VentaCardState();
}
 
class _VentaCardState extends State<_VentaCard> {
  bool _expandido = false;
 
  @override
  Widget build(BuildContext context) {
    final v = widget.venta;
    final esAppCliente = v.vendedor.toLowerCase().contains('app') ||
        v.vendedor.toLowerCase().contains('cliente');
 
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: (esAppCliente ? AppTheme.info : AppTheme.primary).withOpacity(0.1),
              child: Icon(
                esAppCliente ? Icons.shopping_cart_outlined : Icons.point_of_sale,
                color: esAppCliente ? AppTheme.info : AppTheme.primary,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(v.folio, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                AppTheme.statusBadge(
                  esAppCliente ? 'App cliente' : 'Vendedor',
                  esAppCliente ? AppTheme.info : AppTheme.primary,
                ),
              ],
            ),
            subtitle: Text(
              'Cliente: ${v.cliente}\n'
              'Vendedor: ${v.vendedor}\n'
              'Método: ${v.metodoPago}  |  Fecha: ${v.fechaFormateada}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${v.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 15),
                ),
                IconButton(
                  icon: Icon(_expandido ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _expandido = !_expandido),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            isThreeLine: true,
          ),
 
          // ── Detalle de items ────────────────────────────────────────
          if (_expandido && v.items.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  ),
                  ...v.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text('${item.nombre} (${item.codigo})')),
                        Text('x${item.cantidad}', style: const TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(width: 12),
                        Text('\$${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                  const Divider(height: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('\$${v.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}