import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/resultado_repository.dart';
import '../models/resultado_model.dart';

final resultadoRepositoryProvider = Provider<ResultadoRepository>((ref) => ResultadoRepository());

final resultadosStreamProvider = StreamProvider<List<ResultadoModel>>((ref) {
  return ref.watch(resultadoRepositoryProvider).resultadosStream();
});

final resultadoByIdProvider = StreamProvider.family<ResultadoModel?, String>((ref, id) {
  return ref.watch(resultadoRepositoryProvider).resultadoStreamById(id);
});