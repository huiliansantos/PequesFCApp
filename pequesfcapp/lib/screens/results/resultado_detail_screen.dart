import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/resultado_model.dart';
import '../../models/match_model.dart';
import '../../providers/match_provider.dart';

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

class ResultadoDetailScreen extends ConsumerWidget {
  final ResultadoModel resultado;

  const ResultadoDetailScreen({Key? key, required this.resultado}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partidosAsync = ref.watch(matchesProvider);
    final categoriasMapAsync = ref.watch(categoriaEquiposMapProvider);

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
        title: const Text('Detalle de Resultado'),
      ),
      body: partidosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (partidos) {
          final partido = partidos.firstWhere(
            (p) => p.id == resultado.partidoId,
            orElse: () => MatchModel(
              id: '',
              equipoRival: 'Desconocido',
              fecha: DateTime.now(),
              cancha: 'Desconocida',
              torneo: 'Desconocido',
              categoriaEquipoId: 'Desconocida',
              hora: '00:00',
            ),
          );
          return categoriasMapAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (idToLabel) {
              final categoriaEquipoNombre = idToLabel[partido.categoriaEquipoId] ?? partido.categoriaEquipoId ?? 'Desconocida';
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/peques.png',
                              width: 60,
                              height: 60,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                partido != null
                                  ? 'vs ${partido.equipoRival}'
                                  : 'Partido desconocido',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD32F2F),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Resultado:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: resultado.golesFavor > resultado.golesContra
                                    ? Colors.green
                                    : resultado.golesFavor == resultado.golesContra
                                        ? Colors.orange
                                        : Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${resultado.golesFavor} - ${resultado.golesContra}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.calendar_today, color: Colors.teal),
                          title: const Text('Fecha'),
                          subtitle: Text(partido != null
                              ? '${partido.fecha.day}/${partido.fecha.month}/${partido.fecha.year}'
                              : 'Desconocida'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.sports_soccer, color: Colors.blue),
                          title: const Text('Cancha'),
                          subtitle: Text(partido.cancha ?? 'Desconocida'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.emoji_events, color: Colors.orange),
                          title: const Text('Torneo'),
                          subtitle: Text(partido.torneo ?? 'Desconocido'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.category, color: Colors.purple),
                          title: const Text('Categoría'),
                          subtitle: Text(categoriaEquipoNombre),
                        ),
                        if (resultado.observaciones.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.comment, color: Colors.red),
                            title: const Text('Observaciones'),
                            subtitle: Text(resultado.observaciones),
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
    );
  }
}