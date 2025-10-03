import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/asistencia_model.dart';
import '../../providers/asistencia_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/categoria_equipo_provider.dart';
import '../../models/categoria_equipo_model.dart';
import 'modificar_asistencia_screen.dart';

class RegistroAsistenciaScreen extends ConsumerStatefulWidget {
  final String categoriaEquipoId;
  final String entrenamientoId;
  final DateTime fecha;
  final String rol;

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
  final Map<String, bool> permisoMap = {};

  @override
  Widget build(BuildContext context) {
    final jugadoresAsync = ref.watch(playersProvider);
    final categoriaEquipoAsync = ref.watch(categoriasEquiposProvider);
    final asistenciasAsync = ref.watch(asistenciasPorEntrenamientoProvider(widget.entrenamientoId));

    final bool asistenciaYaRegistrada = jugadoresAsync.when(
      loading: () => false,
      error: (e, _) => false,
      data: (jugadores) {
        final asistencias = asistenciasAsync.value ?? [];
        final jugadoresFiltrados = jugadores.where((j) {
          final yaRegistrado = asistencias.any((a) =>
            a.jugadorId == j.id &&
            a.fecha.day == widget.fecha.day &&
            a.fecha.month == widget.fecha.month &&
            a.fecha.year == widget.fecha.year
          );
          return j.categoriaEquipoId == widget.categoriaEquipoId && !yaRegistrado;
        }).toList();
        return jugadoresFiltrados.isEmpty;
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Asistencia'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFD32F2F),
                Color(0xFFF57C00),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      
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
              return asistenciasAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (asistencias) {
                  // Filtra jugadores que NO tienen asistencia registrada para este entrenamiento y fecha
                  final jugadoresFiltrados = jugadores.where((j) {
                    final yaRegistrado = asistencias.any((a) =>
                      a.jugadorId == j.id &&
                      a.fecha.day == widget.fecha.day &&
                      a.fecha.month == widget.fecha.month &&
                      a.fecha.year == widget.fecha.year
                    );
                    return j.categoriaEquipoId == widget.categoriaEquipoId && !yaRegistrado;
                  }).toList();

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Equipo: ${categoriaEquipo.equipo}  |  Categoría: ${categoriaEquipo.categoria}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD32F2F),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Fecha: ${widget.fecha.day}/${widget.fecha.month}/${widget.fecha.year}  Hora: ${TimeOfDay.fromDateTime(widget.fecha).format(context)}',
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: jugadoresFiltrados.isEmpty
                          ? const Center(
                              child: Text(
                                '¡Toda la asistencia del día fue registrada!',
                                style: TextStyle(fontSize: 18, color: Colors.green),
                              ),
                            )
                          : ListView.builder(
                              itemCount: jugadoresFiltrados.length,
                              itemBuilder: (context, index) {
                                final jugador = jugadoresFiltrados[index];
                                final asistio = asistenciaMap[jugador.id] ?? false;
                                final permiso = permisoMap[jugador.id] ?? false;

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
                            ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      //para ir a ver asistencias


      floatingActionButton: (widget.rol == 'admin' || widget.rol == 'profesor')
        ? FloatingActionButton.extended(
            backgroundColor: const Color(0xFFD32F2F),
            icon: Icon(asistenciaYaRegistrada ? Icons.edit : Icons.save),
            label: Text(asistenciaYaRegistrada ? 'Modificar Asistencia' : 'Guardar Asistencia'),
            onPressed: () async {
              if (asistenciaYaRegistrada) {
                // Navegar a pantalla de modificar asistencia
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ModificarAsistenciaScreen(
                      categoriaEquipoId: widget.categoriaEquipoId,
                      entrenamientoId: widget.entrenamientoId,
                      fecha: widget.fecha,
                      rol: widget.rol,
                    ),
                  ),
                );
              } else {
                // Guardar asistencia (igual que antes)
                final jugadores = ref.read(playersProvider).value ?? [];
                final asistencias = ref.read(asistenciasPorEntrenamientoProvider(widget.entrenamientoId)).value ?? [];
                final jugadoresFiltrados = jugadores.where((j) {
                  final yaRegistrado = asistencias.any((a) =>
                    a.jugadorId == j.id &&
                    a.fecha.day == widget.fecha.day &&
                    a.fecha.month == widget.fecha.month &&
                    a.fecha.year == widget.fecha.year
                  );
                  return j.categoriaEquipoId == widget.categoriaEquipoId && !yaRegistrado;
                }).toList();
                final repo = ref.read(asistenciaRepositoryProvider);
                final horaRegistro = DateTime.now();
                for (final jugador in jugadoresFiltrados) {
                  final asistencia = AsistenciaModel(
                    id: const Uuid().v4(),
                    jugadorId: jugador.id,
                    entrenamientoId: widget.entrenamientoId,
                    categoriaEquipoId: widget.categoriaEquipoId,
                    fecha: widget.fecha,
                    presente: asistenciaMap[jugador.id] ?? false,
                    permiso: permisoMap[jugador.id] ?? false,
                    horaRegistro: horaRegistro,
                    observacion: null,
                  );
                  await repo.registrarAsistencia(asistencia);
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
          )
        : null,
    );
  }
}