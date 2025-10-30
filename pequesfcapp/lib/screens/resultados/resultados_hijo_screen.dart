import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/player_model.dart';
import '../../models/resultado_model.dart';
import '../../models/match_model.dart';
import '../../providers/resultado_provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/categoria_equipo_provider.dart';
import '../../models/categoria_equipo_model.dart';

class ResultadosHijoScreen extends ConsumerStatefulWidget {
  final List<PlayerModel> hijos;

  const ResultadosHijoScreen({Key? key, required this.hijos}) : super(key: key);

  @override
  ConsumerState<ResultadosHijoScreen> createState() => _ResultadosHijoScreenState();
}

class _ResultadosHijoScreenState extends ConsumerState<ResultadosHijoScreen> {
  String filtro = 'mis_hijos'; // 'todas' o categoriaEquipoId

  @override
  Widget build(BuildContext context) {
    final idsCategoriaHijos = widget.hijos
        .map((h) => h.categoriaEquipoId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final resultadosAsync = ref.watch(resultadosStreamProvider);
    final partidosAsync = ref.watch(matchesProvider);
    final categoriasAsync = ref.watch(categoriasEquiposProvider);

    return Column(
      children: [
        // Filtro (usa categoriasProvider)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: categoriasAsync.when(
            loading: () => const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: filtro,
                    items: const [
                      DropdownMenuItem(value: 'mis_hijos', child: Text('Mis hijos')),
                      DropdownMenuItem(value: 'todas', child: Text('Todas')),
                    ],
                    onChanged: (v) => setState(() { filtro = v ?? 'mis_hijos'; }),
                  ),
                ),
              ],
            ),
            data: (categorias) {
              final dropdownItems = <DropdownMenuItem<String>>[
                const DropdownMenuItem(value: 'mis_hijos', child: Text('Mis hijos')),
                const DropdownMenuItem(value: 'todas', child: Text('Todas')),
                ...categorias.map((cat) => DropdownMenuItem(
                      value: cat.id,
                      child: Text('${cat.categoria} - ${cat.equipo}'),
                    )),
              ];
              return Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: filtro,
                      items: dropdownItems,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => filtro = value);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Contenido: combinar resultados + partidos + categorias
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

                      // Filtrar resultados según filtro
                      final List<ResultadoModel> resultadosFiltrados = resultados.where((resultado) {
                        final partido = partidosMap[resultado.partidoId];
                        if (partido == null) return false; // omitir resultados sin partido conocido

                        if (filtro == 'todas') return true;
                        if (filtro == 'mis_hijos') return idsCategoriaHijos.contains(partido.categoriaEquipoId);
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
                        itemBuilder: (context, index) {
                          final resultado = resultadosFiltrados[index];
                          final partido = partidosMap[resultado.partidoId];
                          // seguridad: si partido es null (aunque filtramos) devolvemos vacío
                          if (partido == null) return const SizedBox.shrink();

                          // Nombre de la categoría
                          final cat = categoriasMap[partido.categoriaEquipoId];
                          final categoriaNombre = cat != null ? '${cat.categoria} - ${cat.equipo}' : partido.categoriaEquipoId;

                          // Hijo asociado (primer match por categoría)
                          String? nombreHijo;
                          if (filtro == 'mis_hijos') {
                            final hijo = widget.hijos.firstWhere(
                              (h) => h.categoriaEquipoId == partido.categoriaEquipoId,
                              orElse: () => PlayerModel(
                                id: '',
                                nombres: '',
                                apellido: '',
                                categoriaEquipoId: '',
                                fechaDeNacimiento: DateTime(2000, 1, 1),
                                genero: '',
                                foto: '',
                                ci: '',
                                nacionalidad: '',
                              ),
                            );
                            if (hijo.id.isNotEmpty) nombreHijo = '${hijo.nombres} ${hijo.apellido}';
                          }

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
                                  if (nombreHijo != null && nombreHijo.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Text(
                                        'Hijo: $nombreHijo',
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
                                        child: Text(
                                          categoriaNombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Image.asset(
                                        'assets/peques.png',
                                        width: 32,
                                        height: 32,
                                      ),
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
                                      Image.asset(
                                        'assets/rival.png',
                                        width: 32,
                                        height: 32,
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
    );
  }
}