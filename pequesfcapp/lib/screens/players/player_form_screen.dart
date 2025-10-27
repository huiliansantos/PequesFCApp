import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/player_model.dart';
import '../../widgets/gradient_button.dart';
import '../../providers/player_provider.dart';
import '../../providers/categoria_equipo_provider.dart';
import '../../models/categoria_equipo_model.dart';

class PlayerFormScreen extends ConsumerStatefulWidget {
  final PlayerModel? player;

  const PlayerFormScreen({Key? key, this.player}) : super(key: key);

  @override
  ConsumerState<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends ConsumerState<PlayerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nombresController;
  late TextEditingController apellidoController;
  late TextEditingController fotoController;
  late TextEditingController ciController;
  late TextEditingController nuevaNacionalidadController;

  DateTime? fechaDeNacimiento;
  String genero = 'Masculino';
  String nacionalidad = 'Boliviana';
  String? departamentoBolivia;
  String? categoriaEquipoId;
  List<String> nacionalidades = [
    'Argentina',
    'Boliviana',
    'Chilena',
    'Paraguaya',
    'Peruana',
    'Otra'
  ];
  List<String> departamentosBolivia = [
    'La Paz',
    'Santa Cruz',
    'Cochabamba',
    'Oruro',
    'Potosí',
    'Tarija',
    'Chuquisaca',
    'Beni',
    'Pando'
  ];

  @override
  void initState() {
    super.initState();
    nombresController = TextEditingController(text: widget.player?.nombres ?? '');
    apellidoController = TextEditingController(text: widget.player?.apellido ?? '');
    fotoController = TextEditingController(text: widget.player?.foto ?? '');
    ciController = TextEditingController(text: widget.player?.ci ?? '');
    nuevaNacionalidadController = TextEditingController();
    fechaDeNacimiento = widget.player?.fechaDeNacimiento;
    genero = widget.player?.genero ?? 'Masculino';
    nacionalidad = widget.player?.nacionalidad ?? 'Boliviana';
    departamentoBolivia = widget.player?.departamentoBolivia;
    categoriaEquipoId = widget.player?.categoriaEquipoId;
  }

  @override
  void dispose() {
    nombresController.dispose();
    apellidoController.dispose();
    fotoController.dispose();
    ciController.dispose();
    nuevaNacionalidadController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaDeNacimiento ?? DateTime.now().subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        fechaDeNacimiento = picked;
      });
    }
  }

  String? _validateNombre(String? value) {
    if (value == null || value.isEmpty) return 'Campo obligatorio';
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]+$').hasMatch(value)) return 'Solo letras';
    return null;
  }

  String? _validateApellido(String? value) {
    if (value == null || value.isEmpty) return 'Campo obligatorio';
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]+$').hasMatch(value)) return 'Solo letras';
    return null;
  }

  String? _validateCI(String? value) {
    if (value == null || value.isEmpty) return 'Campo obligatorio';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'Solo números';
    return null;
  }

  Future<void> _savePlayer() async {
    if (!_formKey.currentState!.validate() || fechaDeNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos y selecciona una fecha válida')),
      );
      return;
    }

    // Validar edad entre 2 y 18 años
    final edad = DateTime.now().year - fechaDeNacimiento!.year -
        ((DateTime.now().month < fechaDeNacimiento!.month ||
          (DateTime.now().month == fechaDeNacimiento!.month &&
           DateTime.now().day < fechaDeNacimiento!.day)) ? 1 : 0);
    if (edad < 2 || edad > 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo se pueden registrar niños entre 2 y 18 años')),
      );
      return;
    }

    String nacionalidadFinal = nacionalidad;
    if (nacionalidad == 'Otra' && nuevaNacionalidadController.text.isNotEmpty) {
      nacionalidadFinal = nuevaNacionalidadController.text;
      // Aquí podrías guardar la nueva nacionalidad en la base de datos si lo deseas
    }

    final String fotoPorDefecto = 'assets/jugador.png';

    final newPlayer = PlayerModel(
      id: widget.player?.id ?? const Uuid().v4(),
      nombres: nombresController.text,
      apellido: apellidoController.text,
      fechaDeNacimiento: fechaDeNacimiento!,
      genero: genero,
      foto: fotoPorDefecto,
      ci: ciController.text,
      nacionalidad: nacionalidadFinal,
      departamentoBolivia: nacionalidadFinal == 'Boliviana' ? departamentoBolivia : null,
      guardianId: widget.player?.guardianId,
      categoriaEquipoId: categoriaEquipoId ?? '',
    );

    final playerRepo = ref.read(playerRepositoryProvider);
    final existe = await playerRepo.existeJugadorConCI(ciController.text);

    if (existe && widget.player == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya existe un jugador con ese CI')),
      );
      return;
    }

    if (widget.player == null) {
      await playerRepo.addPlayer(newPlayer);
    } else {
      await playerRepo.updatePlayer(newPlayer);
    }

    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _registrarNuevaCategoriaEquipo(BuildContext context) async {
    final _categoriaController = TextEditingController();
    final _equipoController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? nuevoId;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar nueva categoría-equipo'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _categoriaController,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                ),
                TextFormField(
                  controller: _equipoController,
                  decoration: const InputDecoration(labelText: 'Equipo'),
                  validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final repo = ref.read(categoriaEquipoRepositoryProvider);
                  await repo.agregarCategoriaEquipo(
                    CategoriaEquipoModel(
                      id: const Uuid().v4(),
                      categoria: _categoriaController.text,
                      equipo: _equipoController.text,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        );
      },
    );

    if (nuevoId != null) {
      setState(() {
        categoriaEquipoId = nuevoId;
      });
      // Puedes recargar el provider si lo necesitas
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'es_ES');
    final categoriasEquiposAsync = ref.watch(categoriasEquiposProvider);
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
        title: Text(widget.player == null ? 'Crear Jugador' : 'Editar Jugador'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nombresController,
                decoration: const InputDecoration(labelText: 'Nombres'),
                validator: _validateNombre,
              ),
              TextFormField(
                controller: apellidoController,
                decoration: const InputDecoration(labelText: 'Apellidos'),
                validator: _validateApellido,
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text(fechaDeNacimiento == null
                    ? 'Selecciona fecha de nacimiento'
                    : 'Fecha de nacimiento: ${dateFormat.format(fechaDeNacimiento!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
                subtitle: fechaDeNacimiento == null
                    ? const Text('Obligatorio')
                    : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: genero,
                items: ['Masculino', 'Femenino']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    genero = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Género'),
              ),
              TextFormField(
                controller: ciController,
                decoration: const InputDecoration(labelText: 'Carnet de Identidad (CI)'),
                validator: _validateCI,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: nacionalidad,
                decoration: const InputDecoration(labelText: 'Nacionalidad'),
                items: nacionalidades
                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    nacionalidad = value!;
                    if (nacionalidad != 'Boliviana') departamentoBolivia = null;
                  });
                },
              ),
              if (nacionalidad == 'Boliviana')
                DropdownButtonFormField<String>(
                  initialValue: departamentoBolivia,
                  decoration: const InputDecoration(labelText: 'Departamento'),
                  items: departamentosBolivia
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      departamentoBolivia = value!;
                    });
                  },
                  validator: (value) => value == null ? 'Selecciona un departamento' : null,
                ),
              if (nacionalidad == 'Otra')
                TextFormField(
                  controller: nuevaNacionalidadController,
                  decoration: const InputDecoration(labelText: 'Nueva nacionalidad'),
                  validator: (value) {
                    if (nacionalidad == 'Otra' && (value == null || value.isEmpty)) {
                      return 'Ingrese la nacionalidad';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 10),
              categoriasEquiposAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
                data: (lista) {
                  // Ordenar de menor a mayor por el campo categoria (asumiendo que es numérico)
                  final listaOrdenada = [...lista]
                    ..sort((a, b) => int.parse(a.categoria).compareTo(int.parse(b.categoria)));

                  // Si hay fecha de nacimiento, filtra solo la categoría correspondiente
                  List<CategoriaEquipoModel> listaFiltrada = listaOrdenada;
                  if (fechaDeNacimiento != null) {
                    final anioNacimiento = fechaDeNacimiento!.year.toString();
                    listaFiltrada = listaOrdenada.where((cat) => cat.categoria == anioNacimiento).toList();
                  }

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Categoría-Equipo'),
                    initialValue: listaFiltrada.any((item) => item.id == categoriaEquipoId) ? categoriaEquipoId : null,
                    items: [
                      const DropdownMenuItem(
                        value: 'nueva_categoria_equipo',
                        child: Text('Registrar nueva categoría-equipo'),
                      ),
                      ...listaFiltrada.map((item) =>
                        DropdownMenuItem(
                          value: item.id,
                          child: Text('${item.categoria} - ${item.equipo}'),
                        )
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == 'nueva_categoria_equipo') {
                        await _registrarNuevaCategoriaEquipo(context);
                      } else {
                        setState(() => categoriaEquipoId = value);
                      }
                    },
                    validator: (v) => v == null ? 'Selecciona una categoría-equipo' : null,
                  );
                },
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: _savePlayer,
                child: Text(widget.player == null ? 'Crear' : 'Actualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
