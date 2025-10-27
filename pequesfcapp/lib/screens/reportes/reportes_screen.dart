import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../repositories/asistencia_repository.dart';
import 'seleccionar_categoria_screen.dart';
import 'pdf_helper.dart';

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

class FiltroReporteScreen extends StatefulWidget {
  final String tipoReporte;
  const FiltroReporteScreen({Key? key, required this.tipoReporte})
      : super(key: key);

  @override
  State<FiltroReporteScreen> createState() => _FiltroReporteScreenState();
}

class _FiltroReporteScreenState extends State<FiltroReporteScreen> {
  DateTime? _from;
  DateTime? _to;

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _to = picked);
  }

  Future<pw.Document> _generarPDF(String tipoReporte, String filtro, DateTime? from, DateTime? to) async {
    final pdf = pw.Document();
    final repo = AsistenciaRepository();

    // Cargar recursos vía helper
    final logoImage = await loadImageFromAsset('assets/peques.png');

    // Intentar cargar fuentes; si falla usamos tema por defecto del helper
    pw.PageTheme pageTheme;
    try {
      final baseFont = await loadFontFromAsset('assets/fonts/Roboto-Regular.ttf');
      final boldFont = await loadFontFromAsset('assets/fonts/Roboto-Bold.ttf');
      pageTheme = defaultPageTheme(baseFont: baseFont, boldFont: boldFont);
    } catch (_) {
      pageTheme = defaultPageTheme();
    }

    // Formateo de fechas reutilizable
    String formatDate(dynamic rawFecha) {
      if (rawFecha == null) return '';
      try {
        if (rawFecha is Timestamp) {
          final dt = rawFecha.toDate();
          return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        }
        if (rawFecha is int) {
          final dt = DateTime.fromMillisecondsSinceEpoch(rawFecha);
          return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        }
        if (rawFecha is String) {
          final onlyDigits = RegExp(r'^\d+$');
          if (onlyDigits.hasMatch(rawFecha)) {
            final asInt = int.tryParse(rawFecha) ?? 0;
            final millis = rawFecha.length == 10 ? asInt * 1000 : asInt;
            final dt = DateTime.fromMillisecondsSinceEpoch(millis);
            return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          }
          final parsed = DateTime.tryParse(rawFecha);
          if (parsed != null) return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
          return rawFecha.split('T').first;
        }
      } catch (_) {}
      return '';
    }

    void _addPageWithTable(String title, List<String> headers, List<List<String>> rows) {
      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildPdfHeader(logoImage, title),
              pw.SizedBox(height: 12),
              rows.isEmpty
                  ? pw.Text('No hay registros.', style: const pw.TextStyle(fontSize: 12))
                  : buildPdfTable(headers, rows),
              pw.SizedBox(height: 10),
            ],
          ),
        ),
      );
    }

    // ------------------ Asistencias (usa AsistenciaRepository y filtros por fecha) ------------------
    if (tipoReporte == 'asistencias') {
      // cargar mapas de categorías y jugadores
      final categoriasSnapshot = await FirebaseFirestore.instance.collection('categoria_equipo').get();
      final categoriasMap = Map.fromEntries(
        categoriasSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final cat = (data['categoria'] ?? '').toString();
          final equipo = ((data['equipo'] ?? data['nombre']) ?? '').toString();
          final display = equipo.isNotEmpty ? '$cat - $equipo' : cat;
          return MapEntry(doc.id, display);
        }),
      );

      final jugadoresSnapshot = await FirebaseFirestore.instance.collection('jugadores').get();
      final jugadoresMap = <String, String>{};
      for (final d in jugadoresSnapshot.docs) {
        final data = d.data() as Map<String, dynamic>;
        final nombre = ((data['nombres'] ?? data['nombre']) ?? '').toString();
        final apellido = (data['apellido'] ?? '').toString();
        jugadoresMap[d.id] = (nombre + ' ' + apellido).trim();
      }

      // FILTRO: por categoría-equipo => por cada categoría solicitar asistencias por rango al repo
      if (filtro == 'por_categoria_equipo') {
        final allCatIds = categoriasMap.keys.toList()..sort();
        for (final catId in allCatIds) {
          final records = await repo.fetchByCategoriaEquipo(categoriaEquipoId: catId, from: from, to: to);
          if (records.isEmpty) {
            pdf.addPage(pw.Page(pageTheme: pageTheme, build: (ctx) {
              return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                buildPdfHeader(logoImage, 'Asistencias - ${categoriasMap[catId] ?? catId}'),
                pw.SizedBox(height: 12),
                pw.Text('No hay registros de asistencia para esta categoría en el rango seleccionado.', style: const pw.TextStyle(fontSize: 12)),
              ]);
            }));
            continue;
          }

          // Map jugadorId -> stats
          final Map<String, Map<String, int>> statsByPlayer = {};
          for (final r in records) {
            final jid = r.jugadorId;
            final present = r.presente ? 1 : 0;
            final entry = statsByPlayer.putIfAbsent(jid, () => {'sesiones': 0, 'asistencias': 0});
            entry['sesiones'] = entry['sesiones']! + 1;
            entry['asistencias'] = entry['asistencias']! + present;
          }

          final List<List<String>> rows = [];
          for (final entry in statsByPlayer.entries) {
            final jid = entry.key;
            final sesiones = entry.value['sesiones'] ?? 0;
            final asist = entry.value['asistencias'] ?? 0;
            final aus = sesiones - asist;
            final pct = sesiones == 0 ? 0 : ((asist / sesiones) * 100).round();
            final nombreJugador = jugadoresMap[jid] ?? jid;
            rows.add([nombreJugador, sesiones.toString(), asist.toString(), aus.toString(), '$pct%']);
          }

          _addPageWithTable('Asistencias - ${categoriasMap[catId] ?? catId}', ['Jugador', 'Sesiones', 'Asistencias', 'Ausencias', '%'], rows);
        }

        // incluir categoría "Sin asignar": buscar registros con categoria id vacío
        final sinAsignar = await repo.fetchByCategoriaEquipo(categoriaEquipoId: '', from: from, to: to);
        if (sinAsignar.isNotEmpty) {
          final Map<String, Map<String, int>> statsByPlayer = {};
          for (final r in sinAsignar) {
            final jid = r.jugadorId;
            final present = r.presente ? 1 : 0;
            final entry = statsByPlayer.putIfAbsent(jid, () => {'sesiones': 0, 'asistencias': 0});
            entry['sesiones'] = entry['sesiones']! + 1;
            entry['asistencias'] = entry['asistencias']! + present;
          }
          final List<List<String>> rows = [];
          for (final entry in statsByPlayer.entries) {
            final jid = entry.key;
            final sesiones = entry.value['sesiones'] ?? 0;
            final asist = entry.value['asistencias'] ?? 0;
            final aus = sesiones - asist;
            final pct = sesiones == 0 ? 0 : ((asist / sesiones) * 100).round();
            final nombreJugador = jugadoresMap[jid] ?? jid;
            rows.add([nombreJugador, sesiones.toString(), asist.toString(), aus.toString(), '$pct%']);
          }
          _addPageWithTable('Asistencias - Sin asignar', ['Jugador', 'Sesiones', 'Asistencias', 'Ausencias', '%'], rows);
        }
      }
      // FILTRO: por jugador => generar una página por jugador solicitando asistencias al repo
      else if (filtro == 'por_jugador') {
        // obtener lista de jugadores para iterar (puedes limitar si son muchos)
        final jugadoresSnapshotAll = await FirebaseFirestore.instance.collection('jugadores').get();
        for (final jd in jugadoresSnapshotAll.docs) {
          final jugadorId = jd.id;
          final records = await repo.fetchByJugador(jugadorId: jugadorId, from: from, to: to);
          if (records.isEmpty) continue;

          // ordenar por fecha asc
          records.sort((a, b) => a.fecha.compareTo(b.fecha));

          final List<List<String>> rows = records.map((r) {
            final catIds = r.categoriaEquipoId;
            final catDisplay = (catIds.isEmpty) ? 'Sin asignar' : (catIds.split(',').map((id) => categoriasMap[id] ?? id).join(', '));
            final estado = r.presente ? 'Presente' : 'Ausente';
            return [ '${r.fecha.day.toString().padLeft(2,'0')}/${r.fecha.month.toString().padLeft(2,'0')}/${r.fecha.year}', catDisplay, estado];
          }).toList();

          final sesiones = records.length;
          final asist = records.where((r) => r.presente).length;
          final aus = sesiones - asist;
          final pct = sesiones == 0 ? 0 : ((asist / sesiones) * 100).round();
          final nombreJugador = jugadoresMap[jugadorId] ?? jugadorId;
          final title = 'Asistencias - $nombreJugador';

          pdf.addPage(pw.Page(pageTheme: pageTheme, build: (ctx) {
            return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              buildPdfHeader(logoImage, title, subtitle: 'Sesiones: $sesiones — Asistencias: $asist — Ausencias: $aus — $pct%'),
              pw.SizedBox(height: 12),
              rows.isEmpty ? pw.Text('No hay registros.') : buildPdfTable(['Fecha', 'Categoría', 'Estado', 'Nota'], rows),
            ]);
          }));
        }
      }
    }

    // ------------------ Jugadores ------------------
    if (tipoReporte == 'jugadores') {
      final categoriasSnapshot = await FirebaseFirestore.instance.collection('categoria_equipo').get();
      final categoriasMap = Map.fromEntries(
        categoriasSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final cat = (data['categoria'] ?? '').toString();
          final equipo = ((data['equipo'] ?? data['nombre']) ?? '').toString();
          final display = equipo.isNotEmpty ? '$cat - $equipo' : cat;
          return MapEntry(doc.id, display);
        }),
      );

      final jugadoresSnapshot = await FirebaseFirestore.instance.collection('jugadores').get();
      final jugadoresRawDocs = jugadoresSnapshot.docs;

      // Agrupar jugadores por cada categoriaEquipoId (soporta "id1,id2")
      final Map<String, List<Map<String, dynamic>>> playersByCatId = {};
      for (final doc in jugadoresRawDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final rawKey = (data['categoriaEquipoId'] ?? '').toString();
        final ids = rawKey.isEmpty
            ? [''] // mantengo entrada para sin asignar
            : rawKey.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        for (final key in ids) {
          final list = playersByCatId.putIfAbsent(key, () => []);
          list.add({...data, '_id': doc.id});
        }
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
            final fechaStr = formatDate(j['fechaDeNacimiento'] ?? j['fechaNacimiento']);
            final categoriaEquipoNombre = display;
            return [nombres, apellido, ci, fechaStr, categoriaEquipoNombre];
          }).toList();

          _addPageWithTable('Jugadores - $display',
              ['Nombre', 'Apellido', 'CI', 'Fecha Nac.', 'Categoría-Equipo'], tableData);
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
          final fechaStr = formatDate(j['fechaDeNacimiento'] ?? j['fechaNacimiento']);
          final catEquipoId = (j['categoriaEquipoId'] ?? '').toString();
          final categoriaEquipoNombre = categoriasMap[catEquipoId] ?? (j['categoria']?.toString() ?? 'Sin asignar');
          return [nombres, apellido, ci, fechaStr, categoriaEquipoNombre];
        }).toList();

        _addPageWithTable('Jugadores - Sin categoría-equipo asignada',
            ['Nombre', 'Apellido', 'CI', 'Fecha Nac.', 'Categoría-Equipo'], remainingTable);
      } else {
        final List<List<String>> jugadoresTabla = jugadoresRawDocs.map((doc) {
          final j = doc.data() as Map<String, dynamic>;
          final nombres = (j['nombres'] ?? j['nombre'] ?? '').toString();
          final apellido = (j['apellido'] ?? '').toString();
          final ci = (j['ci'] ?? '').toString();
          final fechaStr = formatDate(j['fechaDeNacimiento'] ?? j['fechaNacimiento']);
          final categoriaEquipoId = (j['categoriaEquipoId'] ?? '').toString();
          final categoriaEquipoNombre = categoriasMap[categoriaEquipoId] ?? (j['categoria']?.toString() ?? 'Sin asignar');
          return [nombres, apellido, ci, fechaStr, categoriaEquipoNombre];
        }).toList();

        _addPageWithTable('Lista de Jugadores',
            ['Nombre', 'Apellido', 'CI', 'Fecha Nac.', 'Categoría-Equipo'], jugadoresTabla);
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

      _addPageWithTable('Profesores',
          ['Nombre', 'Apellido', 'CI', 'Celular', 'Fecha Nac.'], profesoresTabla);
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

      _addPageWithTable('Apoderados',
          ['Nombre completo', 'CI', 'Celular', 'Usuario', 'Dirección'], apoderadosTabla);
    }

    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    final tipoReporte = widget.tipoReporte;
    // Definir filtros según tipoReporte
    final List<Map<String, String>> filtros;
    if (tipoReporte == 'jugadores') {
      filtros = [
        {'titulo': 'Todos', 'filtro': 'todos'},
        {'titulo': 'Por categoría-equipo (todas las páginas)', 'filtro': 'por_categoria_equipo'},
        {'titulo': 'Por categoría (seleccionar)', 'filtro': 'por_categoria'},
      ];
    } else if (tipoReporte == 'asistencias') {
      filtros = [
        {'titulo': 'Por categoría-equipo', 'filtro': 'por_categoria_equipo'},
        {'titulo': 'Por jugador', 'filtro': 'por_jugador'},
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
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(_from == null ? 'Desde' : '${_from!.day}/${_from!.month}/${_from!.year}'),
                  onPressed: _pickFrom,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(_to == null ? 'Hasta' : '${_to!.day}/${_to!.month}/${_to!.year}'),
                  onPressed: _pickTo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...filtros.map((f) {
            return ListTile(
              leading: const Icon(Icons.filter_alt),
              title: Text(f['titulo']!),
              trailing: const Icon(Icons.picture_as_pdf),
              onTap: () async {
                final selectedFiltro = f['filtro']!;
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
                  final pdf = await _generarPDF(tipoReporte, selectedFiltro, _from, _to);
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
        ],
      ),
    );
  }
}