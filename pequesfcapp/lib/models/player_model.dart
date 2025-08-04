// Modelo PlayerModel para representar un jugador con:
// id, nombres, apellido, fechaDeNacimiento, lugarDeNacimiento, genero, foto (opcional), guardianId (opcional)

class PlayerModel {
  final String id;
  final String nombres;
  final String apellido;
  final DateTime fechaDeNacimiento;
  final String lugarDeNacimiento;
  final String genero;
  final String? foto;
  final String? guardianId;
  final String? estadoPago;
  final String ci;

  PlayerModel({
    required this.id,
    required this.nombres,
    required this.apellido,
    required this.fechaDeNacimiento,
    required this.lugarDeNacimiento,
    required this.genero,
    this.foto,
    this.guardianId,
    this.estadoPago,
    required this.ci,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      id: map['id'],
      nombres: map['nombres'],
      apellido: map['apellido'],
      fechaDeNacimiento: DateTime.parse(map['fechaDeNacimiento']),
      lugarDeNacimiento: map['lugarDeNacimiento'],
      genero: map['genero'],
      foto: map['foto'],
      guardianId: map['guardianId'],
      estadoPago: map['estadoPago'],
      ci: map['ci'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombres': nombres,
      'apellido': apellido,
      'fechaDeNacimiento': fechaDeNacimiento.toIso8601String(),
      'lugarDeNacimiento': lugarDeNacimiento,
      'genero': genero,
      'foto': foto,
      'guardianId': guardianId,
      'estadoPago': estadoPago,
      'ci': ci,
    };
  }
}
