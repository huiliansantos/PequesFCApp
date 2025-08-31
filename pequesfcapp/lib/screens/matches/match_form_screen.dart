import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/match_model.dart';
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
    equipoRivalController = TextEditingController(text: widget.match?.equipoRival ?? '');
    canchaController = TextEditingController(text: widget.match?.cancha ?? '');
    horaController = TextEditingController(text: widget.match?.hora ?? '');
    fecha = widget.match?.fecha;
    torneo = widget.match?.torneo;
    categoria = widget.match?.categoria;
    equipoId = widget.match?.equipoId;
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
    if (!_formKey.currentState!.validate() || fecha == null || torneo == null || categoria == null || equipoId == null) {
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
      categoria: categoria!,
      equipoId: equipoId!,
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
      ),
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
              if (categoria != null && equiposPorCategoria[categoria] != null)
                DropdownButtonFormField<String>(
                  value: equipoId,
                  decoration: const InputDecoration(labelText: 'Equipo'),
                  items: (equiposPorCategoria[categoria] ?? [])
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => equipoId = value),
                  validator: (v) => v == null ? 'Selecciona un equipo' : null,
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(widget.match == null ? 'Guardar' : 'Actualizar'),
                onPressed: _saveMatch,
              ),
            ],
          ),
        ),
      ),
    );
  }
}