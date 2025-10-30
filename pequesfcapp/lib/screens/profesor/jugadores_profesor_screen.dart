import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/player_model.dart';
import '../../models/categoria_equipo_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/categoria_equipo_provider.dart';

class JugadoresProfesorScreen extends ConsumerStatefulWidget {
  /// campo categoriaEquipoId del profesor. Puede ser:
  /// - un id único: "6723..."
  /// - una lista en string JSON: '["id1","id2"]'
  /// - varios ids separados por comas: "id1,id2"
  final String categoriaEquipoIdProfesor;

  const JugadoresProfesorScreen(
      {Key? key, required this.categoriaEquipoIdProfesor})
      : super(key: key);

  @override
  ConsumerState<JugadoresProfesorScreen> createState() =>
      _JugadoresProfesorScreenState();
}

class _JugadoresProfesorScreenState
    extends ConsumerState<JugadoresProfesorScreen> {
  String filtro = '';
  final searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    filtro = '';
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<String> _parseAssignedIds(String raw) {
    if (raw.trim().isEmpty) return [];
    try {
      final parsed = json.decode(raw);
      if (parsed is List)
        return parsed
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
    } catch (_) {}
    if (raw.contains(',')) {
      return raw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [raw.trim()];
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriasEquiposProvider);
    final jugadoresAsync = ref.watch(playersProvider);

    return Scaffold(
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar jugador...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) =>
                  setState(() => searchQuery = value.toLowerCase()),
            ),
          ),

          // Selector: SOLO las categorías asignadas al profesor
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mis equipos', // título pequeño encima del dropdown
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
                      child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => Container(
                    height: 56,
                    alignment: Alignment.centerLeft,
                    child: Text('Error cargando categorías: $e',
                        style: const TextStyle(color: Colors.red)),
                  ),
                  data: (categorias) {
                    final assignedIds =
                        _parseAssignedIds(widget.categoriaEquipoIdProfesor).toSet();

                    // Filtrar solo categorias cuyo id esté en assignedIds
                    final equiposAsignados = categorias
                        .where((c) => assignedIds.contains(c.id))
                        .toList();

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
                        child: const Text('No tienes equipos asignados',
                            style: TextStyle(color: Colors.grey)),
                      );
                    }

                    // asegurar filtro válido: si no está en la lista, setear al primero (post-frame)
                    final ids = equiposAsignados.map((e) => e.id).toSet();
                    if (filtro.isEmpty || !ids.contains(filtro)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted)
                          setState(() => filtro = equiposAsignados.first.id);
                      });
                    }

                    final items = equiposAsignados
                    
                        .map((c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text('${c.categoria} - ${c.equipo}'),
                            ))
                        .toList();

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
                          value: ids.contains(filtro)
                              ? filtro
                              : equiposAsignados.first.id,
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

          // Lista de jugadores filtrada por la categoria seleccionada y por búsqueda
          Expanded(
            child: jugadoresAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error cargando jugadores: $e')),
              data: (jugadores) {
                if (filtro.isEmpty)
                  return const Center(child: CircularProgressIndicator());

                var jugadoresFiltrados = jugadores
                    .where((j) => j.categoriaEquipoId == filtro)
                    .toList();

                if (searchQuery.isNotEmpty) {
                  jugadoresFiltrados = jugadoresFiltrados.where((j) {
                    final fullName = '${j.nombres} ${j.apellido}'.toLowerCase();
                    return fullName.contains(searchQuery) ||
                        j.ci.toLowerCase().contains(searchQuery);
                  }).toList();
                }

                if (jugadoresFiltrados.isEmpty) {
                  return Center(
                    child:
                        Column(mainAxisSize: MainAxisSize.min, children: const [
                      Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No hay jugadores para este equipo',
                          style: TextStyle(color: Colors.grey)),
                    ]),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: jugadoresFiltrados.length,
                  itemBuilder: (context, index) {
                    final jugador = jugadoresFiltrados[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage: const AssetImage('assets/jugador.png'),
                          backgroundColor: Colors.grey.shade100,
                        ),
                        title: Text('${jugador.nombres} ${jugador.apellido}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('CI: ${jugador.ci}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // TODO: ver detalle jugador
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
