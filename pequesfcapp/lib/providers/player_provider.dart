import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simulación de lista de jugadores (reemplaza con tu modelo real)
final playerListProvider = StateProvider<List<Map<String, dynamic>>>((ref) => [
  {
    'nombre': 'Juan Pérez',
    'categoria': 'Sub-10',
    'apoderado': 'Carlos Pérez',
    'estadoPago': 'pagado',
    'fotoUrl': null,
  },
  // Agrega más jugadores aquí
]);