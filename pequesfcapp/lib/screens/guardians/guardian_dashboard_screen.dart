import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/guardian_model.dart';
import '../../providers/player_provider.dart';
import '../login/login_screen.dart';

class GuardianDashboardScreen extends ConsumerWidget {
  final GuardianModel guardian;

  const GuardianDashboardScreen({super.key, required this.guardian});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Panel del Tutor (${guardian.nombreCompleto})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Aquí puedes limpiar el provider de sesión si usas uno
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mis Hijos'),
            subtitle: playersAsync.when(
              loading: () => const Text('Cargando...'),
              error: (e, _) => Text('Error: $e'),
              data: (jugadores) {
                final misJugadores = jugadores
                    .where((j) => guardian.jugadoresIds.contains(j.id))
                    .toList();
                if (misJugadores.isEmpty) {
                  return const Text('No tiene niños asignados.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: misJugadores
                      .map((j) => Text('${j.nombres} ${j.apellido}'))
                      .toList(),
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Pagos'),
            onTap: () {
              // Navegar a la pantalla de pagos
            },
          ),
          ListTile(
            leading: const Icon(Icons.announcement),
            title: const Text('Avisos'),
            onTap: () {
              // Navegar a la pantalla de avisos
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historial de Asistencia'),
            onTap: () {
              // Navegar a la pantalla de asistencia
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Actualizar Datos de Contacto'),
            onTap: () {
              // Navegar a la pantalla de configuración
            },
          ),
        ],
      ),
    );
  }
}