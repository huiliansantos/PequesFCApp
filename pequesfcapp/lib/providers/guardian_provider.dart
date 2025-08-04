import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/guardian_repository.dart';
import '../models/guardian_model.dart';

// Proveedor del repositorio de guardianes
final guardianRepositoryProvider = Provider((ref) => GuardianRepository());

// Proveedor de stream de guardianes (actualización en tiempo real)
final guardiansStreamProvider = StreamProvider<List<GuardianModel>>((ref) {
  return ref.watch(guardianRepositoryProvider).guardiansStream();
});

// Proveedor para obtener un guardian por ID
final guardianByIdProvider = FutureProvider.family<GuardianModel?, String>((ref, id) async {
  return ref.watch(guardianRepositoryProvider).getGuardianById(id);
});

// Para agregar, editar, eliminar guardianes, usa directamente los métodos del repositorio:
// Ejemplo: ref.read(guardianRepositoryProvider).addGuardian(guardian);