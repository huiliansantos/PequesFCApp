class UsuarioModel {
  final String id;
  final String email;
  final String rol; // <-- este campo

  UsuarioModel({required this.id, required this.email, required this.rol});
  // ...fromMap y toMap...
  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'],
      email: map['email'],
      rol: map['rol'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'rol': rol,
    };
  }
}