import 'package:flutter/material.dart';

class PaymentDetailScreen extends StatelessWidget {
  final String jugador;
  final List<Map<String, dynamic>> historialPagos;

  const PaymentDetailScreen({
    super.key,
    required this.jugador,
    required this.historialPagos,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pagos de $jugador'),
      ),
      body: ListView.builder(
        itemCount: historialPagos.length,
        itemBuilder: (context, index) {
          final pago = historialPagos[index];
          return ListTile(
            leading: Icon(
              pago['estado'] == 'pagado'
                  ? Icons.check_circle
                  : Icons.hourglass_bottom,
              color: pago['estado'] == 'pagado' ? Colors.green : Colors.orange,
            ),
            title: Text('Mes: ${pago['mes']}'),
            subtitle: Text('Monto: S/ ${pago['monto']}'),
            trailing: Chip(
              label: Text(
                pago['estado'].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor:
                  pago['estado'] == 'pagado' ? Colors.green : Colors.red,
            ),
            onTap: () {
              // Mostrar comprobante si existe
            },
          );
        },
      ),
    );
  }
}