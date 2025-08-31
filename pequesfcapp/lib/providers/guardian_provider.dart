import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/guardian_repository.dart';
import '../models/guardian_model.dart';

final guardianRepositoryProvider = Provider<GuardianRepository>((ref) => GuardianRepository());

final guardiansStreamProvider = StreamProvider<List<GuardianModel>>((ref) {
  return ref.watch(guardianRepositoryProvider).guardiansStream();
});

final guardianByIdProvider = StreamProvider.family<GuardianModel?, String>((ref, id) {
  return ref.watch(guardianRepositoryProvider).guardianStreamById(id);
});