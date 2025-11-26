import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/guardian_model.dart';
import '../../models/player_model.dart';
import '../../providers/player_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../providers/guardian_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_registration_service.dart'; // ✅ AGREGADO

class GuardianFormScreen extends ConsumerStatefulWidget {
  final GuardianModel? guardian;
  final PlayerModel? jugador;

  const GuardianFormScreen({Key? key, this.guardian, this.jugador})
      : super(key: key);

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
  bool _isSaving = false; // ✅ AGREGADO

  @override
  void initState() {
    super.initState();
    final partesNombre = widget.guardian?.nombreCompleto.split(' ') ?? ['', ''];
    nombreController = TextEditingController(
        text: partesNombre.isNotEmpty ? partesNombre[0] : '');
    apellidoController = TextEditingController(text: widget.guardian?.apellido ?? '');
    ciController = TextEditingController(text: widget.guardian?.ci ?? '');
    celularController =
        TextEditingController(text: widget.guardian?.celular ?? '');
    direccionController =
        TextEditingController(text: widget.guardian?.direccion ?? '');
    usuarioController =
        TextEditingController(text: widget.guardian?.usuario ?? '');
    contrasenaController =
        TextEditingController(text: widget.guardian?.contrasena ?? '');
    jugadoresSeleccionados = widget.guardian?.jugadoresIds.toList() ?? [];
    if (widget.jugador != null &&
        !jugadoresSeleccionados.contains(widget.jugador!.id)) {
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
    // ✅ NUEVO FORMATO: inicial nombre + primer apellido + primeros 3 dígitos CI
    final inicial =
        nombre.trim().isNotEmpty ? nombre.trim()[0].toLowerCase() : '';

    // Obtener el PRIMER apellido (si hay múltiples separados por espacio)
    final primerApellido = apellido.trim().split(' ').first.toLowerCase();

    // Primeros 3 números del CI
    final ci3 = ci.trim().length >= 3 ? ci.trim().substring(0, 3) : ci.trim();

    return '$inicial$primerApellido$ci3'; // ✅ jgarcia123
  }

  String generarContrasena(String celular) {
    // ✅ NUEVO FORMATO: primeros 3 números celular + 'peques'
    final celular3 = celular.trim().length >= 3
        ? celular.trim().substring(0, 3)
        : celular.trim();
    return '${celular3}peques'; // ✅ 098peques
  }

  Future<bool> existeCI(String ci) async {
    final repo = ref.read(guardianRepositoryProvider);
    final lista = await repo.buscarPorCI(ci);
    // Si es edición, permite el mismo CI del apoderado actual
    if (widget.guardian != null) {
      return lista != null &&
          lista is List &&
          (lista as List).any((g) => g.ci == ci && g.id != widget.guardian!.id);
    }
    return lista != null && lista is List && (lista as List).isNotEmpty;
  }

  Future<void> _saveGuardian() async {
    if (!_formKey.currentState!.validate()) return;

    // Validación extra: CI único
    if (await existeCI(ciController.text)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Ya existe un apoderado con ese carnet de identidad')),
        );
      }
      return;
    }

    // Genera usuario y contraseña automáticamente
    final usuarioGenerado = generarUsuario(
      nombreController.text,
      apellidoController.text,
      ciController.text,
    );
    final contrasenaGenerada = generarContrasena(celularController.text);

    final newGuardian = GuardianModel(
      id: widget.guardian?.id ?? const Uuid().v4(),
      nombreCompleto: nombreController.text,
      apellido: apellidoController.text,
      ci: ciController.text,
      celular: celularController.text,
      direccion: direccionController.text,
      usuario: usuarioGenerado,
      contrasena: contrasenaGenerada,
      jugadoresIds: jugadoresSeleccionados,
      rol: 'apoderado',
    );

    final repo = ref.read(guardianRepositoryProvider);
    final isNew = widget.guardian == null;

    // ✅ GUARDAR EMAIL Y CONTRASEÑA DEL ADMIN
    final adminEmail = FirebaseAuth.instance.currentUser?.email;
    String? adminPassword;
    // Aquí debes obtener la contraseña del admin, por ejemplo desde un campo seguro en tu app
    adminPassword = '123456';

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // ✅ GUARDAR EN FIRESTORE
      if (isNew) {
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
        final jugadoresQuitados = widget.guardian!.jugadoresIds
            .where((id) => !jugadoresSeleccionados.contains(id));
        for (final jugadorId in jugadoresQuitados) {
          await playerRepo.actualizarGuardian(jugadorId, '');
        }
      }

      // ✅ SI ES NUEVO, REGISTRAR EN FIREBASE AUTH
      if (isNew) {
        try {
          await AuthRegistrationService.registrarEnAuth(
            email: '${usuarioGenerado}@peques.local',
            usuario: usuarioGenerado,
            contrasena: contrasenaGenerada,
            tipo: 'apoderado',
            docId: newGuardian.id,
          );
          debugPrint('✅ Apoderado registrado en Auth');

          // ✅ VOLVER A LOGUEAR AL ADMIN AUTOMÁTICAMENTE
          if (adminEmail != null && adminPassword != null) {
            await FirebaseAuth.instance.signOut();
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: adminEmail,
              password: adminPassword,
            );
            debugPrint('✅ Sesión de admin restaurada');
          }
        } catch (e) {
          debugPrint('⚠️ Error al registrar en Auth: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context); // cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNew
                  ? 'Apoderado registrado exitosamente'
                  : 'Apoderado actualizado correctamente',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e, st) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error guardar apoderado: $e\n$st');
      if (mounted) {
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
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.guardian == null
            ? 'Registrar Apoderado'
            : 'Editar Apoderado'),
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
                        if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]+$').hasMatch(v))
                          return 'Solo letras';
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
                        if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]+$').hasMatch(v))
                          return 'Solo letras';
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
                  if (!RegExp(r'^\d{7,}$').hasMatch(v))
                    return 'Debe tener al menos 7 números';
                  return null;
                },
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: celularController,
                decoration: const InputDecoration(labelText: 'Celular'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obligatorio';
                  if (!RegExp(r'^\d{8,}$').hasMatch(v))
                    return 'Debe tener al menos 8 números';
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
              const Text('Asignar Jugador(es)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                  // Solo muestra los jugadores que están seleccionados o que coinciden con la búsqueda
                  final filtrados = jugadores.where((j) {
                    final nombre = '${j.nombres} ${j.apellido}'.toLowerCase();
                    final seleccionado = jugadoresSeleccionados.contains(j.id);
                    return seleccionado ||
                        (searchJugador.isNotEmpty &&
                            nombre.contains(searchJugador));
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
              GradientButton(
                onPressed: _isSaving ? null : _saveGuardian, // ✅ AGREGADO
                child: Text(widget.guardian == null
                    ? 'Registrar Apoderado'
                    : 'Actualizar Apoderado'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
