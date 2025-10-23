import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/torneos_provider.dart';
import '../../models/torneo_model.dart';
import 'torneo_form_screen.dart';

class TorneoListScreen extends ConsumerWidget {
  const TorneoListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final torneosAsync = ref.watch(torneosProvider);

    return Scaffold(
      body: torneosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (torneos) {
          if (torneos.isEmpty) {
            return const Center(child: Text('No hay torneos registrados.'));
          }
          return ListView.builder(
            itemCount: torneos.length,
            itemBuilder: (context, index) {
              final torneo = torneos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.emoji_events, color: Color(0xFFD32F2F)),
                  title: Text(torneo.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Lugar: ${torneo.lugar}\nFecha: ${torneo.fecha.day}/${torneo.fecha.month}/${torneo.fecha.year}'),
                  onTap: () {
                    // Puedes mostrar detalles si lo deseas
                  },
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit, color: Color(0xFFD32F2F)),
                              title: const Text('Modificar'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TorneoFormScreen(torneo: torneo),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete, color: Colors.red),
                              title: const Text('Eliminar'),
                              onTap: () async {
                                Navigator.pop(context);
                                final confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Eliminar torneo'),
                                    content: const Text('¿Estás seguro de eliminar este torneo?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmar == true) {
                                  await FirebaseFirestore.instance
                                      .collection('torneos')
                                      .doc(torneo.id)
                                      .delete();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Torneo eliminado')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD32F2F),
        child: const Icon(Icons.add),
        tooltip: 'Registrar Torneo',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TorneoFormScreen()),
          );
        },
      ),
    );
  }
}