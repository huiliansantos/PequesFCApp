import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/categoria_equipo_repository.dart';
import '../models/categoria_equipo_model.dart';

final categoriaEquipoRepositoryProvider = Provider<CategoriaEquipoRepository>((ref) => CategoriaEquipoRepository());

final categoriasEquiposProvider = StreamProvider<List<CategoriaEquipoModel>>((ref) {
  return ref.watch(categoriaEquipoRepositoryProvider).categoriasEquiposStream();
});