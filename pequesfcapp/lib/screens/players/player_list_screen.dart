import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/player_provider.dart';
import '../players/player_form_screen.dart';
import '../../providers/guardian_provider.dart';
import '../../models/player_model.dart';
import '../../models/guardian_model.dart';
import 'player_detail_screen.dart';

String calcularCategoria(DateTime fechaNacimiento) {
  final ahora = DateTime.now();
  int edad = ahora.year - fechaNacimiento.year;
  return 'Sub-$edad';
}

class PlayerListScreen extends ConsumerStatefulWidget {
  const PlayerListScreen({super.key});

  @override
  ConsumerState<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends ConsumerState<PlayerListScreen> {
  String? categoriaSeleccionada;
  String busqueda = '';

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);
    final guardiansAsync = ref.watch(guardiansStreamProvider);

    return guardiansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (guardians) {
        return playersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (jugadores) {
            final categorias = jugadores
                .map((j) => calcularCategoria(j.fechaDeNacimiento))
                .toSet()
                .toList();

            final jugadoresFiltrados = jugadores.where((jugador) {
              final categoriaJugador = calcularCategoria(jugador.fechaDeNacimiento);
              final coincideCategoria = categoriaSeleccionada == null ||
                  categoriaJugador == categoriaSeleccionada;
              final coincideBusqueda =
                  ('${jugador.nombres} ${jugador.apellido}')
                      .toLowerCase()
                      .contains(busqueda.toLowerCase());
              return coincideCategoria && coincideBusqueda;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: categorias.contains(categoriaSeleccionada) ? categoriaSeleccionada : null,
                          hint: const Text('Filtrar por categoría'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Todas')),
                            ...categorias.map((cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              categoriaSeleccionada = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Buscar jugador o categoría',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              busqueda = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: jugadoresFiltrados.isEmpty
                      ? const Center(child: Text('No se encontraron jugadores.'))
                      : ListView.builder(
                          itemCount: jugadoresFiltrados.length,
                          itemBuilder: (context, index) {
                            final jugador = jugadoresFiltrados[index];
                            final categoriaJugador = calcularCategoria(jugador.fechaDeNacimiento);
                            GuardianModel? guardian;
                            try {
                              guardian = guardians.firstWhere(
                                (g) => g.id == jugador.guardianId,
                              );
                            } catch (e) {
                              guardian = null;
                            }
                            final nombreApoderado = guardian?.nombreCompleto ?? "Sin apoderado";

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: const AssetImage('assets/jugador.png'),
                                ),
                                title: Text(
                                  '${jugador.nombres} ${jugador.apellido}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Categoría: $categoriaJugador\nApoderado: $nombreApoderado',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                trailing: Chip(
                                  label: Text(
                                    jugador.estadoPago?.toUpperCase() ?? 'N/A',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: jugador.estadoPago == 'pagado'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PlayerDetailScreen(player: jugador),
                                    ),
                                  );
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
                                            title: const Text('Modificar jugador'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.push(context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          PlayerFormScreen(player: jugador)));
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.delete, color: Colors.red),
                                            title: const Text('Eliminar jugador'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: const Text('Eliminar jugador'),
                                                    content: const Text('¿Estás seguro de que deseas eliminar este jugador?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(context);
                                                        },
                                                        child: const Text('Cancelar'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          await ref.read(playerRepositoryProvider).deletePlayer(jugador.id);
                                                          Navigator.pop(context);
                                                        },
                                                        child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
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
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
