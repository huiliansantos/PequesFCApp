import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/asistencia_provider.dart';
import 'package:PequesFCApp/models/player_model.dart';
import '../../providers/player_provider.dart';

class VerListaAsistenciaScreen extends ConsumerStatefulWidget {
  final String categoriaEquipoId;

  const VerListaAsistenciaScreen({Key? key, required this.categoriaEquipoId})
      : super(key: key);

  @override
  ConsumerState<VerListaAsistenciaScreen> createState() =>
      _VerListaAsistenciaScreenState();
}

class _VerListaAsistenciaScreenState
    extends ConsumerState<VerListaAsistenciaScreen> {
  DateTime fechaSeleccionada = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final asistenciasAsync = ref
        .watch(asistenciasPorCategoriaEquipoProvider(widget.categoriaEquipoId));
    final jugadoresAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Asistencia'),
        //gradiente
        flexibleSpace: Container(
          decoration: const BoxDecoration(
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Fecha:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  '${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Cambiar'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fechaSeleccionada,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        fechaSeleccionada = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: asistenciasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (asistencias) {
                final asistenciasFiltradas = asistencias.where((a) {
                  final fecha = a.fecha;
                  return fecha.day == fechaSeleccionada.day &&
                      fecha.month == fechaSeleccionada.month &&
                      fecha.year == fechaSeleccionada.year;
                }).toList();

                return jugadoresAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (jugadores) {
                    if (asistenciasFiltradas.isEmpty) {
                      return const Center(
                        child: Text(
                            'No hay asistencia registrada para esta fecha.'),
                      );
                    }
                    return ListView.builder(
                      itemCount: asistenciasFiltradas.length,
                      itemBuilder: (context, index) {
                        final asistencia = asistenciasFiltradas[index];
                        final jugador = jugadores.firstWhere(
                          (j) => j.id == asistencia.jugadorId,
                          orElse: () => PlayerModel(
                            id: '',
                            nombres: 'Jugador',
                            apellido: '',
                            ci: '',
                            fechaDeNacimiento: DateTime(2000, 1, 1),
                            genero: '',
                            foto: '',
                            nacionalidad: '',
                            categoriaEquipoId: '',
                          ),
                        );
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          color: asistencia.presente == true
                              ? Colors.green[50]
                              : asistencia.permiso == true
                                  ? Colors.amber[50]
                                  : asistencia.presente == false &&
                                          asistencia.permiso == false
                                      ? Colors.red[50]
                                      : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  const AssetImage('assets/jugador.png'),
                            ),
                            title: Text(jugador != null
                                ? '${jugador.nombres} ${jugador.apellido}'
                                : 'Jugador'),
                            subtitle: Text(
                                jugador != null ? 'CI: ${jugador.ci}' : ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (asistencia.permiso == true)
                                  const Icon(Icons.assignment_turned_in,
                                      color: Colors.amber),
                                if (asistencia.presente == true)
                                  const Icon(Icons.check_circle,
                                      color: Colors.green),
                                if (asistencia.presente == false &&
                                    asistencia.permiso == false)
                                  const Icon(Icons.cancel, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                  asistencia.horaRegistro != null
                                      ? '${asistencia.horaRegistro.hour.toString().padLeft(2, '0')}:${asistencia.horaRegistro.minute.toString().padLeft(2, '0')}'
                                      : '',
                                  style: const TextStyle(fontSize: 12),
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
      ),
    );
  }
}
