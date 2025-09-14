import 'package:cloud_firestore/cloud_firestore.dart';

class ProfesorModel {
  final String id;
  final String nombre;
  final String apellido;
  final String ci;
  final DateTime fechaNacimiento;
  final String celular;
  final String usuario;
  final String contrasena;
  final String categoriaEquipoId;
  final String rol;

  ProfesorModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.ci,
    required this.fechaNacimiento,
    required this.celular,
    required this.usuario,
    required this.contrasena,
    required this.categoriaEquipoId,
    this.rol = 'profesor',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'apellido': apellido,
    'ci': ci,
    'fechaNacimiento': fechaNacimiento.toIso8601String(),
    'celular': celular,
    'usuario': usuario,
    'contrasena': contrasena,
    'categoriaEquipoId': categoriaEquipoId,
    'rol': rol,
  };
  factory ProfesorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfesorModel(
      id: (data['id'] ?? doc.id).toString(),
      nombre: data['nombre'] ?? '',
      apellido: data['apellido'] ?? '',
      ci: data['ci'] ?? '',
      fechaNacimiento: data['fechaNacimiento'] is String
          ? DateTime.parse(data['fechaNacimiento'])
          : DateTime.now(),
      celular: data['celular'] ?? '',
      usuario: data['usuario'] ?? '',
      contrasena: data['contrasena'] ?? '',
      categoriaEquipoId: data['categoriaEquipoId'] ?? '',
      rol: data['rol'] ?? 'profesor',
    );
  }
  
  factory ProfesorModel.fromMap(Map<String, dynamic> map) => ProfesorModel(
    id: map['id'] ?? '',
    nombre: map['nombre'] ?? '',
    apellido: map['apellido'] ?? '',
    ci: map['ci'] ?? '',
    fechaNacimiento: map['fechaNacimiento'] is String
        ? DateTime.parse(map['fechaNacimiento'])
        : DateTime.now(),
    celular: map['celular'] ?? '',
    usuario: map['usuario'] ?? '',
    contrasena: map['contrasena'] ?? '',
    categoriaEquipoId: map['categoriaEquipoId'] ?? '',
    rol: map['rol'] ?? 'profesor',
  );
  
}