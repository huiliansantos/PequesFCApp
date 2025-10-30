import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/player_model.dart';
import '../../models/categoria_equipo_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/pago_provider.dart';
import '../../providers/categoria_equipo_provider.dart';

class PagosProfesorScreen extends ConsumerStatefulWidget {
  final String categoriaEquipoIdProfesor;

  const PagosProfesorScreen({Key? key, required this.categoriaEquipoIdProfesor}) : super(key: key);

  @override
  ConsumerState<PagosProfesorScreen> createState() => _PagosProfesorScreenState();
}

class _PagosProfesorScreenState extends ConsumerState<PagosProfesorScreen> {
  String filtro = '';

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
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriasEquiposProvider);
    final jugadoresAsync = ref.watch(playersProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Selector de equipo con título "Mis equipos"
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

                      // Asegurar filtro válido
                      if (filtro.isEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => filtro = equiposAsignados.first.id);
                        });
                      }

                      final items = equiposAsignados.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.categoria} - ${c.equipo}'),
                          )).toList();

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
                            value: filtro.isNotEmpty ? filtro : equiposAsignados.first.id,
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

            // Lista de jugadores con sus pagos
            Expanded(
              child: jugadoresAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (jugadores) {
                  if (filtro.isEmpty) return const Center(child: CircularProgressIndicator());

                  final jugadoresFiltrados = jugadores.where((j) => j.categoriaEquipoId == filtro).toList();

                  if (jugadoresFiltrados.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No hay jugadores en este equipo', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: jugadoresFiltrados.length,
                    itemBuilder: (context, index) {
                      final jugador = jugadoresFiltrados[index];
                      final pagosAsync = ref.watch(pagosPorJugadorProvider(jugador.id));

                      return pagosAsync.when(
                        loading: () => const Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(title: Text('Cargando pagos...')),
                        ),
                        error: (e, _) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(title: Text('Error: $e')),
                        ),
                        data: (pagos) {
                          final pagados = pagos.where((p) => p.estado == 'pagado').length;
                          final pendientes = pagos.where((p) => p.estado == 'pendiente').length;
                          final atrasados = pagos.where((p) => p.estado == 'atrasado').length;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Avatar section
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage: const AssetImage('assets/jugador.png'),
                                    backgroundColor: Colors.grey.shade100,
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Name and status indicators
                                  Expanded(
                                    child: Row(
                                      children: [
                                        // Name and status column
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Name
                                              Text(
                                                '${jugador.nombres} ${jugador.apellido}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              
                                              // Status indicators in vertical layout
                                              Row(
                                                children: [
                                                  // Status dots column
                                                  Column(
                                                    children: [
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: const BoxDecoration(
                                                          color: Colors.green,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: const BoxDecoration(
                                                          color: Colors.orange,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: BoxDecoration(
                                                          gradient: const LinearGradient(
                                                            colors: [Colors.yellow, Colors.black],
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.bottomRight,
                                                          ),
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Status text column
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Pagados: $pagados',
                                                        style: const TextStyle(
                                                          color: Colors.black54,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Pendientes: $pendientes',
                                                        style: const TextStyle(
                                                          color: Colors.black54,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Atrasados: $atrasados',
                                                        style: const TextStyle(
                                                          color: Colors.black54,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Arrow icon
                                  const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
                                ],
                              ),
                            ),
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