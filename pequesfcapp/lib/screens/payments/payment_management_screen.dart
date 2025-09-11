import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pago_provider.dart';
import '../../providers/player_provider.dart';
import '../../models/pago_model.dart';
import '../../models/player_model.dart';
import 'payment_form.dart';
import 'payment_history_screen.dart';

const List<String> mesesPendientesPorDefecto = [
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre'
];

class PaymentManagementScreen extends ConsumerStatefulWidget {
  const PaymentManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PaymentManagementScreen> createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState
    extends ConsumerState<PaymentManagementScreen> {
  String busqueda = '';
  String? categoriaSeleccionada;
  String estadoSeleccionado = 'todos';

  @override
  Widget build(BuildContext context) {
    final jugadoresAsync = ref.watch(playersProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar jugador',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        busqueda = value.trim().toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: categoriaSeleccionada,
                  hint: const Text('Categoría'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    ...['2016', '2017', '2018', '2019', '2020'].map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      categoriaSeleccionada = value;
                    });
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: estadoSeleccionado,
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'pagado', child: Text('Pagados')),
                    DropdownMenuItem(
                        value: 'pendiente', child: Text('Pendientes')),
                    DropdownMenuItem(
                        value: 'atrasado', child: Text('Atrasados')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      estadoSeleccionado = value ?? 'todos';
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: jugadoresAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (jugadores) {
                final jugadoresFiltrados = jugadores.where((j) {
                  final coincideBusqueda =
                      j.nombres.toLowerCase().contains(busqueda) ||
                          j.apellido.toLowerCase().contains(busqueda);
                  final coincideCategoria = categoriaSeleccionada == null ||
                      j.categoriaEquipoId == categoriaSeleccionada;
                  return coincideBusqueda && coincideCategoria;
                }).toList();

                if (jugadoresFiltrados.isEmpty) {
                  return const Center(
                      child: Text('No hay jugadores encontrados.'));
                }

                return ListView.builder(
                  itemCount: jugadoresFiltrados.length,
                  itemBuilder: (context, index) {
                    final jugador = jugadoresFiltrados[index];
                    final pagosAsync =
                        ref.watch(pagosPorJugadorProvider(jugador.id));
                    return pagosAsync.when(
                      loading: () =>
                          const ListTile(title: Text('Cargando pagos...')),
                      error: (e, _) => ListTile(title: Text('Error: $e')),
                      data: (pagos) {
                        // Filtra pagos por estado si corresponde
                        final pagosFiltrados = estadoSeleccionado == 'todos'
                            ? pagos
                            : pagos
                                .where((p) => p.estado == estadoSeleccionado)
                                .toList();

                        // Verifica si hay algún mes pendiente
                        final pagosPorMes = {for (var p in pagos) p.mes: p};
                        bool tienePendiente = mesesPendientesPorDefecto.any(
                            (mes) =>
                                !pagosPorMes.containsKey(mes) ||
                                (pagosPorMes[mes]?.estado != 'pagado'));

                        Color estadoColor;
                        String estadoTexto;
                        if (tienePendiente) {
                          estadoColor = Colors.orange;
                          estadoTexto = 'Pendiente';
                        } else if (pagosFiltrados.isNotEmpty &&
                            pagosFiltrados.last.estado == 'pagado') {
                          estadoColor = Colors.green;
                          estadoTexto = 'Pagado';
                        } else if (pagosFiltrados.isNotEmpty &&
                            pagosFiltrados.last.estado == 'atrasado') {
                          estadoColor = Colors.red;
                          estadoTexto = 'Atrasado';
                        } else {
                          estadoColor = Colors.grey;
                          estadoTexto = 'Sin registro';
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: estadoColor,
                              child:
                                  const Icon(Icons.person, color: Colors.white),
                            ),
                            title:
                                Text('${jugador.nombres} ${jugador.apellido}'),
                            subtitle:
                                Text('Categoría: ${jugador.categoriaEquipoId}'),
                            trailing: Chip(
                              label: Text(estadoTexto,
                                  style: const TextStyle(color: Colors.white)),
                              backgroundColor: estadoColor,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentHistoryScreen(
                                    jugadorId: jugador.id,
                                    jugadorNombre:
                                        '${jugador.nombres} ${jugador.apellido}',
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Puedes navegar al formulario de pago para un jugador seleccionado
        },
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFFD32F2F),
        tooltip: 'Registrar pago',
      ),
    );
  }
}
