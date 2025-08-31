//asistencia_repository
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/asistencia_model.dart';

class AsistenciaRepository {
  final _db = FirebaseFirestore.instance;

  Future<void> registrarAsistencia(AsistenciaModel asistencia) async {
    await _db.collection('asistencias').doc(asistencia.id).set(asistencia.toMap());
  }

  Stream<List<AsistenciaModel>> asistenciasPorJugador(String jugadorId) {
    return _db.collection('asistencias')
      .where('jugadorId', isEqualTo: jugadorId)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => AsistenciaModel.fromMap(doc.data())).toList());
  }

  Stream<List<AsistenciaModel>> asistenciasPorEntrenamiento(String entrenamientoId) {
    return _db.collection('asistencias')
      .where('entrenamientoId', isEqualTo: entrenamientoId)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => AsistenciaModel.fromMap(doc.data())).toList());
  }
}
