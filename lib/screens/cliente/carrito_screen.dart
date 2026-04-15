import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/carrito_service.dart';
import '../../services/session_service.dart';
import '../../services/venta_service.dart';
 
class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});
 
  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}
 
class _CarritoScreenState extends State<CarritoScreen> {
  // El cliente solo puede pagar con Tarjeta
  final String _metodoPago = 'Tarjeta';
  bool _procesando = false;
 
  Future<void> _comprarTodo() async {
    final carrito = CarritoService.instance;
    if (carrito.items.isEmpty) return;
 
    setState(() => _procesando = true);
 
    try {
      final sesion = await SessionService.obtenerSesion();
      final nombreCliente = sesion?['nombre'] ?? 'Cliente mostrador';
 
      await VentaService.registrarVenta(
        vendedor: 'App Cliente',
        cliente: nombreCliente,
        metodoPago: _metodoPago,
        items: carrito.items
            .map((item) => VentaItemPayload(
                  idProducto: item.producto.id,
                  cantidad: item.cantidad,
                ))
            .toList(),
      );
 
      carrito.limpiar();
 
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Compra realizada correctamente!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al comprar: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }
 
  void _confirmarLimpiar() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Estás seguro de que quieres eliminar todos los productos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              CarritoService.instance.limpiar();
              Navigator.pop(context);
            },
            child: const Text('Vaciar', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CarritoService.instance,
      builder: (context, _) {
        final carrito = CarritoService.instance;
        final items = carrito.items;
 
        return Scaffold(
          appBar: AppBar(
            title: Text('Carrito (${carrito.totalProductos})'),
            actions: [
              if (items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  tooltip: 'Vaciar carrito',
                  onPressed: _confirmarLimpiar,
                ),
            ],
          ),
          body: items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.black26),
                      SizedBox(height: 12),
                      Text('Tu carrito está vacío',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final p = item.producto;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.nombre,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Text('Precio: \$${p.precioVenta.toStringAsFixed(2)}'),
                                        Text('Subtotal: \$${item.subtotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.success)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () =>
                                            CarritoService.instance.disminuirCantidad(p),
                                      ),
                                      Text('${item.cantidad}',
                                          style: const TextStyle(
                                              fontSize: 16, fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: item.cantidad < p.stock
                                            ? () =>
                                                CarritoService.instance.aumentarCantidad(p)
                                            : null,
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () =>
                                        CarritoService.instance.eliminarProducto(p),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
 
                    // Panel inferior fijo
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.credit_card, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              const Text('Método de pago:',
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Tarjeta',
                                    style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:', style: TextStyle(fontSize: 18)),
                              Text(
                                '\$${carrito.totalCarrito.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _procesando ? null : _comprarTodo,
                              child: _procesando
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5, color: Colors.white),
                                    )
                                  : const Text('Confirmar compra',
                                      style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}