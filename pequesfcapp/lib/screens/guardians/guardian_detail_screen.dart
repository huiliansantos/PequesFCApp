import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/guardian_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/guardian_provider.dart';
import 'guardian_form_screen.dart';

class GuardianDetailScreen extends ConsumerWidget {
  final String guardianId;

  const GuardianDetailScreen({Key? key, required this.guardianId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardianAsync = ref.watch(guardianByIdProvider(guardianId));
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle Apoderado'),
        actions: [
          guardianAsync.when(
            loading: () => const SizedBox(),
            error: (e, _) => const SizedBox(),
            data: (guardian) => IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar Apoderado',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GuardianFormScreen(guardian: guardian),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.red[200],
                      child: const Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: guardianAsync.when(
                        loading: () => const Text(
                          'Cargando...',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        error: (e, _) => Text(
                          'Error: $e',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        data: (guardian) => Text(
                          guardian?.nombreCompleto ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                guardianAsync.when(
                  loading: () => const ListTile(
                    leading: Icon(Icons.badge, color: Colors.blue),
                    title: Text('Carnet de Identidad'),
                    subtitle: Text('Cargando...'),
                  ),
                  error: (e, _) => ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: const Text('Carnet de Identidad'),
                    subtitle: Text('Error: $e'),
                  ),
                  data: (guardian) => ListTile(
                    leading: const Icon(Icons.badge, color: Colors.blue),
                    title: const Text('Carnet de Identidad'),
                    subtitle: Text(guardian?.ci ?? ''),
                  ),
                ),
                guardianAsync.when(
                  loading: () => const ListTile(
                    leading: Icon(Icons.phone, color: Colors.teal),
                    title: Text('Celular'),
                    subtitle: Text('Cargando...'),
                  ),
                  error: (e, _) => ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: const Text('Celular'),
                    subtitle: Text('Error: $e'),
                  ),
                  data: (guardian) => ListTile(
                    leading: const Icon(Icons.phone, color: Colors.teal),
                    title: const Text('Celular'),
                    subtitle: Text(guardian?.celular ?? ''),
                  ),
                ),
                guardianAsync.when(
                  loading: () => const ListTile(
                    leading: Icon(Icons.home, color: Colors.orange),
                    title: Text('Dirección'),
                    subtitle: Text('Cargando...'),
                  ),
                  error: (e, _) => ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: const Text('Dirección'),
                    subtitle: Text('Error: $e'),
                  ),
                  data: (guardian) => ListTile(
                    leading: const Icon(Icons.home, color: Colors.orange),
                    title: const Text('Dirección'),
                    subtitle: Text(guardian?.direccion ?? ''),
                  ),
                ),
                guardianAsync.when(
                  loading: () => const ListTile(
                    leading: Icon(Icons.account_circle, color: Colors.purple),
                    title: Text('Usuario'),
                    subtitle: Text('Cargando...'),
                  ),
                  error: (e, _) => ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: const Text('Usuario'),
                    subtitle: Text('Error: $e'),
                  ),
                  data: (guardian) => ListTile(
                    leading: const Icon(Icons.account_circle, color: Colors.purple),
                    title: const Text('Usuario'),
                    subtitle: Text(guardian?.usuario ?? ''),
                  ),
                ),
                guardianAsync.when(
                  loading: () => const ListTile(
                    leading: Icon(Icons.lock, color: Colors.red),
                    title: Text('Contraseña'),
                    subtitle: Text('Cargando...'),
                  ),
                  error: (e, _) => ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: const Text('Contraseña'),
                    subtitle: Text('Error: $e'),
                  ),
                  data: (guardian) => ListTile(
                    leading: const Icon(Icons.lock, color: Colors.red),
                    title: const Text('Contraseña'),
                    subtitle: Text(guardian?.contrasena ?? ''),
                  ),
                ),
                const Divider(height: 32),
                playersAsync.when(
                  loading: () => const ListTile(
                    leading: Icon(Icons.sports_soccer),
                    title: Text('Jugadores Asignados'),
                    subtitle: Text('Cargando...'),
                  ),
                  error: (e, _) => ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: const Text('Jugadores Asignados'),
                    subtitle: Text('Error: $e'),
                  ),
                  data: (jugadores) {
                    final guardian = guardianAsync.value;
                    final asignados = guardian == null
                        ? []
                        : jugadores.where((j) => guardian.jugadoresIds.contains(j.id)).toList();
                    return ListTile(
                      leading: const Icon(Icons.sports_soccer, color: Colors.green),
                      title: const Text('Jugadores Asignados'),
                      subtitle: asignados.isEmpty
                          ? const Text('Sin jugadores')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: asignados
                                  .map((j) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                                        child: Text('${j.nombres} ${j.apellido}'),
                                      ))
                                  .toList(),
                            ),
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