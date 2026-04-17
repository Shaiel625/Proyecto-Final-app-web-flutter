import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
    setState(() => _futureVentas = VentaService.obtenerVentas());
  }

  List<Compra> _filtrarVentas(List<Compra> ventas) {
    var lista = List<Compra>.from(ventas);
    if (_search.trim().isNotEmpty) {
      final texto = _search.toLowerCase();
      lista = lista.where((venta) =>
          venta.folio.toLowerCase().contains(texto) ||
          venta.cliente.toLowerCase().contains(texto) ||
          venta.metodoPago.toLowerCase().contains(texto) ||
          venta.vendedor.toLowerCase().contains(texto)).toList();
    }
    if (_metodoFiltro != 'Todos') {
      lista = lista.where((venta) => venta.metodoPago == _metodoFiltro).toList();
    }
    lista.sort((a, b) {
      final fa = a.fechaDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final fb = b.fechaDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return _ordenDescendente ? fb.compareTo(fa) : fa.compareTo(fb);
    });
    return lista;
  }

  double _calcularTotal(List<Compra> ventas) =>
      ventas.fold(0, (sum, venta) => sum + venta.total);

  // ── CSV (funciona en web con dart:html) ──────────────────────────────────
  void _exportarCsv(List<Compra> ventas) {
    if (ventas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay ventas para exportar')),
      );
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('Folio,Cliente,Vendedor,Fecha,Metodo de pago,Estado,Total,Productos');
    for (final venta in ventas) {
      final productos = venta.items.isEmpty
          ? ''
          : venta.items.map((item) =>
              '${item.nombre} x${item.cantidad} (\$${item.subtotal.toStringAsFixed(2)})').join(' | ');
      buffer.writeln('"${venta.folio}","${venta.cliente}","${venta.vendedor}",'
          '"${venta.fechaFormateada}","${venta.metodoPago}","${venta.estado}",'
          '"${venta.total.toStringAsFixed(2)}","$productos"');
    }
    final bytes = utf8.encode(buffer.toString());
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'ventas_exportadas.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV descargado correctamente')),
    );
  }

  // ── PDF con logo y gráficas (descarga via dart:html) ────────────────────
  Future<void> _exportarPdf(List<Compra> ventas) async {
    if (ventas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay ventas para exportar')),
      );
      return;
    }

    try {
      final doc = pw.Document();

      pw.ImageProvider? logoImage;
      try {
        final data = await rootBundle.load('assets/images/logo.png');
        logoImage = pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {}

      const azul      = PdfColor.fromInt(0xFF1F4A7C);
      const azulClaro = PdfColor.fromInt(0xFFD5E8F0);
      const gris      = PdfColor.fromInt(0xFF888888);
      const grisClaro = PdfColor.fromInt(0xFFF2F2F2);
      const verde     = PdfColor.fromInt(0xFF1E8449);
      const naranja   = PdfColor.fromInt(0xFFE8A020);
      const morado    = PdfColor.fromInt(0xFF6C3483);
      const rojo      = PdfColor.fromInt(0xFFC0392B);

      final metodoColors = {
        'Efectivo': azul, 'Tarjeta': verde, 'Transferencia': naranja,
      };

      // Datos barras por día
      final ventasPorDia = <String, double>{};
      for (final v in ventas) {
        final f = v.fechaDate;
        if (f != null) {
          final dia = '${f.day.toString().padLeft(2,'0')}/${f.month.toString().padLeft(2,'0')}';
          ventasPorDia[dia] = (ventasPorDia[dia] ?? 0) + v.total;
        }
      }
      final diasOrdenados = ventasPorDia.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final maxBar = diasOrdenados.fold<double>(1, (m, e) => e.value > m ? e.value : m);

      // Datos pastel
      final porMetodo = <String, double>{};
      for (final v in ventas) {
        porMetodo[v.metodoPago] = (porMetodo[v.metodoPago] ?? 0) + v.total;
      }
      final totalGeneral = _calcularTotal(ventas);
      final pieEntries = porMetodo.entries.toList();
      final totalEfectivo = porMetodo['Efectivo'] ?? 0;
      final totalTarjeta  = porMetodo['Tarjeta']  ?? 0;

      final now = DateTime.now();
      final fechaReporte =
          '${now.day.toString().padLeft(2,'0')}-${now.month.toString().padLeft(2,'0')}-${now.year}';

      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: azul, width: 2))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(children: [
                if (logoImage != null)
                  pw.Image(logoImage, width: 44, height: 44)
                else
                  pw.Container(width: 44, height: 44,
                    decoration: const pw.BoxDecoration(color: azul,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
                    child: pw.Center(child: pw.Text('FS',
                        style: pw.TextStyle(color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold, fontSize: 16)))),
                pw.SizedBox(width: 10),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('FerreSmart', style: pw.TextStyle(fontSize: 16,
                      fontWeight: pw.FontWeight.bold, color: azul)),
                  pw.Text('Sistema de Punto de Venta',
                      style: const pw.TextStyle(fontSize: 8, color: gris)),
                ]),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('REPORTE DE VENTAS', style: pw.TextStyle(fontSize: 13,
                    fontWeight: pw.FontWeight.bold, color: azul)),
                pw.Text('Generado: $fechaReporte',
                    style: const pw.TextStyle(fontSize: 8, color: gris)),
              ]),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: azul, width: 1))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('FerreSmart — Reporte de Ventas',
                  style: const pw.TextStyle(fontSize: 8, color: gris)),
              pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: gris)),
            ],
          ),
        ),
        build: (ctx) => [
          // Tarjetas resumen
          pw.Row(children: [
            _tarjetaResumen('Total Ventas', '${ventas.length}', azul),
            pw.SizedBox(width: 8),
            _tarjetaResumen('Total MXN', '\$${totalGeneral.toStringAsFixed(2)}', verde),
            pw.SizedBox(width: 8),
            _tarjetaResumen('Efectivo', '\$${totalEfectivo.toStringAsFixed(2)}', naranja),
            pw.SizedBox(width: 8),
            _tarjetaResumen('Tarjeta', '\$${totalTarjeta.toStringAsFixed(2)}', morado),
          ]),
          pw.SizedBox(height: 20),

          // Título gráficas
          pw.Text('Análisis de Ventas', style: pw.TextStyle(fontSize: 13,
              fontWeight: pw.FontWeight.bold, color: azul)),
          pw.SizedBox(height: 4),
          pw.Divider(color: azul, thickness: 1),
          pw.SizedBox(height: 12),

          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            // Barras por día
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Ventas por Día (MXN)', style: pw.TextStyle(fontSize: 10,
                      fontWeight: pw.FontWeight.bold, color: azul)),
                  pw.SizedBox(height: 8),
                  if (diasOrdenados.isEmpty)
                    pw.Text('Sin datos', style: const pw.TextStyle(fontSize: 9, color: gris))
                  else
                    ...diasOrdenados.map((e) {
                      final pct = (maxBar > 0 ? e.value / maxBar : 0.0).clamp(0.0, 1.0);
                      // Barra de ancho fijo (200pt máximo)
                      final barMaxW = 160.0;
                      final barW = barMaxW * pct;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 7),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(e.key, style: const pw.TextStyle(fontSize: 8)),
                            pw.SizedBox(height: 2),
                            pw.Row(children: [
                              pw.SizedBox(
                                width: barMaxW,
                                height: 14,
                                child: pw.CustomPaint(
                                  painter: (canvas, size) {
                                    canvas.setFillColor(grisClaro);
                                    canvas.drawRRect(0, 0, size.x, 14, 3, 3);
                                    canvas.fillPath();
                                    if (barW > 0) {
                                      canvas.setFillColor(azul);
                                      canvas.drawRRect(0, 0, barW, 14, 3, 3);
                                      canvas.fillPath();
                                    }
                                  },
                                ),
                              ),
                              pw.SizedBox(width: 4),
                              pw.Text('\$${e.value.toStringAsFixed(0)}',
                                  style: pw.TextStyle(fontSize: 7,
                                      fontWeight: pw.FontWeight.bold, color: azul)),
                            ]),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            pw.SizedBox(width: 20),

            // Pastel método de pago
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Por Método de Pago', style: pw.TextStyle(fontSize: 10,
                      fontWeight: pw.FontWeight.bold, color: azul)),
                  pw.SizedBox(height: 8),
                  pw.SizedBox(
                    width: 110, height: 110,
                    child: pw.CustomPaint(
                      painter: (canvas, size) {
                        final cx = size.x / 2;
                        final cy = size.y / 2;
                        final r = size.x / 2 * 0.88;
                        final colors = [azul, verde, naranja, morado, rojo];
                        double start = -3.14159 / 2;
                        final tot = pieEntries.fold<double>(0.0, (s, e) => s + e.value);
                        for (int i = 0; i < pieEntries.length; i++) {
                          final sweep = tot > 0
                              ? (pieEntries[i].value / tot) * 2 * 3.14159
                              : 0.0;
                          canvas.setFillColor(colors[i % colors.length]);
                          canvas.moveTo(cx, cy);
                          canvas.bezierArc(
                            cx + r * _cosA(start), cy + r * _sinA(start),
                            r, r,
                            cx + r * _cosA(start + sweep), cy + r * _sinA(start + sweep),
                            large: sweep > 3.14159,
                          );
                          canvas.lineTo(cx, cy);
                          canvas.fillPath();
                          start += sweep;
                        }
                        canvas.setFillColor(PdfColors.white);
                        canvas.drawEllipse(cx, cy, r * 0.42, r * 0.42);
                        canvas.fillPath();
                      },
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...pieEntries.asMap().entries.map((entry) {
                    final colors = [azul, verde, naranja, morado, rojo];
                    final color = colors[entry.key % colors.length];
                    final pct = totalGeneral > 0
                        ? (entry.value.value / totalGeneral * 100).toStringAsFixed(1)
                        : '0';
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 3),
                      child: pw.Row(children: [
                        pw.Container(width: 10, height: 10,
                            decoration: pw.BoxDecoration(color: color,
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)))),
                        pw.SizedBox(width: 4),
                        pw.Expanded(child: pw.Text(entry.value.key,
                            style: const pw.TextStyle(fontSize: 8))),
                        pw.Text('$pct%', style: pw.TextStyle(fontSize: 8,
                            fontWeight: pw.FontWeight.bold, color: color)),
                      ]),
                    );
                  }),
                ],
              ),
            ),
          ]),
          pw.SizedBox(height: 24),

          // Tabla ventas
          pw.Text('Detalle de Ventas', style: pw.TextStyle(fontSize: 13,
              fontWeight: pw.FontWeight.bold, color: azul)),
          pw.SizedBox(height: 4),
          pw.Divider(color: azul, thickness: 1),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.2),
              1: const pw.FlexColumnWidth(1.8),
              2: const pw.FlexColumnWidth(1.8),
              3: const pw.FlexColumnWidth(1.6),
              4: const pw.FixedColumnWidth(70),
              5: const pw.FixedColumnWidth(75),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: azul),
                children: ['Folio','Cliente','Vendedor','Fecha','Método','Total MXN']
                    .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  child: pw.Text(h, style: pw.TextStyle(fontSize: 8,
                      fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                )).toList(),
              ),
              ...ventas.asMap().entries.map((entry) {
                final idx = entry.key;
                final v = entry.value;
                final metColor = metodoColors[v.metodoPago] ?? gris;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: idx % 2 == 0 ? PdfColors.white : grisClaro),
                  children: [
                    _celda(v.folio, size: 7),
                    _celda(v.cliente, size: 7),
                    _celda(v.vendedor, size: 7),
                    _celda(v.fechaFormateada, size: 7),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                        decoration: pw.BoxDecoration(color: metColor,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3))),
                        child: pw.Text(v.metodoPago, style: pw.TextStyle(fontSize: 7,
                            color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                      child: pw.Text('\$${v.total.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 7,
                              fontWeight: pw.FontWeight.bold, color: azul)),
                    ),
                  ],
                );
              }),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: azulClaro),
                children: [
                  _celda('TOTAL', bold: true, size: 8),
                  _celda('', size: 8), _celda('', size: 8),
                  _celda('${ventas.length} ventas', bold: true, size: 8),
                  _celda('', size: 8),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: pw.Text('\$${totalGeneral.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 8,
                            fontWeight: pw.FontWeight.bold, color: azul)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ));

      // Usar dart:html para descargar (igual que el CSV — esto SÍ funciona en Flutter Web)
      final pdfBytes = await doc.save();
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'reporte-ventas-$fechaReporte.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF descargado correctamente'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('ERROR PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  pw.Widget _tarjetaResumen(String label, String valor, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: pw.BoxDecoration(color: color,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
        child: pw.Column(children: [
          pw.Text(valor, style: pw.TextStyle(fontSize: 13,
              fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          pw.SizedBox(height: 3),
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)),
        ]),
      ),
    );
  }

  pw.Widget _celda(String text, {bool bold = false, double size = 7}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(text, style: pw.TextStyle(fontSize: size,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  double _cosA(double x) {
    double r = 1, t = 1;
    for (int i = 1; i <= 10; i++) { t *= -x * x / ((2*i-1)*(2*i)); r += t; }
    return r;
  }

  double _sinA(double x) {
    double r = x, t = x;
    for (int i = 1; i <= 10; i++) { t *= -x * x / ((2*i)*(2*i+1)); r += t; }
    return r;
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
                const Text('Productos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                if (venta.items.isEmpty)
                  const Text('No hay detalle de productos')
                else
                  ...venta.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Código: ${item.codigo}'),
                        Text('Cantidad: ${item.cantidad}'),
                        Text('Precio unitario: \$${item.precioUnitario.toStringAsFixed(2)}'),
                        Text('Subtotal: \$${item.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(color: Color(0xFF1F4A7C),
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  )),
                const SizedBox(height: 8),
                Text('Total: \$${venta.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        color: Color(0xFF1F4A7C), fontSize: 16)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
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
              return Center(child: Text('Error al cargar ventas:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)));
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
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(children: [
                      const Text('Total vendido',
                          style: TextStyle(fontSize: 15, color: Colors.black54)),
                      const SizedBox(height: 6),
                      Text('\$${totalVendido.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 26,
                              fontWeight: FontWeight.bold, color: Color(0xFF1F4A7C))),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Botones exportar
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportarCsv(ventas),
                        icon: const Icon(Icons.table_chart_outlined),
                        label: const Text('Exportar CSV'),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportarPdf(ventas),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Exportar PDF'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F4A7C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar por folio, cliente, método o vendedor',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true, fillColor: Colors.white,
                    ),
                    onChanged: (value) => setState(() => _search = value),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _metodoFiltro,
                        decoration: InputDecoration(labelText: 'Método de pago',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14))),
                        items: const [
                          DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                          DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                          DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                          DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
                        ],
                        onChanged: (value) => setState(() => _metodoFiltro = value ?? 'Todos'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => setState(() => _ordenDescendente = !_ordenDescendente),
                      icon: Icon(_ordenDescendente ? Icons.arrow_downward : Icons.arrow_upward),
                      tooltip: 'Ordenar por fecha',
                    ),
                  ]),
                  const SizedBox(height: 16),

                  Expanded(
                    child: ventas.isEmpty
                        ? ListView(children: const [
                            SizedBox(height: 120),
                            Center(child: Text('No se encontraron ventas')),
                          ])
                        : ListView.builder(
                            itemCount: ventas.length,
                            itemBuilder: (context, index) {
                              final venta = ventas[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFF1F4A7C).withOpacity(0.1),
                                    child: const Icon(Icons.point_of_sale_outlined,
                                        color: Color(0xFF1F4A7C)),
                                  ),
                                  title: Text('Folio: ${venta.folio}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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