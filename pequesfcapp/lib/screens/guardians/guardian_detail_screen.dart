import 'package:flutter/material.dart';

// Simulación de datos de apoderados
final List<Map<String, dynamic>> apoderados = [
  {
    'nombre': 'Carlos Pérez',
    'correo': 'carlos@mail.com',
    'telefono': '999888777',
    'jugadores': ['Juan Pérez', 'Ana Pérez'],
  },
  {
    'nombre': 'María López',
    'correo': 'maria@mail.com',
    'telefono': '988777666',
    'jugadores': ['Luis López'],
  },
];

class GuardianListScreen extends StatefulWidget {
  const GuardianListScreen({super.key});

  @override
  State<GuardianListScreen> createState() => _GuardianListScreenState();
}

class _GuardianListScreenState extends State<GuardianListScreen> {
  String busqueda = '';

  @override
  Widget build(BuildContext context) {
    final apoderadosFiltrados = apoderados.where((apoderado) {
      return apoderado['nombre'].toLowerCase().contains(busqueda.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Apoderados'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar apoderado',
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
          Expanded(
            child: ListView.builder(
              itemCount: apoderadosFiltrados.length,
              itemBuilder: (context, index) {
                final apoderado = apoderadosFiltrados[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Color(0xFFD32F2F)),
                    title: Text(apoderado['nombre']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Correo: ${apoderado['correo']}'),
                        Text('Teléfono: ${apoderado['telefono']}'),
                        Text('Jugadores: ${apoderado['jugadores'].join(', ')}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GuardianDetailScreen(
                              nombre: apoderado['nombre'],
                              correo: apoderado['correo'],
                              telefono: apoderado['telefono'],
                              jugadores: List<String>.from(apoderado['jugadores']),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción para agregar un nuevo apoderado
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class GuardianDetailScreen extends StatelessWidget {
  final String nombre;
  final String correo;
  final String telefono;
  final List<String> jugadores;

  const GuardianDetailScreen({
    super.key,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.jugadores,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de $nombre'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: $nombre', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Correo: $correo', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Teléfono: $telefono', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Text('Jugadores vinculados:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...jugadores.map((j) => ListTile(
                  leading: const Icon(Icons.child_care, color: Color(0xFFD32F2F)),
                  title: Text(j),
                  onTap: () {
                    // Aquí puedes navegar al detalle del jugador
                  },
                )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción para editar apoderado o agregar jugador
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}