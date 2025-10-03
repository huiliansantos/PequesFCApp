import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/player_model.dart';
import '../../providers/player_provider.dart';

class JugadoresProfesorScreen extends ConsumerStatefulWidget {
  final String categoriaEquipoIdProfesor;

  const JugadoresProfesorScreen({Key? key, required this.categoriaEquipoIdProfesor}) : super(key: key);

  @override
  ConsumerState<JugadoresProfesorScreen> createState() => _JugadoresProfesorScreenState();
}

class _JugadoresProfesorScreenState extends ConsumerState<JugadoresProfesorScreen> {
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
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        //que cargue la foto si tiene, sino un icono de que esta en la carpeta assets de nombre jugador.png
                        leading:const CircleAvatar(
                                backgroundImage: AssetImage('assets/jugador.png'),
                              ),
                        title: Text('${jugador.nombres} ${jugador.apellido}'),
                        subtitle: Text('CI: ${jugador.ci}'),
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