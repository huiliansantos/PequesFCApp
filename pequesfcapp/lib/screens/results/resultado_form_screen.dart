import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/resultado_model.dart';
import '../../widgets/gradient_button.dart';
import '../../providers/match_provider.dart';
import '../../providers/resultado_provider.dart';

class ResultadoFormScreen extends ConsumerStatefulWidget {
  final ResultadoModel? resultado; // Para edición

  const ResultadoFormScreen({Key? key, this.resultado}) : super(key: key);

  @override
  ConsumerState<ResultadoFormScreen> createState() => _ResultadoFormScreenState();
}

class _ResultadoFormScreenState extends ConsumerState<ResultadoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? partidoId;
  int golesFavor = 0;
  int golesContra = 0;
  late TextEditingController observacionesController;

  @override
  void initState() {
    super.initState();
    observacionesController = TextEditingController(text: widget.resultado?.observaciones ?? '');
    partidoId = widget.resultado?.partidoId;
    golesFavor = widget.resultado?.golesFavor ?? 0;
    golesContra = widget.resultado?.golesContra ?? 0;
  }

  @override
  void dispose() {
    observacionesController.dispose();
    super.dispose();
  }

  Future<void> _saveResultado() async {
    if (!_formKey.currentState!.validate() || partidoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    final resultado = ResultadoModel(
      id: widget.resultado?.id ?? const Uuid().v4(),
      partidoId: partidoId!,
      fecha: DateTime.now(),
      golesFavor: golesFavor,
      golesContra: golesContra,
      observaciones: observacionesController.text,
    );

    final repo = ref.read(resultadoRepositoryProvider);

    if (widget.resultado == null) {
      await repo.addResultado(resultado);
    } else {
      await repo.updateResultado(resultado); // Implementa este método en tu repo
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final partidosAsync = ref.watch(matchesProvider);
    final resultadosAsync = ref.watch(resultadosStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.resultado == null ? 'Registrar Resultado' : 'Editar Resultado')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: resultadosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (resultados) => partidosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (partidos) {
                // Filtra partidos sin resultado registrado
                final partidosConResultado = resultados.map((r) => r.partidoId).toSet();
                final partidosDisponibles = widget.resultado == null
                  ? partidos.where((p) => !partidosConResultado.contains(p.id)).toList()
                  : partidos; // Si editando, muestra todos

                // Si el partidoId actual no está en la lista, pon null
                final dropdownValue = partidosDisponibles.any((p) => p.id == partidoId) ? partidoId : null;

                return ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: dropdownValue,
                      decoration: const InputDecoration(labelText: 'Partido'),
                      items: partidosDisponibles.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.equipoRival} (${p.fecha.day}/${p.fecha.month})'),
                      )).toList(),
                      onChanged: (value) => setState(() => partidoId = value),
                      validator: (v) => v == null ? 'Selecciona un partido' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Goles a favor'),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () {
                                      setState(() {
                                        if (golesFavor > 0) golesFavor--;
                                      });
                                    },
                                  ),
                                  Text('$golesFavor', style: const TextStyle(fontSize: 20)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      setState(() {
                                        golesFavor++;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Goles en contra'),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () {
                                      setState(() {
                                        if (golesContra > 0) golesContra--;
                                      });
                                    },
                                  ),
                                  Text('$golesContra', style: const TextStyle(fontSize: 20)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      setState(() {
                                        golesContra++;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: observacionesController,
                      decoration: const InputDecoration(labelText: 'Observaciones'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      onPressed: _saveResultado,
                      child: Text(widget.resultado == null ? 'Guardar Resultado' : 'Actualizar Resultado'),
                    ),
                   
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}