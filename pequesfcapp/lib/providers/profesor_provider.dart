import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../models/profesor_model.dart';
import '../repositories/profesor_repository.dart';


final profesorByUsuarioYContrasenaProvider = FutureProvider.family<ProfesorModel?, Map<String, String>>((ref, cred) async {
  final repository = ref.watch(profesorRepositoryProvider);
  final profesores = await repository.getProfesores();
  return profesores.firstWhereOrNull(
    (p) => p.usuario == cred['usuario'] && p.contrasena == cred['contrasena'],
  );
});

final profesorRepositoryProvider = Provider<ProfesorRepository>((ref) {
  return ProfesorRepository();
});

final profesoresProvider = FutureProvider<List<ProfesorModel>>((ref) async {
  final repository = ref.watch(profesorRepositoryProvider);
  return repository.getProfesores();
});

