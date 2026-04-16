import 'package:flutter/material.dart';
import '../../models/cliente.dart';
import '../../models/compra.dart';
import '../../services/cliente_service.dart';
import '../../services/venta_service.dart';
import '../../core/theme/app_theme.dart';

class VendedorClientesScreen extends StatefulWidget {
  final bool modoSeleccion;

  const VendedorClientesScreen({
    super.key,
    this.modoSeleccion = false,
  });

  @override
  State<VendedorClientesScreen> createState() => _VendedorClientesScreenState();
}

class _VendedorClientesScreenState extends State<VendedorClientesScreen> {
  late Future<List<Cliente>> _futureClientes;
  final TextEditingController _buscarCtrl = TextEditingController();
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _futureClientes = ClienteService.obtenerClientes();
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  void _recargarClientes() {
    setState(() {
      _futureClientes = ClienteService.obtenerClientes();
    });
  }

  List<Cliente> _filtrarClientes(List<Cliente> clientes) {
    if (_busqueda.trim().isEmpty) return clientes;
    final texto = _busqueda.toLowerCase();
    return clientes.where((c) {
      return c.nombre.toLowerCase().contains(texto) ||
          c.correo.toLowerCase().contains(texto) ||
          c.telefono.toLowerCase().contains(texto);
    }).toList();
  }

  void _seleccionarCliente(Cliente cliente) {
    Navigator.pop(context, cliente);
  }

  Future<void> _verCompras(Cliente cliente) async {
    await showDialog(
      context: context,
      builder: (_) => _ComprasClienteDialog(cliente: cliente),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esAncho = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modoSeleccion
            ? 'Seleccionar cliente'
            : 'Clientes registrados'),
        actions: [
          IconButton(
            onPressed: _recargarClientes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _buscarCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar cliente',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _busqueda = value),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Cliente>>(
                future: _futureClientes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar clientes:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final clientes = _filtrarClientes(snapshot.data ?? []);

                  if (clientes.isEmpty) {
                    return const Center(
                        child: Text('No hay clientes registrados'));
                  }

                  if (esAncho) {
                    return GridView.builder(
                      itemCount: clientes.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 380,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                      ),
                      itemBuilder: (context, index) =>
                          _buildClienteCard(clientes[index]),
                    );
                  }

                  return ListView.builder(
                    itemCount: clientes.length,
                    itemBuilder: (context, index) =>
                        _buildClienteCard(clientes[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClienteCard(Cliente cliente) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(
                    cliente.nombre.isNotEmpty
                        ? cliente.nombre[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cliente.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    cliente.activo ? 'Activo' : 'Inactivo',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: (cliente.activo
                          ? AppTheme.success
                          : AppTheme.error)
                      .withOpacity(0.1),
                  labelStyle: TextStyle(
                      color: cliente.activo ? AppTheme.success : AppTheme.error,
                      fontWeight: FontWeight.bold),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email_outlined,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    cliente.correo.isEmpty ? '—' : cliente.correo,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  cliente.telefono.isEmpty ? '—' : cliente.telefono,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                // Botón Ver compras
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _verCompras(cliente),
                    icon: const Icon(Icons.receipt_long_outlined, size: 16),
                    label: const Text('Ver compras'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                    ),
                  ),
                ),
                if (widget.modoSeleccion) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _seleccionarCliente(cliente),
                      child: const Text('Seleccionar'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Diálogo de compras del cliente ─────────────────────────────────────────
class _ComprasClienteDialog extends StatefulWidget {
  final Cliente cliente;

  const _ComprasClienteDialog({required this.cliente});

  @override
  State<_ComprasClienteDialog> createState() => _ComprasClienteDialogState();
}

class _ComprasClienteDialogState extends State<_ComprasClienteDialog> {
  late Future<List<Compra>> _futureCompras;

  @override
  void initState() {
    super.initState();
    _cargarCompras();
  }

  void _cargarCompras() {
    setState(() {
      _futureCompras = _obtenerComprasCliente();
    });
  }

  Future<List<Compra>> _obtenerComprasCliente() async {
    final todas = await VentaService.obtenerVentas();
    return todas
        .where((v) =>
            v.cliente.toLowerCase() ==
            widget.cliente.nombre.toLowerCase())
        .toList()
      ..sort((a, b) {
        final fa = a.fechaDate ?? DateTime(0);
        final fb = b.fechaDate ?? DateTime(0);
        return fb.compareTo(fa);
      });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Compras de ${widget.cliente.nombre}',
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 400,
        child: FutureBuilder<List<Compra>>(
          future: _futureCompras,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)),
              );
            }

            final compras = snapshot.data ?? [];

            if (compras.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Este cliente no tiene compras registradas',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            // Total gastado
            final totalGastado =
                compras.fold<double>(0, (sum, c) => sum + c.total);

            return Column(
              children: [
                // Resumen
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('${compras.length}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary)),
                          const Text('Compras',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('\$${totalGastado.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary)),
                          const Text('Total gastado',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Lista de compras
                Expanded(
                  child: ListView.builder(
                    itemCount: compras.length,
                    itemBuilder: (context, index) {
                      final compra = compras[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          leading: const Icon(Icons.receipt_outlined,
                              color: AppTheme.primary),
                          title: Text(compra.folio,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          subtitle: Text(
                            '${compra.fechaFormateada} · ${compra.metodoPago}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            '\$${compra.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Column(
                                children: compra.items.map((item) {
  final nombre = item.nombre.isNotEmpty
      ? item.nombre
      : 'Producto ${item.idProducto}';
  final cantidad = item.cantidad;
  final subtotal = item.subtotal;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                              '$nombre x$cantidad',
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ),
                                        Text(
                                          '\$${subtotal.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}