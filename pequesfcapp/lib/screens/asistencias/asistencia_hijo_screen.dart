import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/player_model.dart';
import '../../providers/asistencia_provider.dart';
import 'detalle_asistencia_hijo_screen.dart';

class AsistenciaHijoScreen extends ConsumerWidget {
  final List<PlayerModel> hijos;

  const AsistenciaHijoScreen({Key? key, required this.hijos}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ListView.builder(
        itemCount: hijos.length,
        itemBuilder: (context, index) {
          final hijo = hijos[index];
          final asistenciasAsync = ref.watch(asistenciasPorJugadorProvider(hijo.id));
          return asistenciasAsync.when(
            loading: () => const ListTile(title: Text('Cargando asistencias...')),
            error: (e, _) => ListTile(title: Text('Error: $e')),
            data: (asistencias) {
              final totalAsistencias = asistencias.where((a) => a.presente == true && a.permiso != true).length;
              final totalFaltas = asistencias.where((a) => a.presente == false && a.permiso != true).length;
              final totalPermisos = asistencias.where((a) => a.permiso == true).length;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalleAsistenciaHijoScreen(
                          hijo: hijo,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        //poner foto del jugador si tiene, sino poner imagen por defecto jugador.png
                        CircleAvatar(
                          radius: 30,
                          backgroundImage:  AssetImage('assets/jugador.png'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${hijo.nombres} ${hijo.apellido}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              const SizedBox(height: 2),
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('categoria_equipo')
                                    .doc(hijo.categoriaEquipoId)
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Text('Cargando categoría...');
                                  }
                                  if (!snapshot.hasData || !snapshot.data!.exists) {
                                    return const Text('Categoría desconocida');
                                  }
                                  final data = snapshot.data!.data() as Map<String, dynamic>;
                                  return Text(
                                    'Categoría: ${data['categoria']} - ${data['equipo']}',
                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            //asistencias color verde, faltas color rojo, permisos color naranja
                            Text('Asistencias: $totalAsistencias', style: const TextStyle(fontSize: 12, color: Colors.green)),
                            Text('Faltas: $totalFaltas', style: const TextStyle(fontSize: 12, color: Colors.red)),
                            Text('Permisos: $totalPermisos', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                            const SizedBox(height: 4),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ],
                    ),
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