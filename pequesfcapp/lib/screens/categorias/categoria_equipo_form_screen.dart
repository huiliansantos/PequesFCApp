import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/categoria_equipo_model.dart';
import '../../providers/categoria_equipo_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/gradient_button.dart';

class CategoriaEquipoFormScreen extends ConsumerStatefulWidget {
  final CategoriaEquipoModel? categoriaEquipo;

  const CategoriaEquipoFormScreen({
    Key? key,
    this.categoriaEquipo,
  }) : super(key: key);

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
  void initState() {
    super.initState();
    if (widget.categoriaEquipo != null) {
      // Establecer valores iniciales directamente del modelo
      categoriaSeleccionada = widget.categoriaEquipo!.categoria;
      equipoSeleccionado = widget.categoriaEquipo!.equipo;
    }
  }

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
      id: widget.categoriaEquipo?.id ?? const Uuid().v4(),
      categoria: categoriaFinal,
      equipo: equipoFinal,
    );

    try {
      // Mostrar indicador de progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      if (widget.categoriaEquipo != null) {
        await repo.actualizarCategoriaEquipo(model);
      } else {
        await repo.agregarCategoriaEquipo(model);
      }

      if (context.mounted) {
        Navigator.pop(context); // Cerrar indicador
        Navigator.pop(context); // Volver a la lista

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.categoriaEquipo != null
                ? 'Categoría-equipo actualizada correctamente'
                : 'Categoría-equipo creada correctamente'),
            //backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Cerrar indicador
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jugadoresAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          widget.categoriaEquipo != null 
              ? 'Modificar Categoría-Equipo'
              : 'Registrar Categoría-Equipo',
          style: const TextStyle(fontSize: 18)
        ),
      ),
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

          // Asegurar que la categoría actual esté en la lista
          if (widget.categoriaEquipo != null && 
              !anos.contains(widget.categoriaEquipo!.categoria)) {
            anos.add(widget.categoriaEquipo!.categoria);
            anos.sort();
          }

          final categorias = [...anos, 'Otro'];

          // Lista de equipos incluyendo el actual si existe
          final equiposBase = ['Equipo A', 'Equipo B', 'Junior'];
          if (widget.categoriaEquipo != null && 
              !equiposBase.contains(widget.categoriaEquipo!.equipo)) {
            equiposBase.add(widget.categoriaEquipo!.equipo);
          }
          final equipos = [...equiposBase, 'Otro'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Categoría (año de nacimiento)',
                      border: OutlineInputBorder(),
                    ),
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
                  if (categoriaSeleccionada == 'Otro') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: categoriaOtroController,
                      decoration: const InputDecoration(
                        labelText: 'Nueva categoría',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Campo obligatorio';
                        if (!RegExp(r'^\d+$').hasMatch(v)) return 'Solo números';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Equipo',
                      border: OutlineInputBorder(),
                    ),
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
                  if (equipoSeleccionado == 'Otro') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: equipoOtroController,
                      decoration: const InputDecoration(
                        labelText: 'Nuevo equipo',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                    ),
                  ],
                  const SizedBox(height: 24),
                  GradientButton(
                    onPressed: _guardar,
                    child: const Text('Guardar'),
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
