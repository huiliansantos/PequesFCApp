import 'package:flutter/material.dart';

class ResultRegistrationScreen extends StatefulWidget {
  final String rival;
  final String categoria;
  final DateTime fecha;

  const ResultRegistrationScreen({
    super.key,
    required this.rival,
    required this.categoria,
    required this.fecha,
  });

  @override
  State<ResultRegistrationScreen> createState() => _ResultRegistrationScreenState();
}

class _ResultRegistrationScreenState extends State<ResultRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String goles = '';
  String asistencias = '';
  String observaciones = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Resultado'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Rival: ${widget.rival}', style: const TextStyle(fontSize: 18)),
              Text('Categoría: ${widget.categoria}', style: const TextStyle(fontSize: 18)),
              Text('Fecha: ${widget.fecha.day}/${widget.fecha.month}/${widget.fecha.year}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Goles',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => goles = v,
                validator: (v) => v != null && v.isNotEmpty ? null : 'Ingrese goles',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Asistencias',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => asistencias = v,
                validator: (v) => v != null && v.isNotEmpty ? null : 'Ingrese asistencias',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (v) => observaciones = v,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Guardar resultado (conectar a Firestore en el futuro)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Resultado registrado')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}