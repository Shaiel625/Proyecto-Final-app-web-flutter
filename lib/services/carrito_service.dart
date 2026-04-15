import 'package:flutter/foundation.dart';
import '../models/producto.dart';
 
class CarritoItem {
  final Producto producto;
  int cantidad;
 
  CarritoItem({required this.producto, this.cantidad = 1});
 
  double get subtotal => producto.precioVenta * cantidad;
}
 
/// Servicio del carrito como ChangeNotifier.
///
/// Uso en cualquier widget:
///   - Escuchar cambios:  ListenableBuilder(listenable: CarritoService.instance, ...)
///   - Leer sin escuchar: CarritoService.instance.items
class CarritoService extends ChangeNotifier {
  // Instancia global única (singleton)
  static final CarritoService instance = CarritoService._();
  CarritoService._();
 
  final List<CarritoItem> _items = [];
 
  List<CarritoItem> get items => List.unmodifiable(_items);
 
  int get totalProductos => _items.fold(0, (sum, i) => sum + i.cantidad);
 
  double get totalCarrito => _items.fold(0, (sum, i) => sum + i.subtotal);
 
  void agregarProducto(Producto producto, {int cantidad = 1}) {
    final index = _items.indexWhere((i) => i.producto.id == producto.id);
    final cantidadEfectiva = cantidad.clamp(1, producto.stock);
 
    if (index != -1) {
      final nueva = (_items[index].cantidad + cantidadEfectiva).clamp(0, producto.stock);
      _items[index].cantidad = nueva;
    } else {
      _items.add(CarritoItem(producto: producto, cantidad: cantidadEfectiva));
    }
    notifyListeners();
  }
 
  void eliminarProducto(Producto producto) {
    _items.removeWhere((i) => i.producto.id == producto.id);
    notifyListeners();
  }
 
  void aumentarCantidad(Producto producto) {
    final index = _items.indexWhere((i) => i.producto.id == producto.id);
    if (index != -1 && _items[index].cantidad < producto.stock) {
      _items[index].cantidad++;
      notifyListeners();
    }
  }
 
  void disminuirCantidad(Producto producto) {
    final index = _items.indexWhere((i) => i.producto.id == producto.id);
    if (index != -1) {
      if (_items[index].cantidad > 1) {
        _items[index].cantidad--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }
 
  void actualizarCantidad(Producto producto, int cantidad) {
    final index = _items.indexWhere((i) => i.producto.id == producto.id);
    if (index != -1) {
      if (cantidad <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].cantidad = cantidad.clamp(1, producto.stock);
      }
      notifyListeners();
    }
  }
 
  /// Limpia el carrito — llamar siempre al cerrar sesión.
  void limpiar() {
    _items.clear();
    notifyListeners();
  }
}