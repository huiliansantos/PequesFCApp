import 'package:flutter/material.dart';
import 'payment_detail_screen.dart';

// Simulación de datos de pagos
final List<Map<String, dynamic>> pagos = [
  {
    'jugador': 'Juan Pérez',
    'categoria': 'Sub-10',
    'mes': 'Junio',
    'monto': 100.0,
    'estado': 'pagado',
    'comprobanteUrl': null,
    'fechaRegistro': DateTime(2024, 6, 10),
  },
  {
    'jugador': 'Ana López',
    'categoria': 'Sub-8',
    'mes': 'Junio',
    'monto': 100.0,
    'estado': 'pendiente',
    'comprobanteUrl': null,
    'fechaRegistro': DateTime(2024, 6, 12),
  },
];

class PaymentManagementScreen extends StatelessWidget {
  const PaymentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pagos'),
      ),
      body: ListView.builder(
        itemCount: pagos.length,
        itemBuilder: (context, index) {
          final pago = pagos[index];
          // Filtra todos los pagos de este jugador para el historial
          final historial = pagos
              .where((p) => p['jugador'] == pago['jugador'])
              .toList();
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: Icon(
                pago['estado'] == 'pagado'
                    ? Icons.check_circle
                    : Icons.hourglass_bottom,
                color: pago['estado'] == 'pagado' ? Colors.green : Colors.orange,
              ),
              title: Text('${pago['jugador']} (${pago['categoria']})'),
              subtitle: Text('Mes: ${pago['mes']} - Monto: S/ ${pago['monto']}'),
              trailing: Chip(
                label: Text(
                  pago['estado'].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor:
                    pago['estado'] == 'pagado' ? Colors.green : Colors.red,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentDetailScreen(
                      jugador: pago['jugador'],
                      historialPagos: historial,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción para registrar pago manualmente
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}