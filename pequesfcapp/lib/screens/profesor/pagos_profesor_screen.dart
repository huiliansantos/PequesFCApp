import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/player_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/pago_provider.dart';

class PagosProfesorScreen extends ConsumerStatefulWidget {
  final String categoriaEquipoIdProfesor;

  const PagosProfesorScreen({Key? key, required this.categoriaEquipoIdProfesor}) : super(key: key);

  @override
  ConsumerState<PagosProfesorScreen> createState() => _PagosProfesorScreenState();
}

class _PagosProfesorScreenState extends ConsumerState<PagosProfesorScreen> {
  late String filtro;

  @override
  void initState() {
    super.initState();
    filtro = widget.categoriaEquipoIdProfesor;
  }

  @override
  Widget build(BuildContext context) {
    final categoriasStream = FirebaseFirestore.instance.collection('categoria_equipo').snapshots();
    final jugadoresAsync = ref.watch(playersProvider);

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
                            child: const Text('Mi equipo'),
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
            child: jugadoresAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (jugadores) {
                List<PlayerModel> jugadoresFiltrados;
                if (filtro == 'todos') {
                  jugadoresFiltrados = jugadores;
                } else {
                  jugadoresFiltrados = jugadores.where((j) => j.categoriaEquipoId == filtro).toList();
                }
                if (jugadoresFiltrados.isEmpty) {
                  return const Center(child: Text('No hay jugadores para mostrar.'));
                }
                return ListView.builder(
                  itemCount: jugadoresFiltrados.length,
                  itemBuilder: (context, index) {
                    final jugador = jugadoresFiltrados[index];
                    final pagosAsync = ref.watch(pagosPorJugadorProvider(jugador.id));
                    return pagosAsync.when(
                      loading: () => const ListTile(title: Text('Cargando pagos...')),
                      error: (e, _) => ListTile(title: Text('Error: $e')),
                      data: (pagos) {
                        final pagados = pagos.where((p) => p.estado == 'pagado').length;
                        final pendientes = pagos.where((p) => p.estado == 'pendiente').length;
                        final atrasados = pagos.where((p) => p.estado == 'atrasado').length;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: const AssetImage('assets/jugador.png') as ImageProvider,
                            ),
                            title: Text('${jugador.nombres} ${jugador.apellido}'),
                            subtitle: Text('Pagados: $pagados  Pendientes: $pendientes  Atrasados: $atrasados'),
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
      ),
    );
  }
}