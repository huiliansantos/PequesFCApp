import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/categoria_equipo_provider.dart';
import 'categoria_equipo_form_screen.dart'; // Debes crear este formulario
import 'categoria_equipo_detail_screen.dart'; // Debes crear esta pantalla

class CategoriaListScreen extends ConsumerStatefulWidget {
  const CategoriaListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoriaListScreen> createState() => _CategoriaListScreenState();
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.category, color: Color(0xFFD32F2F), size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lista de Categorías',
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                // Ordenar por año descendente si el campo 'categoria' contiene el año
                final ordenados = [...lista]..sort((a, b) {
                  int getAnio(dynamic item) {
                    final exp = RegExp(r'\d{4}');
                    final match = exp.firstMatch(item.categoria);
                    return match != null ? int.tryParse(match.group(0)!) ?? 0 : 0;
                  }
                  return getAnio(b).compareTo(getAnio(a));
                });

                final filtrados = ordenados.where((item) =>
                  item.categoria.toLowerCase().contains(busqueda) ||
                  item.equipo.toLowerCase().contains(busqueda)
                ).toList();

                if (filtrados.isEmpty) {
                  return const Center(child: Text('No se encontraron categorías.'));
                }

                return ListView.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final item = filtrados[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFD32F2F),
                          child: const Icon(Icons.group, color: Colors.white),
                        ),
                        title: Text(
                          item.categoria,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Equipo: ${item.equipo}'),
                        onTap: () {
                          // Ver detalle de categoría-equipo
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoriaEquipoDetailScreen(categoriaEquipo: item),
                            ),
                          );
                        },
                        onLongPress: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (context) => Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit, color: Color(0xFFD32F2F)),
                                    title: const Text('Modificar'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CategoriaEquipoFormScreen(),
                                          settings: RouteSettings(arguments: item),
                                        ),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete, color: Colors.red),
                                    title: const Text('Eliminar'),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      final confirmar = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Eliminar categoría-equipo'),
                                          content: const Text('¿Estás seguro de eliminar esta categoría-equipo?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmar == true) {
                                        // TODO: Implement deletion using the appropriate provider or repository.
                                        // categoriasEquiposProvider is a StreamProvider and does not expose a `.notifier`.
                                        // Replace the following placeholder with a call to the correct controller/state provider.
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Funcionalidad de eliminar no implementada')),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'categoria-fab',
        backgroundColor: const Color(0xFFD32F2F),
        child: const Icon(Icons.add),
        tooltip: 'Nueva Categoría-Equipo',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoriaEquipoFormScreen(),
            ),
          );
        },
      ),
    );
  }
}