import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/match_model.dart';
import '../../widgets/gradient_button.dart';
import '../../providers/match_provider.dart';

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

  @override
  void dispose() {
    equipoRivalController.dispose();
    canchaController.dispose();
    horaController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fecha ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        backgroundColor: const Color(0xFFD32F2F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Dropdown de categoría/equipo desde Firestore
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categoria_equipo').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final docs = snapshot.data!.docs;
                  final items = docs.map((doc) {
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
                validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: canchaController,
                decoration: const InputDecoration(labelText: 'Cancha'),
                validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              ListTile(
                title: Text(fecha == null ? 'Fecha' : 'Fecha: $dateFormat'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
                subtitle: fecha == null ? const Text('Obligatorio') : null,
              ),
              ListTile(
                title: Text(horaController.text.isEmpty
                    ? 'Hora'
                    : 'Hora: ${horaController.text}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
                subtitle: horaController.text.isEmpty ? const Text('Obligatorio') : null,
              ),
              DropdownButtonFormField<String>(
                value: torneo,
                decoration: const InputDecoration(labelText: 'Torneo'),
                items: torneos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (value) => setState(() => torneo = value),
                validator: (v) => v == null ? 'Selecciona un torneo' : null,
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: _saveMatch,
                child: Text(widget.match == null ? 'Guardar' : 'Actualizar'),
              ),
            
            ],
          ),
        ),
      ),
    );
  }
}