import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/player_provider.dart';
import '../../providers/guardian_provider.dart'; // Agrega este import
import '../../models/player_model.dart';
import '../../models/guardian_model.dart';

// Función para calcular la categoría según la fecha de nacimiento
String calcularCategoria(DateTime fechaNacimiento) {
  final ahora = DateTime.now();
  int edad = ahora.year - fechaNacimiento.year;
  if (ahora.month < fechaNacimiento.month ||
      (ahora.month == fechaNacimiento.month &&
          ahora.day < fechaNacimiento.day)) {
    edad--;
  }
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
            // Genera las categorías dinámicamente
            final categorias = jugadores
                .map((j) => calcularCategoria(j.fechaDeNacimiento))
                .toSet()
                .toList();

            // Filtra jugadores por categoría y búsqueda
            final jugadoresFiltrados = jugadores.where((jugador) {
              final categoriaJugador =
                  calcularCategoria(jugador.fechaDeNacimiento);
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.people,
                          color: Color(0xFFD32F2F), size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Lista de Jugadores',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD32F2F),
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black12,
                              offset: Offset(1, 2),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: categoriaSeleccionada,
                          hint: const Text('Filtrar por categoría'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('Todas')),
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
                  child: ListView.builder(
                    itemCount: jugadoresFiltrados.length,
                    itemBuilder: (context, index) {
                      final jugador = jugadoresFiltrados[index];
                      final categoriaJugador =
                          calcularCategoria(jugador.fechaDeNacimiento);
                      GuardianModel? guardian;
                      try {
                        guardian = guardians.firstWhere(
                          (g) => g.id == jugador.guardianId,
                        );
                      } catch (e) {
                        guardian = null;
                      }
                      final nombreApoderado =
                          guardian?.nombreCompleto ?? "Sin apoderado";

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                const AssetImage('assets/jugador.png'),
                          ),
                          title: Text('${jugador.nombres} ${jugador.apellido}'),
                          subtitle: Text(
                              'Categoría: $categoriaJugador\nApoderado: $nombreApoderado'),
                          trailing: Chip(
                            label: Text(
                              jugador.estadoPago ?? 'N/A',
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
                                builder: (_) =>
                                    PlayerDetailScreen(player: jugador),
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

class PlayerDetailScreen extends StatelessWidget {
  final PlayerModel player;

  const PlayerDetailScreen({Key? key, required this.player}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoria = calcularCategoria(player.fechaDeNacimiento);
    return Scaffold(
      appBar: AppBar(
        title: Text("Jugador: " + player.nombres),
        backgroundColor: const Color(0xFFD32F2F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: (player.foto != null &&
                        player.foto!.isNotEmpty)
                    ? NetworkImage(player.foto!)
                    : const AssetImage('assets/jugador.png') as ImageProvider,
                backgroundColor: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Detalles del Jugador',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD32F2F),
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black12,
                    offset: Offset(1, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Categoría: $categoria',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Apoderado: ${player.guardianId ?? "N/A"}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Estado de Pago: ${player.estadoPago ?? "N/A"}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Acción al presionar el botón (por ejemplo, editar detalles del jugador)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Editar Detalles'),
            ),
          ],
        ),
      ),
    );
  }
}
