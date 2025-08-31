import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/asistencia_repository.dart';
import '../models/asistencia_model.dart';

final asistenciaRepositoryProvider = Provider<AsistenciaRepository>((ref) => AsistenciaRepository());

final asistenciasPorJugadorProvider = StreamProvider.family<List<AsistenciaModel>, String>((ref, jugadorId) {
  return ref.watch(asistenciaRepositoryProvider).asistenciasPorJugador(jugadorId);
});

final asistenciasPorEntrenamientoProvider = StreamProvider.family<List<AsistenciaModel>, String>((ref, entrenamientoId) {
  return ref.watch(asistenciaRepositoryProvider).asistenciasPorEntrenamiento(entrenamientoId);
});