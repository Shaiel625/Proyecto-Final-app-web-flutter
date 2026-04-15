import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../services/producto_service.dart';
import '../../widgets/loading_view.dart';
import '../../core/theme/app_theme.dart';
 
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});
 
  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}
 
class _AdminProductsScreenState extends State<AdminProductsScreen> {
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
 
  void _recargar() {
    setState(() => _futureProductos = ProductoService.obtenerProductos());
  }
 
  List<Producto> _filtrar(List<Producto> productos) {
    if (_search.trim().isEmpty) return productos;
    final texto = _search.toLowerCase();
    return productos.where((p) =>
        p.nombre.toLowerCase().contains(texto) ||
        p.codigo.toLowerCase().contains(texto) ||
        p.categoria.toLowerCase().contains(texto) ||
        p.marca.toLowerCase().contains(texto)).toList();
  }
 
  // ── Diálogo: Agregar stock ────────────────────────────────────────────────
  Future<void> _mostrarDialogoAgregarStock(Producto p) async {
    final ctrl = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();
 
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Agregar stock — ${p.nombre}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stock actual: ${p.stock}', style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad a agregar',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Ingresa un número mayor a 0';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
 
    if (confirmar != true) return;
 
    try {
      await ProductoService.agregarStock(
        idProducto: p.id,
        cantidad: int.parse(ctrl.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock actualizado para ${p.nombre}'), backgroundColor: AppTheme.success),
      );
      _recargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    }
  }
 
  // ── Diálogo: Nuevo producto ───────────────────────────────────────────────
  Future<void> _mostrarDialogoNuevoProducto() async {
    final formKey = GlobalKey<FormState>();
    final campos = {
      'codigo': TextEditingController(),
      'nombre': TextEditingController(),
      'descripcion': TextEditingController(),
      'precioVenta': TextEditingController(),
      'costo': TextEditingController(),
      'stock': TextEditingController(text: '0'),
      'stockMinimo': TextEditingController(text: '5'),
      'idCategoria': TextEditingController(text: '1'),
      'idMarca': TextEditingController(text: '1'),
      'unidadMedida': TextEditingController(text: 'pieza'),
    };
 
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo producto'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _campo(campos['codigo']!, 'Código', requerido: true),
                  _campo(campos['nombre']!, 'Nombre', requerido: true),
                  _campo(campos['descripcion']!, 'Descripción'),
                  _campoNumerico(campos['precioVenta']!, 'Precio de venta', decimal: true, requerido: true),
                  _campoNumerico(campos['costo']!, 'Costo', decimal: true, requerido: true),
                  _campoNumerico(campos['stock']!, 'Stock inicial', requerido: true),
                  _campoNumerico(campos['stockMinimo']!, 'Stock mínimo', requerido: true),
                  _campoNumerico(campos['idCategoria']!, 'ID Categoría', requerido: true),
                  _campoNumerico(campos['idMarca']!, 'ID Marca', requerido: true),
                  _campo(campos['unidadMedida']!, 'Unidad de medida', requerido: true),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              try {
                await ProductoService.crearProducto(
                  codigo: campos['codigo']!.text.trim(),
                  nombre: campos['nombre']!.text.trim(),
                  descripcion: campos['descripcion']!.text.trim(),
                  precioVenta: double.parse(campos['precioVenta']!.text),
                  costo: double.parse(campos['costo']!.text),
                  stock: int.parse(campos['stock']!.text),
                  stockMinimo: int.parse(campos['stockMinimo']!.text),
                  idCategoria: int.parse(campos['idCategoria']!.text),
                  idMarca: int.parse(campos['idMarca']!.text),
                  unidadMedida: campos['unidadMedida']!.text.trim(),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Producto creado correctamente'), backgroundColor: AppTheme.success),
                );
                _recargar();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
 
  Widget _campo(TextEditingController ctrl, String label, {bool requerido = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: requerido ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null : null,
      ),
    );
  }
 
  Widget _campoNumerico(TextEditingController ctrl, String label, {bool decimal = false, bool requerido = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: requerido
            ? (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                final n = decimal ? double.tryParse(v) : int.tryParse(v);
                if (n == null) return 'Ingresa un número válido';
                return null;
              }
            : null,
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(onPressed: _recargar, icon: const Icon(Icons.refresh), tooltip: 'Recargar'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevoProducto,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
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
              onChanged: (v) {
                setState(() => _search = v);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Producto>>(
                future: _futureProductos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingView(mensaje: 'Cargando productos...');
                  }
                  if (snapshot.hasError) {
                    return ErrorView(mensaje: '${snapshot.error}', onReintentar: _recargar);
                  }
 
                  final productos = _filtrar(snapshot.data ?? []);
                  if (productos.isEmpty) {
                    return const EmptyView(mensaje: 'No se encontraron productos', icono: Icons.inventory_2_outlined);
                  }
 
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 850) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Código')),
                              DataColumn(label: Text('Nombre')),
                              DataColumn(label: Text('Categoría')),
                              DataColumn(label: Text('Marca')),
                              DataColumn(label: Text('Precio')),
                              DataColumn(label: Text('Stock')),
                              DataColumn(label: Text('Acciones')),
                            ],
                            rows: productos.map((p) {
                              final stockBajo = p.stock <= p.stockMinimo;
                              return DataRow(cells: [
                                DataCell(Text(p.codigo)),
                                DataCell(Text(p.nombre)),
                                DataCell(Text(p.categoria)),
                                DataCell(Text(p.marca)),
                                DataCell(Text('\$${p.precioVenta.toStringAsFixed(2)}')),
                                DataCell(Text(
                                  p.stock.toString(),
                                  style: TextStyle(
                                    color: stockBajo ? AppTheme.error : AppTheme.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.add_box_outlined, color: AppTheme.primary),
                                    tooltip: 'Agregar stock',
                                    onPressed: () => _mostrarDialogoAgregarStock(p),
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        );
                      }
 
                      return ListView.builder(
                        itemCount: productos.length,
                        itemBuilder: (context, index) {
                          final p = productos[index];
                          final stockBajo = p.stock <= p.stockMinimo;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'Código: ${p.codigo}\nCategoría: ${p.categoria}\nMarca: ${p.marca}\n'
                                'Precio: \$${p.precioVenta.toStringAsFixed(2)}\nStock: ${p.stock}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_box_outlined, color: AppTheme.primary),
                                tooltip: 'Agregar stock',
                                onPressed: () => _mostrarDialogoAgregarStock(p),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
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