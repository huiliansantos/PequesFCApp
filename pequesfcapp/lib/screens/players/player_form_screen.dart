import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/player_model.dart';
import '../../providers/player_provider.dart';

class PlayerFormScreen extends ConsumerStatefulWidget {
  final PlayerModel? player; // null si estamos creando, no null si estamos editando

  const PlayerFormScreen({Key? key, this.player}) : super(key: key);

  @override
  ConsumerState<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends ConsumerState<PlayerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nombresController;
  late TextEditingController apellidoController;
  late TextEditingController lugarNacimientoController;
  late TextEditingController fotoController;
  late TextEditingController ciController;

  DateTime? fechaDeNacimiento;
  String genero = 'Masculino'; // Valor por defecto

  @override
  void initState() {
    super.initState();
    nombresController = TextEditingController(text: widget.player?.nombres ?? '');
    apellidoController = TextEditingController(text: widget.player?.apellido ?? '');
    lugarNacimientoController = TextEditingController(text: widget.player?.lugarDeNacimiento ?? '');
    fotoController = TextEditingController(text: widget.player?.foto ?? '');
    ciController = TextEditingController(text: widget.player?.ci ?? '');
    fechaDeNacimiento = widget.player?.fechaDeNacimiento;
    genero = widget.player?.genero ?? 'Masculino';
  }

  @override
  void dispose() {
    nombresController.dispose();
    apellidoController.dispose();
    lugarNacimientoController.dispose();
    fotoController.dispose();
    ciController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaDeNacimiento ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != fechaDeNacimiento) {
      setState(() {
        fechaDeNacimiento = picked;
      });
    }
  }

  Future<void> _savePlayer() async {
    if (!_formKey.currentState!.validate() || fechaDeNacimiento == null) return;

    // Imagen por defecto (puedes cambiar la URL por la tuya)
    final String fotoPorDefecto = 'assets/jugador.png';

    final newPlayer = PlayerModel(
      id: widget.player?.id ?? Uuid().v4(),
      nombres: nombresController.text,
      apellido: apellidoController.text,
      fechaDeNacimiento: fechaDeNacimiento!,
      lugarDeNacimiento: lugarNacimientoController.text,
      genero: genero,
      foto: fotoPorDefecto, // <-- Solo asigna la imagen por defecto
      ci: ciController.text,
      guardianId: widget.player?.guardianId,
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
                decoration: InputDecoration(labelText: 'Nombres'),
                validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: apellidoController,
                decoration: InputDecoration(labelText: 'Apellido'),
                validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              SizedBox(height: 10),
              ListTile(
                title: Text(fechaDeNacimiento == null
                    ? 'Selecciona fecha de nacimiento'
                    : 'Fecha de nacimiento: ${fechaDeNacimiento!.toLocal().toString().split(' ')[0]}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              TextFormField(
                controller: lugarNacimientoController,
                decoration: InputDecoration(labelText: 'Lugar de nacimiento'),
                validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
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
                decoration: InputDecoration(labelText: 'Género'),
              ),
              // Elimina el campo de foto y el botón de cámara
              TextFormField(
                controller: ciController,
                decoration: InputDecoration(labelText: 'Carnet de Identidad (CI)'),
                validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _savePlayer,
                child: Text(widget.player == null ? 'Crear' : 'Actualizar'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
