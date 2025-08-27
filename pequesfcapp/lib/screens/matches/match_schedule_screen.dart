import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/match_provider.dart';
import '../../models/match_model.dart';

class MatchScheduleScreen extends ConsumerStatefulWidget {
  const MatchScheduleScreen({super.key});

  @override
  ConsumerState<MatchScheduleScreen> createState() => _MatchScheduleScreenState();
}

class _MatchScheduleScreenState extends ConsumerState<MatchScheduleScreen> {
  String? categoriaSeleccionada;

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchesProvider);

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (partidos) {
        // Obtén las categorías únicas
        final categorias = partidos.map((p) => p.categoria).toSet().toList();

        // Filtra por categoría
        final partidosFiltrados = partidos.where((partido) {
          return categoriaSeleccionada == null || partido.categoria == categoriaSeleccionada;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFFD32F2F), size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Calendario de Partidos',
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
            Padding(
              padding: const EdgeInsets.all(8.0),
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
            ),            
            Expanded(
              child: partidosFiltrados.isEmpty
                  ? const Center(child: Text('No hay partidos para esta categoría.'))
                  : ListView.builder(
                      itemCount: partidosFiltrados.length,
                      itemBuilder: (context, index) {
                        final partido = partidosFiltrados[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: ListTile(
                            leading: Image.asset(
                              'assets/peques.png',
                              width: 50,
                              height: 50,
                            ),
                            title: Text('${partido.equipoRival} (${partido.categoria})'),
                            subtitle: Text(
                              'Fecha: ${partido.fecha.day}/${partido.fecha.month}/${partido.fecha.year} '
                              'Hora: ${partido.hora}\n'
                              'Lugar: ${partido.cancha}',
                            ),
                            onTap: () {
                              // Acción para ver detalle del partido
                            },
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () {
                    // Acción para agregar un nuevo partido
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}