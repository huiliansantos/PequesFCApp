import 'package:flutter/material.dart';

class PaymentCard extends StatelessWidget {
  final String mes;
  final double monto;
  final String estado; // "pagado" o "pendiente"
  final String? comprobanteUrl;
  final DateTime fechaRegistro;

  const PaymentCard({
    super.key,
    required this.mes,
    required this.monto,
    required this.estado,
    this.comprobanteUrl,
    required this.fechaRegistro,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Icon(
          estado == 'pagado' ? Icons.check_circle : Icons.hourglass_bottom,
          color: estado == 'pagado' ? Colors.green : Colors.orange,
        ),
        title: Text('Mes: $mes'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monto: S/ ${monto.toStringAsFixed(2)}'),
            Text('Fecha: ${fechaRegistro.day}/${fechaRegistro.month}/${fechaRegistro.year}'),
            if (comprobanteUrl != null)
              TextButton(
                onPressed: () {
                  // Aquí puedes mostrar el comprobante en un visor de imágenes
                },
                child: const Text('Ver comprobante'),
              ),
          ],
        ),
        trailing: Chip(
          label: Text(
            estado.toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: estado == 'pagado' ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}