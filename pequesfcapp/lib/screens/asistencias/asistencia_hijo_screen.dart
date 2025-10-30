import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/player_model.dart';
import '../../models/categoria_equipo_model.dart';
import '../../providers/asistencia_provider.dart';
import '../../providers/categoria_equipo_provider.dart';  // Añadir este import
import 'detalle_asistencia_hijo_screen.dart';

class AsistenciaHijoScreen extends ConsumerWidget {
  final List<PlayerModel> hijos;

  const AsistenciaHijoScreen({Key? key, required this.hijos}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriasAsync = ref.watch(categoriasEquiposProvider);  // Usar el provider

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
                        const CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage('assets/jugador.png'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${hijo.nombres} ${hijo.apellido}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)
                              ),
                              const SizedBox(height: 2),
                              // Reemplazar FutureBuilder por AsyncValue de Riverpod
                              categoriasAsync.when(
                                loading: () => const Text('Cargando categoría...'),
                                error: (e, _) => const Text('Categoría desconocida'),
                                data: (categorias) {
                                  final categoria = categorias.firstWhere(
                                    (c) => c.id == hijo.categoriaEquipoId,
                                    orElse: () =>  CategoriaEquipoModel(
                                      id: '',
                                      categoria: 'Sin asignar',
                                      equipo: '',
                                    ),
                                  );
                                  return Text(
                                    'Categoría: ${categoria.categoria} - ${categoria.equipo}',
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
                            Text(
                              'Asistencias: $totalAsistencias',
                              style: const TextStyle(fontSize: 12, color: Colors.green)
                            ),
                            Text(
                              'Faltas: $totalFaltas',
                              style: const TextStyle(fontSize: 12, color: Colors.red)
                            ),
                            Text(
                              'Permisos: $totalPermisos',
                              style: const TextStyle(fontSize: 12, color: Colors.orange)
                            ),
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