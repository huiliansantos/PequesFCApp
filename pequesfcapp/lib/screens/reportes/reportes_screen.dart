import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'seleccionar_categoria_screen.dart';


class ReportesScreen extends StatelessWidget {
  const ReportesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reportes = [
      {'titulo': 'Jugadores', 'tipo': 'jugadores'},
      {'titulo': 'Profesores', 'tipo': 'profesores'},
      {'titulo': 'Apoderados', 'tipo': 'apoderados'},
      {'titulo': 'Asistencias', 'tipo': 'asistencias'},
      {'titulo': 'Pagos', 'tipo': 'pagos'},
    ];

    return Scaffold(
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
        title: const Text('Reportes PDF'),
      ),
      body: ListView(
        children: reportes
            .map((reporte) => ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(reporte['titulo']!),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FiltroReporteScreen(tipoReporte: reporte['tipo']!),
                      ),
                    );
                  },
                ))
            .toList(),
      ),
    );
  }
}

class FiltroReporteScreen extends StatelessWidget {
  final String tipoReporte;
  const FiltroReporteScreen({Key? key, required this.tipoReporte})
      : super(key: key);

  Future<pw.Document> _generarPDF(String tipoReporte, String filtro) async {
    final pdf = pw.Document();

    // Cargar el logo (ajusta la ruta en pubspec.yaml si es necesario)
    final logoImage = await imageFromAssetBundle('assets/peques.png');

    // Estilos comunes
    final titleStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.red900,
    );

    // Encabezado
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
                      )),
                  pw.Text(title,
                      style: pw.TextStyle(
                        fontSize: 20,
                        color: PdfColors.white,
                      )),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Tema de página
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

    pw.Widget _buildTable(List<String> headers, List<List<String>> data) {
      final columnWidths = <int, pw.FlexColumnWidth>{};
      for (var i = 0; i < headers.length; i++) {
        columnWidths[i] = pw.FlexColumnWidth(i == 0 ? 2 : 1);
      }

      return pw.Table.fromTextArray(
        headers: headers,
        data: data,
        headerStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        cellStyle: pw.TextStyle(fontSize: 10),
        headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
        cellAlignment: pw.Alignment.centerLeft,
        columnWidths: columnWidths,
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      );
    }

    // ------------------ Jugadores (incluye por_categoria_equipo) ------------------
    if (tipoReporte == 'jugadores') {
      final categoriasSnapshot = await FirebaseFirestore.instance
          .collection('categoria_equipo')
          .get();
      final categoriasMap = Map.fromEntries(
        categoriasSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final cat = (data['categoria'] ?? '').toString();
          final equipo = ((data['equipo'] ?? data['nombre']) ?? '').toString();
          final display = equipo.isNotEmpty ? '$cat - $equipo' : cat;
          return MapEntry(doc.id, display);
        }),
      );

      String formatDate(dynamic rawFecha) {
        if (rawFecha == null) return '';
        try {
          if (rawFecha is Timestamp) {
            return DateTime.fromMillisecondsSinceEpoch(
                    rawFecha.millisecondsSinceEpoch)
                .toIso8601String()
                .split('T')[0];
          }
          if (rawFecha is int) {
            return DateTime.fromMillisecondsSinceEpoch(rawFecha)
                .toIso8601String()
                .split('T')[0];
          }
          if (rawFecha is String) {
            final onlyDigits = RegExp(r'^\d+$');
            if (onlyDigits.hasMatch(rawFecha)) {
              final asInt = int.tryParse(rawFecha) ?? 0;
              final millis = rawFecha.length == 10 ? asInt * 1000 : asInt;
              return DateTime.fromMillisecondsSinceEpoch(millis)
                  .toIso8601String()
                  .split('T')[0];
            }
            final parsed = DateTime.tryParse(rawFecha);
            if (parsed != null) return parsed.toIso8601String().split('T')[0];
            return rawFecha.split('T').first;
          }
        } catch (_) {}
        return '';
      }

      final jugadoresSnapshot =
          await FirebaseFirestore.instance.collection('jugadores').get();
      final jugadoresRawDocs = jugadoresSnapshot.docs;

      final Map<String, List<Map<String, dynamic>>> playersByCatId = {};
      for (final doc in jugadoresRawDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final key = (data['categoriaEquipoId'] ?? '').toString();
        final list = playersByCatId.putIfAbsent(key, () => []);
        list.add({...data, '_id': doc.id});
      }

      if (filtro == 'por_categoria_equipo') {
        for (final entry in categoriasMap.entries) {
          final catId = entry.key;
          final display = entry.value;
          final players = playersByCatId[catId] ?? [];

          final tableData = players.map((j) {
            final nombres = (j['nombres'] ?? j['nombre'] ?? '').toString();
            final apellido = (j['apellido'] ?? '').toString();
            final ci = (j['ci'] ?? '').toString();
            final fechaStr =
                formatDate(j['fechaDeNacimiento'] ?? j['fechaNacimiento']);
            final categoriaEquipoNombre = display;
            return [nombres, apellido, ci, fechaStr, categoriaEquipoNombre];
          }).toList();

          pdf.addPage(
            pw.Page(
              pageTheme: pageTheme,
              build: (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildHeader('Jugadores - $display'),
                  pw.SizedBox(height: 12),
                  tableData.isEmpty
                      ? pw.Text('No hay jugadores en esta categoría-equipo.',
                          style: pw.TextStyle(fontSize: 12))
                      : _buildTable(
                          ['Nombre', 'Apellido', 'CI', 'Fecha Nac.', 'Categoría-Equipo'],
                          tableData,
                        ),
                  pw.SizedBox(height: 10),
                ],
              ),
            ),
          );
        }

        final unassigned = playersByCatId[''] ?? [];
        final others = playersByCatId.keys
            .where((k) => k.isNotEmpty && !categoriasMap.containsKey(k))
            .expand((k) => playersByCatId[k] ?? [])
            .toList();
        final remaining = [...unassigned, ...others];

        final remainingTable = remaining.map((j) {
          final nombres = (j['nombres'] ?? j['nombre'] ?? '').toString();
          final apellido = (j['apellido'] ?? '').toString();
          final ci = (j['ci'] ?? '').toString();
          final fechaStr =
              formatDate(j['fechaDeNacimiento'] ?? j['fechaNacimiento']);
          final catEquipoId = (j['categoriaEquipoId'] ?? '').toString();
          final categoriaEquipoNombre =
              categoriasMap[catEquipoId] ?? (j['categoria']?.toString() ?? 'Sin asignar');
          return [nombres, apellido, ci, fechaStr, categoriaEquipoNombre];
        }).toList();

        pdf.addPage(
          pw.Page(
            pageTheme: pageTheme,
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                buildHeader('Jugadores - Sin categoría-equipo asignada'),
                pw.SizedBox(height: 12),
                remainingTable.isEmpty
                    ? pw.Text('No hay jugadores sin categoría-equipo.',
                        style: pw.TextStyle(fontSize: 12))
                    : _buildTable(
                        ['Nombre', 'Apellido', 'CI', 'Fecha Nac.', 'Categoría-Equipo'],
                        remainingTable,
                      ),
              ],
            ),
          ),
        );
      } else {
        final List<List<String>> jugadoresTabla =
            jugadoresRawDocs.map((doc) {
          final j = doc.data() as Map<String, dynamic>;
          final nombres = (j['nombres'] ?? j['nombre'] ?? '').toString();
          final apellido = (j['apellido'] ?? '').toString();
          final ci = (j['ci'] ?? '').toString();
          final fechaStr =
              formatDate(j['fechaDeNacimiento'] ?? j['fechaNacimiento']);
          final categoriaEquipoId = (j['categoriaEquipoId'] ?? '').toString();
          final categoriaEquipoNombre =
              categoriasMap[categoriaEquipoId] ?? (j['categoria']?.toString() ?? 'Sin asignar');
          return [nombres, apellido, ci, fechaStr, categoriaEquipoNombre];
        }).toList();

        pdf.addPage(
          pw.Page(
            pageTheme: pageTheme,
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                buildHeader('Lista de Jugadores'),
                pw.SizedBox(height: 20),
                _buildTable(
                  ['Nombre', 'Apellido', 'CI', 'Fecha Nac.', 'Categoría-Equipo'],
                  jugadoresTabla,
                ),
              ],
            ),
          ),
        );
      }
    }

    // ------------------ Profesores ------------------
    else if (tipoReporte == 'profesores') {
      final profSnapshot =
          await FirebaseFirestore.instance.collection('profesores').get();
      final profDocs = profSnapshot.docs;

      String formatDateProf(dynamic raw) {
        if (raw == null) return '';
        try {
          if (raw is Timestamp) {
            return DateTime.fromMillisecondsSinceEpoch(raw.millisecondsSinceEpoch)
                .toIso8601String()
                .split('T')[0];
          }
          if (raw is int) {
            return DateTime.fromMillisecondsSinceEpoch(raw)
                .toIso8601String()
                .split('T')[0];
          }
          if (raw is String) {
            final onlyDigits = RegExp(r'^\d+$');
            if (onlyDigits.hasMatch(raw)) {
              final asInt = int.tryParse(raw) ?? 0;
              final millis = raw.length == 10 ? asInt * 1000 : asInt;
              return DateTime.fromMillisecondsSinceEpoch(millis)
                  .toIso8601String()
                  .split('T')[0];
            }
            final parsed = DateTime.tryParse(raw);
            if (parsed != null) return parsed.toIso8601String().split('T')[0];
            return raw.split('T').first;
          }
        } catch (_) {}
        return '';
      }

      final profesoresTabla = profDocs.map((doc) {
        final p = doc.data() as Map<String, dynamic>;
        final nombre = (p['nombres'] ?? p['nombre'] ?? '').toString();
        final apellido = (p['apellido'] ?? '').toString();
        final ci = (p['ci'] ?? p['dni'] ?? '').toString();
        final celular = (p['celular'] ?? p['telefono'] ?? '').toString();
        final fechaNac = formatDateProf(
            p['fechaNacimiento'] ?? p['fechaDeNacimiento'] ?? p['fecha_nacimiento']);
        return [nombre, apellido, ci, celular, fechaNac];
      }).toList();

      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader('Profesores'),
              pw.SizedBox(height: 12),
              profesoresTabla.isEmpty
                  ? pw.Text('No hay profesores registrados.',
                      style: pw.TextStyle(fontSize: 12))
                  : _buildTable(
                      ['Nombre', 'Apellido', 'CI', 'Celular', 'Fecha Nac.'],
                      profesoresTabla,
                    ),
            ],
          ),
        ),
      );
    }

    // ------------------ Apoderados ------------------
    else if (tipoReporte == 'apoderados') {
      final apoSnapshot =
          await FirebaseFirestore.instance.collection('guardianes').get();
      final apoDocs = apoSnapshot.docs;

      final jugadoresSnapshot =
          await FirebaseFirestore.instance.collection('jugadores').get();
      final jugadoresMap = Map.fromEntries(
        jugadoresSnapshot.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          final nombre =
              '${(data['nombres'] ?? data['nombre'] ?? '').toString()} ${(data['apellido'] ?? '').toString()}'
                  .trim();
          return MapEntry(d.id, nombre);
        }),
      );

      final apoderadosTabla = apoDocs.map((doc) {
        final a = doc.data() as Map<String, dynamic>;
        final nombreCompleto =(a['nombreCompleto']).toString();         
        final ci = (a['ci'] ?? a['dni'] ?? '').toString();
        final celular = (a['celular'] ?? a['telefono'] ?? '').toString();
        final usuario = (a['usuario'] ?? a['username'] ?? a['email'] ?? '').toString();
        final direccion = (a['direccion'] ?? a['domicilio'] ?? a['direccionCompleta'] ?? '').toString();
        return [nombreCompleto, ci, celular, usuario, direccion];
      }).toList();

      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader('Apoderados'),
              pw.SizedBox(height: 12),
              apoderadosTabla.isEmpty
                  ? pw.Text('No hay apoderados registrados.',
                      style: pw.TextStyle(fontSize: 12))
                  : _buildTable(
                      ['Nombre completo', 'CI', 'Celular', 'Usuario', 'Dirección'],
                      apoderadosTabla,
                    ),
            ],
          ),
        ),
      );
    }

    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    // Definir filtros según tipoReporte
    final List<Map<String, String>> filtros;
    if (tipoReporte == 'jugadores') {
      filtros = [
        {'titulo': 'Todos', 'filtro': 'todos'},
        {'titulo': 'Por categoría-equipo (todas las páginas)', 'filtro': 'por_categoria_equipo'},
        {'titulo': 'Por categoría (seleccionar)', 'filtro': 'por_categoria'},
      ];
    } else {
      filtros = [
        {'titulo': 'Generar (todos)', 'filtro': 'todos'},
      ];
    }

    return Scaffold(
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
        title: Text('Filtros - ${tipoReporte[0].toUpperCase()}${tipoReporte.substring(1)}'),
      ),
      body: ListView(
        children: filtros.map((f) {
          return ListTile(
            leading: const Icon(Icons.filter_alt),
            title: Text(f['titulo']!),
            trailing: const Icon(Icons.picture_as_pdf),
            onTap: () async {
              final selectedFiltro = f['filtro']!;
              // caso especial: seleccionar categoría -> navegar a pantalla de selección
              if (tipoReporte == 'jugadores' && selectedFiltro == 'por_categoria') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeleccionarCategoriaScreen(tipoReporte: tipoReporte, filtro: selectedFiltro),
                  ),
                );
                return;
              }

              // Mostrar indicador y generar PDF
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              try {
                final pdf = await _generarPDF(tipoReporte, selectedFiltro);
                Navigator.pop(context); // cerrar indicador
                await Printing.layoutPdf(onLayout: (format) => pdf.save());
              } catch (e) {
                Navigator.pop(context); // cerrar indicador
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al generar el reporte: $e')),
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }
}