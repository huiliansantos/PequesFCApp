import 'package:flutter/material.dart';

// Simulación de datos de partidos
final List<Map<String, dynamic>> partidos = [
  {
    'fecha': DateTime(2024, 6, 20, 10, 0),
    'rival': 'Escuela Fútbol Sur',
    'categoria': 'Sub-10',
    'resultado': null,
  },
  {
    'fecha': DateTime(2024, 6, 27, 11, 0),
    'rival': 'Academia Norte',
    'categoria': 'Sub-8',
    'resultado': '2-1',
  },
];

class MatchScheduleScreen extends StatelessWidget {
  const MatchScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de Partidos'),
      ),
      body: ListView.builder(
        itemCount: partidos.length,
        itemBuilder: (context, index) {
          final partido = partidos[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: const Icon(Icons.sports_soccer, color: Color(0xFFD32F2F)),
              title: Text('${partido['rival']} (${partido['categoria']})'),
              subtitle: Text(
                'Fecha: ${partido['fecha'].day}/${partido['fecha'].month} ${partido['fecha'].hour.toString().padLeft(2, '0')}:${partido['fecha'].minute.toString().padLeft(2, '0')}',
              ),
              trailing: partido['resultado'] != null
                  ? Chip(
                      label: Text('Resultado: ${partido['resultado']}'),
                      backgroundColor: Colors.green,
                      labelStyle: const TextStyle(color: Colors.white),
                    )
                  : const Chip(
                      label: Text('Pendiente'),
                      backgroundColor: Colors.orange,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
              onTap: () {
                // Aquí puedes navegar al registro de resultado de este partido
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción para agregar nuevo partido
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}