import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/asistencia_model.dart';
import '../../providers/asistencia_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/gradient_button.dart';

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
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final jugadoresAsync = ref.watch(playersProvider);
    final asistenciasAsync = ref.watch(asistenciasPorEntrenamientoProvider(widget.entrenamientoId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modificar Asistencia'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: jugadoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (jugadores) {
          return asistenciasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (asistencias) {
              // Filtrar asistencias del día
              final asistenciasDelDia = asistencias.where((a) =>
                a.fecha.day == widget.fecha.day &&
                a.fecha.month == widget.fecha.month &&
                a.fecha.year == widget.fecha.year &&
                a.categoriaEquipoId == widget.categoriaEquipoId
              ).toList();

              // Inicializar mapas solo la primera vez
              if (!_initialized) {
                asistenciaMap.clear();
                permisoMap.clear();
                observacionMap.clear();
                
                for (final jugador in jugadores.where((j) => j.categoriaEquipoId == widget.categoriaEquipoId)) {
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
                _initialized = true;
              }

              final jugadoresFiltrados = jugadores
                  .where((j) => j.categoriaEquipoId == widget.categoriaEquipoId)
                  .toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Fecha: ${widget.fecha.day}/${widget.fecha.month}/${widget.fecha.year}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
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
                                const CircleAvatar(
                                  backgroundImage: AssetImage('assets/jugador.png'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${jugador.nombres} ${jugador.apellido}'),
                                      Text('CI: ${jugador.ci}', 
                                          style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
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
                                const SizedBox(width: 8),
                                Column(
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
      ),
      bottomNavigationBar: (widget.rol == 'admin' || widget.rol == 'profesor')
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: GradientButton(
                    onPressed: () async {
                      final repo = ref.read(asistenciaRepositoryProvider);
                      final jugadores = ref.read(playersProvider).value ?? [];
                      final asistenciasActuales = ref.read(asistenciasPorEntrenamientoProvider(widget.entrenamientoId)).value ?? [];

                      for (final jugador in jugadores.where((j) => j.categoriaEquipoId == widget.categoriaEquipoId)) {
                        final existing = asistenciasActuales.firstWhere(
                          (a) => a.jugadorId == jugador.id &&
                                a.fecha.day == widget.fecha.day &&
                                a.fecha.month == widget.fecha.month &&
                                a.fecha.year == widget.fecha.year,
                          orElse: () => AsistenciaModel(
                            id: '',
                            jugadorId: '',
                            entrenamientoId: '',
                            categoriaEquipoId: '',
                            fecha: DateTime.now(),
                            presente: false,
                            permiso: false,
                            horaRegistro: DateTime.now(),
                          ),
                        );

                        final asistencia = AsistenciaModel(
                          id: existing.id.isEmpty ? const Uuid().v4() : existing.id,
                          jugadorId: jugador.id,
                          entrenamientoId: widget.entrenamientoId,
                          categoriaEquipoId: widget.categoriaEquipoId,
                          fecha: widget.fecha,
                          presente: asistenciaMap[jugador.id] ?? false,
                          permiso: permisoMap[jugador.id] ?? false,
                          horaRegistro: existing.id.isEmpty ? DateTime.now() : existing.horaRegistro,
                          observacion: observacionMap[jugador.id],
                        );

                        await repo.registrarAsistencia(asistencia);
                      }

                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.save, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Guardar Cambios', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}