import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/compra.dart';
import '../../services/venta_service.dart';
import '../../widgets/loading_view.dart';
 
class ClienteComprasScreen extends StatefulWidget {
  const ClienteComprasScreen({super.key});
 
  @override
  State<ClienteComprasScreen> createState() => _ClienteComprasScreenState();
}
 
class _ClienteComprasScreenState extends State<ClienteComprasScreen> {
  late Future<List<Compra>> _futureCompras;
 
  @override
  void initState() {
    super.initState();
    _futureCompras = VentaService.obtenerMisCompras();
  }
 
  void _recargar() {
    setState(() => _futureCompras = VentaService.obtenerMisCompras());
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis compras'),
        actions: [
          IconButton(onPressed: _recargar, icon: const Icon(Icons.refresh), tooltip: 'Recargar'),
        ],
      ),
      body: FutureBuilder<List<Compra>>(
        future: _futureCompras,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(mensaje: 'Cargando tus compras...');
          }
          if (snapshot.hasError) {
            return ErrorView(
              mensaje: 'Error al cargar compras:\n${snapshot.error}',
              onReintentar: _recargar,
            );
          }
 
          final compras = snapshot.data ?? [];
 
          if (compras.isEmpty) {
            return const EmptyView(
              mensaje: 'Aún no tienes compras registradas',
              icono: Icons.shopping_bag_outlined,
            );
          }
 
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: compras.length,
            itemBuilder: (context, index) {
              final c = compras[index];
              return _CompraCard(compra: c);
            },
          );
        },
      ),
    );
  }
}
 
class _CompraCard extends StatefulWidget {
  final Compra compra;
  const _CompraCard({required this.compra});
 
  @override
  State<_CompraCard> createState() => _CompraCardState();
}
 
class _CompraCardState extends State<_CompraCard> {
  bool _expandido = false;
 
  @override
  Widget build(BuildContext context) {
    final c = widget.compra;
 
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primary),
            ),
            title: Text(
              c.folio.isNotEmpty ? c.folio : 'Compra #${c.id}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Fecha: ${c.fechaFormateada}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                Text('Método: ${c.metodoPago}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${c.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                      fontSize: 16),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(() => _expandido = !_expandido),
                  child: Icon(
                    _expandido ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          ),
 
          // Detalle de productos
          if (_expandido && c.items.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Productos:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  ...c.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('${item.nombre} (${item.codigo})',
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            Text('x${item.cantidad}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 13)),
                            const SizedBox(width: 12),
                            Text('\$${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('\$${c.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}