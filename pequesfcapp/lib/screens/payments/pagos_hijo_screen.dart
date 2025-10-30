import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/player_model.dart';
import '../../models/categoria_equipo_model.dart';
import '../../providers/pago_provider.dart';
import '../../providers/categoria_equipo_provider.dart';
import 'historial_pagos_hijo_screen.dart';

class PagosHijoScreen extends ConsumerWidget {
  final List<PlayerModel> hijos;

  const PagosHijoScreen({Key? key, required this.hijos}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriasAsync = ref.watch(categoriasEquiposProvider);
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month - 1; // 0-based index

    return Scaffold(
      body: ListView.builder(
        itemCount: hijos.length,
        itemBuilder: (context, index) {
          final hijo = hijos[index];
          final pagosAsync = ref.watch(pagosPorJugadorProvider(hijo.id));

          return pagosAsync.when(
            loading: () => const Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(title: Text('Cargando pagos...')),
            ),
            error: (e, _) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(title: Text('Error: $e')),
            ),
            data: (pagos) {
              // Filtrar pagos del año actual
              final pagosGestion = pagos.where((p) => p.anio == currentYear).toList();

              // Calcular estado de pagos
              int ultimoMesPagado = -1;
              for (var pago in pagosGestion.where((p) => p.estado == 'pagado')) {
                int mesIndex = mesesPendientesPorDefecto.indexOf(pago.mes);
                if (mesIndex > ultimoMesPagado) {
                  ultimoMesPagado = mesIndex;
                }
              }

              // Calcular estado y meses de deuda
              final mesesDeuda = currentMonth - ultimoMesPagado;
              final estadoPago = _calcularEstadoPago(
                pagosGestion.isEmpty, 
                ultimoMesPagado, 
                currentMonth, 
                mesesDeuda
              );
              final estadoColor = estadoPago.$1;
              final estadoTexto = estadoPago.$2;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: estadoColor,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    '${hijo.nombres} ${hijo.apellido}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: categoriasAsync.when(
                    loading: () => const Text('Cargando categoría...'),
                    error: (_, __) => const Text('Categoría desconocida'),
                    data: (categorias) {
                      final categoria = categorias.firstWhere(
                        (c) => c.id == hijo.categoriaEquipoId,
                        orElse: () =>  CategoriaEquipoModel(
                          id: '',
                          categoria: 'Sin asignar',
                          equipo: '',
                        ),
                      );
                      return Text(
                        'Categoría: ${categoria.categoria} - ${categoria.equipo}',
                        style: const TextStyle(fontSize: 13),
                      );
                    },
                  ),
                  trailing: Chip(
                    label: Text(
                      estadoTexto,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: estadoColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    visualDensity: VisualDensity.compact,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistorialPagosHijoScreen(hijo: hijo),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  (Color, String) _calcularEstadoPago(
    bool sinRegistros,
    int ultimoMesPagado,
    int mesActual,
    int mesesDeuda,
  ) {
    if (sinRegistros) {
      return (Colors.grey, 'Sin registro');
    }
    if (ultimoMesPagado >= mesActual) {
      return (Colors.green, 'Pagado');
    }
    if (mesesDeuda > 3) {
      return (Colors.red, 'Atrasado');
    }
    return (Colors.orange, 'Pendiente');
  }
}

// Lista de meses constante
const List<String> mesesPendientesPorDefecto = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
];