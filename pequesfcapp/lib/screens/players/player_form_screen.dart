import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/player_model.dart';
import '../../widgets/gradient_button.dart';
import '../../providers/player_provider.dart';
import '../../providers/categoria_equipo_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'es_ES');
    final categoriasEquiposAsync = ref.watch(categoriasEquiposProvider);
    return Scaffold(
      appBar: AppBar(
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
                value: genero,
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
                value: nacionalidad,
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
                  value: departamentoBolivia,
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
                  if (lista.isEmpty) {
                    return const Text('No hay categorías-equipo registradas');
                  }
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Categoría-Equipo'),
                    value: lista.any((item) => item.id == categoriaEquipoId) ? categoriaEquipoId : null,
                    items: lista.map((item) =>
                      DropdownMenuItem(
                        value: item.id,
                        child: Text('${item.categoria} - ${item.equipo}'),
                      )
                    ).toList(),
                    onChanged: (value) => setState(() => categoriaEquipoId = value),
                    validator: (v) => v == null ? 'Selecciona una categoría-equipo' : null,
                  );
                },
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: _savePlayer,
                // Cambia el texto del botón según si es creación o edición
                child: Text(widget.player == null ? 'Crear' : 'Actualizar'),
              ),
            
            ],
          ),
        ),
      ),
    );
  }
}
