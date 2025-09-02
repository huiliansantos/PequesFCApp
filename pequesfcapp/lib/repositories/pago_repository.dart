import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pago_model.dart';

class PagoRepository {
  Stream<List<PagoModel>> pagosPorJugador(String jugadorId) {
    return FirebaseFirestore.instance
      .collection('pagos')
      .where('jugadorId', isEqualTo: jugadorId)
      .snapshots()
      .map((snapshot) =>
        snapshot.docs.map((doc) => PagoModel.fromMap(doc.data())).toList()
      );
  }

  Future<void> registrarPago(PagoModel pago) async {
    await FirebaseFirestore.instance
      .collection('pagos')
      .doc(pago.id)
      .set(pago.toMap());
  }
}