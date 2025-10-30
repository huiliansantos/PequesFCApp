import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../asistencias/registro_asistencia_screen.dart';
import '../asistencias/ver_lista_asistencia_screen.dart';
import '../../models/categoria_equipo_model.dart';
import '../../providers/categoria_equipo_provider.dart';

class AsistenciaProfesorScreen extends ConsumerStatefulWidget {
  /// Puede ser:
  /// - un id único: "6723..."
  /// - una lista JSON: '["id1","id2"]'
  /// - varios ids separados por comas: "id1,id2"
  final String categoriaEquipoIdProfesor;

  const AsistenciaProfesorScreen({Key? key, required this.categoriaEquipoIdProfesor}) : super(key: key);

  @override
  ConsumerState<AsistenciaProfesorScreen> createState() => _AsistenciaProfesorScreenState();
}

class _AsistenciaProfesorScreenState extends ConsumerState<AsistenciaProfesorScreen> {
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

    final assignedIds = _parseAssignedIds(widget.categoriaEquipoIdProfesor).toSet();

    return Scaffold(
      // sin AppBar (como pediste)
      body: SafeArea(
        child: Column(
          children: [
            // Título y dropdown "Mis equipos"
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
                      // Filtrar solo las categorias asignadas al profesor
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

                      // Asegurar valor de filtro válido
                      final ids = equiposAsignados.map((e) => e.id).toSet();
                      if (!ids.contains(filtro) && filtro != 'todos') {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => filtro = 'todos');
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

            // Lista de tarjetas: muestra todas las categorías asignadas (si filtro == 'todos')
            // o únicamente la seleccionada
            Expanded(
              child: categoriasAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error cargando categorías: $e')),
                data: (categorias) {
                  final equiposAsignados = categorias.where((c) => assignedIds.contains(c.id)).toList();

                  final List<CategoriaEquipoModel> mostrar;
                  if (filtro == 'todos') {
                    mostrar = equiposAsignados;
                  } else {
                    mostrar = equiposAsignados.where((c) => c.id == filtro).toList();
                  }

                  if (mostrar.isEmpty) {
                    return const Center(child: Text('No hay equipos para mostrar.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: mostrar.length,
                    itemBuilder: (context, index) {
                      final cat = mostrar[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFD32F2F),
                            child: Icon(Icons.group, color: Colors.white),
                          ),
                          title: Text('${cat.categoria}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text('Equipo: ${cat.equipo}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.checklist, color: Colors.green),
                                tooltip: 'Registrar asistencia',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RegistroAsistenciaScreen(
                                        categoriaEquipoId: cat.id,
                                        entrenamientoId: 'entrenamientoId', // Cambia si tienes id real
                                        fecha: DateTime.now(),
                                        rol: 'profesor',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.list_alt, color: Colors.blue),
                                tooltip: 'Ver historial',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VerListaAsistenciaScreen(
                                        categoriaEquipoId: cat.id,
                                      ),
                                    ),
                                  );
                                },
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
      ),
    );
  }
}