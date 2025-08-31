import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/resultado_provider.dart';
import '../../providers/match_provider.dart';
import '../../models/resultado_model.dart';
import '../../models/match_model.dart';
import 'resultado_form_screen.dart';
import 'resultado_detail_screen.dart';

class ResultadosListScreen extends ConsumerStatefulWidget {
  const ResultadosListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ResultadosListScreen> createState() => _ResultadosListScreenState();
}

class _ResultadosListScreenState extends ConsumerState<ResultadosListScreen> {
  String? categoriaSeleccionada;

  @override
  Widget build(BuildContext context) {
    final resultadosAsync = ref.watch(resultadosStreamProvider);
    final partidosAsync = ref.watch(matchesProvider);

    return Scaffold(
        body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.sports_soccer, color: Color(0xFFD32F2F), size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Resultados de Partidos',
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          partidosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (partidos) {
              final categorias = partidos.map((p) => p.categoria).toSet().toList();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
              );
            },
          ),
          Expanded(
            child: resultadosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (resultados) => partidosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (partidos) {
                  if (resultados.isEmpty) {
                    return const Center(child: Text('No hay resultados registrados.'));
                  }
                  // Filtrar resultados por categoría seleccionada
                  final resultadosFiltrados = resultados.where((resultado) {
                    final partido = partidos.firstWhere(
                      (p) => p.id == resultado.partidoId,
                      orElse: () => MatchModel(
                        id: '',
                        equipoRival: 'Desconocido',
                        cancha: '',
                        fecha: DateTime.now(),
                        hora: '',
                        torneo: '',
                        categoria: '',
                        equipoId: '',
                      ),
                    );
                    return categoriaSeleccionada == null ||
                        partido.categoria == categoriaSeleccionada;
                  }).toList();

                  if (resultadosFiltrados.isEmpty) {
                    return const Center(child: Text('No hay resultados para esta categoría.'));
                  }

                  return ListView.builder(
                    itemCount: resultadosFiltrados.length,
                    itemBuilder: (context, index) {
                      final resultado = resultadosFiltrados[index];
                      final partido = partidos.firstWhere(
                        (p) => p.id == resultado.partidoId,
                        orElse: () => MatchModel(
                          id: '',
                          equipoRival: 'Desconocido',
                          cancha: '',
                          fecha: DateTime.now(),
                          hora: '',
                          torneo: '',
                          categoria: '',
                          equipoId: '',
                        ),
                      );
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResultadoDetailScreen(resultado: resultado),
                              ),
                            );
                          },
                          onLongPress: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              builder: (context) => Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.edit, color: Color(0xFFD32F2F)),
                                      title: const Text('Modificar resultado'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ResultadoFormScreen(resultado: resultado),
                                          ),
                                        );
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.delete, color: Colors.red),
                                      title: const Text('Eliminar resultado'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        // Implementa la lógica de eliminación aquí
                                        // ref.read(resultadoRepositoryProvider).deleteResultado(resultado.id);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/peques.png',
                                  width: 40,
                                  height: 40,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${partido.equipoRival} (${partido.fecha.day}/${partido.fecha.month})',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text('Cancha: ${partido.cancha}'),
                                      Text('Torneo: ${partido.torneo}'),
                                      if (resultado.observaciones.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            'Obs: ${resultado.observaciones}',
                                            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: resultado.golesFavor > resultado.golesContra
                                        ? Colors.green
                                        : resultado.golesFavor == resultado.golesContra
                                            ? Colors.orange
                                            : Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${resultado.golesFavor}-${resultado.golesContra}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}