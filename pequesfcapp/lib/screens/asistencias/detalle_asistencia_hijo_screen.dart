import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/player_model.dart';
import '../../providers/asistencia_provider.dart';

class DetalleAsistenciaHijoScreen extends ConsumerWidget {
  final PlayerModel hijo;

  const DetalleAsistenciaHijoScreen({Key? key, required this.hijo})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asistenciasAsync = ref.watch(asistenciasPorJugadorProvider(hijo.id));
    return Scaffold(
      //appbar con el degradado de la app
      appBar: AppBar(
        title: Text('Asistencia de ${hijo.nombres}'),
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
      body: asistenciasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (asistencias) {
          if (asistencias.isEmpty) {
            return const Center(child: Text('No hay asistencias registradas.'));
          }
          asistencias.sort((a, b) => b.fecha.compareTo(a.fecha));
          return ListView.builder(
            itemCount: asistencias.length,
            itemBuilder: (context, index) {
              final asistencia = asistencias[index];
              Color color;
              String texto;
              if (asistencia.permiso == true) {
                color = Colors.orange;
                texto = 'Permiso';
              } else if (asistencia.presente == true) {
                color = Colors.green;
                texto = 'Asistió';
              } else {
                color = Colors.red;
                texto = 'Faltó';
              }
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child:
                        const Icon(Icons.event_available, color: Colors.white),
                  ),
                  title: Text(
                      '${asistencia.fecha.day}/${asistencia.fecha.month}/${asistencia.fecha.year}'),
                  subtitle: Text(asistencia.observacion ?? '-'),
                  trailing: Chip(
                    label: Text(texto,
                        style: const TextStyle(color: Colors.white)),
                    backgroundColor: color,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
