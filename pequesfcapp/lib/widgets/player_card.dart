import 'package:flutter/material.dart';

class PlayerCard extends StatelessWidget {
  final String nombre;
  final String categoria;
  final String apoderado;
  final String estadoPago;
  final String? fotoUrl;

  const PlayerCard({
    super.key,
    required this.nombre,
    required this.categoria,
    required this.apoderado,
    required this.estadoPago,
    this.fotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: fotoUrl != null
              ? NetworkImage(fotoUrl!)
              : null,
          child: fotoUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Categoría: $categoria\nApoderado: $apoderado'),
        trailing: Chip(
          label: Text(
            estadoPago,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: estadoPago == 'pagado'
              ? Colors.green
              : Colors.red,
        ),
      ),
    );
  }
}