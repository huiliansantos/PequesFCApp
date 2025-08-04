import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/guardian_model.dart';
import '../../providers/player_provider.dart'; // Importa el provider de jugadores

class GuardianDetailScreen extends ConsumerWidget {
  final GuardianModel guardian;

  const GuardianDetailScreen({Key? key, required this.guardian}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(guardian.nombreCompleto)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(title: Text('CI'), subtitle: Text(guardian.ci)),
            ListTile(title: Text('Celular'), subtitle: Text(guardian.celular)),
            ListTile(title: Text('Dirección'), subtitle: Text(guardian.direccion)),
            ListTile(title: Text('Usuario'), subtitle: Text(guardian.usuario)),
            ListTile(title: Text('Contraseña'), subtitle: Text(guardian.contrasena)),
            playersAsync.when(
              loading: () => const ListTile(title: Text('Jugadores'), subtitle: Text('Cargando...')),
              error: (e, _) => ListTile(title: Text('Jugadores'), subtitle: Text('Error: $e')),
              data: (jugadores) {
                final asignados = jugadores
                  .where((j) => guardian.jugadoresIds.contains(j.id))
                  .toList();
                return ListTile(
                  title: const Text('Jugadores Asignados'),
                  subtitle: asignados.isEmpty
                    ? const Text('Sin jugadores')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: asignados.map((j) => Text('${j.nombres} ${j.apellido}')).toList(),
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}