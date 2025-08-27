import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/match_model.dart';
import '../../providers/match_provider.dart';

class MatchFormScreen extends ConsumerStatefulWidget {
  const MatchFormScreen({Key? key}) : super(key: key);

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
  String? categoria;
  String? equipoId;
  TimeOfDay? horaSeleccionada;

  // Simulación de datos (reemplaza por tus providers reales)
  final List<String> torneos = ['Apertura', 'Clausura', 'Amistoso'];
  final List<String> categorias = ['Sub-8', 'Sub-10', 'Sub-12', 'Sub-14', 'Sub-16'];
  final Map<String, List<String>> equiposPorCategoria = {
    'Sub-8': ['Peques Sub8 Junior', 'Peques Sub8'],
    'Sub-10': ['Peques Sub10 Junior', 'Peques Sub10'],
    // ...agrega más según tus datos...
  };

  @override
  void initState() {
    super.initState();
    equipoRivalController = TextEditingController();
    canchaController = TextEditingController();
    horaController = TextEditingController();
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
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
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
    if (!_formKey.currentState!.validate() || fecha == null || torneo == null || categoria == null || equipoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    final newMatch = MatchModel(
      id: const Uuid().v4(),
      equipoRival: equipoRivalController.text,
      cancha: canchaController.text,
      fecha: fecha!,
      hora: horaController.text,
      torneo: torneo!,
      categoria: categoria!,
      equipoId: equipoId!,
    );

    final matchRepo = ref.read(matchRepositoryProvider);
    await matchRepo.addMatch(newMatch);

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = fecha != null ? '${fecha!.day}/${fecha!.month}/${fecha!.year}' : '';
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Partido')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
              DropdownButtonFormField<String>(
                value: categoria,
                decoration: const InputDecoration(labelText: 'CATEGORIA'),
                items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) {
                  setState(() {
                    categoria = value;
                    equipoId = null;
                  });
                },
                validator: (v) => v == null ? 'Selecciona una categoría' : null,
              ),
              if (categoria != null)
                DropdownButtonFormField<String>(
                  value: equipoId,
                  decoration: const InputDecoration(labelText: 'Equipo'),
                  items: equiposPorCategoria[categoria]!
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => equipoId = value),
                  validator: (v) => v == null ? 'Selecciona un equipo' : null,
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                onPressed: _saveMatch,
              ),
            ],
          ),
        ),
      ),
    );
  }
}