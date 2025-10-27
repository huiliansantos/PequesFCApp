import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class SeleccionarCategoriaScreen extends StatelessWidget {
  final String tipoReporte;
  final String filtro;

  const SeleccionarCategoriaScreen({Key? key, required this.tipoReporte, required this.filtro}) : super(key: key);

  Future<pw.Document> _generarPDF(String categoria) async {
    final pdf = pw.Document();
    
    // Cargar el logo
    final logoImage = await imageFromAssetBundle('assets/peques.png');
    
    // Estilos comunes
    final titleStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.red900,
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
                  pw.Text('Pequeños FC', 
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
          ],
        ),
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

    // Mapear categoria_equipo id -> "Categoria - Equipo"
    final categoriasSnapshot = await FirebaseFirestore.instance
        .collection('categoria_equipo')
        .orderBy('createdAt', descending: true) // <-- más reciente a más antiguo
        .get();
    final categoriasMap = Map.fromEntries(categoriasSnapshot.docs.map((doc) {
      final data = doc.data();
      final categoriaText = (data['categoria'] ?? '').toString();
      final equipoText = (data['equipo'] ?? data['nombre'] ?? '').toString();
      final display = equipoText.isNotEmpty ? '$categoriaText - $equipoText' : categoriaText;
      return MapEntry(doc.id, display);
    }));

    // Obtener jugadores de la categoría seleccionada
    final snapshot = await FirebaseFirestore.instance
        .collection('jugadores')
        .where('categoria', isEqualTo: categoria)
        .get();
    
    final jugadores = snapshot.docs.map((doc) {
      final data = doc.data();
      // Fecha de nacimiento en formato YYYY-MM-DD si es posible
      String fechaNac = '';
      final rawFecha = data['fechaDeNacimiento'] ?? data['fechaNacimiento'];
      if (rawFecha != null) {
        try {
          if (rawFecha is Timestamp) {
            fechaNac = DateTime.fromMillisecondsSinceEpoch(rawFecha.millisecondsSinceEpoch).toIso8601String().split('T')[0];
          } else if (rawFecha is int) {
            fechaNac = DateTime.fromMillisecondsSinceEpoch(rawFecha).toIso8601String().split('T')[0];
          } else if (rawFecha is String) {
            fechaNac = rawFecha.split('T').first;
          }
        } catch (_) {
          fechaNac = '';
        }
      }

      final categoriaEquipoId = data['categoriaEquipoId']?.toString();
      final categoriaEquipoNombre = (categoriaEquipoId != null && categoriasMap.containsKey(categoriaEquipoId))
          ? categoriasMap[categoriaEquipoId]!
          : (data['categoria']?.toString() ?? 'Sin asignar');

      return {
        'nombres': (data['nombres'] ?? '').toString(),
        'apellido': (data['apellido'] ?? '').toString(),
        'ci': (data['ci'] ?? '').toString(),
        'fechaNac': fechaNac,
        'categoriaEquipo': categoriaEquipoNombre,
      };
    }).toList();

    // Construir la tabla de datos
    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            buildHeader('Jugadores - $categoria'),
            pw.SizedBox(height: 20),
            _buildTable(
              ['Nombre', 'Apellido', 'CI', 'Fecha Nac.', 'Categoría-Equipo'],
              jugadores.map((j) => [
                j['nombres'] ?? '',
                j['apellido'] ?? '',
                j['ci'] ?? '',
                j['fechaNac'] ?? '',
                j['categoriaEquipo'] ?? '',
              ]).toList(),
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  pw.Widget _buildTable(List<String> headers, List<List<String>> data) {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('categoria_equipo').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final categorias = snapshot.data!.docs.map((doc) => doc['categoria'].toString()).toSet().toList();
        categorias.sort();
        
        return Scaffold(
          appBar: AppBar(
            //degradado de colores en el AppBar
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: const Text('Selecciona Categoría')),
          body: ListView(
            children: categorias.map((cat) => ListTile(
              title: Text(cat),
              trailing: const Icon(Icons.picture_as_pdf),
              onTap: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  final pdf = await _generarPDF(cat);
                  Navigator.pop(context); // Cierra el diálogo de progreso
                  await Printing.layoutPdf(
                    onLayout: (format) => pdf.save(),
                  );
                } catch (e) {
                  Navigator.pop(context); // Cierra el diálogo de progreso
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al generar el reporte: $e')),
                  );
                }
              },
            )).toList(),
          ),
        );
      },
    );
  }
}