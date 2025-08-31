import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/match_repository.dart';
import '../models/match_model.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) => MatchRepository());

final matchesProvider = StreamProvider<List<MatchModel>>((ref) {
  return ref.watch(matchRepositoryProvider).matchesStream();
});

final matchByIdProvider = StreamProvider.family<MatchModel?, String>((ref, id) {
  return ref.watch(matchRepositoryProvider).matchStreamById(id);
});