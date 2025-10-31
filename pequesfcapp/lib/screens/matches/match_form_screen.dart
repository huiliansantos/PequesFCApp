import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatear fechas si lo deseas
import '../../models/match_model.dart';
import '../../widgets/gradient_button.dart';
import '../../providers/match_provider.dart';
import '../torneos/torneo_form_screen.dart';

class MatchFormScreen extends ConsumerStatefulWidget {
  final MatchModel? match;

  const MatchFormScreen({Key? key, this.match}) : super(key: key);

  @override
  ConsumerState<MatchFormScreen> createState() => _MatchFormScreenState();
}

class _MatchFormScreenState extends ConsumerState<MatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController equipoRivalController;
  late TextEditingController canchaController;
  late TextEditingController horaController;
  DateTime? fecha;
  String? torneo;
  String? categoriaEquipoId;
  String? equipoRivalId;
  TimeOfDay? horaSeleccionada;
  String? torneoId;
  List<Map<String, dynamic>> torneosFirestore = [];
  //generar nombre de categoria a partir del categoriaEquipoId
  

  final List<String> torneos = ['Apertura', 'Clausura', 'Amistoso'];

  @override
  void initState() {
    super.initState();
    equipoRivalController = TextEditingController(text: widget.match?.equipoRival ?? '');
    canchaController = TextEditingController(text: widget.match?.cancha ?? '');
    horaController = TextEditingController(text: widget.match?.hora ?? '');
    fecha = widget.match?.fecha;
    torneo = widget.match?.torneo;
    categoriaEquipoId = widget.match?.categoriaEquipoId;
    _loadTorneos();
    
    if (widget.match?.hora != null && widget.match!.hora.isNotEmpty) {
      final parts = widget.match!.hora.split(':');
      if (parts.length == 2) {
        horaSeleccionada = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  Future<void> _loadTorneos() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('torneos')
        .orderBy('fecha', descending: true)
        .get();
    setState(() {
      torneosFirestore = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'nombre': doc['nombre'] ?? '',
              })
          .toList();
    });
  }

  @override
  void dispose() {
    equipoRivalController.dispose();
    canchaController.dispose();
    horaController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    // Si estamos registrando (widget.match == null) no permitir días pasados:
    final firstDate = widget.match == null
        ? DateTime(now.year, now.month, now.day) // hoy (sin hora)
        : DateTime.now().subtract(const Duration(days: 365)); // al editar permitir fechas recientes pasadas (ajustable)

    final lastDate = DateTime.now().add(const Duration(days: 365));
    // initialDate debe estar entre firstDate y lastDate
    DateTime initial = fecha ?? now;
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        fecha = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: horaSeleccionada ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        horaSeleccionada = picked;
        horaController.text = picked.format(context);
      });
    }
  }

  Future<void> _saveMatch() async {
    if (!_formKey.currentState!.validate() || fecha == null || torneo == null || categoriaEquipoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    final match = MatchModel(
      id: widget.match?.id ?? const Uuid().v4(),
      equipoRival: equipoRivalController.text,
      cancha: canchaController.text,
      fecha: fecha!,
      hora: horaController.text,
      torneo: torneo!,
      categoriaEquipoId: categoriaEquipoId!,      
    );

    final matchRepo = ref.read(matchRepositoryProvider);
    if (widget.match == null) {
      await matchRepo.addMatch(match);
    } else {
      await matchRepo.updateMatch(match);
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = fecha != null ? '${fecha!.day}/${fecha!.month}/${fecha!.year}' : '';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.match == null ? 'Registrar Partido' : 'Modificar Partido'),
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
              // Dropdown de categoría/equipo desde Firestore, ordenado por año descendente
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categoria_equipo').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final docs = snapshot.data!.docs;
                  // Ordenar por año descendente si el campo 'categoria' contiene el año
                  List<QueryDocumentSnapshot> ordenados = [...docs];
                  ordenados.sort((a, b) {
                    int getAnio(dynamic doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final exp = RegExp(r'\d{4}');
                      final match = exp.firstMatch(data['categoria'] ?? '');
                      return match != null ? int.tryParse(match.group(0)!) ?? 0 : 0;
                    }
                    return getAnio(b).compareTo(getAnio(a));
                  });

                  final items = ordenados.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final id = (data['id'] ?? doc.id).toString();
                    final categoria = data['categoria'] ?? '';
                    final equipo = data['equipo'] ?? '';
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text('$categoria - $equipo'),
                    );
                  }).toList();
                  return DropdownButtonFormField<String>(
                    value: categoriaEquipoId,
                    decoration: const InputDecoration(
                      labelText: 'Categoría y Equipo',
                      border: OutlineInputBorder(),
                    ),
                    items: items,
                    onChanged: (value) {
                      setState(() {
                        categoriaEquipoId = value;
                      });
                    },
                    validator: (value) => value == null ? 'Seleccione una categoría/equipo' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: equipoRivalController,
                decoration: const InputDecoration(labelText: 'Equipo Rival'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: canchaController,
                decoration: const InputDecoration(labelText: 'Cancha'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(fecha == null ? 'Fecha' : 'Fecha: $dateFormat'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
                subtitle: fecha == null ? const Text('Obligatorio', style: TextStyle(color: Colors.red)) : null,
              ),
              ListTile(
                title: Text(horaController.text.isEmpty
                    ? 'Hora'
                    : 'Hora: ${horaController.text}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
                subtitle: horaController.text.isEmpty ? const Text('Obligatorio', style: TextStyle(color: Colors.red)) : null,
              ),
              DropdownButtonFormField<String>(
                value: torneoId,
                decoration: const InputDecoration(labelText: 'Torneo'),
                items: [
                  ...torneosFirestore.map((t) => DropdownMenuItem(
                        value: t['id'],
                        child: Text(t['nombre']),
                      )),
                  const DropdownMenuItem(
                    value: 'nuevo',
                    child: Text('Registrar nuevo torneo...'),
                  ),
                ],
                onChanged: (value) async {
                  if (value == 'nuevo') {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TorneoFormScreen(),
                      ),
                    );
                    await _loadTorneos();
                    if (result is String) {
                      setState(() {
                        torneoId = result;
                        torneo = torneosFirestore.firstWhere(
                          (t) => t['id'] == result,
                          orElse: () => {'nombre': ''},
                        )['nombre'];
                      });
                    }
                  } else {
                    setState(() {
                      torneoId = value;
                      torneo = torneosFirestore.firstWhere(
                        (t) => t['id'] == value,
                        orElse: () => {'nombre': ''},
                      )['nombre'];
                    });
                  }
                },
                validator: (v) => v == null ? 'Selecciona un torneo' : null,
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      fecha != null &&
                      horaController.text.isNotEmpty &&
                      torneo != null &&
                      categoriaEquipoId != null) {
                    _saveMatch();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Completa todos los campos obligatorios')),
                    );
                  }
                },
                child: Text(widget.match == null ? 'Guardar' : 'Actualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}