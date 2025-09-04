import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id;
  final String equipoRival;
  final String cancha;
  final DateTime fecha;
  final String hora;
  final String torneo;
  final String categoriaEquipoId;


  MatchModel({
    required this.id,
    required this.equipoRival,
    required this.cancha,
    required this.fecha,
    required this.hora,
    required this.torneo,
    required this.categoriaEquipoId,

  });

  factory MatchModel.fromMap(Map<String, dynamic> map) => MatchModel(
    id: map['id']?.toString() ?? '',
    equipoRival: map['equipoRival']?.toString() ?? '',
    cancha: map['cancha']?.toString() ?? '',
    fecha: map['fecha'] is Timestamp
        ? (map['fecha'] as Timestamp).toDate()
        : (map['fecha'] is String
            ? DateTime.tryParse(map['fecha'] as String) ?? DateTime.now()
            : DateTime.now()),
    hora: map['hora']?.toString() ?? '',
    torneo: map['torneo']?.toString() ?? '',
    categoriaEquipoId: map['categoriaEquipoId']?.toString() ?? '',
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipoRival': equipoRival,
      'cancha': cancha,
      'fecha': fecha.toIso8601String(),
      'hora': hora,
      'torneo': torneo,
      'categoriaEquipoId': categoriaEquipoId,
    };
  }
}