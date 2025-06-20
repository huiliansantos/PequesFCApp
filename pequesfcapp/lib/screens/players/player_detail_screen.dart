import 'package:flutter/material.dart';

class PlayerDetailScreen extends StatelessWidget {
  final String nombre;
  final String categoria;
  final String apoderado;
  final String estadoPago;
  final String? fotoUrl;

  const PlayerDetailScreen({
    super.key,
    required this.nombre,
    required this.categoria,
    required this.apoderado,
    required this.estadoPago,
    this.fotoUrl,
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
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl!) : null,
                child: fotoUrl == null ? const Icon(Icons.person, size: 40) : null,
              ),
            ),
            const SizedBox(height: 24),
            Text('Nombre: $nombre', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Categoría: $categoria', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Apoderado: $apoderado', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Estado de pago: $estadoPago', style: const TextStyle(fontSize: 16)),
            // Puedes agregar más información aquí, como historial de pagos, partidos, etc.
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción para editar jugador
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}