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

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  String busqueda = '';
  String? categoriaSeleccionada;

  @override
  Widget build(BuildContext context) {
    // Obtén las categorías únicas
    final categorias = pagos.map((p) => p['categoria'] as String).toSet().toList();

    // Filtra por categoría y búsqueda
    final pagosFiltrados = pagos.where((pago) {
      final coincideCategoria = categoriaSeleccionada == null || pago['categoria'] == categoriaSeleccionada;
      final coincideBusqueda = pago['jugador'].toLowerCase().contains(busqueda.toLowerCase()) ||
          pago['categoria'].toLowerCase().contains(busqueda.toLowerCase());
      return coincideCategoria && coincideBusqueda;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: categoriaSeleccionada,
                  hint: const Text('Filtrar por categoría'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    ...categorias.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      categoriaSeleccionada = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar jugador o categoría',
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
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.payment, color: Color(0xFFD32F2F), size: 28),
              const SizedBox(width: 8),
              Text(
                'Gestión de Pagos',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD32F2F),
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black12,
                      offset: Offset(1, 2),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: pagosFiltrados.length,
            itemBuilder: (context, index) {
              final pago = pagosFiltrados[index];
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
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
          child: Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              onPressed: () {
                // Acción para registrar pago manualmente
              },
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }
}