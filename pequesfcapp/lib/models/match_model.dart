class MatchModel {
  final String id;
  final String equipoRival;
  final String cancha;
  final DateTime fecha;
  final String hora;
  final String torneo;
  final String categoria;
  final String equipoId;

  MatchModel({
    required this.id,
    required this.equipoRival,
    required this.cancha,
    required this.fecha,
    required this.hora,
    required this.torneo,
    required this.categoria,
    required this.equipoId,
  });

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      id: map['id'] as String,
      equipoRival: map['equipoRival'] as String,
      cancha: map['cancha'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      hora: map['hora'] as String,
      torneo: map['torneo'] as String,
      categoria: map['categoria'] as String,
      equipoId: map['equipoId'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipoRival': equipoRival,
      'cancha': cancha,
      'fecha': fecha.toIso8601String(),
      'hora': hora,
      'torneo': torneo,
      'categoria': categoria,
      'equipoId': equipoId,
    };
  }
}