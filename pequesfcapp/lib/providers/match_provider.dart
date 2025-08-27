import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';
import '../repositories/match_repository.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) => MatchRepository());

final matchesProvider = StreamProvider<List<MatchModel>>((ref) {
  return ref.watch(matchRepositoryProvider).getMatchesStream();
});