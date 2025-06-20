import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simulación de lista de pagos (reemplaza con tu modelo real)
final paymentListProvider = StateProvider<List<Map<String, dynamic>>>((ref) => [
  {
    'mes': 'Junio',
    'monto': 100.0,
    'estado': 'pagado',
    'comprobanteUrl': null,
    'fechaRegistro': DateTime.now(),
  },
  // Agrega más pagos aquí
]);