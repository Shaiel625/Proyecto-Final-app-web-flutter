import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../services/producto_service.dart';
import '../../core/routes/app_routes.dart';
import '../../services/carrito_service.dart';

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
    setState(() {
      _futureProductos = ProductoService.obtenerProductos();
    });
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
    final ctrl = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    final cantidadSeleccionada = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void actualizar(int nuevo) {
              if (nuevo < 1) nuevo = 1;
              if (nuevo > p.stock) nuevo = p.stock;
              cantidad = nuevo;
              ctrl.text = '$nuevo';
              ctrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: ctrl.text.length));
              setStateDialog(() {});
            }

            return AlertDialog(
              title: Text('Agregar ${p.nombre}'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${p.precioVenta.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Color(0xFF1F4A7C),
                          fontWeight: FontWeight.w600,
                          fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text('Stock disponible: ${p.stock}',
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: cantidad > 1
                              ? () => actualizar(cantidad - 1)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 28),
                          color: const Color(0xFF1F4A7C),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: ctrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 8),
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null) actualizar(n);
                            },
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n < 1) return 'Mín 1';
                              if (n > p.stock) return 'Máx ${p.stock}';
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: cantidad < p.stock
                              ? () => actualizar(cantidad + 1)
                              : null,
                          icon: const Icon(Icons.add_circle_outline, size: 28),
                          color: const Color(0xFF1F4A7C),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F4A7C).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '\$${(p.precioVenta * cantidad).toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1F4A7C)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context, cantidad);
                    }
                  },
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (cantidadSeleccionada != null) {
      CarritoService.instance.agregarProducto(
        p,
        cantidad: cantidadSeleccionada,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${p.nombre} x$cantidadSeleccionada agregado al carrito'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F4A7C),
        title: const Text('Catálogo'),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () async {
              final actualizado = await Navigator.pushNamed(
                context,
                AppRoutes.carrito,
              );
              if (actualizado == true) {
                _recargarProductos();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.clienteCompras);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.clientePerfil);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar producto',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Producto>>(
                future: _futureProductos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar catálogo:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _recargarProductos,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  final productos = _filtrar(snapshot.data ?? []);

                  if (productos.isEmpty) {
                    return const Center(
                        child: Text('No se encontraron productos'));
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
                    itemBuilder: (context, index) {
                      final p = productos[index];
                      final sinStock = p.stock <= 0;

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 90,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 52,
                                  color: Color(0xFF1F4A7C),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                p.nombre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text('Categoría: ${p.categoria}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              Text('Marca: ${p.marca}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Text(
                                '\$${p.precioVenta.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F4A7C),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                sinStock
                                    ? 'Sin stock'
                                    : 'Disponible (${p.stock})',
                                style: TextStyle(
                                  color:
                                      sinStock ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: sinStock
                                      ? null
                                      : () => _seleccionarCantidad(p),
                                  child: const Text('Agregar al carrito'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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