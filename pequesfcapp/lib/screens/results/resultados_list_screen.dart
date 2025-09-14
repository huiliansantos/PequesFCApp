import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/resultado_provider.dart';
import '../../providers/match_provider.dart';
import '../../models/resultado_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/categoria_equipo_provider.dart';
import '../../models/match_model.dart';
import 'resultado_form_screen.dart';
import '../../models/categoria_equipo_model.dart';
import 'resultado_detail_screen.dart';

class ResultadosListScreen extends ConsumerStatefulWidget {
  const ResultadosListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ResultadosListScreen> createState() =>
      _ResultadosListScreenState();
}

class _ResultadosListScreenState extends ConsumerState<ResultadosListScreen> {
  String? categoriaSeleccionada;

  Future<String> getCategoriaEquipoNombre(String categoriaEquipoId) async {
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
    final resultadosAsync = ref.watch(resultadosStreamProvider);
    final partidosAsync = ref.watch(matchesProvider);

    return Scaffold(
      body: Column(
        children: [
          partidosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (partidos) {
              final categorias =
                  partidos.map((p) => p.categoriaEquipoId).toSet().toList();
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: DropdownButton<String>(
                  value: categoriaSeleccionada,
                  hint: const Text('Filtrar por categoría'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    ...categorias.map((cat) =>
                        DropdownMenuItem(value: cat, child: Text(cat))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      categoriaSeleccionada = value;
                    });
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
                    return const Center(
                        child: Text('No hay resultados registrados.'));
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
                    return categoriaSeleccionada == null ||
                        partido.categoriaEquipoId == categoriaSeleccionada;
                  }).toList();

                  if (resultadosFiltrados.isEmpty) {
                    return const Center(
                        child: Text('No hay resultados para esta categoría.'));
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
                      Color resultadoColor;
                      if (resultado.golesFavor > resultado.golesContra) {
                        resultadoColor = Colors.green;
                      } else if (resultado.golesFavor == resultado.golesContra) {
                        resultadoColor = Colors.amber;
                      } else {
                        resultadoColor = Colors.red;
                      }

                      return FutureBuilder<String>(
                        future: getCategoriaEquipoNombre(partido.categoriaEquipoId),
                        builder: (context, snapshot) {
                          final categoriaEquipoNombre = snapshot.data ?? partido.categoriaEquipoId;
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
                                    builder: (_) =>
                                        ResultadoDetailScreen(resultado: resultado),
                                  ),
                                );
                              },
                              onLongPress: () {
                                showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                  ),
                                  builder: (context) => Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.edit,
                                              color: Color(0xFFD32F2F)),
                                          title: const Text('Modificar resultado'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ResultadoFormScreen(
                                                    resultado: resultado),
                                              ),
                                            );
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.delete,
                                              color: Colors.red),
                                          title: const Text('Eliminar resultado'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            // Implementa la lógica de eliminación aquí
                                            // ref.read(resultadoRepositoryProvider).deleteResultado(resultado.id);
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
                                              fontSize: 10,
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
                                              fontSize: 10,
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
                                          'Fecha: ${partido.fecha.day}/${partido.fecha.month}/${partido.fecha.year}',
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