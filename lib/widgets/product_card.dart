import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../core/theme/app_theme.dart';
 
/// Tarjeta de producto reutilizable para el catálogo del cliente y el POS.
///
/// Parámetros:
///   - [producto]: datos del producto a mostrar.
///   - [onAgregar]: callback al pulsar el botón de agregar. Si es null, el botón aparece deshabilitado.
///   - [mostrarCosto]: muestra el costo además del precio de venta (útil en vistas de admin).
///   - [etiquetaBoton]: texto del botón de acción (por defecto 'Agregar al carrito').
class ProductCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback? onAgregar;
  final bool mostrarCosto;
  final String etiquetaBoton;
 
  const ProductCard({
    super.key,
    required this.producto,
    this.onAgregar,
    this.mostrarCosto = false,
    this.etiquetaBoton = 'Agregar al carrito',
  });
 
  @override
  Widget build(BuildContext context) {
    final sinStock = producto.stock <= 0;
    final stockBajo =
        !sinStock && producto.stock <= producto.stockMinimo;
 
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen / placeholder ────────────────────────────────────────
            Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 10),
 
            // ── Nombre ──────────────────────────────────────────────────────
            Text(
              producto.nombre,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
 
            // ── Categoría y marca ───────────────────────────────────────────
            Text(
              producto.categoria,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              producto.marca,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
 
            // ── Precio ──────────────────────────────────────────────────────
            Text(
              '\$${producto.precioVenta.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            if (mostrarCosto)
              Text(
                'Costo: \$${producto.costo.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            const SizedBox(height: 6),
 
            // ── Stock ───────────────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  sinStock
                      ? Icons.remove_circle_outline
                      : stockBajo
                          ? Icons.warning_amber_outlined
                          : Icons.check_circle_outline,
                  size: 14,
                  color: sinStock
                      ? AppTheme.error
                      : stockBajo
                          ? AppTheme.warning
                          : AppTheme.success,
                ),
                const SizedBox(width: 4),
                Text(
                  sinStock
                      ? 'Sin stock'
                      : stockBajo
                          ? 'Stock bajo (${producto.stock})'
                          : 'Disponible (${producto.stock})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sinStock
                        ? AppTheme.error
                        : stockBajo
                            ? AppTheme.warning
                            : AppTheme.success,
                  ),
                ),
              ],
            ),
 
            const Spacer(),
 
            // ── Botón de acción ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sinStock ? null : onAgregar,
                child: Text(etiquetaBoton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}