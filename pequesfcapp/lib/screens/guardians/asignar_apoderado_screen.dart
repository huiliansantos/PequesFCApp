import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/player_model.dart';
import '../../models/guardian_model.dart';
import '../../providers/guardian_provider.dart';
import '../../providers/player_provider.dart';
import 'guardian_form_screen.dart';
import '../../widgets/gradient_button.dart';

class AsignarApoderadoScreen extends ConsumerStatefulWidget {
  final PlayerModel jugador;

  const AsignarApoderadoScreen({Key? key, required this.jugador}) : super(key: key);

  @override
  ConsumerState<AsignarApoderadoScreen> createState() => _AsignarApoderadoScreenState();
}

class _AsignarApoderadoScreenState extends ConsumerState<AsignarApoderadoScreen> {
  String? guardianIdSeleccionado;

  @override
  Widget build(BuildContext context) {
    final guardiansAsync = ref.watch(guardiansStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar Apoderado'),
        //fondo degradado
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jugador:', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person, color: Color(0xFFD32F2F)),
                title: Text('${widget.jugador.nombres} ${widget.jugador.apellido}'),
              ),
            ),
            const SizedBox(height: 16),
            guardiansAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (guardians) {
                return DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Buscar apoderado',
                    border: OutlineInputBorder(),
                  ),
                  // ignore: deprecated_member_use
                  value: guardianIdSeleccionado,
                  items: [
                    ...guardians.map((g) => DropdownMenuItem(
                      value: g.id,
                      child: Text('${g.nombreCompleto} - CI: ${g.ci}'),
                    )),
                    const DropdownMenuItem(
                      value: 'nuevo_apoderado',
                      child: Text('Registrar nuevo apoderado'),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == 'nuevo_apoderado') {
                      // Navega al formulario de registro de apoderado
                      final nuevoGuardian = await Navigator.push<GuardianModel>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GuardianFormScreen(),
                        ),
                      );
                      if (nuevoGuardian != null) {
                        setState(() {
                          guardianIdSeleccionado = nuevoGuardian.id;
                        });
                      }
                    } else {
                      setState(() {
                        guardianIdSeleccionado = value;
                      });
                    }
                  },
                  validator: (v) => v == null ? 'Seleccione un apoderado' : null,
                );
              },
            ),
            const SizedBox(height: 24),
            GradientButton(
              onPressed: () async {
                if (guardianIdSeleccionado == null || guardianIdSeleccionado == 'nuevo_apoderado') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seleccione un apoderado válido')),
                  );
                  return;
                }
                // Actualiza el jugador con el nuevo apoderado
                final repo = ref.read(playerRepositoryProvider);
                await repo.updatePlayer(widget.jugador.copyWith(guardianId: guardianIdSeleccionado));
                if (context.mounted) Navigator.pop(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.save, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Asignar apoderado', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}