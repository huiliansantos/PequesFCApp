import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final _db = FirebaseFirestore.instance;

  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    print('Buscando usuario con UID: $uid');
    print('Documento existe: ${doc.exists}');
    if (doc.exists) {
      print('Datos: ${doc.data()}');
      return doc.data()?['rol'] as String?;
    } else {
      print('No existe el documento para ese UID');
      return null;
    }
  }
}