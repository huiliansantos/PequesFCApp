import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/asistencia_provider.dart';

class ReporteAsistenciaScreen extends ConsumerWidget {
  final String jugadorId;
  const ReporteAsistenciaScreen({Key? key, required this.jugadorId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asistenciasAsync = ref.watch(asistenciasPorJugadorProvider(jugadorId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Asistencia'),
        backgroundColor: const Color(0xFFD32F2F),
      ),
      body: asistenciasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (asistencias) => ListView.builder(
          itemCount: asistencias.length,
          itemBuilder: (context, index) {
            final asistencia = asistencias[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(
                  asistencia.presente ? Icons.check_circle : Icons.cancel,
                  color: asistencia.presente ? Colors.green : Colors.red,
                ),
                title: Text('Fecha: ${asistencia.fecha.day}/${asistencia.fecha.month}/${asistencia.fecha.year}'),
                subtitle: Text(asistencia.presente ? 'Presente' : 'Ausente'),
                trailing: asistencia.observacion != null
                    ? Icon(Icons.comment, color: Colors.blue)
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}