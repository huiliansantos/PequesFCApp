import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/player_repository.dart';
import '../models/player_model.dart';

final playerRepositoryProvider = Provider((ref) => PlayerRepository());

final playersProvider = StreamProvider<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).playersStream();
});

final playerProvider = FutureProvider.family<PlayerModel?, String>((ref, id) async {
  return ref.watch(playerRepositoryProvider).getPlayerById(id);
});