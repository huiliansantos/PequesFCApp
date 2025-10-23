import 'package:cloud_firestore/cloud_firestore.dart';

class TorneoModel {
  final String id;
  final String nombre;
  final String lugar;
  final DateTime fecha;

  TorneoModel({
    required this.id,
    required this.nombre,
    required this.lugar,
    required this.fecha,
  });

  factory TorneoModel.fromFirestore(Map<String, dynamic> map, String docId) {
    return TorneoModel(
      id: docId,
      nombre: map['nombre'] ?? '',
      lugar: map['lugar'] ?? '',
      fecha: (map['fecha'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'lugar': lugar,
      'fecha': Timestamp.fromDate(fecha),
    };
  }
}