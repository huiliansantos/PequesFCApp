import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/categoria_equipo_provider.dart';
import 'registro_asistencia_screen.dart';
import 'ver_lista_asistencia_screen.dart'; // Debes crear esta pantalla

class CategoriaListAsistenciaScreen extends ConsumerStatefulWidget {
  const CategoriaListAsistenciaScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoriaListAsistenciaScreen> createState() => _CategoriaListAsistenciaScreenState();
}

class _CategoriaListAsistenciaScreenState extends ConsumerState<CategoriaListAsistenciaScreen> {
  String busqueda = '';

  @override
  Widget build(BuildContext context) {
    final categoriasEquiposAsync = ref.watch(categoriasEquiposProvider);

    return Scaffold(
      body: Column(
        children: [          
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
                final filtrados = lista.where((item) =>
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
                                      categoriaEquipoId: item.id,
                                      entrenamientoId: 'entrenamientoId', // tu lógica para el id
                                      fecha: DateTime.now(),
                                      rol: 'admin', // tu lógica para el rol
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.list_alt, color: Colors.blue),
                              tooltip: 'Ver asistencia',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VerListaAsistenciaScreen(
                                      categoriaEquipoId: item.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          // Opcional: puedes usar el tap para editar o ver detalles
                        },
                        onLongPress: () {
                          // Opcional: menú contextual para modificar/eliminar categoría-equipo
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
          // Navega al formulario de registro de categoría-equipo
          // Navigator.push(context, MaterialPageRoute(builder: (_) => CategoriaEquipoFormScreen()));
        },
      ),
    );
  }
}