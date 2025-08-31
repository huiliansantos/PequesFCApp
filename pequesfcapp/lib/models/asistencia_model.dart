import 'package:cloud_firestore/cloud_firestore.dart';

class AsistenciaModel {
  final String id;
  final String jugadorId;
  final String entrenamientoId;
  final DateTime fecha;
  final bool presente;
  final String? observacion;

  AsistenciaModel({
    required this.id,
    required this.jugadorId,
    required this.entrenamientoId,
    required this.fecha,
    required this.presente,
    this.observacion,
  });

  factory AsistenciaModel.fromMap(Map<String, dynamic> map) => AsistenciaModel(
    id: map['id'],
    jugadorId: map['jugadorId'],
    entrenamientoId: map['entrenamientoId'],
    fecha: (map['fecha'] as Timestamp).toDate(),
    presente: map['presente'],
    observacion: map['observacion'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'jugadorId': jugadorId,
    'entrenamientoId': entrenamientoId,
    'fecha': fecha,
    'presente': presente,
    'observacion': observacion,
  };
}