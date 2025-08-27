import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/guardian_model.dart';
import '../../models/player_model.dart'; // Para mostrar jugadores
import '../../providers/player_provider.dart'; // Para obtener jugadores
import '../../providers/guardian_provider.dart'; // Importa el provider de guardianes
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GuardianFormScreen extends ConsumerStatefulWidget {
  const GuardianFormScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GuardianFormScreen> createState() => _GuardianFormScreenState();
}

class _GuardianFormScreenState extends ConsumerState<GuardianFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nombreController;
  late TextEditingController ciController;
  late TextEditingController celularController;
  late TextEditingController direccionController;

  List<String> jugadoresSeleccionados = [];
  String searchJugador = '';

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController();
    ciController = TextEditingController();
    celularController = TextEditingController();
    direccionController = TextEditingController();
  }

  @override
  void dispose() {
    nombreController.dispose();
    ciController.dispose();
    celularController.dispose();
    direccionController.dispose();
    super.dispose();
  }

  String generarUsuario(String nombreCompleto, String ci) {
    final partes = nombreCompleto.trim().split(' ');
    if (partes.length < 2) return '';
    final usuario =
        '${partes[0][0].toLowerCase()}${partes[1].toLowerCase()}${ci.substring(ci.length - 4)}';
    return usuario;
  }

  String generarContrasena(String celular) {
    return '$celular' 'peques';
  }

  Future<void> _saveGuardian() async {
    if (!_formKey.currentState!.validate()) return;

    final usuario = generarUsuario(nombreController.text, ciController.text);
    final contrasena = generarContrasena(celularController.text);

    final newGuardian = GuardianModel(
      id: Uuid().v4(),
      nombreCompleto: nombreController.text,
      ci: ciController.text,
      celular: celularController.text,
      direccion: direccionController.text,
      usuario: usuario,
      contrasena: contrasena,
      jugadoresIds: jugadoresSeleccionados,
    );

    final guardianRepo = ref.read(guardianRepositoryProvider);
    await guardianRepo.addGuardian(newGuardian);

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Apoderado')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obligatorio';
                  if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]+$').hasMatch(v))
                    return 'Solo letras';
                  return null;
                },
              ),
              TextFormField(
                controller: ciController,
                decoration: const InputDecoration(labelText: 'CI'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obligatorio';
                  if (!RegExp(r'^\d+$').hasMatch(v)) return 'Solo números';
                  return null;
                },
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: celularController,
                decoration: const InputDecoration(labelText: 'Celular'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obligatorio';
                  if (!RegExp(r'^\d{8}$').hasMatch(v))
                    return 'Debe tener 8 números';
                  return null;
                },
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: direccionController,
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 20),
              Text('Asignar Jugador(es)',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar jugador',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    searchJugador = value.trim().toLowerCase();
                  });
                },
              ),
              playersAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
                data: (jugadores) {
                  final filtrados = jugadores.where((j) {
                    final nombre = '${j.nombres} ${j.apellido}'.toLowerCase();
                    return nombre.contains(searchJugador);
                  }).toList();
                  return Column(
                    children: filtrados
                        .map((j) => CheckboxListTile(
                              title: Text('${j.nombres} ${j.apellido}'),
                              value: jugadoresSeleccionados.contains(j.id),
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    jugadoresSeleccionados.add(j.id);
                                  } else {
                                    jugadoresSeleccionados.remove(j.id);
                                  }
                                });
                              },
                            ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveGuardian,
                child: const Text('Registrar Apoderado'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
