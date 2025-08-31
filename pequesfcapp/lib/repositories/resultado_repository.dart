import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/resultado_model.dart';

class ResultadoRepository {
  final _db = FirebaseFirestore.instance;

  Future<void> addResultado(ResultadoModel resultado) async {
    await _db.collection('resultados').doc(resultado.id).set(resultado.toMap());
  }
  //implementar actualización y eliminación
  Future<void> updateResultado(ResultadoModel resultado) async {
    await _db.collection('resultados').doc(resultado.id).update(resultado.toMap());
  }

  Future<void> deleteResultado(String id) async {
    await _db.collection('resultados').doc(id).delete();
  }

  Stream<List<ResultadoModel>> resultadosStream() {
    return _db.collection('resultados').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => ResultadoModel.fromMap(doc.data())).toList()
    );
  }

  Stream<ResultadoModel?> resultadoStreamById(String id) {
    return _db.collection('resultados').doc(id).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return ResultadoModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }
}