import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/categoria_equipo_model.dart';
import '../../providers/player_provider.dart';

class CategoriaEquipoDetailScreen extends ConsumerWidget {
  final CategoriaEquipoModel categoriaEquipo;

  const CategoriaEquipoDetailScreen({Key? key, required this.categoriaEquipo}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jugadoresAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Categoría-Equipo'),
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.category, color: Color(0xFFD32F2F)),
                  title: const Text('Categoría'),
                  subtitle: Text(categoriaEquipo.categoria),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.group, color: Colors.orange),
                  title: const Text('Equipo'),
                  subtitle: Text(categoriaEquipo.equipo),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.people, color: Colors.green),
                  title: Text('Jugadores'),
                ),
                jugadoresAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (jugadores) {
                    final jugadoresCategoria = jugadores
                        .where((j) => j.categoriaEquipoId == categoriaEquipo.id)
                        .toList();
                    if (jugadoresCategoria.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No hay jugadores registrados en esta categoría-equipo.'),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: jugadoresCategoria.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final jugador = jugadoresCategoria[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.person, color: Colors.green),
                          title: Text('${jugador.nombres} ${jugador.apellido}'),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}