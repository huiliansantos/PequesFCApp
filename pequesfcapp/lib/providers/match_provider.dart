import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/match_repository.dart';
import '../models/match_model.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) => MatchRepository());

final matchesProvider = StreamProvider<List<MatchModel>>((ref) {
  return ref.watch(matchRepositoryProvider).matchesStream();
});

final matchByIdProvider = StreamProvider.family<MatchModel?, String>((ref, id) {
  return ref.watch(matchRepositoryProvider).matchStreamById(id);
});

// Ejemplo de provider
final partidosPorCategoriaEquipoProvider = StreamProvider.family<List<MatchModel>, String>((ref, categoriaEquipoId) {
  return FirebaseFirestore.instance
    .collection('partidos')
    .where('categoriaEquipoId', isEqualTo: categoriaEquipoId)
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => MatchModel.fromMap(doc.data() as Map<String, dynamic>)).toList());
});