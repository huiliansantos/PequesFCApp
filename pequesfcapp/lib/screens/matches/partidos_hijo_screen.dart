import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/player_model.dart';
import '../../models/match_model.dart';
import '../../providers/match_provider.dart';

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

class PartidosHijoScreen extends ConsumerWidget {
  final List<PlayerModel> hijos;

  const PartidosHijoScreen({Key? key, required this.hijos}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hijos.isEmpty) {
      return const Center(child: Text('No hay hijos registrados.'));
    }
    return ListView.builder(
      itemCount: hijos.length,
      itemBuilder: (context, index) {
        final hijo = hijos[index];
        final partidosAsync = ref.watch(partidosPorCategoriaEquipoProvider(hijo.categoriaEquipoId));
        return partidosAsync.when(
          loading: () => const ListTile(title: Text('Cargando partidos...')),
          error: (e, _) => ListTile(title: Text('Error: $e')),
          data: (partidos) {
            if (partidos.isEmpty) {
              return ListTile(
                leading: const Icon(Icons.sports_soccer, color: Color(0xFFD32F2F)),
                title: Text('${hijo.nombres} ${hijo.apellido}'),
                subtitle: const Text('No hay partidos programados para su equipo'),
              );
            }
            return Column(
              children: partidos.map((partido) => FutureBuilder<String>(
                future: getCategoriaEquipoNombre(partido.categoriaEquipoId),
                builder: (context, snapshot) {
                  final categoriaEquipoNombre = snapshot.data ?? partido.categoriaEquipoId;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Logo
                          Image.asset(
                            'assets/peques.png',
                            width: 60,
                            height: 60,
                          ),
                          const SizedBox(width: 16),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  partido.equipoRival,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  categoriaEquipoNombre,
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Fecha: ${partido.fecha.day}/${partido.fecha.month}/${partido.fecha.year}  Hora: ${partido.hora}',
                                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lugar: ${partido.cancha}',
                                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )).toList(),
            );
          },
        );
      },
    );
  }
}