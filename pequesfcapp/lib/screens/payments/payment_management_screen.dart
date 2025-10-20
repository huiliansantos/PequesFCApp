import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/pago_provider.dart';
import '../../providers/player_provider.dart';
import 'payment_history_screen.dart';
import '../../providers/categoria_equipo_provider.dart';


const List<String> mesesPendientesPorDefecto = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
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

  int gestionActual = 2025; // Gestión por defecto para el estado general

  @override
  Widget build(BuildContext context) {
    final jugadoresAsync = ref.watch(playersProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
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
                const SizedBox(width: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: categoriaSeleccionada,
                        hint: const Text('Categoría'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Todas las categorías')),
                          ...ref
                              .watch(categoriasEquiposProvider)
                              .maybeWhen(
                                data: (categorias) {
                                  final ordenadas = [...categorias]
                                    ..sort((a, b) {
                                      final catComp = a.categoria.compareTo(b.categoria);
                                      if (catComp != 0) return catComp;
                                      return a.equipo.compareTo(b.equipo);
                                    });
                                  return ordenadas
                                      .map((ce) => DropdownMenuItem(
                                            value: ce.id,
                                            child: Text('${ce.categoria} - ${ce.equipo}'),
                                          ))
                                      .toList();
                                },
                                orElse: () => <DropdownMenuItem<String>>[],
                              )
                              .toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            categoriaSeleccionada = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
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
                            : pagos.where((p) => p.estado == estadoSeleccionado).toList();

                        // Solo pagos de la gestión actual (2025)
                        final pagosGestion = pagos.where((p) => p.anio == gestionActual).toList();

                        // Obtén el índice del último mes pagado
                        int ultimoMesPagado = -1;
                        for (var pago in pagosGestion) {
                          if (pago.estado == 'pagado') {
                            int mesIndex = mesesPendientesPorDefecto.indexOf(pago.mes);
                            if (mesIndex > ultimoMesPagado) {
                              ultimoMesPagado = mesIndex;
                            }
                          }
                        }

                        // Mes actual (0 = Enero, 1 = Febrero, ...)
                        int mesActual = DateTime.now().month - 1;

                        // Calcula cuántos meses debe hasta el mes actual
                        int mesesDeuda = mesActual - ultimoMesPagado;

                        // Estado general y color
                        Color estadoColor;
                        String estadoTexto;

                        if (pagos.isEmpty) {
                          estadoColor = Colors.grey;
                          estadoTexto = 'Sin registro';
                        } else if (ultimoMesPagado >= mesActual) {
                          estadoColor = Colors.green;
                          estadoTexto = 'Pagado';
                        } else if (mesesDeuda > 3) {
                          estadoColor = Colors.red;
                          estadoTexto = 'Atrasado';
                        } else {
                          estadoColor = Colors.orange;
                          estadoTexto = 'Pendiente';
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
                            subtitle: FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('categoria_equipo')
                                  .doc(jugador.categoriaEquipoId)
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text('Cargando categoría...');
                                }
                                if (!snapshot.hasData || !snapshot.data!.exists) {
                                  return const Text('Categoría desconocida');
                                }
                                final data = snapshot.data!.data()
                                    as Map<String, dynamic>;
                                return Text(
                                    'Categoría: ${data['categoria']} - ${data['equipo']}');
                              },
                            ),
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
