import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pago_provider.dart';
import '../../models/pago_model.dart';
import 'payment_form.dart';

const List<String> mesesDelAno = [
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

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  final String jugadorId;
  final String jugadorNombre;

  const PaymentHistoryScreen({
    Key? key,
    required this.jugadorId,
    required this.jugadorNombre,
  }) : super(key: key);

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  String? anioSeleccionado;
  String estadoSeleccionado = 'todos';

  int get gestionActual => DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final pagosAsync = ref.watch(pagosPorJugadorProvider(widget.jugadorId));

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Historial de Pagos'),
            Text(
              widget.jugadorNombre,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: anioSeleccionado,
                    hint: const Text('Seleccionar año'),
                    items: [
                      for (var i = 2020; i <= DateTime.now().year; i++)
                        DropdownMenuItem(
                            value: i.toString(), child: Text(i.toString())),
                    ],
                    onChanged: (value) {
                      setState(() {
                        anioSeleccionado = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: estadoSeleccionado,
                    hint: const Text('Seleccionar estado'),
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
                ),
              ],
            ),
          ),
          // ESTADO GENERAL DE LA GESTIÓN
          pagosAsync.when(
            loading: () => const SizedBox(height: 16),
            error: (e, _) => const SizedBox(height: 16),
            data: (pagos) {
              // Filtrar pagos por la gestión seleccionada o actual
              final gestion = anioSeleccionado != null
                  ? int.tryParse(anioSeleccionado!) ?? gestionActual
                  : gestionActual;
              final pagosGestion =
                  pagos.where((p) => p.fechaPago.year == gestion).toList();

              // Lógica de estado general SOLO para la gestión seleccionada
              int ultimoMesPagado = -1;
              for (var pago in pagosGestion) {
                if (pago.estado == 'pagado') {
                  int mesIndex = mesesDelAno.indexOf(pago.mes);
                  if (mesIndex > ultimoMesPagado) {
                    ultimoMesPagado = mesIndex;
                  }
                }
              }
              int mesActual = (gestion == DateTime.now().year)
                  ? DateTime.now().month - 1
                  : 11; // Si es gestión pasada, considera hasta diciembre

              int mesesDeuda = mesActual - ultimoMesPagado;

              Color estadoColor;
              String estadoTexto;

              if (pagosGestion.isEmpty) {
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

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Text(
                      'Estado general:',
                      //tamaño del texto

                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        estadoTexto,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      backgroundColor: estadoColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      visualDensity: VisualDensity.compact,
                    ),
                    const Spacer(),
                    Text(
                      'Gestión: $gestion',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: pagosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (pagos) {
                // Filtrar por año si está seleccionado
                final pagosFiltradosPorAnio = anioSeleccionado == null
                    ? pagos
                    : pagos
                        .where((p) =>
                            p.fechaPago.year.toString() == anioSeleccionado)
                        .toList();

                // Filtrar por estado si está seleccionado
                final pagosFiltrados = estadoSeleccionado == 'todos'
                    ? pagosFiltradosPorAnio
                    : pagosFiltradosPorAnio
                        .where((p) => p.estado == estadoSeleccionado)
                        .toList();

                // Ordenar por orden de meses
                pagosFiltrados.sort((a, b) {
                  final mesA = mesesDelAno.indexOf(a.mes);
                  final mesB = mesesDelAno.indexOf(b.mes);
                  return mesA.compareTo(mesB);
                });

                // Mostrar pagos registrados
                final mesesPagados = pagosFiltrados.map((p) => p.mes).toSet();
                final items = <Widget>[];

                for (final pago in pagosFiltrados) {
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
                  items.add(Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: estadoColor,
                        child:
                            const Icon(Icons.attach_money, color: Colors.white),
                      ),
                      title: Text(
                          '${pago.mes} -  ${pago.monto.toStringAsFixed(2)} Bs.'),
                      //añadir gestion

                      subtitle: Text(
                        'Gestión: ${pago.fechaPago.year}\n'
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
                      onTap: pago.estado != 'pagado'
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentForm(
                                    jugadorId: widget.jugadorId,
                                    jugadorNombre: widget.jugadorNombre,
                                    mesInicial: pago.mes,
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  ));
                }

                // Mostrar meses pendientes por defecto (solo si no hay pago registrado para ese mes)
                for (final mes in mesesDelAno) {
                  if (!mesesPagados.contains(mes)) {
                    items.add(Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.attach_money, color: Colors.white),
                        ),
                        title: Text('$mes - S/ 0.00'),
                        subtitle: const Text('Pendiente de pago'),
                        trailing: const Chip(
                          label: Text('PENDIENTE',
                              style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.orange,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentForm(
                                jugadorId: widget.jugadorId,
                                jugadorNombre: widget.jugadorNombre,
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
          ),
        ],
      ),
    );
  }
}
