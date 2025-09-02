import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/pago_repository.dart';
import '../models/pago_model.dart';

final pagoRepositoryProvider = Provider((ref) => PagoRepository());

final pagosPorJugadorProvider = StreamProvider.family<List<PagoModel>, String>((ref, jugadorId) {
  return ref.watch(pagoRepositoryProvider).pagosPorJugador(jugadorId);
});