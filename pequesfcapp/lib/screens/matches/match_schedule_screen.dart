import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/match_provider.dart';
import '../../models/match_model.dart';
import '../../models/resultado_model.dart';
import 'match_detail_screen.dart';
import 'match_form_screen.dart';

class MatchScheduleScreen extends ConsumerStatefulWidget {
  const MatchScheduleScreen({super.key});

  @override
  ConsumerState<MatchScheduleScreen> createState() =>
      _MatchScheduleScreenState();
}

class _MatchScheduleScreenState extends ConsumerState<MatchScheduleScreen> {
  String categoriaSeleccionada = 'Todas las categorias';

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

  String _normalizeId(dynamic v) {
    if (v == null) return '';
    return v.toString().trim();
  }

  bool _partidoHasResultadoForId(MatchModel partido, Set<String> partidosConResultado) {
    final pid = _normalizeId(partido.id);
    if (pid.isEmpty) return false;
    if (partidosConResultado.contains(pid)) return true;
    final pidLower = pid.toLowerCase();
    if (partidosConResultado.any((r) => r.toLowerCase() == pidLower)) return true;
    if (pid.length >= 8) {
      final tail = pid.substring(pid.length - 8);
      if (partidosConResultado.any((r) => r.endsWith(tail))) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error partidos: $e')),
        data: (partidos) {
          return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('resultados').snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error resultados: ${snap.error}'));
              }

              final resultados = snap.data?.docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final partidoIdRaw = (data['partidoId'] ??
                            data['matchId'] ??
                            data['matchID'] ??
                            '')
                        .toString();
                    final partidoId = partidoIdRaw.trim();
                    return ResultadoModel(
                      id: d.id,
                      partidoId: partidoId,
                      fecha: data['fecha'] is Timestamp
                          ? (data['fecha'] as Timestamp).toDate()
                          : (data['fecha'] is String
                              ? DateTime.tryParse(data['fecha'])
                              : null),
                      golesFavor: (data['golesFavor'] ?? data['golesA'] ?? 0) is int
                          ? (data['golesFavor'] ?? data['golesA'] ?? 0) as int
                          : int.tryParse((data['golesFavor'] ?? data['golesA'] ?? 0).toString()) ?? 0,
                      golesContra: (data['golesContra'] ?? data['golesB'] ?? 0) is int
                          ? (data['golesContra'] ?? data['golesB'] ?? 0) as int
                          : int.tryParse((data['golesContra'] ?? data['golesB'] ?? 0).toString()) ?? 0,
                      observaciones: (data['observaciones'] ?? data['observations'] ?? '').toString(),
                    );
                  }).toList() ??
                  <ResultadoModel>[];

              final partidosConResultado = resultados
                  .map((r) => _normalizeId(r.partidoId))
                  .where((id) => id.isNotEmpty)
                  .toSet();

              final partidosSinResultado = partidos
                  .where((p) => !_partidoHasResultadoForId(p, partidosConResultado))
                  .toList();

              final categoriasIds = partidosSinResultado
                  .map((p) => _normalizeId(p.categoriaEquipoId))
                  .toSet()
                  .toList();

              final partidosFiltrados = partidosSinResultado.where((partido) {
                if (categoriaSeleccionada == 'Todas las categorias') return true;
                return _normalizeId(partido.categoriaEquipoId) == _normalizeId(categoriaSeleccionada);
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cargamos las categorías desde Firestore y las mostramos como "categoria - equipo" ordenadas
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('categoria_equipo').get(),
                      builder: (context, catSnap) {
                        if (catSnap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (catSnap.hasError) {
                          return Center(child: Text('Error categorías: ${catSnap.error}'));
                        }

                        final docs = catSnap.data?.docs ?? [];
                        final Map<String, String> idToLabel = {
                          for (var d in docs)
                            d.id: '${(d.data() as Map<String, dynamic>)['categoria'] ?? ''}'
                                ' - ${(d.data() as Map<String, dynamic>)['equipo'] ?? ''}'
                        };

                        // Construye lista de pares (id, label) solo para los ids presentes en partidos
                        final idLabelPairs = categoriasIds
                            .map((id) => MapEntry(id, idToLabel[id]?.trim() ?? id))
                            .toList()
                          ..sort((a, b) => a.value.compareTo(b.value));

                        final validIds = idLabelPairs.map((e) => e.key).toList();
                        final valueToShow = (validIds.contains(categoriaSeleccionada) || categoriaSeleccionada == 'Todas las categorias')
                            ? categoriaSeleccionada
                            : 'Todas las categorias';

                        return DropdownButton<String>(
                          value: valueToShow,
                          hint: const Text('Filtrar por categoría'),
                          isExpanded: true,
                          items: <DropdownMenuItem<String>>[
                            const DropdownMenuItem(value: 'Todas las categorias', child: Text('Todas las categorias')),
                            ...idLabelPairs.map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value.isEmpty ? 'Sin asignar' : e.value),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              categoriaSeleccionada = value ?? 'Todas las categorias';
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Expanded(
                     child: partidosFiltrados.isEmpty
                        ? const Center(child: Text('No hay partidos pendientes \n (todos tienen resultados o no hay partidos).'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: partidosFiltrados.length,
                            itemBuilder: (context, index) {
                              final partido = partidosFiltrados[index];
                              return FutureBuilder<String>(
                                future: getCategoriaEquipoNombre(partido.categoriaEquipoId),
                                builder: (context, snapshot) {
                                  final categoriaEquipoNombre = snapshot.data ?? (partido.categoriaEquipoId ?? 'Sin asignar');

                                  // CARD con diseño solicitado
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    elevation: 4,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => MatchDetailScreen(match: partido)),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 18.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            //reducir el espacio arriba y abajo del nombre del torneo
                                            const SizedBox(height: 2),
                                            // Torneo title
                                            if (partido.torneo != null && partido.torneo!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 6.0),
                                                child: Text(
                                                  'Torneo: ${partido.torneo!}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFD32F2F),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            const Divider(color: Colors.black12, thickness: 1),
                                            const SizedBox(height: 2),
                                            // Middle row: left label + center time + right rival
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                // Left: categoria / equipo local (bold)
                                                Expanded(
                                                  child: Text(
                                                    categoriaEquipoNombre,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // home logo
                                                Image.asset('assets/peques.png',
                                                 width: 40, height: 40),
                                                const SizedBox(width: 8),
                                                // Time center
                                                Text(
                                                  partido.hora ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFF57C00),
                                                    fontSize: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Rival logo and name
                                                Image.asset('assets/rival.png', 
                                                width: 40, height: 40),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    partido.equipoRival ?? '',
                                                    textAlign: TextAlign.left,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            // Location row
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on, color: Color(0xFFD32F2F), size: 16),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    partido.cancha ?? '',
                                                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            // Date row
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today, color: Color(0xFFD32F2F), size: 16),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Fecha: ${_formatDateField(partido.fecha)}',
                                                  style: const TextStyle(fontSize: 13, color: Colors.black54),
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
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF57C00),
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchFormScreen()));
        },
      ),
    );
  }
}
