import 'package:flutter/material.dart';
import 'player_detail_screen.dart';

// Simulación de datos de jugadores
final List<Map<String, dynamic>> jugadores = [
  {
    'nombre': 'Juan Pérez',
    'categoria': 'Sub-10',
    'apoderado': 'Carlos Pérez',
    'estadoPago': 'pagado',
    'fotoUrl': null,
  },
  {
    'nombre': 'Ana López',
    'categoria': 'Sub-8',
    'apoderado': 'María López',
    'estadoPago': 'pendiente',
    'fotoUrl': null,
  },
];

class PlayerListScreen extends StatefulWidget {
  const PlayerListScreen({super.key});

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  String? categoriaSeleccionada;
  String busqueda = '';

  @override
  Widget build(BuildContext context) {
    // Obtén las categorías únicas
    final categorias = jugadores.map((j) => j['categoria'] as String).toSet().toList();

    // Filtra por categoría y búsqueda
    final jugadoresFiltrados = jugadores.where((jugador) {
      final coincideCategoria = categoriaSeleccionada == null || jugador['categoria'] == categoriaSeleccionada;
      final coincideBusqueda = jugador['nombre'].toLowerCase().contains(busqueda.toLowerCase());
      return coincideCategoria && coincideBusqueda;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Jugadores'),
      ),
      body: Column(
        children: [
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
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      ...categorias.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
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
                      hintText: 'Buscar jugador',
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
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: jugador['fotoUrl'] != null
                          ? NetworkImage(jugador['fotoUrl'])
                          : null,
                      child: jugador['fotoUrl'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(jugador['nombre']),
                    subtitle: Text('Categoría: ${jugador['categoria']}\nApoderado: ${jugador['apoderado']}'),
                    trailing: Chip(
                      label: Text(
                        jugador['estadoPago'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: jugador['estadoPago'] == 'pagado' ? Colors.green : Colors.red,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerDetailScreen(
                            nombre: jugador['nombre'],
                            categoria: jugador['categoria'],
                            apoderado: jugador['apoderado'],
                            estadoPago: jugador['estadoPago'],
                            fotoUrl: jugador['fotoUrl'],
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción para agregar nuevo jugador
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}