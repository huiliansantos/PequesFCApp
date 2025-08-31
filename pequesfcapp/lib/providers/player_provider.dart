import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/player_repository.dart';
import '../models/player_model.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) => PlayerRepository());

final playersProvider = StreamProvider<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).playersStream();
});

final playerByIdProvider = StreamProvider.family<PlayerModel?, String>((ref, id) {
  return ref.watch(playerRepositoryProvider).playerStreamById(id);
});