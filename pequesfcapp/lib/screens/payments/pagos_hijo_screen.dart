import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/player_model.dart';
import '../../models/pago_model.dart';
import '../../providers/pago_provider.dart';
import '../../providers/categoria_equipo_provider.dart';

class PagosHijoScreen extends ConsumerStatefulWidget {
  final List<PlayerModel> hijos;

  const PagosHijoScreen({Key? key, required this.hijos}) : super(key: key);

  @override
  ConsumerState<PagosHijoScreen> createState() => _PagosHijoScreenState();
}

class _PagosHijoScreenState extends ConsumerState<PagosHijoScreen> {
  String busqueda = '';
  String? categoriaSeleccionada;
  String estadoSeleccionado = 'todos';

  @override
  Widget build(BuildContext context) {
    // Solo los hijos asignados
    final hijos = widget.hijos;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                /*TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar hijo',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      busqueda = value.trim().toLowerCase();
                    });
                  },
                ),
                const SizedBox(width: 8),*/
            
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: hijos.length,
              itemBuilder: (context, index) {
                final hijo = hijos[index];
                if (!(hijo.nombres.toLowerCase().contains(busqueda) ||
                    hijo.apellido.toLowerCase().contains(busqueda))) {
                  return const SizedBox.shrink();
                }
                if (categoriaSeleccionada != null &&
                    hijo.categoriaEquipoId != categoriaSeleccionada) {
                  return const SizedBox.shrink();
                }
                final pagosAsync = ref.watch(pagosPorJugadorProvider(hijo.id));
                return pagosAsync.when(
                  loading: () =>
                      const ListTile(title: Text('Cargando pagos...')),
                  error: (e, _) => ListTile(title: Text('Error: $e')),
                  data: (pagos) {
                    // Filtra pagos por estado si corresponde
                    final pagosFiltrados = estadoSeleccionado == 'todos'
                        ? pagos
                        : pagos.where((p) => p.estado == estadoSeleccionado).toList();

                    // Obtén el índice del último mes pagado
                    int ultimoMesPagado = -1;
                    for (var pago in pagos) {
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
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text('${hijo.nombres} ${hijo.apellido}'),
                        subtitle: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('categoria_equipo')
                              .doc(hijo.categoriaEquipoId)
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
                              style: const TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: estadoColor,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          visualDensity: VisualDensity.compact,
                        ),
                        onTap: () {
                          // Aquí puedes navegar al historial de pagos del hijo
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Puedes definir tu lista de meses así:
const List<String> mesesPendientesPorDefecto = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
];