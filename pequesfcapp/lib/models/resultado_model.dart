class ResultadoModel {
  final String id;
  final String partidoId;
  final DateTime? fecha;
  final int golesFavor;
  final int golesContra;
  final String observaciones;
  final String? docId; // <-- ID de documento Firestore (solo para la app)

  ResultadoModel({
    required this.id,
    required this.partidoId,
    required this.fecha,
    required this.golesFavor,
    required this.golesContra,
    required this.observaciones,
    this.docId, // <-- opcional
  });

  factory ResultadoModel.fromFirestore(
      Map<String, dynamic> map, String docId) {
    return ResultadoModel(
      id: map['id'] as String,
      partidoId: map['partidoId'] as String,
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha'] as String) : null,
      golesFavor: map['golesFavor'] as int,
      golesContra: map['golesContra'] as int,
      observaciones: map['observaciones'] as String,
      docId: docId,
    );
  }

  factory ResultadoModel.fromMap(Map<String, dynamic> map) {
    return ResultadoModel(
      id: map['id'] as String,
      partidoId: map['partidoId'] as String,
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha'] as String) : null,
      golesFavor: map['golesFavor'] as int,
      golesContra: map['golesContra'] as int,
      observaciones: map['observaciones'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partidoId': partidoId,
      'fecha': fecha?.toIso8601String(),
      'golesFavor': golesFavor,
      'golesContra': golesContra,
      'observaciones': observaciones,
      // docId no se guarda en Firestore
    };
  }
}