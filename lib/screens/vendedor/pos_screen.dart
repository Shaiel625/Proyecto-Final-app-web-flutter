import 'package:flutter/material.dart';
import '../../models/cliente.dart';
import '../../models/producto.dart';
import '../../services/cliente_service.dart';
import '../../services/divisa_service.dart';
import '../../services/producto_service.dart';
import '../../services/venta_service.dart';
import '../../services/session_service.dart';
 
class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
 
  @override
  State<PosScreen> createState() => _PosScreenState();
}
 
class _PosScreenState extends State<PosScreen> {
  late Future<List<Producto>> _futureProductos;
  late Future<List<Cliente>> _futureClientes;
  late Future<List<DivisaInfo>> _futureDivisas;
 
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
 
  final List<_CartItem> _carrito = [];
  bool _procesandoVenta = false;
 
  Cliente? _clienteSeleccionado;
  String _metodoPagoSeleccionado = 'Efectivo';
  String _divisaSeleccionada = 'MXN';
 
  final List<String> _metodosPago = [
    'Efectivo',
    'Tarjeta',
    'Transferencia',
  ];
 
  double _tasaCambio = 1.0;
  String _fechaTasa = '';
  bool _cargandoTasa = false;
 
  @override
  void initState() {
    super.initState();
    _futureProductos = ProductoService.obtenerProductos();
    _futureClientes = ClienteService.obtenerClientes();
    _futureDivisas = DivisaService.obtenerMonedasDisponibles();
    _cargarTasaCambio();
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
 
  Future<void> _cargarTasaCambio() async {
    if (_divisaSeleccionada == 'MXN') {
      if (!mounted) return;
      setState(() {
        _tasaCambio = 1.0;
        _fechaTasa = '';
        _cargandoTasa = false;
      });
      return;
    }
 
    setState(() {
      _cargandoTasa = true;
    });
 
    try {
      final conversion = await DivisaService.obtenerTasa(
        base: 'MXN',
        target: _divisaSeleccionada,
      );
 
      if (!mounted) return;
 
      setState(() {
        _tasaCambio = conversion.rate;
        _fechaTasa = conversion.date;
        _cargandoTasa = false;
      });
    } catch (e) {
      if (!mounted) return;
 
      setState(() {
        _tasaCambio = 1.0;
        _fechaTasa = '';
        _cargandoTasa = false;
      });
 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cargar la divisa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
 
  Future<void> _mostrarDialogoCantidad(Producto producto) async {
    int cantidad = 1;
    final ctrl = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();
 
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void actualizar(int nuevo) {
              if (nuevo < 1) nuevo = 1;
              if (nuevo > producto.stock) nuevo = producto.stock;
              cantidad = nuevo;
              ctrl.text = '$nuevo';
              ctrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: ctrl.text.length));
              setDialogState(() {});
            }
 
            return AlertDialog(
              title: const Text('Agregar producto'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(producto.nombre,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Precio: \$${producto.precioVenta.toStringAsFixed(2)}',
                        style: const TextStyle(color: Color(0xFF1F4A7C))),
                    const SizedBox(height: 4),
                    Text('Stock disponible: ${producto.stock}',
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: cantidad > 1 ? () => actualizar(cantidad - 1) : null,
                          icon: const Icon(Icons.remove_circle_outline, size: 28),
                          color: const Color(0xFF1F4A7C),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: ctrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null) actualizar(n);
                            },
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n < 1) return 'Mín 1';
                              if (n > producto.stock) return 'Máx ${producto.stock}';
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: cantidad < producto.stock ? () => actualizar(cantidad + 1) : null,
                          icon: const Icon(Icons.add_circle_outline, size: 28),
                          color: const Color(0xFF1F4A7C),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Subtotal preview
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F4A7C).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '\$${(producto.precioVenta * cantidad).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F4A7C)),
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
                      _agregarAlCarrito(producto, cantidad);
                      Navigator.pop(context);
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
  }
 
  void _agregarAlCarrito(Producto producto, int cantidad) {
    final index = _carrito.indexWhere((item) => item.producto.id == producto.id);
 
    setState(() {
      if (index >= 0) {
        final nuevaCantidad = _carrito[index].cantidad + cantidad;
 
        if (nuevaCantidad <= producto.stock) {
          _carrito[index].cantidad = nuevaCantidad;
        } else {
          _carrito[index].cantidad = producto.stock;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Se ajustó al stock máximo disponible (${producto.stock})',
              ),
            ),
          );
        }
      } else {
        _carrito.add(
          _CartItem(
            producto: producto,
            cantidad: cantidad,
          ),
        );
      }
    });
  }
 
  void _incrementarCantidad(_CartItem item) {
    setState(() {
      if (item.cantidad < item.producto.stock) {
        item.cantidad++;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No hay más stock disponible para ${item.producto.nombre}',
            ),
          ),
        );
      }
    });
  }
 
  void _disminuirCantidad(_CartItem item) {
    setState(() {
      if (item.cantidad > 1) {
        item.cantidad--;
      } else {
        _carrito.remove(item);
      }
    });
  }
 
  void _quitarDelCarrito(_CartItem item) {
    setState(() {
      _carrito.remove(item);
    });
  }
 
  Future<void> _seleccionarDivisaConBuscador(List<DivisaInfo> divisas) async {
    final searchCtrl = TextEditingController();
    List<DivisaInfo> filtradas = List.from(divisas);
 
    final seleccionada = await showDialog<DivisaInfo>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Seleccionar divisa'),
              content: SizedBox(
                width: 430,
                height: 430,
                child: Column(
                  children: [
                    TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Buscar por código o nombre',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        final texto = value.toLowerCase().trim();
 
                        setDialogState(() {
                          filtradas = divisas.where((divisa) {
                            return divisa.codigo.toLowerCase().contains(texto) ||
                                divisa.nombre.toLowerCase().contains(texto);
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtradas.isEmpty
                          ? const Center(
                              child: Text('No se encontraron divisas'),
                            )
                          : ListView.builder(
                              itemCount: filtradas.length,
                              itemBuilder: (context, index) {
                                final divisa = filtradas[index];
                                final esActual =
                                    divisa.codigo == _divisaSeleccionada;
 
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: esActual
                                        ? const Color(0xFF1F4A7C)
                                        : Colors.grey.shade300,
                                    child: Text(
                                      divisa.codigo.substring(0, 1),
                                      style: TextStyle(
                                        color: esActual
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(divisa.codigo),
                                  subtitle: Text(
                                    divisa.nombre.isEmpty
                                        ? 'Sin descripción'
                                        : divisa.nombre,
                                  ),
                                  trailing: esActual
                                      ? const Icon(
                                          Icons.check,
                                          color: Color(0xFF1F4A7C),
                                        )
                                      : null,
                                  onTap: () {
                                    Navigator.pop(context, divisa);
                                  },
                                );
                              },
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
              ],
            );
          },
        );
      },
    );
 
    searchCtrl.dispose();
 
    if (seleccionada != null && seleccionada.codigo != _divisaSeleccionada) {
      setState(() {
        _divisaSeleccionada = seleccionada.codigo;
      });
      await _cargarTasaCambio();
    }
  }
 
  double get _subtotal {
    return _carrito.fold(
      0,
      (sum, item) => sum + (item.producto.precioVenta * item.cantidad),
    );
  }
 
  double get _iva => _subtotal * 0.16;
 
  double get _total => _subtotal + _iva;
 
  double get _totalConvertido => _total * _tasaCambio;
 
  Future<void> _confirmarVenta() async {
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega productos al carrito')),
      );
      return;
    }
 
    setState(() {
      _procesandoVenta = true;
    });
 
    try {
      final sesion = await SessionService.obtenerSesion();
      final nombreVendedor = sesion?['nombre'] ?? 'Vendedor';
 
      await VentaService.registrarVenta(
        vendedor: nombreVendedor,
        cliente: _clienteSeleccionado?.nombre ?? 'Cliente mostrador',
        metodoPago: _metodoPagoSeleccionado,
        items: _carrito
            .map(
              (item) => VentaItemPayload(
                idProducto: item.producto.id,
                cantidad: item.cantidad,
              ),
            )
            .toList(),
      );
 
      final totalVenta = _total;
      final totalDivisa = _totalConvertido;
      final divisa = _divisaSeleccionada;
 
      if (!mounted) return;
 
      setState(() {
        _carrito.clear();
        _clienteSeleccionado = null;
        _metodoPagoSeleccionado = 'Efectivo';
        _divisaSeleccionada = 'MXN';
        _tasaCambio = 1.0;
        _fechaTasa = '';
        _procesandoVenta = false;
      });
 
      _recargarProductos();
 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            divisa == 'MXN'
                ? 'Venta registrada. Total: \$${totalVenta.toStringAsFixed(2)} MXN'
                : 'Venta registrada. Total: \$${totalVenta.toStringAsFixed(2)} MXN / ${totalDivisa.toStringAsFixed(2)} $divisa',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
 
      setState(() {
        _procesandoVenta = false;
      });
 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo completar la venta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
 
  Future<void> _cobrar() async {
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega productos al carrito')),
      );
      return;
    }
 
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${_clienteSeleccionado?.nombre ?? 'Cliente mostrador'}'),
            const SizedBox(height: 6),
            Text('Método de pago: $_metodoPagoSeleccionado'),
            const SizedBox(height: 6),
            Text('Total MXN: \$${_total.toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            Text(
              _divisaSeleccionada == 'MXN'
                  ? 'Total MXN: ${_total.toStringAsFixed(2)}'
                  : 'Total $_divisaSeleccionada: ${_totalConvertido.toStringAsFixed(2)}',
            ),
            if (_divisaSeleccionada != 'MXN' && _fechaTasa.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Tasa: 1 MXN = ${_tasaCambio.toStringAsFixed(4)} $_divisaSeleccionada',
                style: const TextStyle(color: Colors.black54),
              ),
              Text(
                'Fecha API: $_fechaTasa',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _procesandoVenta ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _procesandoVenta
                ? null
                : () async {
                    Navigator.pop(context);
                    await _confirmarVenta();
                  },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final esAncho = MediaQuery.of(context).size.width > 980;
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('Punto de Venta'),
        backgroundColor: const Color(0xFF1F4A7C),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: FutureBuilder<List<Producto>>(
        future: _futureProductos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
 
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar productos:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
 
          final productos = _filtrar(snapshot.data ?? []);
 
          if (esAncho) {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildProductos(productos),
                ),
                Container(
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  flex: 2,
                  child: _buildCarrito(),
                ),
              ],
            );
          }
 
          return Column(
            children: [
              Expanded(
                child: _buildProductos(productos),
              ),
              SizedBox(
                height: 560,
                child: _buildCarrito(),
              ),
            ],
          );
        },
      ),
    );
  }
 
  Widget _buildProductos(List<Producto> productos) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              labelText: 'Buscar producto',
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
          const SizedBox(height: 16),
          Expanded(
            child: productos.isEmpty
                ? const Center(
                    child: Text('No se encontraron productos'),
                  )
                : GridView.builder(
                    itemCount: productos.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 280,
                    ),
                    itemBuilder: (context, index) {
                      final producto = productos[index];
                      final sinStock = producto.stock <= 0;
 
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                producto.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Código: ${producto.codigo}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Categoría: ${producto.categoria}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Marca: ${producto.marca}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Text(
                                '\$${producto.precioVenta.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F4A7C),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Stock: ${producto.stock}',
                                style: TextStyle(
                                  color: sinStock ? Colors.red : Colors.black87,
                                  fontWeight: sinStock
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: sinStock || _procesandoVenta
                                      ? null
                                      : () => _mostrarDialogoCantidad(producto),
                                  icon: const Icon(Icons.add_shopping_cart),
                                  label: Text(
                                    sinStock ? 'Sin stock' : 'Agregar',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildCarrito() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Carrito',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F4A7C),
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Cliente>>(
            future: _futureClientes,
            builder: (context, snapshot) {
              final clientes = snapshot.data ?? [];
 
              return Autocomplete<Cliente>(
                optionsBuilder: (TextEditingValue textValue) {
                  if (textValue.text.isEmpty) {
                    return clientes;
                  }
                  final texto = textValue.text.toLowerCase();
                  return clientes.where((c) =>
                      c.nombre.toLowerCase().contains(texto) ||
                      c.correo.toLowerCase().contains(texto));
                },
                displayStringForOption: (c) => c.nombre,
                onSelected: (c) {
                  setState(() => _clienteSeleccionado = c);
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                  // Si hay cliente seleccionado, mostrar su nombre
                  if (_clienteSeleccionado != null &&
                      controller.text.isEmpty) {
                    controller.text = _clienteSeleccionado!.nombre;
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !_procesandoVenta,
                    decoration: InputDecoration(
                      labelText: 'Buscar cliente',
                      hintText: 'Cliente mostrador',
                      prefixIcon: const Icon(Icons.person_search_outlined),
                      suffixIcon: _clienteSeleccionado != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              tooltip: 'Limpiar (Cliente mostrador)',
                              onPressed: () {
                                setState(() => _clienteSeleccionado = null);
                                controller.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final c = options.elementAt(index);
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    const Color(0xFF1F4A7C).withOpacity(0.1),
                                child: Text(
                                  c.nombre.isNotEmpty
                                      ? c.nombre[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: Color(0xFF1F4A7C),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(c.nombre),
                              subtitle: Text(c.correo,
                                  style: const TextStyle(fontSize: 12)),
                              onTap: () => onSelected(c),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _metodoPagoSeleccionado,
            decoration: InputDecoration(
              labelText: 'Método de pago',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _metodosPago
                .map(
                  (metodo) => DropdownMenuItem(
                    value: metodo,
                    child: Text(metodo),
                  ),
                )
                .toList(),
            onChanged: _procesandoVenta
                ? null
                : (value) {
                    setState(() {
                      _metodoPagoSeleccionado = value ?? 'Efectivo';
                    });
                  },
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<DivisaInfo>>(
            future: _futureDivisas,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
 
              if (snapshot.hasError) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'No se pudieron cargar las divisas: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
 
              final divisas = snapshot.data ?? [
                DivisaInfo(codigo: 'MXN', nombre: 'Peso mexicano', simbolo: '\$'),
              ];
 
              if (!divisas.any((d) => d.codigo == _divisaSeleccionada)) {
                _divisaSeleccionada =
                    divisas.any((d) => d.codigo == 'MXN') ? 'MXN' : divisas.first.codigo;
              }
 
              final divisaActual = divisas.firstWhere(
                (d) => d.codigo == _divisaSeleccionada,
                orElse: () => DivisaInfo(
                  codigo: _divisaSeleccionada,
                  nombre: '',
                  simbolo: '',
                ),
              );
 
              return InkWell(
                onTap: _procesandoVenta
                    ? null
                    : () async {
                        await _seleccionarDivisaConBuscador(divisas);
                      },
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Divisa',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: const Icon(Icons.search),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          divisaActual.etiqueta,
                          style: const TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          if (_cargandoTasa)
            const LinearProgressIndicator()
          else
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _divisaSeleccionada == 'MXN'
                    ? 'Moneda base del sistema: MXN'
                    : '1 MXN = ${_tasaCambio.toStringAsFixed(4)} $_divisaSeleccionada'
                        '${_fechaTasa.isNotEmpty ? '  •  API: $_fechaTasa' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: _carrito.isEmpty
                ? const Center(
                    child: Text('No hay productos en el carrito'),
                  )
                : ListView.builder(
                    itemCount: _carrito.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(_carrito[index]);
                    },
                  ),
          ),
          const SizedBox(height: 12),
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(fontSize: 15, color: Colors.grey)),
              Text('\$${_subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 15, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          // IVA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('IVA (16%):', style: TextStyle(fontSize: 15, color: Colors.grey)),
              Text('\$${_iva.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 15, color: Colors.grey)),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total MXN:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Flexible(
                child: Text(
                  '\$${_total.toStringAsFixed(2)}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F4A7C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total $_divisaSeleccionada:',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              Flexible(
                child: Text(
                  _divisaSeleccionada == 'MXN'
                      ? _total.toStringAsFixed(2)
                      : _totalConvertido.toStringAsFixed(2),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F4A7C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _procesandoVenta ? null : _cobrar,
              icon: _procesandoVenta
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.point_of_sale),
              label: Text(_procesandoVenta ? 'Procesando...' : 'Cobrar'),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildCartItem(_CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: _procesandoVenta ? null : () => _quitarDelCarrito(item),
              icon: const Icon(Icons.delete_outline),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.producto.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text('Cantidad: ${item.cantidad}'),
                  const SizedBox(height: 4),
                  Text(
                    'Subtotal: \$${(item.producto.precioVenta * item.cantidad).toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                IconButton(
                  onPressed:
                      _procesandoVenta ? null : () => _incrementarCantidad(item),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                IconButton(
                  onPressed:
                      _procesandoVenta ? null : () => _disminuirCantidad(item),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
 
class _CartItem {
  final Producto producto;
  int cantidad;
 
  _CartItem({
    required this.producto,
    required this.cantidad,
  });
}