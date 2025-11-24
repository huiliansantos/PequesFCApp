import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/profesor_model.dart';
import '../../widgets/gradient_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profesor_provider.dart';
import '../../services/auth_registration_service.dart';  // ✅ AGREGADO

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
  String rol = 'profesor';

  bool multiAsignacion = false;
  final Set<String> equiposSeleccionados = {};

  List<Map<String, String>> categoriaEquipoItems = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  bool _expandedMultiList = false;

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
      rol = widget.profesor!.rol;

      if (categoriaEquipoId != null && categoriaEquipoId!.contains(',')) {
        multiAsignacion = true;
        equiposSeleccionados.addAll(
          categoriaEquipoId!
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty),
        );
      }
    }

    _loadCategoriaEquipoItems();

    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _loadCategoriaEquipoItems() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('categoria_equipo').get();
      final items = <Map<String, String>>[];
      final seen = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final idField = (data['id'] ?? doc.id).toString();
        if (seen.contains(idField)) continue;
        seen.add(idField);
        final categoria = (data['categoria'] ?? '').toString();
        final equipo = (data['equipo'] ?? '').toString();
        items.add({
          'docId': doc.id,
          'id': idField,
          'categoria': categoria,
          'equipo': equipo,
          'label': '$categoria - $equipo'
        });
      }

      int _getYear(Map<String, String> it) {
        final cat = it['categoria'] ?? '';
        final match = RegExp(r'\d{4}').firstMatch(cat);
        if (match != null) return int.tryParse(match.group(0)!) ?? 0;
        return 0;
      }

      items.sort((a, b) => _getYear(b).compareTo(_getYear(a)));

      if (mounted) {
        setState(() => categoriaEquipoItems = items);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar equipos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String generarUsuario(String nombre, String apellido) {
    final inicial =
        nombre.trim().isNotEmpty ? nombre.trim()[0].toLowerCase() : '';
    final primerApellido = apellido.trim().split(' ').first.toLowerCase();
    return '$inicial$primerApellido';
  }

  String generarContrasena(String ci) {
        // ✅ NUEVO FORMATO: primeros 3 números celular + 'peques'
    final ci3 = ci.trim().length >= 3
        ? ci.trim().substring(0, 3)
        : ci.trim();
    return '${ci3}peques'; // ✅ 098peques
  }

  @override
  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    ciController.dispose();
    celularController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _validarFormulario() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return false;
    if (fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Seleccione fecha de nacimiento'),
        backgroundColor: Colors.red,
      ));
      return false;
    }
    if (multiAsignacion) {
      if (equiposSeleccionados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Seleccione al menos un equipo'),
          backgroundColor: Colors.red,
        ));
        return false;
      }
    } else {
      if (categoriaEquipoId == null || categoriaEquipoId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Seleccione un equipo'),
          backgroundColor: Colors.red,
        ));
        return false;
      }
    }
    return true;
  }

  Future<void> _onGuardar() async {
    if (!_validarFormulario()) return;

    final ci = ciController.text.trim();
    final isEdit = widget.profesor != null;

    try {
      // 1) Comprobar unicidad del CI en Firestore
      final query = await FirebaseFirestore.instance
          .collection('profesores')
          .where('ci', isEqualTo: ci)
          .get();

      final exists = query.docs.any((doc) {
        if (isEdit) {
          final docIdField =
              (doc.data() as Map<String, dynamic>)['id']?.toString() ?? '';
          return doc.id != widget.profesor!.id &&
              docIdField != widget.profesor!.id;
        }
        return true;
      });

      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ya existe un profesor con ese CI'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } catch (e, st) {
      debugPrint('Error comprobando CI único: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar CI: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final usuario = generarUsuario(
      nombreController.text,
      apellidoController.text,
    );
    final contrasena = generarContrasena(ci);
    final categoriaFinal = multiAsignacion
        ? equiposSeleccionados.join(',')
        : (categoriaEquipoId ?? '');

    final profesor = ProfesorModel(
      id: isEdit ? widget.profesor!.id : const Uuid().v4(),
      nombre: nombreController.text.trim(),
      apellido: apellidoController.text.trim(),
      ci: ci,
      fechaNacimiento: fechaNacimiento!,
      celular: celularController.text.trim(),
      usuario: usuario,
      contrasena: contrasena,
      categoriaEquipoId: categoriaFinal,
      rol: rol,
    );

    // Mostrar loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final repo = ref.read(profesorRepositoryProvider);

      // ✅ GUARDAR EN FIRESTORE
      if (isEdit) {
        await repo.updateProfesor(profesor);
      } else {
        await repo.addProfesor(profesor);
      }

      ref.invalidate(profesoresProvider);

      // ✅ SI ES NUEVO, REGISTRAR EN FIREBASE AUTH
      // Usar usuario@peques.local como email (no guardamos en modelo)
      if (!isEdit) {
        try {
          await AuthRegistrationService.registrarEnAuth(
            email: '$usuario@peques.local',  // ✅ Generar email del usuario
            usuario: usuario,
            contrasena: contrasena,
            tipo: 'profesor',
            docId: profesor.id,
          );
          debugPrint('✅ Profesor registrado en Auth');
        } catch (e) {
          debugPrint('⚠️ Error al registrar en Auth: $e');
          // Continuar sin error - el usuario puede hacer login manual
        }
      }

      if (mounted) {
        Navigator.pop(context); // cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Profesor actualizado'
                  : 'Profesor registrado exitosamente',
            ),           
          ),
        );
        Navigator.pop(context);
      }
    } catch (e, st) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error guardar profesor: $e\n$st');
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

  String? _validateRequired(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  String? _validateCI(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
    if (!RegExp(r'^\d{6,12}$').hasMatch(v.trim())) return 'CI inválido';
    return null;
  }

  String? _validateCelular(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
    if (!RegExp(r'^[0-9+\s\-]{6,20}$').hasMatch(v.trim())) {
      return 'Número inválido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.profesor != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modificar Profesor' : 'Registrar Profesor'),
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
        child: ListView(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: _validateRequired,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: apellidoController,
                    decoration: const InputDecoration(labelText: 'Apellido'),
                    validator: _validateRequired,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: ciController,
                    decoration:
                        const InputDecoration(labelText: 'Carnet de Identidad'),
                    keyboardType: TextInputType.number,
                    validator: _validateCI,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: celularController,
                    decoration: const InputDecoration(labelText: 'Celular'),
                    keyboardType: TextInputType.phone,
                    validator: _validateCelular,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(fechaNacimiento == null
                        ? 'Fecha de nacimiento'
                        : 'Fecha: ${fechaNacimiento!.day}/${fechaNacimiento!.month}/${fechaNacimiento!.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fechaNacimiento ?? DateTime(2000, 1, 1),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => fechaNacimiento = picked);
                      }
                    },
                    subtitle: fechaNacimiento == null
                        ? const Text('Obligatorio')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Asignar múltiples equipos'),
                      ),
                      Switch(
                        value: multiAsignacion,
                        onChanged: (v) => setState(() {
                          multiAsignacion = v;
                          if (!v) {
                            if (equiposSeleccionados.isNotEmpty) {
                              categoriaEquipoId = equiposSeleccionados.first;
                            }
                          } else {
                            if (categoriaEquipoId != null &&
                                categoriaEquipoId!.isNotEmpty) {
                              equiposSeleccionados.clear();
                              equiposSeleccionados.addAll(
                                categoriaEquipoId!
                                    .split(',')
                                    .map((s) => s.trim())
                                    .where((s) => s.isNotEmpty),
                              );
                            }
                          }
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSelector(),
                  const SizedBox(height: 20),
                  GradientButton(
                    onPressed: _onGuardar,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.profesor != null ? Icons.save : Icons.save,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.profesor != null
                              ? 'Guardar Cambios'
                              : 'Registrar',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelector() {
    final items = categoriaEquipoItems;

    final filtered = _searchTerm.isEmpty
        ? items
        : items.where((it) {
            final label = (it['label'] ?? '').toLowerCase();
            final categoria = (it['categoria'] ?? '').toLowerCase();
            final equipo = (it['equipo'] ?? '').toLowerCase();
            return label.contains(_searchTerm) ||
                categoria.contains(_searchTerm) ||
                equipo.contains(_searchTerm);
          }).toList();

    if (!multiAsignacion) {
      final dropdownItems = filtered
          .map((it) =>
              DropdownMenuItem<String>(value: it['id'], child: Text(it['label'] ?? '')))
          .toList();
      final valueExists = dropdownItems.any((d) => d.value == categoriaEquipoId);
      final dropdownValue = valueExists ? categoriaEquipoId : null;
      return DropdownButtonFormField<String>(
        value: dropdownValue,
        decoration: const InputDecoration(
          labelText: 'Equipo asignado',
          border: OutlineInputBorder(),
        ),
        items: dropdownItems,
        onChanged: (value) => setState(() => categoriaEquipoId = value),
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Seleccione un equipo' : null,
      );
    } else {
      final displayCount =
          _expandedMultiList ? filtered.length : min(3, filtered.length);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Buscar equipos',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por categoría o equipo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Seleccione equipos',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: filtered.isEmpty
                ? const Center(child: Text('No se encontraron equipos'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: displayCount,
                    itemBuilder: (context, index) {
                      final it = filtered[index];
                      final id = it['id']!;
                      final label = it['label']!;
                      final checked = equiposSeleccionados.contains(id);
                      return CheckboxListTile(
                        value: checked,
                        title: Text(label),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              equiposSeleccionados.add(id);
                            } else {
                              equiposSeleccionados.remove(id);
                            }
                            categoriaEquipoId =
                                equiposSeleccionados.join(',');
                          });
                        },
                      );
                    },
                  ),
          ),
          if (filtered.length > 3)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    setState(() => _expandedMultiList = !_expandedMultiList),
                child: Text(_expandedMultiList
                    ? 'Ver menos'
                    : 'Ver más (${filtered.length - 3})'),
              ),
            ),
        ],
      );
    }
  }
}