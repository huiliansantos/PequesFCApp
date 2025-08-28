import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/guardian_model.dart';

class GuardianRepository {
  final _db = FirebaseFirestore.instance;

  // Stream de todos los guardianes (actualización en tiempo real)
  Stream<List<GuardianModel>> guardiansStream() {
    return _db.collection('guardianes').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => GuardianModel.fromMap(doc.data())).toList()
    );
  }

  // Obtener un guardian por ID
  Future<GuardianModel?> getGuardianById(String id) async {
    final doc = await _db.collection('guardianes').doc(id).get();
    if (!doc.exists) return null;
    return GuardianModel.fromMap(doc.data()!);
  }

  // Obtener un guardian por email
  Future<GuardianModel?> getGuardianByEmail(String email) async {
    final query = await _db
        .collection('guardianes')
        .where('usuario', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return GuardianModel.fromMap(query.docs.first.data());
  }

  // Agregar un nuevo guardian
  Future<void> addGuardian(GuardianModel guardian) async {
    final batch = _db.batch();

    // 1. Agregar el campo rol al guardian
    final guardianData = guardian.toMap();
    guardianData['rol'] = 'apoderado';

    final guardianRef = _db.collection('guardianes').doc(guardian.id);
    batch.set(guardianRef, guardianData);

    // 2. Actualizar los jugadores seleccionados con el guardianId
    for (final jugadorId in guardian.jugadoresIds) {
      final jugadorRef = _db.collection('jugadores').doc(jugadorId);
      batch.update(jugadorRef, {'guardianId': guardian.id});
    }

    await batch.commit();
  }

  // Editar un guardian existente
  Future<void> updateGuardian(GuardianModel guardian) async {
    await _db.collection('guardianes').doc(guardian.id).update(guardian.toMap());
  }

  // Eliminar un guardian
  Future<void> deleteGuardian(String id) async {
    await _db.collection('guardianes').doc(id).delete();
  }

  // Autenticar a un guardian
  Future<GuardianModel?> autenticarGuardian(String usuario, String contrasena) async {
    final query = await _db
        .collection('guardianes')
        .where('usuario', isEqualTo: usuario)
        .where('contrasena', isEqualTo: contrasena)
        .where('rol', isEqualTo: 'apoderado')
        .get();

    if (query.docs.isEmpty) return null;
    return GuardianModel.fromMap(query.docs.first.data());
  }

  // Stream de un guardian por ID (actualización en tiempo real)
  Stream<GuardianModel?> guardianStreamById(String id) {
    return _db.collection('guardianes').doc(id).snapshots().map(
      (doc) => doc.exists ? GuardianModel.fromMap(doc.data()!) : null,
    );
  }
}