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

// OPTIMIZACIÓN: Provider para obtener el mapa de categoriaEquipoId -> nombre
final categoriaEquiposMapProvider = FutureProvider<Map<String, String>>((ref) async {
  final query = await FirebaseFirestore.instance.collection('categoria_equipo').get();
  final map = <String, String>{};
  for (final doc in query.docs) {
    final data = doc.data();
    final categoria = (data['categoria'] ?? '').toString();
    final equipo = (data['equipo'] ?? '').toString();
    final label = [
      if (categoria.isNotEmpty) categoria,
      if (equipo.isNotEmpty) equipo,
    ].join(' - ');
    map[doc.id] = label.isNotEmpty ? label : doc.id;
  }
  return map;
});

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

  int gestionActual = DateTime.now().year;

  int _getYearFromLabel(String label) {
    final match = RegExp(r'\d{4}').firstMatch(label);
    if (match != null) return int.tryParse(match.group(0)!) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final jugadoresAsync = ref.watch(playersProvider);
    final categoriasMapAsync = ref.watch(categoriaEquiposMapProvider);

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
                      child: categoriasMapAsync.when(
                        loading: () => const SizedBox(
                            height: 48,
                            child: Center(child: CircularProgressIndicator())),
                        error: (e, _) => const SizedBox(
                            height: 48,
                            child: Center(child: Text('Error categorías'))),
                        data: (idToLabel) {
                          // Ordenar entries por año (categoria) descendente
                          final entries = idToLabel.entries.toList();
                          entries.sort((a, b) => _getYearFromLabel(b.value).compareTo(_getYearFromLabel(a.value)));

                          final items = <DropdownMenuItem<String>>[
                            const DropdownMenuItem<String>(value: '', child: Text('Todas las categorías')),
                            ...entries.map((e) => DropdownMenuItem<String>(
                                  value: e.key,
                                  child: Text(e.value),
                                )),
                          ];

                          return DropdownButton<String>(
                            value: categoriaSeleccionada,
                            hint: const Text('Categoría'),
                            isExpanded: true,
                            items: items,
                            onChanged: (value) {
                              setState(() {
                                categoriaSeleccionada = value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: estadoSeleccionado,
                      items: const [
                        DropdownMenuItem(value: 'todos', child: Text('Todos')),
                        DropdownMenuItem(value: 'pagado', child: Text('Pagados')),
                        DropdownMenuItem(value: 'pendiente', child: Text('Pendientes')),
                        DropdownMenuItem(value: 'atrasado', child: Text('Atrasados')),
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
                return categoriasMapAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error categorías')),
                  data: (idToLabel) {
                    final jugadoresFiltrados = jugadores.where((j) {
                      final coincideBusqueda =
                          j.nombres.toLowerCase().contains(busqueda) ||
                              j.apellido.toLowerCase().contains(busqueda);
                      final coincideCategoria = categoriaSeleccionada == null ||
                          categoriaSeleccionada == '' ||
                          j.categoriaEquipoId == categoriaSeleccionada;
                      return coincideBusqueda && coincideCategoria;
                    }).toList();

                    // Ordenar jugadores por categoría (año) descendente, si mismo año por apellido asc
                    jugadoresFiltrados.sort((a, b) {
                      final ya = _getYearFromLabel(idToLabel[a.categoriaEquipoId] ?? '');
                      final yb = _getYearFromLabel(idToLabel[b.categoriaEquipoId] ?? '');
                      if (yb != ya) return yb.compareTo(ya);
                      return a.apellido.toLowerCase().compareTo(b.apellido.toLowerCase());
                    });

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
                            // calcular estado del jugador con los pagos del año actual
                            final pagosGestion = pagos.where((p) => p.anio == gestionActual).toList();

                            int ultimoMesPagado = -1;
                            for (var pago in pagosGestion) {
                              if (pago.estado == 'pagado') {
                                int mesIndex = mesesPendientesPorDefecto.indexOf(pago.mes);
                                if (mesIndex > ultimoMesPagado) ultimoMesPagado = mesIndex;
                              }
                            }

                            int mesActual = DateTime.now().month - 1;
                            int mesesDeuda = mesActual - ultimoMesPagado;

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

                            final categoriaEquipoNombre =
                                idToLabel[jugador.categoriaEquipoId] ??
                                    'Categoría desconocida';

                            // aplicar filtro por estado: si no coincide, ocultar el card
                            final estadoFiltrado = estadoSeleccionado.toLowerCase();
                            final estadoActualLower = estadoTexto.toLowerCase();
                            final mostrar = estadoFiltrado == 'todos' ||
                                (estadoFiltrado == 'pagado' && estadoActualLower == 'pagado') ||
                                (estadoFiltrado == 'pendiente' && estadoActualLower == 'pendiente') ||
                                (estadoFiltrado == 'atrasado' && estadoActualLower == 'atrasado');

                            return Visibility(
                              visible: mostrar,
                              child: Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: estadoColor,
                                    child: const Icon(Icons.person, color: Colors.white),
                                  ),
                                  title: Text('${jugador.nombres} ${jugador.apellido}'),
                                  subtitle: Text('Categoría: $categoriaEquipoNombre'),
                                  trailing: Chip(
                                    label: Text(estadoTexto, style: const TextStyle(color: Colors.white)),
                                    backgroundColor: estadoColor,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PaymentHistoryScreen(
                                          jugadorId: jugador.id,
                                          jugadorNombre: '${jugador.nombres} ${jugador.apellido}',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
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
