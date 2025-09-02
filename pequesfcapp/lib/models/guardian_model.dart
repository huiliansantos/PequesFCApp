class GuardianModel {
  final String id;
  final String nombreCompleto;
  final String ci;
  final String celular;
  final String direccion;
  final String usuario;
  final String contrasena;
  final String rol;
  final List<String> jugadoresIds; // IDs de jugadores asignados

  GuardianModel({
    required this.id,
    required this.nombreCompleto,
    required this.ci,
    required this.celular,
    required this.direccion,
    required this.usuario,
    required this.contrasena,
    required this.jugadoresIds,
    this.rol = 'apoderado',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombreCompleto': nombreCompleto,
    'ci': ci,
    'celular': celular,
    'direccion': direccion,
    'usuario': usuario,
    'contrasena': contrasena,
    'jugadoresIds': jugadoresIds,
    'rol': rol,
  };

  factory GuardianModel.fromMap(Map<String, dynamic> map) => GuardianModel(
    id: map['id'] ?? '',
    nombreCompleto: map['nombreCompleto'] ?? '',
    ci: map['ci'] ?? '',
    celular: map['celular'] ?? '',
    direccion: map['direccion'] ?? '',
    usuario: map['usuario'] ?? '',
    contrasena: map['contrasena'] ?? '',
    jugadoresIds: List<String>.from(map['jugadoresIds'] ?? []),
    rol: map['rol'] ?? 'apoderado',
  );
}