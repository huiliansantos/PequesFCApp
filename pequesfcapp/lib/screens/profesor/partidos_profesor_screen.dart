import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/match_model.dart';
import '../../models/categoria_equipo_model.dart';
import '../../providers/match_provider.dart';
import '../../providers/categoria_equipo_provider.dart';

class PartidosProfesorScreen extends ConsumerStatefulWidget {
  /// Campo `categoriaEquipoId` del profesor.
  /// Puede ser:
  /// - un id único: "6723..."
  /// - una lista JSON: '["id1","id2"]'
  /// - varios ids separados por comas: "id1,id2"
  final String categoriaEquipoIdProfesor;

  const PartidosProfesorScreen({
    Key? key,
    required this.categoriaEquipoIdProfesor,
  }) : super(key: key);

  @override
  ConsumerState<PartidosProfesorScreen> createState() => _PartidosProfesorScreenState();
}

class _PartidosProfesorScreenState extends ConsumerState<PartidosProfesorScreen> {
  String filtro = '';
  List<String> _assignedIds = [];

  @override
  void initState() {
    super.initState();
    _assignedIds = _parseAssignedIds(widget.categoriaEquipoIdProfesor);
    // dejar vacío hasta cargar categorías para validar; se ajustará cuando haya items
    filtro = '';
  }

  List<String> _parseAssignedIds(String raw) {
    if (raw.trim().isEmpty) return [];
    try {
      final parsed = json.decode(raw);
      if (parsed is List) return parsed.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    } catch (_) {}
    if (raw.contains(',')) {
      return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [raw.trim()];
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriasEquiposProvider);
    final partidosAllAsync = ref.watch(partidosProviderAll);

    return Scaffold(
        body: Column(
        children: [
          // Selector: SOLO las categorías asignadas al profesor (titulo encima)
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
                  loading: () => const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Container(
                    height: 56,
                    alignment: Alignment.centerLeft,
                    child: Text('Error cargando categorías: $e', style: const TextStyle(color: Colors.red)),
                  ),
                  data: (categorias) {
                    // Filtrar solo categorias asignadas
                    final equiposAsignados = categorias.where((c) => _assignedIds.contains(c.id)).toList();

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

                    // Asegurar filtro válido: si no existe, seleccionar 'todos' por defecto
                    final ids = equiposAsignados.map((e) => e.id).toSet();
                    if (filtro.isEmpty || (!ids.contains(filtro) && filtro != 'todos')) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => filtro = 'todos'); // por defecto mostrar todos los equipos asignados
                      });
                    }

                    final items = <DropdownMenuItem<String>>[];
                    // opción 'todos' para mostrar partidos de todos los equipos asignados
                    items.add(const DropdownMenuItem(value: 'todos', child: Text('Todos los equipos')));
                    // añadir cada equipo asignado
                    for (final c in equiposAsignados) {
                      items.add(DropdownMenuItem(value: c.id, child: Text('${c.categoria} - ${c.equipo}')));
                    }

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

          // Lista de partidos
          Expanded(
            child: partidosAllAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error cargando partidos: $e')),
              data: (partidosAll) {
                // map de categorias para nombres rápidos
                final Map<String, CategoriaEquipoModel> categoriasMap = {
                  for (var c in (ref.read(categoriasEquiposProvider).maybeWhen(data: (v) => v, orElse: () => <CategoriaEquipoModel>[]))) c.id: c
                };

                // filtrar partidos según filtro:
                List<MatchModel> partidos;
                if (filtro == 'todos') {
                  // todos los partidos de los equipos asignados
                  partidos = partidosAll.where((p) => _assignedIds.contains(p.categoriaEquipoId)).toList();
                } else {
                  partidos = partidosAll.where((p) => p.categoriaEquipoId == filtro).toList();
                }

                if (partidos.isEmpty) {
                  return const Center(child: Text('No hay partidos programados.'));
                }

                partidos.sort((a, b) => b.fecha.compareTo(a.fecha));

                return ListView.builder(
                  itemCount: partidos.length,
                  itemBuilder: (context, index) {
                    final partido = partidos[index];
                    final cat = categoriasMap[partido.categoriaEquipoId];
                    final catNombre = cat != null ? '${cat.categoria} - ${cat.equipo}' : partido.categoriaEquipoId;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
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
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    catNombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Image.asset('assets/peques.png', width: 32, height: 32),
                                const SizedBox(width: 8),
                                Text(
                                  partido.hora,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF57C00),
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Image.asset('assets/rival.png', width: 32, height: 32),
                                Expanded(
                                  child: Text(
                                    partido.equipoRival,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: const [
                                Icon(Icons.location_on, color: Color(0xFFD32F2F), size: 18),
                                SizedBox(width: 4),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Color(0xFFD32F2F), size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  'Fecha: ${partido.fecha.day}/${partido.fecha.month}/${partido.fecha.year}',
                                  style: const TextStyle(color: Colors.black54, fontSize: 14),
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
            ),
          ),
        ],
      ),
    );
  }
}