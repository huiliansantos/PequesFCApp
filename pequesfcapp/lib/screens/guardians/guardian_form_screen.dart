import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/guardian_model.dart';
import '../../models/player_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/guardian_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GuardianFormScreen extends ConsumerStatefulWidget {
  final GuardianModel? guardian;
  final PlayerModel? jugador;

  const GuardianFormScreen({Key? key, this.guardian, this.jugador}) : super(key: key);

  @override
  ConsumerState<GuardianFormScreen> createState() => _GuardianFormScreenState();
}

class _GuardianFormScreenState extends ConsumerState<GuardianFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nombreController;
  late TextEditingController apellidoController;
  late TextEditingController ciController;
  late TextEditingController celularController;
  late TextEditingController direccionController;
  late TextEditingController usuarioController;
  late TextEditingController contrasenaController;

  List<String> jugadoresSeleccionados = [];
  String searchJugador = '';

  @override
  void initState() {
    super.initState();
    final partesNombre = widget.guardian?.nombreCompleto.split(' ') ?? ['', ''];
    nombreController = TextEditingController(text: partesNombre.isNotEmpty ? partesNombre[0] : '');
    apellidoController = TextEditingController(text: partesNombre.length > 1 ? partesNombre[1] : '');
    ciController = TextEditingController(text: widget.guardian?.ci ?? '');
    celularController = TextEditingController(text: widget.guardian?.celular ?? '');
    direccionController = TextEditingController(text: widget.guardian?.direccion ?? '');
    usuarioController = TextEditingController(text: widget.guardian?.usuario ?? '');
    contrasenaController = TextEditingController(text: widget.guardian?.contrasena ?? '');
    jugadoresSeleccionados = widget.guardian?.jugadoresIds.toList() ?? [];
    if (widget.jugador != null && !jugadoresSeleccionados.contains(widget.jugador!.id)) {
      jugadoresSeleccionados.add(widget.jugador!.id);
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    ciController.dispose();
    celularController.dispose();
    direccionController.dispose();
    usuarioController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  String generarUsuario(String nombre, String apellido, String ci) {
    final inicial = nombre.trim().isNotEmpty ? nombre.trim()[0].toLowerCase() : '';
    final ap = apellido.trim().toLowerCase();
    final ci3 = ci.trim().length >= 3 ? ci.trim().substring(0, 3) : ci.trim();
    return '$inicial$ap$ci3';
  }

  String generarContrasena(String celular) {
    return '$celular' 'pequestarija';
  }

  Future<void> _saveGuardian() async {
    if (!_formKey.currentState!.validate()) return;

    // Genera usuario y contraseña automáticamente solo si es nuevo
    final usuarioGenerado = generarUsuario(nombreController.text, apellidoController.text, ciController.text);
    final contrasenaGenerada = generarContrasena(celularController.text);

    final newGuardian = GuardianModel(
      id: widget.guardian?.id ?? const Uuid().v4(),
      nombreCompleto: '${nombreController.text} ${apellidoController.text}',
      ci: ciController.text,
      celular: celularController.text,
      direccion: direccionController.text,
      usuario: usuarioGenerado,
      contrasena: contrasenaGenerada,
      jugadoresIds: jugadoresSeleccionados,
      rol: 'apoderado',
    );

    final repo = ref.read(guardianRepositoryProvider);

    if (widget.guardian == null) {
      await repo.addGuardian(newGuardian);
    } else {
      await repo.updateGuardian(newGuardian);
    }

    // ACTUALIZA EL GUARDIAN EN CADA JUGADOR ASIGNADO
    final playerRepo = ref.read(playerRepositoryProvider);
    for (final jugadorId in jugadoresSeleccionados) {
      await playerRepo.actualizarGuardian(jugadorId, newGuardian.id);
    }

    // Si quitaste jugadores, pon guardianId en vacío
    if (widget.guardian != null) {
      final jugadoresQuitados = widget.guardian!.jugadoresIds.where((id) => !jugadoresSeleccionados.contains(id));
      for (final jugadorId in jugadoresQuitados) {
        await playerRepo.actualizarGuardian(jugadorId, '');
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apoderado registrado/actualizado correctamente')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.guardian == null ? 'Registrar Apoderado' : 'Editar Apoderado'),
        backgroundColor: const Color(0xFFD32F2F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Campo obligatorio';
                        if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]+$').hasMatch(v)) return 'Solo letras';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: apellidoController,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Campo obligatorio';
                        if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]+$').hasMatch(v)) return 'Solo letras';
                        return null;
                      },
                    ),
                  ),
                ],
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
                  if (!RegExp(r'^\d{8}$').hasMatch(v)) return 'Debe tener 8 números';
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
              Text('Asignar Jugador(es)', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                child: Text(widget.guardian == null ? 'Registrar Apoderado' : 'Actualizar Apoderado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
