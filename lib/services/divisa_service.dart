import 'dart:convert';
import 'package:http/http.dart' as http;
 
class DivisaInfo {
  final String codigo;
  final String nombre;
  final String simbolo;
 
  DivisaInfo({required this.codigo, required this.nombre, required this.simbolo});
 
  String get etiqueta => nombre.isEmpty ? codigo : '$codigo - $nombre';
}
 
class DivisaConversion {
  final String base;
  final String target;
  final double rate;
  final String date;
 
  DivisaConversion({
    required this.base,
    required this.target,
    required this.rate,
    required this.date,
  });
}
 
class DivisaService {
  /// Obtiene la tasa de cambio entre [base] y [target] usando la API Frankfurter.
  ///
  /// La API devuelve: { "base": "MXN", "date": "2024-01-01", "rates": { "USD": 0.058 } }
  static Future<DivisaConversion> obtenerTasa({
    String base = 'MXN',
    required String target,
  }) async {
    if (base == target) {
      return DivisaConversion(base: base, target: target, rate: 1.0, date: '');
    }
 
    final uri = Uri.parse(
      'https://api.frankfurter.dev/v1/latest?base=$base&symbols=$target',
    );
 
    final response = await http.get(uri, headers: {'Accept': 'application/json'});
 
    if (response.statusCode != 200) {
      throw Exception('No se pudo obtener la tasa de cambio (${response.statusCode})');
    }
 
    final data = jsonDecode(response.body) as Map<String, dynamic>;
 
    // Respuesta correcta: { "base": "MXN", "date": "...", "rates": { "USD": 0.058 } }
    final rates = data['rates'] as Map<String, dynamic>?;
    if (rates == null || !rates.containsKey(target)) {
      throw Exception('La divisa "$target" no está disponible');
    }
 
    return DivisaConversion(
      base: data['base']?.toString() ?? base,
      target: target,
      rate: (rates[target] as num).toDouble(),
      date: data['date']?.toString() ?? '',
    );
  }
 
  /// Obtiene la lista de divisas disponibles en Frankfurter.
  ///
  /// La API devuelve: { "AUD": "Australian Dollar", "BGN": "Bulgarian Lev", ... }
  static Future<List<DivisaInfo>> obtenerMonedasDisponibles() async {
    final uri = Uri.parse('https://api.frankfurter.dev/v1/currencies');
    final response = await http.get(uri, headers: {'Accept': 'application/json'});
 
    if (response.statusCode != 200) {
      throw Exception('No se pudieron obtener las divisas disponibles');
    }
 
    final data = jsonDecode(response.body) as Map<String, dynamic>;
 
    // Respuesta correcta: { "AUD": "Australian Dollar", ... }
    final monedas = data.entries
        .map((e) => DivisaInfo(
              codigo: e.key,
              nombre: e.value.toString(),
              simbolo: '',
            ))
        .toList()
      ..sort((a, b) => a.codigo.compareTo(b.codigo));
 
    return monedas;
  }
}