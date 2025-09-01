import 'package:cloud_firestore/cloud_firestore.dart';

class AsistenciaModel {
  final String id;
  final String jugadorId;
  final String entrenamientoId;
  final String categoriaEquipoId; // <-- Agregado
  final DateTime fecha;
  final bool presente;
  final String? observacion;
  final bool permiso;
  final DateTime horaRegistro;

  AsistenciaModel({
    required this.id,
    required this.jugadorId,
    required this.entrenamientoId,
    required this.categoriaEquipoId, // <-- Agregado
    required this.fecha,
    required this.presente,
    this.observacion,
    required this.permiso,
    required this.horaRegistro,
  });

  factory AsistenciaModel.fromMap(Map<String, dynamic> map) => AsistenciaModel(
    id: map['id'] ?? '',
    jugadorId: map['jugadorId'] ?? '',
    entrenamientoId: map['entrenamientoId'] ?? '',
    categoriaEquipoId: map['categoriaEquipoId'] ?? '', // <-- Agregado
    fecha: map['fecha'] != null && map['fecha'] is Timestamp
        ? (map['fecha'] as Timestamp).toDate()
        : DateTime.now(),
    presente: map['presente'] ?? false,
    observacion: map['observacion'],
    permiso: map['permiso'] ?? false,
    horaRegistro: map['horaRegistro'] != null && map['horaRegistro'] is Timestamp
        ? (map['horaRegistro'] as Timestamp).toDate()
        : DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'jugadorId': jugadorId,
    'entrenamientoId': entrenamientoId,
    'categoriaEquipoId': categoriaEquipoId, // <-- Agregado
    'fecha': Timestamp.fromDate(fecha), // <-- Guarda como Timestamp
    'presente': presente,
    'observacion': observacion,
    'permiso': permiso,
    'horaRegistro': Timestamp.fromDate(horaRegistro), // <-- Guarda como Timestamp
  };
}
