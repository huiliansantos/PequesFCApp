import 'package:flutter/material.dart';
import '../../models/pago_model.dart';

class PaymentDetailScreen extends StatelessWidget {
  final PagoModel pago;
  final List<PagoModel> historialPagos;

  const PaymentDetailScreen({
    Key? key,
    required this.pago,
    required this.historialPagos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color estadoColor;
    switch (pago.estado) {
      case 'pagado':
        estadoColor = Colors.green;
        break;
      case 'pendiente':
        estadoColor = Colors.orange;
        break;
      case 'atrasado':
        estadoColor = Colors.red;
        break;
      default:
        estadoColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Pago'),
        backgroundColor: const Color(0xFFD32F2F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: estadoColor,
                  child: const Icon(Icons.attach_money, color: Colors.white),
                ),
                title: Text(
                    '${pago.mes} - S/ ${pago.monto.toStringAsFixed(2)}'),
                subtitle: Text(
                  'Fecha de pago: ${pago.fechaPago.day}/${pago.fechaPago.month}/${pago.fechaPago.year}\n'
                  'Estado: ${pago.estado.toUpperCase()}\n'
                  'Observación: ${pago.observacion ?? "-"}',
                ),
                trailing: Chip(
                  label: Text(
                    pago.estado.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: estadoColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Historial de pagos',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD32F2F)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: historialPagos.isEmpty
                  ? const Center(child: Text('No hay historial de pagos.'))
                  : ListView.builder(
                      itemCount: historialPagos.length,
                      itemBuilder: (context, index) {
                        final hist = historialPagos[index];
                        Color histColor;
                        switch (hist.estado) {
                          case 'pagado':
                            histColor = Colors.green;
                            break;
                          case 'pendiente':
                            histColor = Colors.orange;
                            break;
                          case 'atrasado':
                            histColor = Colors.red;
                            break;
                          default:
                            histColor = Colors.grey;
                        }
                        return ListTile(
                          leading: Icon(Icons.calendar_today, color: histColor),
                          title: Text(
                              '${hist.mes} - S/ ${hist.monto.toStringAsFixed(2)}'),
                          subtitle: Text(
                            'Fecha: ${hist.fechaPago.day}/${hist.fechaPago.month}/${hist.fechaPago.year}',
                          ),
                          trailing: Chip(
                            label: Text(hist.estado.toUpperCase(),
                                style: const TextStyle(color: Colors.white)),
                            backgroundColor: histColor,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}