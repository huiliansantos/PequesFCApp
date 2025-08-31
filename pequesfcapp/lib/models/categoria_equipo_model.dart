class CategoriaEquipoModel {
  final String id;
  final String categoria;
  final String equipo;

  CategoriaEquipoModel({
    required this.id,
    required this.categoria,
    required this.equipo,
  });

  factory CategoriaEquipoModel.fromMap(Map<String, dynamic> map) => CategoriaEquipoModel(
    id: map['id'],
    categoria: map['categoria'],
    equipo: map['equipo'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'categoria': categoria,
    'equipo': equipo,
  };
}