import 'package:flutter/material.dart';
import 'guardian_detail_screen.dart';

// Simulación de datos de apoderados
final List<Map<String, dynamic>> apoderados = [
  {
    'nombre': 'Carlos Pérez',
    'correo': 'carlos@mail.com',
    'telefono': '999888777',
    'jugadores': ['Juan Pérez', 'Ana Pérez'],
  },
  {
    'nombre': 'Carla Pérez',
    'correo': 'carla@mail.com',
    'telefono': '999888777',
    'jugadores': ['Juan Pérez', 'Ana Pérez'],
  },
    {
    'nombre': 'Cristian Pérez',
    'correo': 'cristian@mail.com',
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
                    onTap: () {
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