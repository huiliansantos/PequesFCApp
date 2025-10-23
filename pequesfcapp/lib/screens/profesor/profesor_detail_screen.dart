import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/profesor_model.dart';
import '../../models/categoria_equipo_model.dart';
import '../../providers/profesor_provider.dart';
import '../../providers/categoria_equipo_provider.dart';

class ProfesorDetailScreen extends ConsumerWidget {
  final String profesorId;
  const ProfesorDetailScreen({Key? key, required this.profesorId})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfesores = ref.watch(profesoresProvider);
    final categoriasEquiposAsync = ref.watch(categoriasEquiposProvider);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: asyncProfesores.when(
              loading: () => const Text('Profesor'),
              error: (e, _) => const Text('Profesor'),
              data: (profesores) {
                final profesor = profesores.firstWhere(
                  (p) => p.id == profesorId,
                  orElse: () => ProfesorModel(
                    id: '',
                    nombre: '',
                    apellido: '',
                    ci: '',
                    fechaNacimiento: DateTime.now(),
                    celular: '',
                    usuario: '',
                    contrasena: '',
                    categoriaEquipoId: '',
                  ),
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profesor.nombre,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Profesor',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                );
              },
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
              final profesor = profesores.firstWhere(
                (p) => p.id == profesorId,
                orElse: () => ProfesorModel(
                  id: '',
                  nombre: '',
                  apellido: '',
                  ci: '',
                  fechaNacimiento: DateTime.now(),
                  celular: '',
                  usuario: '',
                  contrasena: '',
                  categoriaEquipoId: '',
                ),
              );
              if (profesor.id.isEmpty) {
                return const Center(child: Text('Profesor no encontrado'));
              }
              final categoriaEquipo = categoriasEquipos.firstWhere(
                (ce) => ce.id == profesor.categoriaEquipoId,
                orElse: () =>
                    CategoriaEquipoModel(id: '', categoria: '', equipo: ''),
              );
              final categoriaEquipoNombre = categoriaEquipo.id.isNotEmpty
                  ? '${categoriaEquipo.categoria} - ${categoriaEquipo.equipo}'
                  : 'Sin asignar';
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage:
                            const AssetImage('assets/profesor.png'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 16),
                        child: _ProfesorDetailContent(
                          profesor: profesor,
                          categoriaEquipoNombre: categoriaEquipoNombre,
                          formatDate: _formatDate,
                        ),
                      ),
                    ),
                  ],
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _ProfesorDetailContent extends StatefulWidget {
  final ProfesorModel profesor;
  final String categoriaEquipoNombre;
  final String Function(DateTime) formatDate;

  const _ProfesorDetailContent({
    Key? key,
    required this.profesor,
    required this.categoriaEquipoNombre,
    required this.formatDate,
  }) : super(key: key);

  @override
  State<_ProfesorDetailContent> createState() => _ProfesorDetailContentState();
}

class _ProfesorDetailContentState extends State<_ProfesorDetailContent> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final contrasena = widget.profesor.contrasena ;
    final contrasenaOculta = '*' * contrasena.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow(Icons.person, Colors.blue, 'Nombre', widget.profesor.nombre),
        _detailRow(Icons.person_outline, Colors.blue, 'Apellido',
            widget.profesor.apellido),
        _detailRow(Icons.badge, Colors.blue, 'CI', widget.profesor.ci),
        _detailRow(Icons.cake, Colors.purple, 'Fecha de nacimiento',
            widget.formatDate(widget.profesor.fechaNacimiento)),
        _detailRow(
            Icons.phone, Colors.teal, 'Celular', widget.profesor.celular),
        _detailRow(Icons.account_circle, Colors.purple, 'Usuario',
            widget.profesor.usuario),
        _detailRow(Icons.sports_soccer, Colors.green, 'Categoría/Equipo',
            widget.categoriaEquipoNombre),
        _detailRow(
          Icons.lock,
          Colors.red,
          'Contraseña',
          _showPassword ? contrasena : contrasenaOculta,
          trailing: IconButton(
            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, Color iconColor, String label, String value,
      {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
