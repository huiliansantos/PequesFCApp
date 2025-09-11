import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profesor_model.dart';
import '../repositories/profesor_repository.dart';

final profesorRepositoryProvider = Provider<ProfesorRepository>((ref) {
  return ProfesorRepository();
});

final profesoresProvider = FutureProvider<List<ProfesorModel>>((ref) async {
  final repository = ref.watch(profesorRepositoryProvider);
  return repository.getProfesores();
});

