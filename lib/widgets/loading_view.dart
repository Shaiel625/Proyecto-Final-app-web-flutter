import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
 
/// Indicador de carga centrado, con mensaje opcional.
///
/// Uso: LoadingView()  o  LoadingView(mensaje: 'Cargando productos...')
class LoadingView extends StatelessWidget {
  final String mensaje;
 
  const LoadingView({super.key, this.mensaje = 'Cargando...'});
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: 16),
          Text(
            mensaje,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
 
/// Vista de error con botón de reintento opcional.
///
/// Uso:
///   ErrorView(mensaje: snapshot.error.toString())
///   ErrorView(mensaje: 'Sin conexión', onReintentar: _recargar)
class ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;
 
  const ErrorView({super.key, required this.mensaje, this.onReintentar});
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
 
/// Vista de lista vacía con ícono y mensaje.
///
/// Uso: EmptyView(mensaje: 'No hay productos disponibles')
class EmptyView extends StatelessWidget {
  final String mensaje;
  final IconData icono;
 
  const EmptyView({
    super.key,
    required this.mensaje,
    this.icono = Icons.inbox_outlined,
  });
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 64, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}