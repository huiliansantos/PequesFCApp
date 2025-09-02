import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pago_provider.dart';
import '../../models/pago_model.dart';
import 'payment_form.dart';

const List<String> mesesDelAno = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
];

class PaymentHistoryScreen extends ConsumerWidget {
  final String jugadorId;
  final String jugadorNombre;

  const PaymentHistoryScreen({
    Key? key,
    required this.jugadorId,
    required this.jugadorNombre,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagosAsync = ref.watch(pagosPorJugadorProvider(jugadorId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Pagos - $jugadorNombre'),
        backgroundColor: const Color(0xFFD32F2F),
      ),
      body: pagosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (pagos) {
          final mesesPendientes = mesesDelAno.sublist(7, 12);
          final pagosPorMes = {for (var p in pagos) p.mes: p};

          final items = <Widget>[];

          // Mostrar pagos registrados
          for (final pago in pagos) {
            Color estadoColor;
            switch (pago.estado) {
              case 'pagado': estadoColor = Colors.green; break;
              case 'pendiente': estadoColor = Colors.orange; break;
              case 'atrasado': estadoColor = Colors.red; break;
              default: estadoColor = Colors.grey;
            }
            items.add(Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: estadoColor,
                  child: const Icon(Icons.attach_money, color: Colors.white),
                ),
                title: Text('${pago.mes} - S/ ${pago.monto.toStringAsFixed(2)}'),
                subtitle: Text(
                  'Fecha: ${pago.fechaPago.day}/${pago.fechaPago.month}/${pago.fechaPago.year}\n'
                  'Observación: ${pago.observacion ?? "-"}',
                ),
                trailing: Chip(
                  label: Text(
                    pago.estado.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: estadoColor,
                ),
                // Solo permite registrar pago si no está pagado
                onTap: pago.estado != 'pagado'
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentForm(
                              jugadorId: jugadorId,
                              jugadorNombre: jugadorNombre,
                              mesInicial: pago.mes,
                            ),
                          ),
                        );
                      }
                    : null,
              ),
            ));
          }

          // Mostrar meses pendientes por defecto
          for (final mes in mesesPendientes) {
            if (!pagosPorMes.containsKey(mes)) {
              items.add(Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.attach_money, color: Colors.white),
                  ),
                  title: Text('$mes - S/ 0.00'),
                  subtitle: const Text('Pendiente de pago'),
                  trailing: const Chip(
                    label: Text('PENDIENTE', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.orange,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentForm(
                          jugadorId: jugadorId,
                          jugadorNombre: jugadorNombre,
                          mesInicial: mes,
                        ),
                      ),
                    );
                  },
                ),
              ));
            }
          }

          if (items.isEmpty) {
            return const Center(child: Text('No hay pagos registrados.'));
          }
          return ListView(children: items);
        },
      ),
    );
  }
}