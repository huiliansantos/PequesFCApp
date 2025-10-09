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
  final String? estadoPago;
  final String categoriaEquipoId;

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
    this.estadoPago,
    required this.categoriaEquipoId,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    // Soporta fecha como String o Timestamp (Firestore)
    DateTime fecha;
    if (map['fechaDeNacimiento'] is String) {
      fecha = DateTime.tryParse(map['fechaDeNacimiento'] as String) ?? DateTime.now();
    } else if (map['fechaDeNacimiento'] != null &&
        map['fechaDeNacimiento'].toString().contains('Timestamp')) {
      fecha = (map['fechaDeNacimiento'] as dynamic).toDate();
    } else {
      fecha = DateTime.now();
    }

    return PlayerModel(
      id: map['id'] as String? ?? '',
      nombres: map['nombres'] as String? ?? '',
      apellido: map['apellido'] as String? ?? '',
      fechaDeNacimiento: fecha,
      genero: map['genero'] as String? ?? '',
      foto: map['foto'] as String? ?? '',
      ci: map['ci'] as String? ?? '',
      nacionalidad: map['nacionalidad'] as String? ?? '',
      departamentoBolivia: map['departamentoBolivia'] as String?,
      guardianId: map['guardianId'] as String?,
      estadoPago: map['estadoPago'] as String?,
      categoriaEquipoId: map['categoriaEquipoId'] as String? ?? '',
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
      'estadoPago': estadoPago,
      'categoriaEquipoId': categoriaEquipoId,
    };
  }

  PlayerModel copyWith({
    String? id,
    String? nombres,
    String? apellido,
    DateTime? fechaDeNacimiento,
    String? genero,
    String? foto,
    String? ci,
    String? nacionalidad,
    String? departamentoBolivia,
    String? guardianId,
    String? estadoPago,
    String? categoriaEquipoId,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      nombres: nombres ?? this.nombres,
      apellido: apellido ?? this.apellido,
      fechaDeNacimiento: fechaDeNacimiento ?? this.fechaDeNacimiento,
      genero: genero ?? this.genero,
      foto: foto ?? this.foto,
      ci: ci ?? this.ci,
      nacionalidad: nacionalidad ?? this.nacionalidad,
      departamentoBolivia: departamentoBolivia ?? this.departamentoBolivia,
      guardianId: guardianId ?? this.guardianId,
      estadoPago: estadoPago ?? this.estadoPago,
      categoriaEquipoId: categoriaEquipoId ?? this.categoriaEquipoId,
    );
  }
}
