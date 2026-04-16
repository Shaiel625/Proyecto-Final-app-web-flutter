import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../services/carrito_service.dart';
import '../../services/session_service.dart';
import '../../services/venta_service.dart';
import '../../models/compra.dart';
class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final String _metodoPago = 'Tarjeta';
  bool _procesando = false;

  Future<void> _comprarTodo() async {
    final carrito = CarritoService.instance;
    if (carrito.items.isEmpty) return;

    setState(() => _procesando = true);

    try {
      final sesion = await SessionService.obtenerSesion();
      final nombreCliente = sesion?['nombre'] ?? 'Cliente mostrador';

      final venta = await VentaService.registrarVenta(
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

      // Guardar items antes de limpiar para el voucher
      final itemsVoucher = List.from(carrito.items);
      carrito.limpiar();

      if (!mounted) return;
      await _mostrarVoucher(venta, itemsVoucher);

      if (!mounted) return;
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

  Future<void> _mostrarVoucher(Compra venta, List itemsVoucher) async {
    final fechaStr = venta.fechaFormateada;

    // Calcular subtotal desde items del carrito
    double subtotalVoucher = venta.total > 0 ? venta.total / 1.16 : 0;
    if (subtotalVoucher == 0) {
      for (final item in itemsVoucher) {
        subtotalVoucher += item.producto.precioVenta * item.cantidad;
      }
    }
    final ivaVoucher = subtotalVoucher * 0.16;
    final totalVoucher = subtotalVoucher + ivaVoucher;

    // Texto del voucher para copiar/descargar
    final textoVoucher = StringBuffer();
    textoVoucher.writeln('============================');
    textoVoucher.writeln('       FerreSmart');
    textoVoucher.writeln('  Sistema de Punto de Venta');
    textoVoucher.writeln('============================');
    textoVoucher.writeln('Folio: ${venta.folio.isNotEmpty ? venta.folio : venta.id}');
    textoVoucher.writeln('Fecha: $fechaStr');
    textoVoucher.writeln('Cliente: ${venta.cliente}');
    textoVoucher.writeln('Método de pago: ${venta.metodoPago}');
    textoVoucher.writeln('----------------------------');
    for (final item in itemsVoucher) {
      final subtotal = item.producto.precioVenta * item.cantidad;
      textoVoucher.writeln(
          '${item.producto.nombre} x${item.cantidad}  \$${subtotal.toStringAsFixed(2)}');
    }
    textoVoucher.writeln('----------------------------');
    textoVoucher.writeln('Subtotal:    \$${subtotalVoucher.toStringAsFixed(2)}');
    textoVoucher.writeln('IVA (16%):   \$${ivaVoucher.toStringAsFixed(2)}');
    textoVoucher.writeln('----------------------------');
    textoVoucher.writeln('TOTAL:       \$${totalVoucher.toStringAsFixed(2)}');
    textoVoucher.writeln('============================');
    textoVoucher.writeln('¡Gracias por su compra!');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.success, size: 28),
            const SizedBox(width: 8),
            const Text('¡Compra exitosa!'),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado voucher
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Text('POS FERRETERÍA',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.primary)),
                      const SizedBox(height: 4),
                      Text('VOUCHER DE COMPRA',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              letterSpacing: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Folio y fecha
                _filaVoucher('Folio',
                    venta.folio.isNotEmpty ? venta.folio : venta.id),
                _filaVoucher('Fecha', fechaStr),
                _filaVoucher('Cliente', venta.cliente),
                _filaVoucher('Método de pago', venta.metodoPago),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),

                // Items
                const Text('Productos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ...itemsVoucher.map((item) {
                  final subtotal = item.producto.precioVenta * item.cantidad;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.producto.nombre} x${item.cantidad}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '\$${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }),

                const Divider(),
                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    Text('\$${subtotalVoucher.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                // IVA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('IVA (16%)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    Text('\$${ivaVoucher.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '\$${totalVoucher.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primary),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Center(
                  child: Text('¡Gracias por su compra!',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copiar'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: textoVoucher.toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Voucher copiado al portapapeles'),
                    backgroundColor: AppTheme.success),
              );
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.download_outlined),
            label: const Text('Descargar'),
            onPressed: () {
              final folio = venta.folio.isNotEmpty ? venta.folio : venta.id;
              Clipboard.setData(ClipboardData(text: textoVoucher.toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Voucher $folio copiado — pégalo en un bloc de notas para guardar'),
                  backgroundColor: AppTheme.primary,
                  duration: const Duration(seconds: 4),
                ),
              );
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Cerrar'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _filaVoucher(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(valor,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _confirmarLimpiar() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Vaciar carrito?'),
        content: const Text('Se eliminarán todos los productos del carrito.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              CarritoService.instance.limpiar();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Vaciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carrito = CarritoService.instance;

    return ListenableBuilder(
      listenable: carrito,
      builder: (context, _) {
        final items = carrito.items;
        final total = items.fold<double>(
          0,
          (sum, item) => sum + item.producto.precioVenta * item.cantidad,
        );

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Mi carrito'),
                if (items.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ]
              ],
            ),
            actions: [
              if (items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Vaciar carrito',
                  onPressed: _confirmarLimpiar,
                ),
            ],
          ),
          body: items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 72, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Tu carrito está vacío',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final subtotal =
                              item.producto.precioVenta * item.cantidad;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.producto.nombre,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                            '\$${item.producto.precioVenta.toStringAsFixed(2)} c/u',
                                            style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  // Controles cantidad con campo editable
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        color: AppTheme.primary,
                                        onPressed: () =>
                                            carrito.disminuirCantidad(item.producto),
                                      ),
                                      SizedBox(
                                        width: 52,
                                        child: TextField(
                                          controller: TextEditingController(
                                              text: '${item.cantidad}')
                                            ..selection = TextSelection.collapsed(
                                                offset: '${item.cantidad}'.length),
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(
                                                vertical: 6),
                                            isDense: true,
                                          ),
                                          onChanged: (v) {
                                            final n = int.tryParse(v);
                                            if (n != null && n > 0) {
                                              carrito.actualizarCantidad(
                                                  item.producto, n);
                                            }
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        color: AppTheme.primary,
                                        onPressed: () =>
                                            carrito.agregarProducto(item.producto),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      '\$${subtotal.toStringAsFixed(2)}',
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Total y botón pagar
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -4))
                        ],
                      ),
                      child: Column(
                        children: [
                          // Método de pago
                          Row(
                            children: [
                              const Icon(Icons.credit_card,
                                  color: AppTheme.primary),
                              const SizedBox(width: 8),
                              const Text('Método de pago: '),
                              Text(_metodoPago,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Subtotal
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              Text('\$${(total / 1.16).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // IVA
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('IVA (16%):', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              Text('\$${(total - total / 1.16).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text('\$${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _procesando ? null : _comprarTodo,
                              icon: _procesando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white))
                                  : const Icon(Icons.shopping_bag_outlined),
                              label: _procesando
                                  ? const Text('Procesando...')
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