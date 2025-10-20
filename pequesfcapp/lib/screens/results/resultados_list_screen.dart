import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/resultado_provider.dart';
import '../../providers/match_provider.dart';
import '../../models/match_model.dart';
import 'resultado_form_screen.dart';
import 'resultado_detail_screen.dart';

/// Provide a map of categoria_equipo documentId -> display label so the UI can
/// show human readable category/team labels; this defines the missing provider
/// `categoriaEquiposMapProvider` used in this screen.
final categoriaEquiposMapProvider = FutureProvider<Map<String, String>>((ref) async {
  final query = await FirebaseFirestore.instance.collection('categoria_equipo').get();
  final map = <String, String>{};
  for (final doc in query.docs) {
    final data = doc.data();
    final categoria = (data['categoria'] ?? '').toString();
    final equipo = (data['equipo'] ?? '').toString();
    final label = [
      if (categoria.isNotEmpty) categoria,
      if (equipo.isNotEmpty) equipo,
    ].join(' - ');
    map[doc.id] = label.isNotEmpty ? label : doc.id;
  }
  return map;
});

class ResultadosListScreen extends ConsumerStatefulWidget {
  const ResultadosListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ResultadosListScreen> createState() =>
      _ResultadosListScreenState();
}

class _ResultadosListScreenState extends ConsumerState<ResultadosListScreen> {
  String? categoriaSeleccionada;

  Future<String> getCategoriaEquipoNombre(String? categoriaEquipoId) async {
    final id = (categoriaEquipoId ?? '').trim();
    if (id.isEmpty) return 'Sin asignar';
    final doc = await FirebaseFirestore.instance
        .collection('categoria_equipo')
        .doc(id)
        .get();
    if (!doc.exists) return id;
    final data = doc.data();
    if (data == null) return id;
    final categoria = (data['categoria'] ?? '').toString();
    final equipo = (data['equipo'] ?? '').toString();
    final label = [
      if (categoria.isNotEmpty) categoria,
      if (equipo.isNotEmpty) equipo
    ].join(' - ');
    return label.isNotEmpty ? label : id;
  }

  String _formatDateField(dynamic fechaField) {
    if (fechaField == null) return 'Fecha no definida';
    if (fechaField is Timestamp) {
      final d = fechaField.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    if (fechaField is DateTime) {
      final d = fechaField;
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    if (fechaField is String) {
      final parsed = DateTime.tryParse(fechaField);
      if (parsed != null) {
        return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
      }
      return fechaField;
    }
    return fechaField.toString();
  }

  // Helper para eliminar resultado buscando por docId o por campo 'id'
  Future<void> _deleteResultadoById(BuildContext context, String resultadoId, String? partidoId) async {
    final col = FirebaseFirestore.instance.collection('resultados');
    final scaffold = ScaffoldMessenger.of(context);
    final idTrim = (resultadoId).trim();

    try {
      // 1) Intentar borrar asumiendo que resultadoId es el document ID
      if (idTrim.isNotEmpty) {
        final docRef = col.doc(idTrim);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          await docRef.delete();
          // opcional: desmarcar hasResult en partido
          if (partidoId != null && partidoId.isNotEmpty) {
            try {
              await FirebaseFirestore.instance.collection('partidos').doc(partidoId).update({'hasResult': false});
            } catch (_) {}
          }
          scaffold.showSnackBar(const SnackBar(content: Text('Resultado eliminado')));
          return;
        }
      }

      // 2) Si no existe documento con ese id, buscar documento(s) donde el campo 'id' == resultadoId
      if (idTrim.isNotEmpty) {
        final query = await col.where('id', isEqualTo: idTrim).get();
        if (query.docs.isNotEmpty) {
          for (final d in query.docs) {
            await col.doc(d.id).delete();
          }
          if (partidoId != null && partidoId.isNotEmpty) {
            try {
              await FirebaseFirestore.instance.collection('partidos').doc(partidoId).update({'hasResult': false});
            } catch (_) {}
          }
          scaffold.showSnackBar(const SnackBar(content: Text('Resultado eliminado')));
          return;
        }
      }

      // 3) No encontrado
      scaffold.showSnackBar(const SnackBar(content: Text('No se encontró el resultado para eliminar')));
    } catch (e) {
      scaffold.showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultadosAsync = ref.watch(resultadosStreamProvider);
    final partidosAsync = ref.watch(matchesProvider);
    final categoriasMapAsync = ref.watch(categoriaEquiposMapProvider);

    return Scaffold(
      body: Column(
        children: [
          partidosAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(child: Text('Error: $e')),
            ),
            data: (partidos) {
              // IDs de categorías presentes en los partidos
              final categoriasIds = partidos
                  .map((p) => p.categoriaEquipoId)
                  .where((id) => id.isNotEmpty)
                  .toSet()
                  .toList();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: categoriasMapAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error categorías: $e')),
                  data: (idToLabel) {
                    final idLabelPairs = categoriasIds
                        .map((id) => MapEntry(id, idToLabel[id]?.trim() ?? id))
                        .toList()
                      ..sort((a, b) => a.value.compareTo(b.value));

                    final valueToShow = idLabelPairs.any((e) => e.key == categoriaSeleccionada)
                        ? categoriaSeleccionada
                        : null;

                    return DropdownButton<String>(
                      value: valueToShow,
                      hint: const Text('Filtrar por categoría'),
                      isExpanded: true,
                      items: <DropdownMenuItem<String>>[
                        const DropdownMenuItem(value: null, child: Text('Todas las categorías')),
                        ...idLabelPairs.map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value.isEmpty ? 'Sin asignar' : e.value),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          categoriaSeleccionada = value;
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
          Expanded(
            child: resultadosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (resultados) => partidosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (partidos) {
                  if (resultados.isEmpty) {
                    return const Center(child: Text('No hay resultados registrados.'));
                  }

                  final resultadosFiltrados = resultados.where((resultado) {
                    final partido = partidos.firstWhere(
                      (p) => p.id == resultado.partidoId,
                      orElse: () => MatchModel(
                        id: '',
                        equipoRival: 'Desconocido',
                        cancha: '',
                        fecha: DateTime.now(),
                        hora: '',
                        torneo: '',
                        categoriaEquipoId: '',
                      ),
                    );
                    return categoriaSeleccionada == null || partido.categoriaEquipoId == categoriaSeleccionada;
                  }).toList();

                  if (resultadosFiltrados.isEmpty) {
                    return const Center(child: Text('No hay resultados para esta categoría.'));
                  }

                  return ListView.builder(
                    itemCount: resultadosFiltrados.length,
                    itemBuilder: (context, index) {
                      final resultado = resultadosFiltrados[index];
                      final partido = partidos.firstWhere(
                        (p) => p.id == resultado.partidoId,
                        orElse: () => MatchModel(
                          id: '',
                          equipoRival: 'Desconocido',
                          cancha: '',
                          fecha: DateTime.now(),
                          hora: '',
                          torneo: '',
                          categoriaEquipoId: '',
                        ),
                      );

                      // Calcula marcador y color
                      final marcador = '${resultado.golesFavor}-${resultado.golesContra}';
                      final gf = resultado.golesFavor;
                      final gc = resultado.golesContra;
                      Color resultadoColor;
                      if (gf > gc) {
                        resultadoColor = Colors.green;
                      } else if (gf == gc) {
                        resultadoColor = Colors.amber;
                      } else {
                        resultadoColor = Colors.red;
                      }

                      return FutureBuilder<String>(
                        future: getCategoriaEquipoNombre(partido.categoriaEquipoId),
                        builder: (context, snapshot) {
                          final categoriaEquipoNombre = snapshot.data ?? 'Sin asignar';
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 3,
                            color: Colors.white,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ResultadoDetailScreen(resultado: resultado),
                                  ),
                                );
                              },
                              onLongPress: () {
                                showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                  ),
                                  builder: (context) => Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.edit, color: Color(0xFFD32F2F)),
                                          title: const Text('Modificar resultado'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ResultadoFormScreen(resultado: resultado),
                                              ),
                                            );
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.delete, color: Colors.red),
                                          title: const Text('Eliminar resultado'),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            final confirmar = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Eliminar resultado'),
                                                content: const Text('¿Estás seguro de eliminar este resultado?'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                                                ],
                                              ),
                                            );
                                            if (confirmar != true) return;
                                            await _deleteResultadoById(context, resultado.id, resultado.partidoId);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (partido.torneo.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Text(
                                          partido.torneo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFD32F2F),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            categoriaEquipoNombre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Image.asset(
                                          'assets/peques.png',
                                          width: 40,
                                          height: 40,
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: resultadoColor,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            marcador,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Image.asset(
                                          'assets/rival.png',
                                          width: 40,
                                          height: 40,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            partido.equipoRival,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, color: Color(0xFFD32F2F), size: 14),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            partido.cancha,
                                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, color: Color(0xFFD32F2F), size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Fecha: ${_formatDateField(partido.fecha)}',
                                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}