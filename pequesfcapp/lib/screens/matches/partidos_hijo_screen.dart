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

class PartidosHijoScreen extends ConsumerStatefulWidget {
  final List<PlayerModel> hijos;

  const PartidosHijoScreen({Key? key, required this.hijos}) : super(key: key);

  @override
  ConsumerState<PartidosHijoScreen> createState() => _PartidosHijoScreenState();
}

class _PartidosHijoScreenState extends ConsumerState<PartidosHijoScreen> {
  String filtro = 'mis_hijos'; // 'todos', 'mis_hijos', o categoriaEquipoId

  @override
  Widget build(BuildContext context) {
    // IDs de equipos de los hijos (solo válidos)
    final idsCategoriaHijos = widget.hijos
        .map((h) => h.categoriaEquipoId)
        .where((id) => id != null && id.isNotEmpty)
        .toSet()
        .toList();

    final partidosAsyncTodos = ref.watch(partidosProviderAll);
    final categoriasStream = FirebaseFirestore.instance.collection('categoria_equipo').snapshots();

    return Column(
      children: [
        // Filtro
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
                        const DropdownMenuItem(
                            value: 'mis_hijos', child: Text('Mis hijos')),
                        const DropdownMenuItem(
                            value: 'todos', child: Text('Todos')),
                        ...categorias.map((cat) => DropdownMenuItem(
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
        if (filtro == 'mis_hijos' && idsCategoriaHijos.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: Text('No tienes hijos asignados.')),
          ),
        if (!(filtro == 'mis_hijos' && idsCategoriaHijos.isEmpty))
          Expanded(
            child: partidosAsyncTodos.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (partidos) {
                // Filtrar partidos según filtro
                List<MatchModel> partidosFiltrados;
                if (filtro == 'todos') {
                  partidosFiltrados = partidos;
                } else if (filtro == 'mis_hijos') {
                  partidosFiltrados = partidos.where((partido) =>
                      idsCategoriaHijos.contains(partido.categoriaEquipoId)).toList();
                } else {
                  partidosFiltrados = partidos
                      .where((partido) => partido.categoriaEquipoId == filtro)
                      .toList();
                }

                // Ordenar por fecha descendente
                partidosFiltrados.sort((a, b) => b.fecha.compareTo(a.fecha));

                if (partidosFiltrados.isEmpty) {
                  return const Center(child: Text('No hay partidos programados.'));
                }

                return ListView.builder(
                  itemCount: partidosFiltrados.length,
                  itemBuilder: (context, index) {
                    final partido = partidosFiltrados[index];

                    // Buscar el hijo correspondiente a este partido
                    String? nombreHijo;
                    if (filtro == 'mis_hijos') {
                      final hijo = widget.hijos.firstWhere(
                        (h) => h.categoriaEquipoId == partido.categoriaEquipoId,
                        orElse: () => PlayerModel(
                          id: '',
                          nombres: '',
                          apellido: '',
                          categoriaEquipoId: '',
                          fechaDeNacimiento: DateTime(2000, 1, 1),
                          genero: '',
                          foto: '',
                          ci: '',
                          nacionalidad: '',
                        ),
                      );
                      if (hijo.id.isNotEmpty) {
                        nombreHijo = '${hijo.nombres} ${hijo.apellido}';
                      }
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
                                if (nombreHijo != null && nombreHijo.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      'Hijo: $nombreHijo',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                        fontSize: 13,
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
                                          fontSize: 13,
                                        ),
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
                );
              },
            ),
          ),
      ],
    );
  }
}
