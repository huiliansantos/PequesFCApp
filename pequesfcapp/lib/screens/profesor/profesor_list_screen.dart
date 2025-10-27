import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profesor_provider.dart';
import 'package:PequesFCApp/repositories/profesor_repository.dart';
import '../../providers/categoria_equipo_provider.dart';
import 'profesor_form_screen.dart';
import 'profesor_detail_screen.dart';

class ProfesorListScreen extends ConsumerStatefulWidget {
  const ProfesorListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfesorListScreen> createState() => _ProfesorListScreenState();
}

class _ProfesorListScreenState extends ConsumerState<ProfesorListScreen> {
  String busqueda = '';

  @override
  Widget build(BuildContext context) {
    final profesoresAsync = ref.watch(profesoresProvider);
    final categoriasEquiposAsync = ref.watch(categoriasEquiposProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar profesor',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  setState(() => busqueda = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: profesoresAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (profesores) {
                return categoriasEquiposAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (categorias) {
                    // Crear mapa de id -> categoría-equipo para búsqueda rápida
                    final categoriasMap = {
                      for (var c in categorias)
                        c.id: '${c.categoria} - ${c.equipo}'
                    };

                    final filtrados = profesores.where((prof) {
                      final search = busqueda.toLowerCase();
                      return prof.nombre.toLowerCase().contains(search) ||
                          prof.apellido.toLowerCase().contains(search) ||
                          prof.ci.toLowerCase().contains(search);
                    }).toList();

                    if (filtrados.isEmpty) {
                      return const Center(
                        child: Text('No se encontraron profesores'),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtrados.length,
                      itemBuilder: (context, index) {
                        final profesor = filtrados[index];

                        // Procesar equipos asignados
                        String equiposText = 'Sin asignar';
                        if (profesor.categoriaEquipoId.isNotEmpty) {
                          final ids = profesor.categoriaEquipoId.split(',');
                          final equipos = ids
                              .map((id) => categoriasMap[id.trim()])
                              .where((e) => e != null)
                              .toList();
                          if (equipos.isNotEmpty) {
                            equiposText = equipos.join('\n');
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            //cambiar el icono por la imagen profesor.png
                            leading: Image.asset(
                              'assets/profesor.png',
                              width: 48,
                              height: 48,
                            ),  
                            title: Text(
                              '${profesor.nombre} ${profesor.apellido}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CI: ${profesor.ci}'),
                                Text('Celular: ${profesor.celular}'),
                                const SizedBox(height: 4),
                                Text(
                                  'Equipos:\n$equiposText',
                                  style: TextStyle(
                                    color: equiposText == 'Sin asignar'
                                        ? Colors.red
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfesorDetailScreen(
                                      profesorId: profesor.id),
                                ),
                              );
                            },
                            onLongPress: () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                builder: (context) => Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(
                                          Icons.edit,
                                          color: Color(0xFFD32F2F),
                                        ),
                                        title: const Text('Modificar'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ProfesorFormScreen(
                                                profesor: profesor,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        title: const Text('Eliminar'),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          final confirmar =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                  'Eliminar profesor'),
                                              content: Text(
                                                  '¿Estás seguro de eliminar a ${profesor.nombre} ${profesor.apellido}?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Cancelar'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text(
                                                    'Eliminar',
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmar == true) {
                                            await ref
                                                .read(
                                                    profesorRepositoryProvider)
                                                .deleteProfesor(profesor.id);
                                            ref.invalidate(profesoresProvider);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Profesor eliminado correctamente')),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
    );
  }
}
