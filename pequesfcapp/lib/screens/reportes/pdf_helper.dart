import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Carga una imagen desde assets y devuelve un pw.MemoryImage para usar en el pdf.
Future<pw.MemoryImage> loadImageFromAsset(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  return pw.MemoryImage(data.buffer.asUint8List());
}

/// Carga una fuente TTF desde assets y la convierte a pw.Font.
Future<pw.Font> loadFontFromAsset(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final byteData = await data.buffer.asByteData();
  return pw.Font.ttf(byteData);
}

/// Construye un PageTheme consistente (A4). Si no se pasan fuentes se usa el PageTheme por defecto.
pw.PageTheme defaultPageTheme({pw.Font? baseFont, pw.Font? boldFont}) {
  final theme = (baseFont != null)
      ? pw.ThemeData.withFont(base: baseFont, bold: boldFont ?? baseFont)
      : null;

  return pw.PageTheme(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(20),
    theme: theme,
    buildBackground: (context) => pw.Container(
      // borde sutil para consistencia visual
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.orange900, width: 1),
      ),
    ),
  );
}

/// Construye el header (logo + títulos) reutilizable en los PDFs.
pw.Widget buildPdfHeader(pw.ImageProvider logoImage, String title, {String? subtitle}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      gradient: pw.LinearGradient(
        colors: [PdfColors.red900, PdfColors.orange900],
        begin: pw.Alignment.topLeft,
        end: pw.Alignment.bottomRight,
      ),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.ClipOval(child: pw.Container(width: 56, height: 56, child: pw.Image(logoImage))),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Peques FC', style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text(title, style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
              if (subtitle != null) pw.Text(subtitle, style: pw.TextStyle(color: PdfColors.white, fontSize: 9)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Genera una tabla a partir de headers y filas (cada fila es List<String>).
pw.Widget buildPdfTable(List<String> headers, List<List<String>> rows) {
  return pw.Table.fromTextArray(
    headers: headers,
    data: rows,
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
    cellStyle: const pw.TextStyle(fontSize: 9),
    cellAlignment: pw.Alignment.centerLeft,
    columnWidths: {0: const pw.FlexColumnWidth()},
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
  );
}

/// Guarda y comparte/imprime el PDF (usa package printing).
Future<void> sharePdfDocument(pw.Document pdf, String filename) async {
  final bytes = await pdf.save();
  await Printing.sharePdf(bytes: bytes, filename: filename);
}

/// Atajo para devolver bytes del pdf (útil si quieres enviar a servidor o guardar en archivo).
Future<List<int>> pdfToBytes(pw.Document pdf) async {
  return pdf.save();
}