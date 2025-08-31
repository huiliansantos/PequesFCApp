import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/categoria_equipo_model.dart';

class CategoriaEquipoRepository {
  final _db = FirebaseFirestore.instance;

  Future<void> addCategoriaEquipo(CategoriaEquipoModel model) async {
    await _db.collection('categoria_equipo').doc(model.id).set(model.toMap());
  }

  Stream<List<CategoriaEquipoModel>> categoriasEquiposStream() {
    return _db.collection('categoria_equipo').snapshots().map((snap) =>
      snap.docs.map((doc) => CategoriaEquipoModel.fromMap(doc.data())).toList()
    );
  }
}