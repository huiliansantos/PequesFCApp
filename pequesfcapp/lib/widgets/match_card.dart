import 'package:flutter/material.dart';

class MatchCard extends StatelessWidget {
  final String rival;
  final String categoria;
  final DateTime fecha;
  final String? resultado; // Ej: "2-1" o null si aún no se juega

  const MatchCard({
    super.key,
    required this.rival,
    required this.categoria,
    required this.fecha,
    this.resultado,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.sports_soccer, color: Color(0xFFD32F2F)),
        title: Text('Rival: $rival'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categoría: $categoria'),
            Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}'),
            if (resultado != null)
              Text('Resultado: $resultado'),
          ],
        ),
        trailing: resultado != null
            ? const Icon(Icons.check, color: Colors.green)
            : const Icon(Icons.schedule, color: Colors.orange),
      ),
    );
  }
}