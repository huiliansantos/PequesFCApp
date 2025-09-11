import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/profesor_model.dart';
import '../../widgets/gradient_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profesor_provider.dart';

class ProfesorFormScreen extends ConsumerStatefulWidget {
  final ProfesorModel? profesor;

  const ProfesorFormScreen({Key? key, this.profesor}) : super(key: key);

  @override
  ConsumerState<ProfesorFormScreen> createState() => _ProfesorFormScreenState();
}

class _ProfesorFormScreenState extends ConsumerState<ProfesorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final ciController = TextEditingController();
  final celularController = TextEditingController();
  DateTime? fechaNacimiento;
  String? categoriaEquipoId;

  String generarUsuario(String nombre, String apellido) {
    final inicial = nombre.trim().isNotEmpty ? nombre.trim()[0].toLowerCase() : '';
    final primerApellido = apellido.trim().split(' ').first.toLowerCase();
    return '$inicial$primerApellido';
  }

  String generarContrasena(String ci) => '${ci}peques';

  @override
  void initState() {
    super.initState();
    if (widget.profesor != null) {
      nombreController.text = widget.profesor!.nombre;
      apellidoController.text = widget.profesor!.apellido;
      ciController.text = widget.profesor!.ci;
      celularController.text = widget.profesor!.celular;
      fechaNacimiento = widget.profesor!.fechaNacimiento;
      categoriaEquipoId = widget.profesor!.categoriaEquipoId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.profesor != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modificar Profesor' : 'Registrar Profesor'),
        backgroundColor: const Color(0xFFD32F2F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: apellidoController,
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: ciController,
                decoration: const InputDecoration(labelText: 'Carnet de Identidad'),
                validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: celularController,
                decoration: const InputDecoration(labelText: 'Celular'),
                validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              ListTile(
                title: Text(fechaNacimiento == null
                    ? 'Fecha de nacimiento'
                    : 'Fecha: ${fechaNacimiento!.day}/${fechaNacimiento!.month}/${fechaNacimiento!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000, 1, 1),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      fechaNacimiento = picked;
                    });
                  }
                },
                subtitle: fechaNacimiento == null ? const Text('Obligatorio') : null,
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categoria_equipo').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  final ids = <String>{};
                  final items = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final id = (data['id'] ?? doc.id).toString();
                    // Evita duplicados
                    if (ids.contains(id)) return false;
                    ids.add(id);
                    return true;
                  }).map<DropdownMenuItem<String>>((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final id = (data['id'] ?? doc.id).toString();
                    final categoria = data['categoria'] ?? '';
                    final equipo = data['equipo'] ?? '';
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text('$categoria - $equipo'),
                    );
                  }).toList();

                  // Si el valor actual no está en los items, ponlo en null
                  final valueExists = items.any((item) => item.value == categoriaEquipoId);
                  final dropdownValue = valueExists ? categoriaEquipoId : null;

                  return DropdownButtonFormField<String>(
                    value: dropdownValue,
                    decoration: const InputDecoration(
                      labelText: 'Equipo asignado',
                      border: OutlineInputBorder(),
                    ),
                    items: items,
                    onChanged: (value) => setState(() => categoriaEquipoId = value),
                    validator: (v) => v == null ? 'Seleccione un equipo' : null,
                  );
                },
              ),
              const SizedBox(height: 20),
              
              GradientButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() && fechaNacimiento != null) {
                    final usuario = generarUsuario(nombreController.text, apellidoController.text);
                    final contrasena = generarContrasena(ciController.text);
                    final profesor = ProfesorModel(
                      id: isEdit ? widget.profesor!.id : const Uuid().v4(),
                      nombre: nombreController.text,
                      apellido: apellidoController.text,
                      ci: ciController.text,
                      fechaNacimiento: fechaNacimiento!,
                      celular: celularController.text,
                      usuario: usuario,
                      contrasena: contrasena,
                      categoriaEquipoId: categoriaEquipoId!,
                    );
                    final repo = ref.read(profesorRepositoryProvider);
                    if (isEdit) {
                      await repo.updateProfesor(profesor);
                      if (context.mounted) {
                        ref.invalidate(profesoresProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profesor actualizado correctamente')),
                        );
                        Navigator.pop(context);
                      }
                    } else {
                      await repo.addProfesor(profesor);
                      if (context.mounted) {
                        ref.invalidate(profesoresProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profesor registrado correctamente')),
                        );
                        Navigator.pop(context);
                      }
                    }
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isEdit ? Icons.save : Icons.save, color: Colors.white),
                    SizedBox(width: 8),
                    Text(isEdit ? 'Guardar Cambios' : 'Registrar'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}