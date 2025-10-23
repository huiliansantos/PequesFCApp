import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/torneo_model.dart';

final torneosProvider = StreamProvider<List<TorneoModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('torneos')
      .orderBy('fecha', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TorneoModel.fromFirestore(doc.data(), doc.id))
          .toList());
});