import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/categoria_equipo_provider.dart';
import '../../models/categoria_equipo_model.dart';
import '../asistencias/registro_asistencia_screen.dart';

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
                        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFFD32F2F)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegistroAsistenciaScreen(
                                categoriaEquipoId: item.id,
                                entrenamientoId: 'entrenamientoId', // Puedes generar o seleccionar el id del entrenamiento
                                fecha: DateTime.now(),
                                rol: 'rol', // Puedes generar o seleccionar el rol del usuario
                              ),
                            ),
                          );
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