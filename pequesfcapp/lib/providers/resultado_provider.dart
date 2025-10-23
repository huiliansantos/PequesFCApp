import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/resultado_repository.dart';
import '../models/resultado_model.dart';

final resultadoRepositoryProvider = Provider<ResultadoRepository>((ref) => ResultadoRepository());

final resultadosStreamProvider = StreamProvider<List<ResultadoModel>>((ref) {
  final repo = ref.watch(resultadoRepositoryProvider);
  return repo.resultadosStream();
});

// Set de partidoIds que tienen resultado (útil para filtrar UI)
final resultadosIdsProvider = StreamProvider<Set<String>>((ref) {
  // ignore: deprecated_member_use
  return ref.watch(resultadosStreamProvider.stream).map((list) {
    return list.map((r) => (r.partidoId).trim()).where((s) => s.isNotEmpty).toSet();
  });
});

final resultadoByIdProvider = StreamProvider.family<ResultadoModel?, String>((ref, id) {
  return ref.watch(resultadoRepositoryProvider).resultadoStreamById(id);
});
final resultadosProvider = FutureProvider<List<ResultadoModel>>((ref) async {
  return ref.watch(resultadoRepositoryProvider).getResultados();
});