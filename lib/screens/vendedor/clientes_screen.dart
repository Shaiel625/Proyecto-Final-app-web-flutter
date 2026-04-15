import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cliente.dart';
import '../../services/cliente_service.dart';
import '../../widgets/loading_view.dart';
 
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
 
  void _recargar() {
    setState(() => _futureClientes = ClienteService.obtenerClientes());
  }
 
  List<Cliente> _filtrar(List<Cliente> clientes) {
    if (_busqueda.trim().isEmpty) return clientes;
    final texto = _busqueda.toLowerCase();
    return clientes.where((c) =>
        c.nombre.toLowerCase().contains(texto) ||
        c.correo.toLowerCase().contains(texto) ||
        c.telefono.toLowerCase().contains(texto)).toList();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.modoSeleccion ? 'Seleccionar cliente' : 'Clientes registrados'),
        actions: [
          IconButton(onPressed: _recargar, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _buscarCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar cliente',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _busqueda = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Cliente>>(
                future: _futureClientes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingView(mensaje: 'Cargando clientes...');
                  }
                  if (snapshot.hasError) {
                    return ErrorView(
                      mensaje: 'Error al cargar clientes:\n${snapshot.error}',
                      onReintentar: _recargar,
                    );
                  }
 
                  final clientes = _filtrar(snapshot.data ?? []);
 
                  if (clientes.isEmpty) {
                    return const EmptyView(
                      mensaje: 'No hay clientes registrados',
                      icono: Icons.people_outline,
                    );
                  }
 
                  final esAncho = MediaQuery.of(context).size.width > 800;
 
                  if (esAncho) {
                    return GridView.builder(
                      itemCount: clientes.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 380,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.45,
                      ),
                      itemBuilder: (context, index) =>
                          _ClienteCard(
                            cliente: clientes[index],
                            modoSeleccion: widget.modoSeleccion,
                            onSeleccionar: () =>
                                Navigator.pop(context, clientes[index]),
                          ),
                    );
                  }
 
                  return ListView.builder(
                    itemCount: clientes.length,
                    itemBuilder: (context, index) => _ClienteCard(
                      cliente: clientes[index],
                      modoSeleccion: widget.modoSeleccion,
                      onSeleccionar: () =>
                          Navigator.pop(context, clientes[index]),
                    ),
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
 
class _ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final bool modoSeleccion;
  final VoidCallback onSeleccionar;
 
  const _ClienteCard({
    required this.cliente,
    required this.modoSeleccion,
    required this.onSeleccionar,
  });
 
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 10),
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
                AppTheme.statusBadge(
                  cliente.activo ? 'Activo' : 'Inactivo',
                  cliente.activo ? AppTheme.success : AppTheme.error,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _dato(Icons.email_outlined,
                cliente.correo.isEmpty ? '—' : cliente.correo),
            _dato(Icons.phone_outlined,
                cliente.telefono.isEmpty ? '—' : cliente.telefono),
            if (modoSeleccion) ...[
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSeleccionar,
                  child: const Text('Seleccionar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
 
  Widget _dato(IconData icono, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icono, size: 15, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}