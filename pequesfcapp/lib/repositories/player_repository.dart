import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';

class PlayerRepository {
  final CollectionReference jugadoresCollection =
      FirebaseFirestore.instance.collection('jugadores');

  // Agregar un jugador
  Future<void> addPlayer(PlayerModel player) async {
    await jugadoresCollection.doc(player.id).set(player.toMap());
  }

  // Obtener todos los jugadores
  Future<List<PlayerModel>> getPlayers() async {
    final snapshot = await jugadoresCollection.get();
    return snapshot.docs
        .map((doc) => PlayerModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Actualizar un jugador
  Future<void> updatePlayer(PlayerModel player) async {
    await jugadoresCollection.doc(player.id).set(player.toMap());
  }

  // Eliminar un jugador
  Future<void> deletePlayer(String id) async {
    await jugadoresCollection.doc(id).delete();
  }

  // Obtener un solo jugador por id
  Future<PlayerModel?> getPlayerById(String id) async {
    final doc = await jugadoresCollection.doc(id).get();
    if (doc.exists) {
      return PlayerModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<bool> existeJugadorConCI(String ci) async {
    final query = await jugadoresCollection.where('ci', isEqualTo: ci).get();
    return query.docs.isNotEmpty;
  }

  Stream<List<PlayerModel>> playersStream() {
    return jugadoresCollection.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => PlayerModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }
  Stream<PlayerModel?> playerStreamById(String id) {
    return jugadoresCollection.doc(id).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return PlayerModel.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}
