import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/player_model.dart';
import '../../models/match_model.dart';
import '../../providers/match_provider.dart';
import '../../providers/categoria_equipo_provider.dart';
import '../../models/categoria_equipo_model.dart';

class PartidosHijoScreen extends ConsumerStatefulWidget {
  final List<PlayerModel> hijos;

  const PartidosHijoScreen({Key? key, required this.hijos}) : super(key: key);

  @override
  ConsumerState<PartidosHijoScreen> createState() => _PartidosHijoScreenState();
}

class _PartidosHijoScreenState extends ConsumerState<PartidosHijoScreen> {
  String filtro = 'mis_hijos';

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriasEquiposProvider);
    final partidosAsync = ref.watch(partidosProviderAll);
    
    // IDs de equipos de los hijos (solo válidos)
    final idsCategoriaHijos = widget.hijos
        .map((h) => h.categoriaEquipoId)
        .where((id) => id != null && id.isNotEmpty)
        .toSet()
        .toList();

    return Column(
      children: [
        // Filtro
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: categoriasAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error cargando categorías: $e'),
            data: (categorias) {
              return Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: filtro,
                      items: [
                        const DropdownMenuItem(
                          value: 'mis_hijos', 
                          child: Text('Mis hijos')
                        ),
                        const DropdownMenuItem(
                          value: 'todos', 
                          child: Text('Todos')
                        ),
                        ...categorias.map((cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text('${cat.categoria} - ${cat.equipo}'),
                        )),
                      ],
                      onChanged: (value) => setState(() => filtro = value!),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        if (filtro == 'mis_hijos' && idsCategoriaHijos.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: Text('No tienes hijos asignados.')),
          ),

        if (!(filtro == 'mis_hijos' && idsCategoriaHijos.isEmpty))
          Expanded(
            child: partidosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (partidos) {
                // Filtrar partidos según filtro
                final partidosFiltrados = _filtrarPartidos(
                  partidos, 
                  filtro, 
                  idsCategoriaHijos
                );

                if (partidosFiltrados.isEmpty) {
                  return const Center(
                    child: Text('No hay partidos programados.')
                  );
                }

                return ListView.builder(
                  itemCount: partidosFiltrados.length,
                  itemBuilder: (context, index) {
                    return _PartidoCard(
                      partido: partidosFiltrados[index],
                      hijo: filtro == 'mis_hijos' 
                        ? _buscarHijoParaPartido(
                            partidosFiltrados[index], 
                            widget.hijos
                          ) 
                        : null,
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  List<MatchModel> _filtrarPartidos(
    List<MatchModel> partidos, 
    String filtro, 
    List<String> idsCategoriaHijos
  ) {
    List<MatchModel> filtered;
    
    if (filtro == 'todos') {
      filtered = partidos;
    } else if (filtro == 'mis_hijos') {
      filtered = partidos.where((p) => 
        idsCategoriaHijos.contains(p.categoriaEquipoId)
      ).toList();
    } else {
      filtered = partidos.where((p) => 
        p.categoriaEquipoId == filtro
      ).toList();
    }

    // Ordenar por fecha descendente
    filtered.sort((a, b) => b.fecha.compareTo(a.fecha));
    return filtered;
  }

  PlayerModel? _buscarHijoParaPartido(
    MatchModel partido, 
    List<PlayerModel> hijos
  ) {
    return hijos.firstWhere((h) => 
      h.categoriaEquipoId == partido.categoriaEquipoId
    );
  }
}

class _PartidoCard extends ConsumerWidget {
  final MatchModel partido;
  final PlayerModel? hijo;

  const _PartidoCard({
    required this.partido,
    this.hijo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriasAsync = ref.watch(categoriasEquiposProvider);

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

            if (hijo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  'Hijo: ${hijo!.nombres} ${hijo!.apellido}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontSize: 13,
                  ),
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: categoriasAsync.when(
                    loading: () => const Text('Cargando...'),
                    error: (_, __) => const Text('Error'),
                    data: (categorias) {
                      final cat = categorias.firstWhere(
                        (c) => c.id == partido.categoriaEquipoId,
                        orElse: () =>  CategoriaEquipoModel(
                          id: '', 
                          categoria: 'Sin asignar',
                          equipo: ''
                        ),
                      );
                      return Text(
                        '${cat.categoria} - ${cat.equipo}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ),
                Image.asset(
                  'assets/peques.png',
                  width: 32,
                  height: 32,
                ),
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
            _InfoRow(
              icon: Icons.location_on,
              text: partido.cancha,
            ),
            const SizedBox(height: 4),
            _InfoRow(
              icon: Icons.calendar_today,
              text: 'Fecha: ${partido.fecha.day}/${partido.fecha.month}/${partido.fecha.year}',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFD32F2F), size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
