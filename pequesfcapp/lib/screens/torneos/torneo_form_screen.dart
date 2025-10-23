import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/torneo_model.dart';
import '../../widgets/gradient_button.dart';

class TorneoFormScreen extends StatefulWidget {
  final TorneoModel? torneo;
  const TorneoFormScreen({Key? key, this.torneo}) : super(key: key);

  @override
  State<TorneoFormScreen> createState() => _TorneoFormScreenState();
}

class _TorneoFormScreenState extends State<TorneoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nombreController;
  late TextEditingController lugarController;
  DateTime? fecha;

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController(text: widget.torneo?.nombre ?? '');
    lugarController = TextEditingController(text: widget.torneo?.lugar ?? '');
    fecha = widget.torneo?.fecha;
  }

  @override
  void dispose() {
    nombreController.dispose();
    lugarController.dispose();
    super.dispose();
  }

  Future<void> _guardarTorneo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (fecha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una fecha')),
      );
      return;
    }
    final data = {
      'nombre': nombreController.text.trim(),
      'lugar': lugarController.text.trim(),
      'fecha': Timestamp.fromDate(fecha!),
    };
    final col = FirebaseFirestore.instance.collection('torneos');
    if (widget.torneo == null) {
      await col.add(data);
    } else {
      await col.doc(widget.torneo!.id).update(data);
    }
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.torneo == null ? 'Registrar Torneo' : 'Modificar Torneo'),
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
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del torneo'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese el nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: lugarController,
                decoration: const InputDecoration(labelText: 'Lugar'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese el lugar' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Color(0xFFD32F2F)),
                title: Text(fecha == null
                    ? 'Seleccionar fecha'
                    : '${fecha!.day}/${fecha!.month}/${fecha!.year}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: fecha ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => fecha = picked);
                },
                trailing: fecha == null
                    ? const Icon(Icons.error, color: Colors.red)
                    : null,
              ),
              if (fecha == null)
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, top: 4.0),
                  child: Text(
                    'Debes seleccionar una fecha',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),
              //añadir el gradient button
              GradientButton(onPressed: _guardarTorneo,
               child: Text(widget.torneo == null ? 'Registrar' : 'Actualizar')),
            
            ],
          ),
        ),
      ),
    );
  }
}