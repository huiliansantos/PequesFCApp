import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/pago_model.dart';
import '../../providers/pago_provider.dart';
import '../../widgets/gradient_button.dart';

const List<String> mesesDelAno = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre'
];

const List<int> anios = [2021, 2022, 2023, 2024, 2025];

class PaymentForm extends ConsumerStatefulWidget {
  final String jugadorId;
  final String jugadorNombre;
  final String? mesInicial; // <-- Nuevo parámetro

  const PaymentForm({
    Key? key,
    required this.jugadorId,
    required this.jugadorNombre,
    this.mesInicial,
  }) : super(key: key);

  @override
  ConsumerState<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _observacionController = TextEditingController();
  DateTime _fechaPago = DateTime.now();
  String _estado = 'pagado';
  String? _mesSeleccionado;
  int? _anioSeleccionado; // <-- Nuevo campo

  @override
  void initState() {
    super.initState();
    _mesSeleccionado = widget.mesInicial;
    _anioSeleccionado = 2025; // <-- Año por defecto
  }

  @override
  void dispose() {
    _montoController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registrar pago de:'),
            Text(
              '${widget.jugadorNombre}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto (Bs/)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese el monto';
                  if (double.tryParse(value) == null) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _mesSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Mes',
                  border: OutlineInputBorder(),
                ),
                items: mesesDelAno.map((mes) =>
                  DropdownMenuItem(value: mes, child: Text(mes))
                ).toList(),
                onChanged: (value) {
                  setState(() {
                    _mesSeleccionado = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Seleccione el mes';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _anioSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Año',
                  border: OutlineInputBorder(),
                ),
                items: anios.map((anio) =>
                  DropdownMenuItem(value: anio, child: Text(anio.toString()))
                ).toList(),
                onChanged: (value) {
                  setState(() {
                    _anioSeleccionado = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Seleccione el año';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de pago'),
                subtitle: Text(
                  '${_fechaPago.day}/${_fechaPago.month}/${_fechaPago.year}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _fechaPago,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _fechaPago = picked;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _estado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pagado', child: Text('Pagado')),
                  DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                  DropdownMenuItem(value: 'atrasado', child: Text('Atrasado')),
                ],
                onChanged: (value) {
                  setState(() {
                    _estado = value ?? 'pagado';
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacionController,
                decoration: const InputDecoration(
                  labelText: 'Observación (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              GradientButton(
                onPressed: _guardarPago,
                child: const Text('Guardar pago'),
              ),
            
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarPago() async {
    if (_formKey.currentState?.validate() ?? false) {
      final pago = PagoModel(
        id: const Uuid().v4(),
        jugadorId: widget.jugadorId,
        fechaPago: _fechaPago,
        monto: double.tryParse(_montoController.text) ?? 0.0,
        mes: _mesSeleccionado ?? '',
        anio: _anioSeleccionado ?? 0,
        estado: _estado,
        observacion: _observacionController.text.trim().isEmpty
            ? null
            : _observacionController.text.trim(),
      );
      await ref.read(pagoRepositoryProvider).registrarPago(pago);
      if (context.mounted) Navigator.pop(context);
    }
  }
}