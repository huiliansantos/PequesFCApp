class ResultadoModel {
  final String id;
  final String partidoId;
  final int golesFavor;
  final int golesContra;
  final String observaciones;

  ResultadoModel({
    required this.id,
    required this.partidoId,
    required this.golesFavor,
    required this.golesContra,
    required this.observaciones,
  });

  factory ResultadoModel.fromMap(Map<String, dynamic> map) {
    return ResultadoModel(
      id: map['id'] as String,
      partidoId: map['partidoId'] as String,
      golesFavor: map['golesFavor'] as int,
      golesContra: map['golesContra'] as int,
      observaciones: map['observaciones'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partidoId': partidoId,
      'golesFavor': golesFavor,
      'golesContra': golesContra,
      'observaciones': observaciones,
    };
  }
}