import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/guardian_repository.dart';
import '../models/guardian_model.dart';

// Proveedor del repositorio de guardianes
final guardianRepositoryProvider = Provider<GuardianRepository>((ref) => GuardianRepository());

// Proveedor de stream de todos los guardianes (actualización en tiempo real)
final guardiansStreamProvider = StreamProvider<List<GuardianModel>>((ref) {
  return ref.watch(guardianRepositoryProvider).guardiansStream();
});

// Proveedor reactivo para obtener un guardian por ID (actualización automática)
final guardianByIdProvider = StreamProvider.family<GuardianModel?, String>((ref, id) {
  return ref.watch(guardianRepositoryProvider).guardianStreamById(id);
});

// Para agregar, editar, eliminar guardianes, usa directamente los métodos del repositorio:
// Ejemplo: ref.read(guardianRepositoryProvider).addGuardian(guardian);