import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/categoria_equipo_provider.dart';
import 'categoria_equipo_form_screen.dart';
import 'categoria_equipo_detail_screen.dart';

class CategoriaListScreen extends ConsumerStatefulWidget {
  const CategoriaListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoriaListScreen> createState() =>
      _CategoriaListScreenState();
}

class _CategoriaListScreenState extends ConsumerState<CategoriaListScreen> {
  String busqueda = '';

  @override
  Widget build(BuildContext context) {
    final categoriasEquiposAsync = ref.watch(categoriasEquiposProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar categoría o equipo',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  busqueda = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: categoriasEquiposAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (lista) {
                final ordenados = [...lista]..sort((a, b) {
                    int getAnio(dynamic item) {
                      final exp = RegExp(r'\d{4}');
                      final match = exp.firstMatch(item.categoria);
                      return match != null
                          ? int.tryParse(match.group(0)!) ?? 0
                          : 0;
                    }

                    return getAnio(b).compareTo(getAnio(a));
                  });

                final filtrados = ordenados
                    .where((item) =>
                        item.categoria.toLowerCase().contains(busqueda) ||
                        item.equipo.toLowerCase().contains(busqueda))
                    .toList();

                if (filtrados.isEmpty) {
                  return const Center(
                      child: Text('No se encontraron categorías.'));
                }

                return ListView.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final item = filtrados[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: const Icon(Icons.group,
                              color: Colors.white, size: 30),
                        ),
                        title: Text(
                          item.categoria,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Equipo: ${item.equipo}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoriaEquipoDetailScreen(
                                  categoriaEquipo: item),
                            ),
                          );
                        },
                        onLongPress: () {
                          // capturar el context padre
                          final parentContext = context;
                          showModalBottomSheet(
                            context: parentContext,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (sheetContext) => Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit, color: Color(0xFFD32F2F)),
                                    title: const Text('Modificar'),
                                    onTap: () {
                                      Navigator.pop(sheetContext);
                                      Navigator.push(
                                        parentContext,
                                        MaterialPageRoute(
                                          builder: (_) => CategoriaEquipoFormScreen(categoriaEquipo: item),
                                        ),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete, color: Colors.red),
                                    title: const Text('Eliminar'),
                                    onTap: () async {
                                      // cerrar bottom sheet usando sheetContext
                                      Navigator.pop(sheetContext);

                                      // Mostrar diálogo usando el context padre (parentContext)
                                      final shouldDelete = await showDialog<bool>(
                                        context: parentContext,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Eliminar categoría-equipo'),
                                          content: const Text('¿Estás seguro de eliminar esta categoría-equipo?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                            TextButton(onPressed: () => Navigator.pop(ctx, true), 
                                            child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );

                                      if (shouldDelete != true || !mounted) return;

                                      debugPrint('Eliminando categoría con ID: ${item.id}');
                                      // Mostrar SnackBar inicial
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Eliminando categoría: ${item.categoria}'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );

                                      try {
                                        // 5. Mostrar loading
                                        if (context.mounted) {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          );
                                        }

                                        // 6. Intentar eliminar
                                        debugPrint('Intentando eliminar categoría con ID: ${item.id}');
                                        await ref
                                            .read(categoriaEquipoControllerProvider)
                                            .eliminarCategoriaEquipo(item.id);

                                        // 7. Refrescar provider
                                        ref.invalidate(categoriasEquiposProvider);

                                        // 8. Cerrar loading y mostrar éxito
                                        if (context.mounted) {
                                          Navigator.pop(context); // Cerrar loading
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Categoría eliminada correctamente'),
                                              //backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e, stack) {
                                        // 9. Manejar error
                                        debugPrint('Error al eliminar: $e');
                                        debugPrint('Stack trace: $stack');
                                        
                                        if (context.mounted) {
                                          Navigator.pop(context); // Cerrar loading
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error al eliminar: $e'),
                                              backgroundColor: Colors.red,
                                            ),
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
            ),
          ),
        ],
      ),
    );
  }
}
