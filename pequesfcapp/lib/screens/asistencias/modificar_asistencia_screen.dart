import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/asistencia_model.dart';
import '../../providers/asistencia_provider.dart';
import '../../providers/player_provider.dart';

class ModificarAsistenciaScreen extends ConsumerStatefulWidget {
  final String categoriaEquipoId;
  final String entrenamientoId;
  final DateTime fecha;
  final String rol;

  const ModificarAsistenciaScreen({
    Key? key,
    required this.categoriaEquipoId,
    required this.entrenamientoId,
    required this.fecha,
    required this.rol,
  }) : super(key: key);

  @override
  ConsumerState<ModificarAsistenciaScreen> createState() => _ModificarAsistenciaScreenState();
}

class _ModificarAsistenciaScreenState extends ConsumerState<ModificarAsistenciaScreen> {
  final Map<String, bool> asistenciaMap = {};
  final Map<String, bool> permisoMap = {};
  final Map<String, String?> observacionMap = {};

  @override
  Widget build(BuildContext context) {
    final jugadoresAsync = ref.watch(playersProvider);
    final asistenciasAsync = ref.watch(asistenciasPorEntrenamientoProvider(widget.entrenamientoId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modificar Asistencia'),
        backgroundColor: const Color(0xFFD32F2F),
      ),
      body: jugadoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (jugadores) {
          return asistenciasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (asistencias) {
              final asistenciasDelDia = asistencias.where((a) =>
                a.fecha.day == widget.fecha.day &&
                a.fecha.month == widget.fecha.month &&
                a.fecha.year == widget.fecha.year &&
                a.categoriaEquipoId == widget.categoriaEquipoId
              ).toList();

              final jugadoresFiltrados = jugadores.where((j) => j.categoriaEquipoId == widget.categoriaEquipoId).toList();

              // Precarga los valores
              for (final jugador in jugadoresFiltrados) {
                final asistencia = asistenciasDelDia.firstWhere(
                  (a) => a.jugadorId == jugador.id,
                  orElse: () => AsistenciaModel(
                    id: '',
                    jugadorId: jugador.id,
                    entrenamientoId: widget.entrenamientoId,
                    categoriaEquipoId: widget.categoriaEquipoId,
                    fecha: widget.fecha,
                    presente: false,
                    permiso: false,
                    horaRegistro: DateTime.now(),
                    observacion: null,
                  ),
                );
                asistenciaMap[jugador.id] = asistencia.presente;
                permisoMap[jugador.id] = asistencia.permiso;
                observacionMap[jugador.id] = asistencia.observacion;
              }

              return ListView.builder(
                itemCount: jugadoresFiltrados.length,
                itemBuilder: (context, index) {
                  final jugador = jugadoresFiltrados[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundImage: const AssetImage('assets/jugador.png'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${jugador.nombres} ${jugador.apellido}'),
                                Text('CI: ${jugador.ci}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: permisoMap[jugador.id] ?? false,
                                  onChanged: (widget.rol == 'admin' || widget.rol == 'profesor')
                                      ? (value) {
                                          setState(() {
                                            permisoMap[jugador.id] = value ?? false;
                                            if (value == true) {
                                              asistenciaMap[jugador.id] = false;
                                            }
                                          });
                                        }
                                      : null,
                                  activeColor: Colors.amber,
                                ),
                                const Text('Permiso', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: asistenciaMap[jugador.id] ?? false,
                                  onChanged: (widget.rol == 'admin' || widget.rol == 'profesor')
                                      ? (value) {
                                          setState(() {
                                            asistenciaMap[jugador.id] = value ?? false;
                                            if (value == true) {
                                              permisoMap[jugador.id] = false;
                                            }
                                          });
                                        }
                                      : null,
                                  activeColor: Colors.green,
                                ),
                                const Text('Asistió', style: TextStyle(fontSize: 12)),
                              ],
                            ),
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
      floatingActionButton: (widget.rol == 'admin' || widget.rol == 'profesor')
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFD32F2F),
              icon: const Icon(Icons.save),
              label: const Text('Guardar Cambios'),
              onPressed: () async {
                final repo = ref.read(asistenciaRepositoryProvider);
                final jugadores = ref.read(playersProvider).value ?? [];
                for (final jugador in jugadores.where((j) => j.categoriaEquipoId == widget.categoriaEquipoId)) {
                  final asistencia = AsistenciaModel(
                    id: const Uuid().v4(), // Puedes usar el id existente si lo tienes
                    jugadorId: jugador.id,
                    entrenamientoId: widget.entrenamientoId,
                    categoriaEquipoId: widget.categoriaEquipoId,
                    fecha: widget.fecha,
                    presente: asistenciaMap[jugador.id] ?? false,
                    permiso: permisoMap[jugador.id] ?? false,
                    horaRegistro: DateTime.now(),
                    observacion: observacionMap[jugador.id],
                  );
                  await repo.registrarAsistencia(asistencia);
                }
                if (context.mounted) Navigator.pop(context);
              },
            )
          : null,
    );
  }
}