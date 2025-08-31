import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/categoria_equipo_model.dart';
import '../../providers/categoria_equipo_provider.dart';
import '../../providers/player_provider.dart';

class CategoriaEquipoFormScreen extends ConsumerStatefulWidget {
  const CategoriaEquipoFormScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoriaEquipoFormScreen> createState() => _CategoriaEquipoFormScreenState();
}

class _CategoriaEquipoFormScreenState extends ConsumerState<CategoriaEquipoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? categoriaSeleccionada;
  String? equipoSeleccionado;
  final categoriaOtroController = TextEditingController();
  final equipoOtroController = TextEditingController();

  @override
  void dispose() {
    categoriaOtroController.dispose();
    equipoOtroController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(categoriaEquipoRepositoryProvider);

    final categoriaFinal = categoriaSeleccionada == 'Otro'
        ? categoriaOtroController.text.trim()
        : categoriaSeleccionada ?? '';

    final equipoFinal = equipoSeleccionado == 'Otro'
        ? equipoOtroController.text.trim()
        : equipoSeleccionado ?? '';

    final model = CategoriaEquipoModel(
      id: const Uuid().v4(),
      categoria: categoriaFinal,
      equipo: equipoFinal,
    );
    await repo.addCategoriaEquipo(model);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final jugadoresAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Categoría-Equipo')),
      body: jugadoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (jugadores) {
          // Obtener años de nacimiento únicos y ordenados
          final anos = jugadores
              .map((j) => j.fechaDeNacimiento.year.toString())
              .toSet()
              .toList()
            ..sort();

          final categorias = [...anos, 'Otro'];

          final equipos = ['Equipo A', 'Equipo B', 'Junior', 'Otro'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Categoría (año de nacimiento)'),
                    value: categoriaSeleccionada,
                    items: categorias
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        categoriaSeleccionada = value;
                        if (value != 'Otro') categoriaOtroController.clear();
                      });
                    },
                    validator: (v) => v == null || v.isEmpty
                        ? 'Campo obligatorio'
                        : (v == 'Otro' && categoriaOtroController.text.trim().isEmpty
                            ? 'Ingresa una nueva categoría'
                            : null),
                  ),
                  if (categoriaSeleccionada == 'Otro')
                    TextFormField(
                      controller: categoriaOtroController,
                      decoration: const InputDecoration(labelText: 'Nueva categoría'),
                      validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Equipo'),
                    value: equipoSeleccionado,
                    items: equipos
                        .map((eq) => DropdownMenuItem(value: eq, child: Text(eq)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        equipoSeleccionado = value;
                        if (value != 'Otro') equipoOtroController.clear();
                      });
                    },
                    validator: (v) => v == null || v.isEmpty
                        ? 'Campo obligatorio'
                        : (v == 'Otro' && equipoOtroController.text.trim().isEmpty
                            ? 'Ingresa un nuevo equipo'
                            : null),
                  ),
                  if (equipoSeleccionado == 'Otro')
                    TextFormField(
                      controller: equipoOtroController,
                      decoration: const InputDecoration(labelText: 'Nuevo equipo'),
                      validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                    onPressed: _guardar,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}