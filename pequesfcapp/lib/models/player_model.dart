// Modelo PlayerModel para representar un jugador con:
// id, nombres, apellido, fechaDeNacimiento, lugarDeNacimiento, genero, foto (opcional), guardianId (opcional)

class PlayerModel {
  final String id;
  final String nombres;
  final String apellido;
  final DateTime fechaDeNacimiento;
  final String genero;
  final String foto;
  final String ci;
  final String? guardianId;
  final String nacionalidad;
  final String? departamentoBolivia;
  final String? estadoPago; // <-- NUEVO

  PlayerModel({
    required this.id,
    required this.nombres,
    required this.apellido,
    required this.fechaDeNacimiento,
    required this.genero,
    required this.foto,
    required this.ci,
    required this.nacionalidad,
    this.departamentoBolivia,
    this.guardianId,
    this.estadoPago, // <-- NUEVO
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      id: map['id'] as String,
      nombres: map['nombres'] as String,
      apellido: map['apellido'] as String,
      fechaDeNacimiento: DateTime.parse(map['fechaDeNacimiento'] as String),
      genero: map['genero'] as String,
      foto: map['foto'] as String,
      ci: map['ci'] as String,
      nacionalidad: map['nacionalidad'] as String,
      departamentoBolivia: map['departamentoBolivia'] as String?,
      guardianId: map['guardianId'] as String?,
      estadoPago: map['estadoPago'] as String?, // <-- NUEVO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombres': nombres,
      'apellido': apellido,
      'fechaDeNacimiento': fechaDeNacimiento.toIso8601String(),
      'genero': genero,
      'foto': foto,
      'ci': ci,
      'nacionalidad': nacionalidad,
      'departamentoBolivia': departamentoBolivia,
      'guardianId': guardianId,
      'estadoPago': estadoPago, // <-- NUEVO
    };
  }
}
