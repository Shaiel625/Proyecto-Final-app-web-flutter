import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../../models/compra.dart';
import '../../services/venta_service.dart';
 
class VendedorSalesScreen extends StatefulWidget {
  const VendedorSalesScreen({super.key});
 
  @override
  State<VendedorSalesScreen> createState() => _VendedorSalesScreenState();
}
 
class _VendedorSalesScreenState extends State<VendedorSalesScreen> {
  late Future<List<Compra>> _futureVentas;
  final TextEditingController _searchCtrl = TextEditingController();
 
  String _search = '';
  String _metodoFiltro = 'Todos';
  bool _ordenDescendente = true;
 
  @override
  void initState() {
    super.initState();
    _futureVentas = VentaService.obtenerVentas();
  }
 
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _recargar() async {
    setState(() {
      _futureVentas = VentaService.obtenerVentas();
    });
  }
 
  List<Compra> _filtrarVentas(List<Compra> ventas) {
    var lista = List<Compra>.from(ventas);
 
    if (_search.trim().isNotEmpty) {
      final texto = _search.toLowerCase();
      lista = lista.where((venta) {
        return venta.folio.toLowerCase().contains(texto) ||
            venta.cliente.toLowerCase().contains(texto) ||
            venta.metodoPago.toLowerCase().contains(texto) ||
            venta.vendedor.toLowerCase().contains(texto);
      }).toList();
    }
 
    if (_metodoFiltro != 'Todos') {
      lista = lista
          .where((venta) => venta.metodoPago == _metodoFiltro)
          .toList();
    }
 
    lista.sort((a, b) {
      final fechaA = a.fechaDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final fechaB = b.fechaDate ?? DateTime.fromMillisecondsSinceEpoch(0);
 
      return _ordenDescendente
          ? fechaB.compareTo(fechaA)
          : fechaA.compareTo(fechaB);
    });
 
    return lista;
  }
 
  double _calcularTotal(List<Compra> ventas) {
    return ventas.fold(0, (sum, venta) => sum + venta.total);
  }
 
  void _exportarVentasCsv(List<Compra> ventas) {
    if (ventas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay ventas para exportar'),
        ),
      );
      return;
    }
 
    final buffer = StringBuffer();
 
    buffer.writeln(
      'Folio,Cliente,Vendedor,Fecha,Metodo de pago,Estado,Total,Productos',
    );
 
    for (final venta in ventas) {
      final productos = venta.items.isEmpty
          ? ''
          : venta.items
              .map(
                (item) =>
                    '${item.nombre} x${item.cantidad} (\$${item.subtotal.toStringAsFixed(2)})',
              )
              .join(' | ');
 
      buffer.writeln(
        '"${venta.folio}",'
        '"${venta.cliente}",'
        '"${venta.vendedor}",'
        '"${venta.fechaFormateada}",'
        '"${venta.metodoPago}",'
        '"${venta.estado}",'
        '"${venta.total.toStringAsFixed(2)}",'
        '"$productos"',
      );
    }
 
    final bytes = utf8.encode(buffer.toString());
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
    final url = html.Url.createObjectUrlFromBlob(blob);
 
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'ventas_exportadas.csv')
      ..click();
 
    html.Url.revokeObjectUrl(url);
 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Archivo CSV descargado correctamente'),
      ),
    );
  }
 
  void _mostrarDetalle(Compra venta) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(venta.folio),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cliente: ${venta.cliente}'),
                const SizedBox(height: 8),
                Text('Vendedor: ${venta.vendedor}'),
                const SizedBox(height: 8),
                Text('Fecha: ${venta.fechaFormateada}'),
                const SizedBox(height: 8),
                Text('Método: ${venta.metodoPago}'),
                const SizedBox(height: 8),
                Text('Estado: ${venta.estado}'),
                const SizedBox(height: 14),
                const Text(
                  'Productos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                if (venta.items.isEmpty)
                  const Text('No hay detalle de productos')
                else
                  ...venta.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Código: ${item.codigo}'),
                            Text('Cantidad: ${item.cantidad}'),
                            Text(
                              'Precio unitario: \$${item.precioUnitario.toStringAsFixed(2)}',
                            ),
                            Text(
                              'Subtotal: \$${item.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF1F4A7C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Total: \$${venta.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F4A7C),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis ventas'),
        backgroundColor: const Color(0xFF1F4A7C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<List<Compra>>(
          future: _futureVentas,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
 
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar ventas:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
 
            final ventas = _filtrarVentas(snapshot.data ?? []);
            final totalVendido = _calcularTotal(ventas);
 
            return RefreshIndicator(
              onRefresh: _recargar,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F4A7C).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total vendido',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${totalVendido.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F4A7C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _exportarVentasCsv(ventas);
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Exportar ventas a CSV'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar por folio, cliente, método o vendedor',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _search = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _metodoFiltro,
                          decoration: InputDecoration(
                            labelText: 'Método de pago',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Todos',
                              child: Text('Todos'),
                            ),
                            DropdownMenuItem(
                              value: 'Efectivo',
                              child: Text('Efectivo'),
                            ),
                            DropdownMenuItem(
                              value: 'Tarjeta',
                              child: Text('Tarjeta'),
                            ),
                            DropdownMenuItem(
                              value: 'Transferencia',
                              child: Text('Transferencia'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _metodoFiltro = value ?? 'Todos';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _ordenDescendente = !_ordenDescendente;
                          });
                        },
                        icon: Icon(
                          _ordenDescendente
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                        ),
                        tooltip: 'Ordenar por fecha',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ventas.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Text('No se encontraron ventas'),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: ventas.length,
                            itemBuilder: (context, index) {
                              final venta = ventas[index];
 
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFF1F4A7C)
                                        .withOpacity(0.1),
                                    child: const Icon(
                                      Icons.point_of_sale_outlined,
                                      color: Color(0xFF1F4A7C),
                                    ),
                                  ),
                                  title: Text(
                                    'Folio: ${venta.folio}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Cliente: ${venta.cliente}\n'
                                      'Fecha: ${venta.fechaFormateada}\n'
                                      'Método: ${venta.metodoPago}\n'
                                      'Total: \$${venta.total.toStringAsFixed(2)}',
                                      style: const TextStyle(height: 1.4),
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _mostrarDetalle(venta),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}