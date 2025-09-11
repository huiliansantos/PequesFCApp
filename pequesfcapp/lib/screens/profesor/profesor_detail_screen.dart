import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/profesor_model.dart';
import '../../models/categoria_equipo_model.dart';
import '../../providers/profesor_provider.dart';
import '../../providers/categoria_equipo_provider.dart';

class ProfesorDetailScreen extends ConsumerWidget {
  final String profesorId;
  const ProfesorDetailScreen({Key? key, required this.profesorId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfesores = ref.watch(profesoresProvider);
    final categoriasEquiposAsync = ref.watch(categoriasEquiposProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Profesor'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: asyncProfesores.when(
        data: (profesores) {
          return categoriasEquiposAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (categoriasEquipos) {
              final profesor = profesores.firstWhere((p) => p.id == profesorId, orElse: () => ProfesorModel(
                id: '', nombre: '', apellido: '', ci: '', fechaNacimiento: DateTime.now(), celular: '', usuario: '', contrasena: '', categoriaEquipoId: '',
              ));
              if (profesor.id.isEmpty) {
                return const Center(child: Text('Profesor no encontrado'));
              }
              final categoriaEquipo = categoriasEquipos.firstWhere(
                (ce) => ce.id == profesor.categoriaEquipoId,
                orElse: () => CategoriaEquipoModel(id: '', categoria: '', equipo: ''),
              );
              final categoriaEquipoNombre = categoriaEquipo.id.isNotEmpty
                  ? '${categoriaEquipo.categoria} - ${categoriaEquipo.equipo}'
                  : 'Sin asignar';
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Icon(Icons.person, size: 80, color: Theme.of(context).primaryColor),
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow('Nombre', profesor.nombre),
                        _buildDetailRow('Apellido', profesor.apellido),
                        _buildDetailRow('CI', profesor.ci),
                        _buildDetailRow('Fecha de nacimiento', _formatDate(profesor.fechaNacimiento)),
                        _buildDetailRow('Celular', profesor.celular),
                        _buildDetailRow('Usuario', profesor.usuario),
                        _buildDetailRow('Categoría/Equipo', categoriaEquipoNombre),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
