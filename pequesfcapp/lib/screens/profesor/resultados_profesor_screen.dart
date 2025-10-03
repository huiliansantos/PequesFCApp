import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/resultado_model.dart';
import '../../models/match_model.dart';
import '../../providers/resultado_provider.dart';
import '../../providers/match_provider.dart';

class ResultadosProfesorScreen extends ConsumerStatefulWidget {
  final String categoriaEquipoIdProfesor;

  const ResultadosProfesorScreen({Key? key, required this.categoriaEquipoIdProfesor}) : super(key: key);

  @override
  ConsumerState<ResultadosProfesorScreen> createState() => _ResultadosProfesorScreenState();
}

class _ResultadosProfesorScreenState extends ConsumerState<ResultadosProfesorScreen> {
  late String filtro;

  @override
  void initState() {
    super.initState();
    filtro = widget.categoriaEquipoIdProfesor;
  }

  Future<String> getCategoriaEquipoNombre(String categoriaEquipoId) async {
    final doc = await FirebaseFirestore.instance
        .collection('categoria_equipo')
        .doc(categoriaEquipoId)
        .get();
    if (!doc.exists) return categoriaEquipoId;
    final data = doc.data()!;
    return '${data['categoria']} - ${data['equipo']}';
  }

  @override
  Widget build(BuildContext context) {
    final categoriasStream = FirebaseFirestore.instance.collection('categoria_equipo').snapshots();
    final resultadosAsync = ref.watch(resultadosStreamProvider);
    final partidosAsync = ref.watch(matchesProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: categoriasStream,
              builder: (context, snapshot) {
                final categorias = snapshot.hasData
                    ? snapshot.data!.docs
                        .map((d) => {
                              'id': d.id,
                              'nombre': '${d['categoria']} - ${d['equipo']}'
                            })
                        .toList()
                    : [];
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: filtro,
                        items: [
                          DropdownMenuItem(
                            value: widget.categoriaEquipoIdProfesor,
                            child: const Text('Mis equipos'),
                          ),
                          const DropdownMenuItem(
                            value: 'todos',
                            child: Text('Todos'),
                          ),
                          ...categorias
                              .where((cat) => cat['id'] != widget.categoriaEquipoIdProfesor)
                              .map((cat) => DropdownMenuItem(
                                    value: cat['id'],
                                    child: Text(cat['nombre']),
                                  )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            filtro = value!;
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: resultadosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (resultados) => partidosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (partidos) {
                  List<ResultadoModel> resultadosFiltrados;
                  if (filtro == 'todos') {
                    resultadosFiltrados = resultados;
                  } else {
                    resultadosFiltrados = resultados.where((resultado) {
                      final partido = partidos.firstWhere(
                        (p) => p.id == resultado.partidoId,
                        orElse: () => MatchModel(
                          id: '',
                          equipoRival: '',
                          cancha: '',
                          fecha: DateTime.now(),
                          hora: '',
                          torneo: '',
                          categoriaEquipoId: '',
                        ),
                      );
                      return partido.categoriaEquipoId == filtro;
                    }).toList();
                  }
                  resultadosFiltrados.sort((a, b) {
                    final partidoA = partidos.firstWhere((p) => p.id == a.partidoId, orElse: () => MatchModel(id: '', equipoRival: '', cancha: '', fecha: DateTime.now(), hora: '', torneo: '', categoriaEquipoId: ''));
                    final partidoB = partidos.firstWhere((p) => p.id == b.partidoId, orElse: () => MatchModel(id: '', equipoRival: '', cancha: '', fecha: DateTime.now(), hora: '', torneo: '', categoriaEquipoId: ''));
                    return partidoB.fecha.compareTo(partidoA.fecha);
                  });
                  if (resultadosFiltrados.isEmpty) {
                    return const Center(child: Text('No hay resultados para mostrar.'));
                  }
                  // ...tu Card de resultado aquí...
                  return ListView.builder(
                    itemCount: resultadosFiltrados.length,
                    itemBuilder: (context, index) {
                      final resultado = resultadosFiltrados[index];
                      final partido = partidos.firstWhere((p) => p.id == resultado.partidoId, orElse: () => MatchModel(id: '', equipoRival: '', cancha: '', fecha: DateTime.now(), hora: '', torneo: '', categoriaEquipoId: ''));
                      final marcador = '${resultado.golesFavor}-${resultado.golesContra}';
                      Color resultadoColor;
                      if (resultado.golesFavor > resultado.golesContra) {
                        resultadoColor = Colors.green;
                      } else if (resultado.golesFavor == resultado.golesContra) {
                        resultadoColor = Colors.amber;
                      } else {
                        resultadoColor = Colors.red;
                      }
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        color: Colors.white,
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
                                    child: FutureBuilder<String>(
                                      future: getCategoriaEquipoNombre(partido.categoriaEquipoId),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Text('Cargando...');
                                        }
                                        return Text(
                                          snapshot.data ?? partido.categoriaEquipoId,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Image.asset(
                                    'assets/peques.png',
                                    width: 32,
                                    height: 32,
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
                                    width: 32,
                                    height: 32,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      partido.equipoRival,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Color(0xFFD32F2F), size: 16),
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
                                  const Icon(Icons.calendar_today, color: Color(0xFFD32F2F), size: 16),
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