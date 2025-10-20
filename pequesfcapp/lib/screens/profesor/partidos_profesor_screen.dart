import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/match_provider.dart';

class PartidosProfesorScreen extends ConsumerStatefulWidget {
  final String categoriaEquipoIdProfesor;

  const PartidosProfesorScreen({Key? key, required this.categoriaEquipoIdProfesor}) : super(key: key);

  @override
  ConsumerState<PartidosProfesorScreen> createState() => _PartidosProfesorScreenState();
}

class _PartidosProfesorScreenState extends ConsumerState<PartidosProfesorScreen> {
  late String filtro;

  @override
  void initState() {
    super.initState();
    filtro = widget.categoriaEquipoIdProfesor; // Por defecto, el equipo del profesor
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

    // Selección del provider según filtro
    final partidosProvider = filtro == 'todos'
        ? partidosProviderAll
        : partidosPorCategoriaEquipoProvider(filtro);

    return Scaffold(
      body: Column(
        children: [
          // Dropdown de filtro
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
          // Lista de partidos
          Expanded(
            child: ref.watch(partidosProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (partidos) {
                if (partidos.isEmpty) {
                  return const Center(child: Text('No hay partidos programados.'));
                }
                partidos.sort((a, b) => b.fecha.compareTo(a.fecha));
                return ListView.builder(
                  itemCount: partidos.length,
                  itemBuilder: (context, index) {
                    final partido = partidos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
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
                                    fontSize: 16,
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
                                          fontSize: 15,
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
                                Text(
                                  partido.hora,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF57C00),
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Image.asset(
                                    'assets/rival.png',
                                    width: 32,
                                    height: 32,
                                  ),
                                Expanded(
                                  child: Text(
                                    partido.equipoRival,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Color(0xFFD32F2F), size: 18),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    partido.cancha,
                                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Color(0xFFD32F2F), size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  'Fecha: ${partido.fecha.day}/${partido.fecha.month}/${partido.fecha.year}',
                                  style: const TextStyle(color: Colors.black54, fontSize: 14),
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
        ],
      ),
    );
  }
}