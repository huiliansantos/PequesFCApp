import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';

class MatchRepository {
  final _db = FirebaseFirestore.instance;

  Future<void> addMatch(MatchModel match) async {
    await _db.collection('partidos').doc(match.id).set(match.toMap());
  }

  Stream<List<MatchModel>> getMatchesStream() {
    return _db.collection('partidos').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => MatchModel.fromMap(doc.data())).toList()
    );
  }
  Future<void> updateMatch(MatchModel match) async {
    await _db.collection('partidos').doc(match.id).set(match.toMap());
  }
  Future<void> deleteMatch(String id) async {
    await _db.collection('partidos').doc(id).delete();
  }
  Stream<MatchModel?> matchStreamById(String id) {
    return _db.collection('partidos').doc(id).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return MatchModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }
  Stream<List<MatchModel>> matchesStream() {
    return _db.collection('partidos').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => MatchModel.fromMap(doc.data())).toList()
    );
  }
}