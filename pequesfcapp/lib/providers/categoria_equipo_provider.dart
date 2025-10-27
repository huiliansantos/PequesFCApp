import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/categoria_equipo_repository.dart';
import '../models/categoria_equipo_model.dart';

/// Provider para el repositorio de categorías-equipos
final categoriaEquipoRepositoryProvider = Provider<CategoriaEquipoRepository>((ref) => CategoriaEquipoRepository());

/// Provider para escuchar cambios en tiempo real de categorías-equipos
final categoriasEquiposProvider = StreamProvider<List<CategoriaEquipoModel>>((ref) {
  return ref.watch(categoriaEquipoRepositoryProvider).categoriasEquiposStream();
});

/// Provider para el controlador de operaciones
final categoriaEquipoControllerProvider = Provider((ref) {
  return CategoriaEquipoController(ref);
});

class CategoriaEquipoController {
  final Ref _ref;
  
  CategoriaEquipoController(this._ref);

  /// Verifica si ya existe una categoría-equipo con los mismos datos
  Future<bool> existeDuplicado(CategoriaEquipoModel categoriaEquipo) async {
    try {
      final repository = _ref.read(categoriaEquipoRepositoryProvider);
      return await repository.existeCategoriaEquipo(
        categoriaEquipo.categoria,
        categoriaEquipo.equipo,
      );
    } catch (e) {
      throw 'Error al verificar duplicados: $e';
    }
  }

  Future<void> agregarCategoriaEquipo(CategoriaEquipoModel categoriaEquipo) async {
    try {
      final repository = _ref.read(categoriaEquipoRepositoryProvider);
      
      // Verificar duplicados antes de agregar
      if (await existeDuplicado(categoriaEquipo)) {
        throw 'Ya existe una categoría-equipo con estos datos';
      }
      
      await repository.agregarCategoriaEquipo(categoriaEquipo);
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw 'Error al agregar la categoría-equipo: $e';
    }
  }

  Future<void> actualizarCategoriaEquipo(CategoriaEquipoModel categoriaEquipo) async {
    try {
      final repository = _ref.read(categoriaEquipoRepositoryProvider);
      
      // Obtener categoría actual para comparar cambios
      final actual = await repository.getCategoriaEquipo(categoriaEquipo.id);
      if (actual == null) {
        throw 'No se encontró la categoría-equipo a actualizar';
      }
      
      // Si cambió categoria o equipo, verificar duplicados
      if (actual.categoria != categoriaEquipo.categoria || 
          actual.equipo != categoriaEquipo.equipo) {
        if (await existeDuplicado(categoriaEquipo)) {
          throw 'Ya existe otra categoría-equipo con estos datos';
        }
      }
      
      await repository.actualizarCategoriaEquipo(categoriaEquipo);
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw 'Error al actualizar la categoría-equipo: $e';
    }
  }

  Future<void> eliminarCategoriaEquipo(String id) async {
    try {
      debugPrint('🔍 Iniciando eliminación de categoría-equipo');
      debugPrint('📌 ID a eliminar: $id');
      
      final repository = _ref.read(categoriaEquipoRepositoryProvider);
      
      // Verificar si existe antes de eliminar
      final existe = await repository.getCategoriaEquipo(id);
      if (existe == null) {
        debugPrint('❌ No se encontró la categoría-equipo con ID: $id');
        throw 'No se encontró la categoría-equipo';
      }
      
      debugPrint('✅ Categoría encontrada: ${existe.categoria} - ${existe.equipo}');
      
      // Intentar eliminar
      await repository.eliminarCategoriaEquipo(id);
      debugPrint('🗑️ Categoría-equipo eliminada correctamente');
      
    } catch (e, stack) {
      debugPrint('❌ Error al eliminar categoría-equipo:');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      throw 'Error al eliminar la categoría-equipo: $e';
    }
  }
}
