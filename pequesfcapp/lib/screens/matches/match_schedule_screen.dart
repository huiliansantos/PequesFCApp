import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/match_provider.dart';
import '../../models/match_model.dart';
import 'match_detail_screen.dart';
import 'match_form_screen.dart';

class MatchScheduleScreen extends ConsumerStatefulWidget {
  const MatchScheduleScreen({super.key});

  @override
  ConsumerState<MatchScheduleScreen> createState() => _MatchScheduleScreenState();
}

class _MatchScheduleScreenState extends ConsumerState<MatchScheduleScreen> {
  String? categoriaSeleccionada;

  Future<String> getCategoriaEquipoNombre(String categoriaEquipoId) async {
    if (categoriaEquipoId.isEmpty) return '';
    final doc = await FirebaseFirestore.instance
        .collection('categoria_equipo')
        .doc(categoriaEquipoId)
        .get();
    if (!doc.exists) return categoriaEquipoId;
    final data = doc.data()!;
    return '${data['categoria'] ?? ''} - ${data['equipo'] ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchesProvider);

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (partidos) {
        final categorias = partidos.map((p) => p.categoriaEquipoId).toSet().toList();

        final partidosFiltrados = partidos.where((partido) {
          return categoriaSeleccionada == null || partido.categoriaEquipoId == categoriaSeleccionada;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                value: categorias.contains(categoriaSeleccionada) ? categoriaSeleccionada : null,
                hint: const Text('Filtrar por categoría'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas')),
                  ...categorias.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                ],
                onChanged: (value) {
                  setState(() {
                    categoriaSeleccionada = value;
                  });
                },
              ),
            ),
            Expanded(
              child: partidosFiltrados.isEmpty
                  ? const Center(child: Text('No hay partidos para esta categoría.'))
                  : ListView.builder(
                      itemCount: partidosFiltrados.length,
                      itemBuilder: (context, index) {
                        final partido = partidosFiltrados[index];
                        return FutureBuilder<String>(
                          future: getCategoriaEquipoNombre(partido.categoriaEquipoId),
                          builder: (context, snapshot) {
                            final categoriaEquipoNombre = snapshot.data ?? partido.categoriaEquipoId;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MatchDetailScreen(match: partido),
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
                                            title: const Text('Modificar partido'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => MatchFormScreen(match: partido),
                                                ),
                                              );
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.delete, color: Colors.red),
                                            title: const Text('Eliminar partido'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('¿Eliminar partido?'),
                                                  content: const Text('¿Estás seguro de eliminar este partido?'),
                                                  actions: [
                                                    TextButton(
                                                      child: const Text('Cancelar'),
                                                      onPressed: () => Navigator.pop(context),
                                                    ),
                                                    TextButton(
                                                      child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                                      onPressed: () async {
                                                        Navigator.pop(context);
                                                        await ref.read(matchRepositoryProvider).deleteMatch(partido.id);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  leading: Image.asset(
                                    'assets/peques.png',
                                    width: 50,
                                    height: 50,
                                  ),
                                  title: Text(
                                    partido.equipoRival,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        categoriaEquipoNombre,
                                        style: const TextStyle(color: Colors.black87),
                                      ),
                                      Text(
                                        'Fecha: ${partido.fecha.day}/${partido.fecha.month}/${partido.fecha.year}  Hora: ${partido.hora}',
                                        style: const TextStyle(color: Colors.black54),
                                      ),
                                      Text(
                                        'Lugar: ${partido.cancha}',
                                        style: const TextStyle(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
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
  }
}