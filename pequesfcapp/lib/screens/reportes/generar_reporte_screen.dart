import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GenerarReporteScreen extends StatelessWidget {
  final String tipoReporte;
  final String filtro;

  const GenerarReporteScreen({Key? key, required this.tipoReporte, required this.filtro}) : super(key: key);

  Future<pw.Document> _generarPDF() async {
    final pdf = pw.Document();
    
    // Cargar el logo
    final logoImage = await imageFromAssetBundle('assets/peques.png');
    
    // Estilos comunes
    final titleStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.red900,
    );

    final subtitleStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.orange900,
    );

    // Función para crear el encabezado
    pw.Widget buildHeader(String title) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [PdfColors.red900, PdfColors.orange900],
            begin: pw.Alignment.topLeft,
            end: pw.Alignment.bottomRight,
          ),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        ),
        child: pw.Row(
          children: [
            pw.ClipOval(
              child: pw.Container(
                width: 60,
                height: 60,
                child: pw.Image(logoImage),
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Peques FC', 
                    style: pw.TextStyle(
                      fontSize: 28, 
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    )
                  ),
                  pw.Text(title, 
                    style: pw.TextStyle(
                      fontSize: 20,
                      color: PdfColors.white,
                    )
                  ),
                ],
              ),
            ),
            pw.Text(
              DateTime.now().toString().split(' ')[0],
              style: pw.TextStyle(color: PdfColors.white),
            ),
          ],
        ),
      );
    }

    // Estilo común para las tablas
    pw.Table tableBuilder(List<String> headers, List<List<String>> data) {
      return pw.TableHelper.fromTextArray(
        headers: headers,
        data: data,
        headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(
          color: PdfColors.red900,
        ),
        rowDecoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(
              color: PdfColors.grey300,
              width: 0.5,
            ),
          ),
        ),
        cellAlignment: pw.Alignment.center,
        cellPadding: const pw.EdgeInsets.all(8),
        cellStyle: const pw.TextStyle(fontSize: 12),
      );
    }

    // Configuración de página común
    pw.PageTheme pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.robotoRegular(),
        bold: await PdfGoogleFonts.robotoBold(),
      ),
      buildBackground: (context) => pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.orange900, width: 2),
        ),
      ),
    );

    if (tipoReporte == 'jugadores') {
      final snapshot = await FirebaseFirestore.instance.collection('jugadores').get();
      final jugadores = snapshot.docs.map((doc) => doc.data()).toList();

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader('Lista de Jugadores'),
              pw.SizedBox(height: 20),
              tableBuilder(
                ['Nombre', 'Apellido', 'CI', 'Categoría'],
                jugadores.map((j) => [
                  (j['nombres'] ?? '').toString(),
                  (j['apellido'] ?? '').toString(),
                  (j['ci'] ?? '').toString(),
                  (j['categoriaEquipoId'] ?? '').toString(),
                ]).toList(),
              ),
            ],
          ),
        ),
      );
    } else if (tipoReporte == 'jugadores_categoria') {
      final snapshot = await FirebaseFirestore.instance.collection('jugadores').get();
      final jugadores = snapshot.docs.map((doc) => doc.data()).toList();

      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader('Jugadores por Categoría'),
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
    } else if (tipoReporte == 'jugadores_categoria_equipo') {
      final snapshot = await FirebaseFirestore.instance.collection('jugadores').get();
      final jugadores = snapshot.docs.map((doc) => doc.data()).toList();

      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader('Jugadores por Categoría-Equipo'),
              pw.SizedBox(height: 20),
              ..._groupBy(jugadores, 'categoriaEquipoId').entries.map((entry) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Categoría-Equipo: ${entry.key}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.TableHelper.fromTextArray(
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
    } else if (tipoReporte == 'partidos_programados') {
      final snapshot = await FirebaseFirestore.instance.collection('partidos').get();
      final partidos = snapshot.docs.map((doc) => doc.data()).toList();

      partidos.sort((a, b) => (a['fecha'] ?? '').compareTo(b['fecha'] ?? ''));

      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader('Partidos Programados por Fecha'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Fecha', 'Equipo A', 'Equipo B', 'Lugar'],
                data: partidos.map((p) => [
                  p['fecha'] ?? '',
                  p['equipoA'] ?? '',
                  p['equipoB'] ?? '',
                  p['lugar'] ?? '',
                ]).toList(),
              ),
            ],
          ),
        ),
      );
    } else if (tipoReporte == 'resultados_fecha') {
      final snapshot = await FirebaseFirestore.instance.collection('resultados').get();
      final resultados = snapshot.docs.map((doc) => doc.data()).toList();

      resultados.sort((a, b) => (a['fecha'] ?? '').compareTo(b['fecha'] ?? ''));

      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader('Resultados por Fecha'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Fecha', 'Equipo A', 'Equipo B', 'Goles A', 'Goles B'],
                data: resultados.map((r) => [
                  r['fecha'] ?? '',
                  r['equipoA'] ?? '',
                  r['equipoB'] ?? '',
                  r['golesA']?.toString() ?? '',
                  r['golesB']?.toString() ?? '',
                ]).toList(),
              ),
            ],
          ),
        ),
      );
    } else if (tipoReporte == 'asistencias_equipo') {
      final snapshot = await FirebaseFirestore.instance.collection('asistencias').get();
      final asistencias = snapshot.docs.map((doc) => doc.data()).toList();

      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader('Asistencias por Equipo'),
              pw.SizedBox(height: 20),
              ..._groupBy(asistencias, 'equipoId').entries.map((entry) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Equipo: ${entry.key}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.TableHelper.fromTextArray(
                    headers: ['Fecha', 'Jugador', 'Estado'],
                    data: entry.value.map((a) => [
                      a['fecha'] ?? '',
                      a['jugadorNombre'] ?? '',
                      a['estado'] ?? '',
                    ]).toList(),
                  ),
                  pw.SizedBox(height: 12),
                ],
              )),
            ],
          ),
        ),
      );
    } else if (tipoReporte == 'asistencias_jugador') {
      final snapshot = await FirebaseFirestore.instance.collection('asistencias').get();
      final asistencias = snapshot.docs.map((doc) => doc.data()).toList();

      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader('Asistencias por Jugador'),
              pw.SizedBox(height: 20),
              ..._groupBy(asistencias, 'jugadorId').entries.map((entry) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Jugador: ${entry.key}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.TableHelper.fromTextArray(
                    headers: ['Fecha', 'Equipo', 'Estado'],
                    data: entry.value.map((a) => [
                      a['fecha'] ?? '',
                      a['equipoNombre'] ?? '',
                      a['estado'] ?? '',
                    ]).toList(),
                  ),
                  pw.SizedBox(height: 12),
                ],
              )),
            ],
          ),
        ),
      );
    } else if (tipoReporte == 'pagos_estado') {
      final snapshot = await FirebaseFirestore.instance.collection('pagos').get();
      final pagos = snapshot.docs.map((doc) => doc.data()).toList();

      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader('Pagos por Estado'),
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
    } else if (tipoReporte == 'pagos_jugador') {
      final snapshot = await FirebaseFirestore.instance.collection('pagos').get();
      final pagos = snapshot.docs.map((doc) => doc.data()).toList();

      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader('Pagos por Jugador'),
              pw.SizedBox(height: 20),
              ..._groupBy(pagos, 'jugadorId').entries.map((entry) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Jugador: ${entry.key}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.TableHelper.fromTextArray(
                    headers: ['Mes', 'Monto', 'Estado', 'Fecha'],
                    data: entry.value.map((p) => [
                      p['mes'] ?? '',
                      p['monto']?.toString() ?? '',
                      p['estado'] ?? '',
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
    } else if (tipoReporte == 'profesores') {
      final snapshot = await FirebaseFirestore.instance.collection('profesores').get();
      final profesores = snapshot.docs.map((doc) => doc.data()).toList();

      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader('Lista de Profesores'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Nombre', 'Apellido', 'CI', 'Celular', 'Categoría-Equipo'],
                data: profesores.map((p) => [
                  p['nombre'] ?? '',
                  p['apellido'] ?? '',
                  p['ci'] ?? '',
                  p['celular'] ?? '',
                  p['categoriaEquipoId'] ?? '',
                ]).toList(),
              ),
            ],
          ),
        ),
      );
    } else if (tipoReporte == 'apoderados') {
      final snapshot = await FirebaseFirestore.instance.collection('apoderados').get();
      final apoderados = snapshot.docs.map((doc) => doc.data()).toList();

      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader('Lista de Apoderados'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Nombre', 'Apellido', 'CI', 'Celular'],
                data: apoderados.map((a) => [
                  a['nombreCompleto'] ?? '',
                  a['apellido'] ?? '',
                  a['ci'] ?? '',
                  a['celular'] ?? '',
                ]).toList(),
              ),
            ],
          ),
        ),
      );
    } else {
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Center(
            child: pw.Text('Reporte: $tipoReporte'),
          ),
        ),
      );
    }
    return pdf;
  }

  // Agrupa una lista de mapas por una clave
  Map<String, List<Map<String, dynamic>>> _groupBy(List<Map<String, dynamic>> list, String key) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final item in list) {
      final groupKey = item[key]?.toString() ?? 'Sin asignar';
      map.putIfAbsent(groupKey, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Generar PDF'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generar y descargar PDF'),
              onPressed: () async {
                final pdf = await _generarPDF();
                await Printing.sharePdf(bytes: await pdf.save(), filename: '$tipoReporte.pdf');
              },
            ),
          ),
        ],
      ),
    );
  }
}