import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/player_provider.dart';
import '../../providers/guardian_provider.dart';
import 'guardian_form_screen.dart';

class GuardianDetailScreen extends ConsumerStatefulWidget {
  final String guardianId;

  const GuardianDetailScreen({Key? key, required this.guardianId}) : super(key: key);

  @override
  ConsumerState<GuardianDetailScreen> createState() => _GuardianDetailScreenState();
}

class _GuardianDetailScreenState extends ConsumerState<GuardianDetailScreen> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final guardianAsync = ref.watch(guardianByIdProvider(widget.guardianId));
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: true,
            title: guardianAsync.when(
              loading: () => const Text('Apoderado'),
              error: (e, _) => const Text('Apoderado'),
              data: (guardian) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guardian?.nombreCompleto ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Apoderado',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
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
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundImage: const AssetImage('assets/apoderado.png'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                child: guardianAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (guardian) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow(Icons.person, Colors.blue, 'Nombre:', guardian?.nombreCompleto ?? ''),
                      _detailRow(Icons.badge, Colors.blue, 'CI:', guardian?.ci ?? ''),
                      _detailRow(Icons.phone, Colors.teal, 'Celular:', guardian?.celular ?? ''),
                      _detailRow(Icons.home, Colors.orange, 'Dirección:', guardian?.direccion ?? ''),
                      _detailRow(Icons.account_circle, Colors.purple, 'Usuario:', guardian?.usuario ?? ''),
                      _detailRow(
                        Icons.lock,
                        Colors.red,
                        'Contraseña:',
                        _showPassword ? (guardian?.contrasena ?? '') : '*' * (guardian?.contrasena.length ?? 0),
                        trailing: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: playersAsync.when(
                  loading: () => const ListTile(
                    leading: Icon(Icons.sports_soccer),
                    title: Text('Jugadores Asignados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text('Cargando...', style: TextStyle(fontSize: 15)),
                  ),
                  error: (e, _) => ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: const Text('Jugadores Asignados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text('Error: $e', style: const TextStyle(fontSize: 15)),
                  ),
                  data: (jugadores) {
                    final guardian = guardianAsync.value;
                    final asignados = guardian == null
                        ? []
                        : jugadores.where((j) => guardian.jugadoresIds.contains(j.id)).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.sports_soccer, color: Colors.green, size: 24),
                            SizedBox(width: 8),
                            Text('Jugadores Asignados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        asignados.isEmpty
                            ? const Text('Sin jugadores', style: TextStyle(fontSize: 15))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: asignados
                                    .map((j) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                                          child: Text('${j.nombres} ${j.apellido}', style: const TextStyle(fontSize: 15)),
                                        ))
                                    .toList(),
                              ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para cada fila de atributo
  Widget _detailRow(IconData icon, Color iconColor, String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}