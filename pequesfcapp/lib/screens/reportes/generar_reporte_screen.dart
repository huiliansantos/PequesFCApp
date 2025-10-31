import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class GenerarReporteScreen extends StatelessWidget {
  final String tipoReporte;
  final String? filtros;

  const GenerarReporteScreen({
    Key? key,
    required this.tipoReporte,
    this.filtros,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generando reporte'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final pageTheme = await _buildTheme(format);
    Map<String, dynamic> filtrosMap = {};
    
    if (filtros != null && filtros!.isNotEmpty) {
      try {
        filtrosMap = json.decode(filtros!) as Map<String, dynamic>;
      } catch (e) {
        print('Error decodificando filtros: $e');
      }
    }

    if (tipoReporte == 'pagos_estado') {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('pagos');
      
      // Aplicar filtros si existen
      if (filtrosMap.containsKey('categoria')) {
        query = query.where('categoriaEquipoId', isEqualTo: filtrosMap['categoria']);
      }
      if (filtrosMap.containsKey('fechaInicio')) {
        final fechaInicio = DateTime.parse(filtrosMap['fechaInicio']);
        query = query.where('fechaPago', isGreaterThanOrEqualTo: fechaInicio);
      }
      if (filtrosMap.containsKey('fechaFin')) {
        final fechaFin = DateTime.parse(filtrosMap['fechaFin']);
        query = query.where('fechaPago', isLessThanOrEqualTo: fechaFin);
      }

      final pagosSnapshot = await query.get();
      final pagos = pagosSnapshot.docs.map((doc) => doc.data()).toList();

      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Pagos por Estado'),
              pw.SizedBox(height: 20),
              ..._groupBy(pagos, 'estado').entries.map((entry) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Estado: ${entry.key}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.TableHelper.fromTextArray(
                    headers: ['Jugador', 'Mes', 'Monto', 'Fecha'],
                    data: entry.value.map((p) => [
                      p['jugadorNombre'] ?? '',
                      p['mes'] ?? '',
                      p['monto']?.toString() ?? '',
                      p['fechaPago'] ?? '',
                    ]).toList(),
                  ),
                  pw.SizedBox(height: 12),
                ],
              )),
            ],
          ),
        ),
      );
    } 
    else if (tipoReporte == 'jugadores_categoria') {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('jugadores');
      
      if (filtrosMap.containsKey('categoria')) {
        query = query.where('categoriaEquipoId', isEqualTo: filtrosMap['categoria']);
      }

      final jugadoresSnapshot = await query.get();
      final jugadores = jugadoresSnapshot.docs.map((doc) => doc.data()).toList();

      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Jugadores por Categoría'),
              pw.SizedBox(height: 20),
              ..._groupBy(jugadores, 'categoria').entries.map((entry) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Categoría: ${entry.key}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  // ignore: deprecated_member_use
                  pw.Table.fromTextArray(
                    headers: ['Nombre', 'Apellido', 'CI'],
                    data: entry.value.map((j) => [
                      j['nombres'] ?? '',
                      j['apellido'] ?? '',
                      j['ci'] ?? '',
                    ]).toList(),
                  ),
                  pw.SizedBox(height: 12),
                ],
              )),
            ],
          ),
        ),
      );
    }
    // ...existing code for other report types...

    return pdf.save();
  }

  // ...existing helper methods...

  Map<String, List<Map<String, dynamic>>> _groupBy(List<Map<String, dynamic>> items, String key) {
    return {
      for (var item in items) item[key]: (items.where((i) => i[key] == item[key]).toList())
    };
  }

  pw.Widget _buildHeader(String title) {
    return pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold));
  }

  Future<pw.PageTheme> _buildTheme(PdfPageFormat format) async {
    return pw.PageTheme(
      pageFormat: format,
      // Add any additional theme properties here
    );
  }
}