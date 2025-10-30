import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/resultado_model.dart';
import '../../models/match_model.dart';
import '../../models/categoria_equipo_model.dart';
import '../../providers/resultado_provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/categoria_equipo_provider.dart';

class ResultadosProfesorScreen extends ConsumerStatefulWidget {
  /// campo `categoriaEquipoId` del profesor.
  /// puede ser: un id único, una lista JSON '["id1","id2"]' o 'id1,id2'
  final String categoriaEquipoIdProfesor;

  const ResultadosProfesorScreen({Key? key, required this.categoriaEquipoIdProfesor}) : super(key: key);

  @override
  ConsumerState<ResultadosProfesorScreen> createState() => _ResultadosProfesorScreenState();
}

class _ResultadosProfesorScreenState extends ConsumerState<ResultadosProfesorScreen> {
  String filtro = 'todos';

  List<String> _parseAssignedIds(String raw) {
    if (raw.trim().isEmpty) return [];
    try {
      final parsed = json.decode(raw);
      if (parsed is List) return parsed.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    } catch (_) {}
    if (raw.contains(',')) return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return [raw.trim()];
  }

  @override
  void initState() {
    super.initState();
    filtro = 'todos';
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriasEquiposProvider);
    final resultadosAsync = ref.watch(resultadosStreamProvider);
    final partidosAsync = ref.watch(matchesProvider);

    return Scaffold(
      // sin AppBar por pedido
      body: SafeArea(
        child: Column(
          children: [
            // Dropdown título + selector de equipos asignados
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mis equipos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  categoriasAsync.when(
                    loading: () => const SizedBox(height: 56, child: Center(child: CircularProgressIndicator())),
                    error: (e, _) => Container(
                      height: 56,
                      alignment: Alignment.centerLeft,
                      child: Text('Error cargando categorías: $e', style: const TextStyle(color: Colors.red)),
                    ),
                    data: (categorias) {
                      final assignedIds = _parseAssignedIds(widget.categoriaEquipoIdProfesor).toSet();
                      final equiposAsignados = categorias.where((c) => assignedIds.contains(c.id)).toList();

                      if (equiposAsignados.isEmpty) {
                        return Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text('No tienes equipos asignados', style: TextStyle(color: Colors.grey)),
                        );
                      }

                      final ids = equiposAsignados.map((e) => e.id).toSet();
                      if (!ids.contains(filtro) && filtro != 'todos') {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => filtro = equiposAsignados.first.id);
                        });
                      }

                      final items = <DropdownMenuItem<String>>[
                        const DropdownMenuItem(value: 'todos', child: Text('Todos mis equipos')),
                        ...equiposAsignados.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text('${c.categoria} - ${c.equipo}'),
                            )),
                      ];

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: ids.contains(filtro) || filtro == 'todos' ? filtro : equiposAsignados.first.id,
                            items: items,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => filtro = value);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Contenido: combinar resultados + partidos + categorias para mostrar tarjetas
            Expanded(
              child: resultadosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error resultados: $e')),
                data: (resultados) {
                  return partidosAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error partidos: $e')),
                    data: (partidos) {
                      return categoriasAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error categorías: $e')),
                        data: (categorias) {
                          // Mapas para accesos rápidos
                          final partidosMap = {for (var p in partidos) p.id: p};
                          final categoriasMap = {for (var c in categorias) c.id: c};
                          final assignedIds = _parseAssignedIds(widget.categoriaEquipoIdProfesor).toSet();

                          // Filtrar resultados según filtro
                          final List<ResultadoModel> resultadosFiltrados = resultados.where((resultado) {
                            final partido = partidosMap[resultado.partidoId];
                            if (partido == null) return false;
                            if (filtro == 'todos') return assignedIds.contains(partido.categoriaEquipoId);
                            return partido.categoriaEquipoId == filtro;
                          }).toList();

                          // Ordenar por fecha del partido (desc)
                          resultadosFiltrados.sort((a, b) {
                            final pa = partidosMap[a.partidoId];
                            final pb = partidosMap[b.partidoId];
                            final da = pa?.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
                            final db = pb?.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
                            return db.compareTo(da);
                          });

                          if (resultadosFiltrados.isEmpty) {
                            return const Center(child: Text('No hay resultados para mostrar.'));
                          }

                          return ListView.builder(
                            itemCount: resultadosFiltrados.length,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemBuilder: (context, index) {
                              final resultado = resultadosFiltrados[index];
                              final partido = partidosMap[resultado.partidoId];
                              if (partido == null) return const SizedBox.shrink();

                              final cat = categoriasMap[partido.categoriaEquipoId];
                              final categoriaNombre = cat != null ? '${cat.categoria} - ${cat.equipo}' : partido.categoriaEquipoId;

                              final marcador = '${resultado.golesFavor}-${resultado.golesContra}';
                              Color resultadoColor;
                              if (resultado.golesFavor > resultado.golesContra) {
                                resultadoColor = Colors.green;
                              } else if (resultado.golesFavor == resultado.golesContra) {
                                resultadoColor = Colors.amber;
                              } else {
                                resultadoColor = Colors.red;
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 3,
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (partido.torneo.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Text(
                                            partido.torneo,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFD32F2F),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              categoriaNombre,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Image.asset('assets/peques.png', width: 32, height: 32),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: resultadoColor,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              marcador,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Image.asset('assets/rival.png', width: 32, height: 32),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              partido.equipoRival,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, color: Color(0xFFD32F2F), size: 16),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              partido.cancha,
                                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, color: Color(0xFFD32F2F), size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Fecha: ${partido.fecha.day}/${partido.fecha.month}/${partido.fecha.year}',
                                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
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
      ),
    );
  }
}