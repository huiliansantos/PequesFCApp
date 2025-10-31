import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart'; // Add this import for PdfPageFormat
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class ReportesPdfPreviewScreen extends StatelessWidget {
  final String tipoReporte;
  final Map<String, dynamic>? filtros;

  const ReportesPdfPreviewScreen({
    Key? key,
    required this.tipoReporte,
    this.filtros,
  }) : super(key: key);

  Future<Uint8List> _loadAsset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // helper para formatear distintos tipos de fecha
    String _formatDate(dynamic f) {
      if (f == null) return '';
      try {
        if (f is Timestamp) return f.toDate().toString().split(' ')[0];
        if (f is DateTime) return f.toString().split(' ')[0];
        if (f is String) {
          // intenta parsear ISO, si falla devuelve la misma cadena (ya legible en muchos casos)
          try {
            final dt = DateTime.parse(f);
            return dt.toString().split(' ')[0];
          } catch (_) {
            return f;
          }
        }
        return f.toString();
      } catch (_) {
        return f.toString();
      }
    }

    // cargar logo (opcional)
    Uint8List? logoBytes;
    try {
      final data = await rootBundle.load('assets/peques.png');
      logoBytes = data.buffer.asUint8List();
    } catch (_) {
      logoBytes = null;
    }

    // cargar mapa categorias -> "Categoria - Equipo"
    final categoriasMap = <String, String>{};
    QuerySnapshot catSnap = await FirebaseFirestore.instance.collection('categoria_equipo').get();
    if (catSnap.docs.isEmpty) {
      catSnap = await FirebaseFirestore.instance.collection('categorias_equipos').get();
    }
    for (var d in catSnap.docs) {
      final m = Map<String, dynamic>.from(d.data() as Map);
      final nombreCat = (m['categoria'] ?? m['nombre'] ?? '').toString();
      final nombreEquipo = (m['equipo'] ?? m['nombreEquipo'] ?? m['team'] ?? '').toString();
      final label = [nombreCat, nombreEquipo].where((s) => s.isNotEmpty).join(' - ');
      categoriasMap[d.id] = label.isNotEmpty ? label : d.id;
    }

    // determinar label de categoria filtrada (para header)
    String categoriaFiltroLabel = '';
    if (filtros != null && filtros!['categoria'] != null) {
      final cid = filtros!['categoria'].toString();
      categoriaFiltroLabel = categoriasMap[cid] ?? cid;
    }

    final pw.Widget header = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logoBytes != null)
          pw.Container(width: 56, height: 56, child: pw.Image(pw.MemoryImage(logoBytes))),
        pw.SizedBox(width: 12),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('PEQUES FC', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text('Reporte: ${tipoReporte.replaceAll('_', ' ').toUpperCase()}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          if (categoriaFiltroLabel.isNotEmpty)
            pw.Text('Categoría-Equipo: $categoriaFiltroLabel', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
          pw.Text('Generado: ${now.toLocal()}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ])
      ],
    );

    // CASO: reportes de PAGOS
    if (tipoReporte == 'pagos_estado' || tipoReporte == 'pagos_jugador') {
      Query<Map<String, dynamic>> pagosQuery = FirebaseFirestore.instance.collection('pagos');

      if (filtros != null) {
        if (filtros!['categoria'] != null) {
          pagosQuery = pagosQuery.where('categoriaEquipoId', isEqualTo: filtros!['categoria']);
        }
        if (filtros!['jugador'] != null) {
          pagosQuery = pagosQuery.where('jugadorId', isEqualTo: filtros!['jugador']);
        }
        if (filtros!['fechaInicio'] != null) {
          final from = DateTime.parse(filtros!['fechaInicio']);
          pagosQuery = pagosQuery.where('fechaPago', isGreaterThanOrEqualTo: from);
        }
        if (filtros!['fechaFin'] != null) {
          final to = DateTime.parse(filtros!['fechaFin']);
          pagosQuery = pagosQuery.where('fechaPago', isLessThanOrEqualTo: to);
        }
      }

      final pagosSnap = await pagosQuery.get();
      final pagos = pagosSnap.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data() as Map);
        m['id'] = d.id;
        return m;
      }).toList();

      // cargar jugadores para datos personales
      final jugadoresSnap = await FirebaseFirestore.instance.collection('jugadores').get();
      final jugadoresMap = <String, Map<String, dynamic>>{};
      for (var d in jugadoresSnap.docs) {
        jugadoresMap[d.id] = Map<String, dynamic>.from(d.data() as Map);
      }

      // si no hay label de categoria y hay pagos, intentar inferir
      if (categoriaFiltroLabel.isEmpty && pagos.isNotEmpty) {
        final first = pagos.first;
        final catId = (first['categoriaEquipoId'] ?? jugadoresMap[first['jugadorId']]?['categoriaEquipoId'])?.toString();
        if (catId != null && categoriasMap.containsKey(catId)) categoriaFiltroLabel = categoriasMap[catId]!;
      }

      // construir filas
      final rows = pagos.map((p) {
        final jugador = jugadoresMap[p['jugadorId']] ?? {};
        final nombre = (jugador['nombres'] ?? jugador['nombre'] ?? jugador['nombreCompleto'] ?? '').toString().trim();
        final apellido = (jugador['apellido'] ?? jugador['apellidoPaterno'] ?? '').toString().trim();
        final displayName = (nombre + ' ' + apellido).trim();
        // fecha nacimiento (revisar posibles campos)
        final fn = jugador['fechaDeNacimiento'] ?? jugador['fechaNacimiento'] ?? jugador['fecha_nacimiento'] ?? jugador['fechaNacimiento'];
        final fechaNacimiento = _formatDate(fn);
        final nacionalidad = (jugador['nacionalidad'] ?? jugador['pais'] ?? '').toString();
        final fechaPago = _formatDate(p['fechaPago'] ?? p['fechaPagoString'] ?? p['fecha_pago']);
        final mes = p['mes']?.toString() ?? '';
        final monto = p['monto']?.toString() ?? '0';
        final estado = p['estado']?.toString() ?? '';
        return [displayName, fechaNacimiento, nacionalidad, fechaPago, mes, 'Bs. $monto', estado];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: format,
          header: (_) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: header),
          build: (context) => [
            pw.SizedBox(height: 6),
            pw.Table.fromTextArray(
              headers: ['Jugador', 'Fecha nacimiento', 'Nacionalidad', 'Fecha pago', 'Mes', 'Monto', 'Estado'],
              data: rows,
            ),
          ],
        ),
      );

    } else {
      // Otros reportes: jugadores / profesores / guardianes
      String collection = 'jugadores';
      if (tipoReporte == 'profesores') collection = 'profesores';
      if (tipoReporte == 'apoderados') collection = 'guardianes';

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(collection);
      if (filtros != null && filtros!['categoria'] != null && collection == 'jugadores') {
        query = query.where('categoriaEquipoId', isEqualTo: filtros!['categoria']);
      }

      final snap = await query.get();
      final docs = snap.docs.map((d) => Map<String, dynamic>.from(d.data() as Map)).toList();

      // construir filas según colección
      final rows = docs.map((data) {
        String apellido = '';
        String nombre = '';
        if (collection == 'jugadores') {
          apellido = (data['apellido'] ?? '').toString();
          nombre = (data['nombres'] ?? '').toString();
        } else if (collection == 'profesores') {
          apellido = (data['apellido'] ?? '').toString();
          nombre = (data['nombre'] ?? '').toString();
        } else if (collection == 'guardianes') {
          // guardianes tienen nombreCompleto
          nombre = (data['nombreCompleto'] ?? '').toString();
          // intentar separar apellido si no hay campo
          apellido = (data['apellido'] ?? '').toString();
        }

        final fn = data['fechaDeNacimiento'] ?? data['fechaNacimiento'] ?? data['fecha_nacimiento'] ?? data['fechaNacimiento'];
        final fechaNacimiento = _formatDate(fn);
        final nacionalidad = (data['nacionalidad'] ?? data['pais'] ?? '').toString();
        final categoriaId = (data['categoriaEquipoId'] ?? data['categoria'] ?? '').toString();
        final categoriaLabel = categoriaId.isNotEmpty ? (categoriasMap[categoriaId] ?? categoriaId) : '';

        return [apellido, nombre, fechaNacimiento, nacionalidad, categoriaLabel];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: format,
          header: (_) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: header),
          build: (context) => [
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Apellido', 'Nombre', 'Fecha nacimiento', 'Nacionalidad', 'Categoría - Equipo'],
              data: rows,
            ),
          ],
        ),
      );
    }

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista previa del reporte'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFF57C00)]),
          ),
        ),
      ),
      body: PdfPreview(
        build: (format) => _buildPdf(format),
      ),
    );
  }
}
