import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/resultado_model.dart';

class ResultadoRepository {
  final _db = FirebaseFirestore.instance;
  final _col = 'resultados';

  Future<void> addResultado(ResultadoModel resultado) async {
    // usa doc(resultado.id) si generas id fuera; si no, puedes usar add()
    await _db.collection(_col).doc(resultado.id).set(resultado.toMap());
  }

  Future<void> updateResultado(ResultadoModel resultado) async {
    await _db.collection(_col).doc(resultado.id).update(resultado.toMap());
  }

  Future<void> deleteResultado(String docId) async {
    await _db.collection(_col).doc(docId).delete();
  }

  Stream<List<ResultadoModel>> resultadosStream() {
    return _db.collection(_col).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ResultadoModel.fromMap({...doc.data(), 'id': doc.id})).toList());
  }

  Stream<ResultadoModel?> resultadoStreamById(String id) {
    return _db.collection(_col).doc(id).snapshots().map((snapshot) {
      if (snapshot.exists) return ResultadoModel.fromMap({...snapshot.data()!, 'id': snapshot.id});
      return null;
    });
  }

  Future<List<ResultadoModel>> getResultados() async {
    final querySnapshot = await _db.collection(_col).get();
    return querySnapshot.docs.map((doc) => ResultadoModel.fromMap({...doc.data(), 'id': doc.id})).toList();
  }

  // Eliminación "flexible": intenta por docId, por campo 'id' y por combinación de partido/goles/fecha
  Future<bool> deleteResultadoFlexible({
    required String posibleId,
    String? partidoId,
    int? golesFavor,
    int? golesContra,
    DateTime? fecha,
  }) async {
    final colRef = _db.collection(_col);
    final idTrim = posibleId.trim();
    // 1) intentar como document id
    if (idTrim.isNotEmpty) {
      final docRef = colRef.doc(idTrim);
      final snap = await docRef.get();
      if (snap.exists) {
        await docRef.delete();
        return true;
      }
    }

    // 2) buscar por campo 'id' dentro de documentos
    if (idTrim.isNotEmpty) {
      final q = await colRef.where('id', isEqualTo: idTrim).get();
      if (q.docs.isNotEmpty) {
        for (final d in q.docs) await colRef.doc(d.id).delete();
        return true;
      }
    }

    // 3) buscar por partidoId + goles (y fecha si viene)
    Query query = colRef;
    if (partidoId != null && partidoId.isNotEmpty) query = query.where('partidoId', isEqualTo: partidoId);
    if (golesFavor != null) query = query.where('golesFavor', isEqualTo: golesFavor);
    if (golesContra != null) query = query.where('golesContra', isEqualTo: golesContra);

    final q2 = await query.get();
    if (q2.docs.isNotEmpty) {
      List<QueryDocumentSnapshot> candidates = q2.docs;
      if (fecha != null) {
        candidates = candidates.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final f = data['fecha'];
          DateTime? docDate;
          if (f is Timestamp) docDate = f.toDate();
          else if (f is String) docDate = DateTime.tryParse(f);
          else if (f is DateTime) docDate = f;
          if (docDate == null) return false;
          return docDate.year == fecha.year && docDate.month == fecha.month && docDate.day == fecha.day;
        }).toList();
      }
      for (final d in (candidates.isNotEmpty ? candidates : q2.docs)) {
        await colRef.doc(d.id).delete();
      }
      return true;
    }

    return false; // no encontrado
  }
}