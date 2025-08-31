import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/asistencia_model.dart';
import '../../providers/asistencia_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/categoria_equipo_provider.dart';
import '../../models/categoria_equipo_model.dart';
//import '../../providers/usuario_provider.dart'; // Tu provider de usuario actual

class RegistroAsistenciaScreen extends ConsumerStatefulWidget {
  final String categoriaEquipoId;
  final String entrenamientoId;
  final DateTime fecha;
  final String rol; // <-- Nuevo parámetro

  const RegistroAsistenciaScreen({
    Key? key,
    required this.categoriaEquipoId,
    required this.entrenamientoId,
    required this.fecha,
    required this.rol,
  }) : super(key: key);

  @override
  ConsumerState<RegistroAsistenciaScreen> createState() => _RegistroAsistenciaScreenState();
}

class _RegistroAsistenciaScreenState extends ConsumerState<RegistroAsistenciaScreen> {
  final Map<String, bool> asistenciaMap = {};

  @override
  Widget build(BuildContext context) {
    final jugadoresAsync = ref.watch(playersProvider);
    final categoriaEquipoAsync = ref.watch(categoriasEquiposProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Asistencia'),
        backgroundColor: const Color(0xFFD32F2F),
      ),
      body: categoriaEquipoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (categoriasEquipos) {
          final categoriaEquipo = categoriasEquipos.firstWhere(
            (item) => item.id == widget.categoriaEquipoId,
            orElse: () => CategoriaEquipoModel(id: '', categoria: 'Sin asignar', equipo: ''),
          );

          return jugadoresAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (jugadores) {
              final jugadoresFiltrados = jugadores.where(
                (j) => j.categoriaEquipoId == widget.categoriaEquipoId
              ).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Equipo: ${categoriaEquipo.equipo}  |  Categoría: ${categoriaEquipo.categoria}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ),
                  Expanded(
                    child: jugadoresFiltrados.isEmpty
                      ? const Center(child: Text('No hay jugadores en este equipo.'))
                      : ListView.builder(
                          itemCount: jugadoresFiltrados.length,
                          itemBuilder: (context, index) {
                            final jugador = jugadoresFiltrados[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: (widget.rol == 'admin' || widget.rol == 'profesor')
                                ? CheckboxListTile(
                                    title: Text('${jugador.nombres} ${jugador.apellido}'),
                                    subtitle: Text('CI: ${jugador.ci}'),
                                    value: asistenciaMap[jugador.id] ?? false,
                                    onChanged: (value) {
                                      setState(() {
                                        asistenciaMap[jugador.id] = value ?? false;
                                      });
                                    },
                                    secondary: CircleAvatar(
                                      backgroundImage: const AssetImage('assets/jugador.png'),
                                    ),
                                  )
                                : ListTile(
                                    title: Text('${jugador.nombres} ${jugador.apellido}'),
                                    subtitle: Text('CI: ${jugador.ci}'),
                                    trailing: Icon(Icons.visibility, color: Colors.grey),
                                  ),
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
    );
  }
}