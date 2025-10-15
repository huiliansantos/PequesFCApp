import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/profesor_model.dart';
import '../../providers/profesor_provider.dart';
import '../../models/categoria_equipo_model.dart';
import '../../providers/categoria_equipo_provider.dart';
import 'profesor_detail_screen.dart';
import 'profesor_form_screen.dart';

class ProfesorListScreen extends ConsumerWidget {
  const ProfesorListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profesoresAsync = ref.watch(profesoresProvider);
    final categoriasEquiposAsync = ref.watch(categoriasEquiposProvider);

    return Scaffold(
      body: profesoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profesores) {
          return categoriasEquiposAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (categoriasEquipos) {
              if (profesores.isEmpty) {
                return const Center(
                    child: Text('No hay profesores registrados.'));
              }
              return ListView.builder(
                itemCount: profesores.length,
                itemBuilder: (context, index) {
                  final profesor = profesores[index];
                  final categoriaEquipo = categoriasEquipos.firstWhere(
                    (ce) => ce.id == profesor.categoriaEquipoId,
                    orElse: () =>
                        CategoriaEquipoModel(id: '', categoria: '', equipo: ''),
                  );
                  final categoriaEquipoNombre = categoriaEquipo.id.isNotEmpty
                      ? '${categoriaEquipo.categoria} - ${categoriaEquipo.equipo}'
                      : 'Sin asignar';
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProfesorDetailScreen(profesorId: profesor.id),
                        ),
                      );
                    },
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) => SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit,
                                    color: Color(0xFFD32F2F)),
                                title: const Text('Modificar'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProfesorFormScreen(
                                          profesor: profesor),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading:
                                    const Icon(Icons.delete, color: Colors.red),
                                title: const Text('Eliminar'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('¿Eliminar profesor?'),
                                      content: const Text(
                                          '¿Estás seguro de eliminar este profesor?'),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancelar'),
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                        ),
                                        TextButton(
                                          child: const Text('Eliminar',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ref
                                        .read(profesorRepositoryProvider)
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
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              const AssetImage('assets/profesor.png'),
                        ),
                        title: Text('${profesor.nombre} ${profesor.apellido}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CI: ${profesor.ci}'),
                            Text('Celular: ${profesor.celular}'),
                            Text('Usuario: ${profesor.usuario}'),
                            Text('Categoría/Equipo: $categoriaEquipoNombre'),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
