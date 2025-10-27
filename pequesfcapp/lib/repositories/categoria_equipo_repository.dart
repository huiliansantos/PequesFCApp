import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/categoria_equipo_model.dart';

class CategoriaEquipoRepository {
  final _db = FirebaseFirestore.instance;
  final _collection = 'categoria_equipo';

  // Create
  Future<void> agregarCategoriaEquipo(CategoriaEquipoModel model) async {
    try {
      await _db.collection(_collection).doc(model.id).set(model.toMap());
    } catch (e) {
      throw 'Error al agregar categoría-equipo: $e';
    }
  }

  // Read (Stream)
  Stream<List<CategoriaEquipoModel>> categoriasEquiposStream() {
    try {
      return _db
          .collection(_collection)
          .orderBy('categoria') // Ordenado por categoria
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => CategoriaEquipoModel.fromMap(doc.data()))
              .toList());
    } catch (e) {
      throw 'Error al obtener categorías-equipos: $e';
    }
  }

  // Read (Single)
  Future<CategoriaEquipoModel?> getCategoriaEquipo(String id) async {
    try {
      final doc = await _db.collection(_collection).doc(id).get();
      if (doc.exists) {
        return CategoriaEquipoModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw 'Error al obtener categoría-equipo: $e';
    }
  }

  // Update
  Future<void> actualizarCategoriaEquipo(CategoriaEquipoModel model) async {
    try {
      await _db.collection(_collection).doc(model.id).update(model.toMap());
    } catch (e) {
      throw 'Error al actualizar categoría-equipo: $e';
    }
  }

  // Delete
  Future<void> eliminarCategoriaEquipo(String id) async {
    try {
      final collectionRef = _db.collection(_collection);

      // 1) Intentar eliminar usando id como documentId
      final docRef = collectionRef.doc(id);
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        await docRef.delete();
        return;
      }

      // 2) Si no existe, buscar por el campo 'id' dentro de los documentos
      final query = await collectionRef.where('id', isEqualTo: id).limit(1).get();
      if (query.docs.isNotEmpty) {
        await collectionRef.doc(query.docs.first.id).delete();
        return;
      }

      // 3) Si no se encontró nada, lanzar excepción informativa
      throw 'No se encontró documento para eliminar con id: $id';
    } catch (e) {
      throw 'Error al eliminar categoría-equipo: $e';
    }
  }

  // Check if exists
  Future<bool> existeCategoriaEquipo(String categoria, String equipo) async {
    try {
      final result = await _db
          .collection(_collection)
          .where('categoria', isEqualTo: categoria)
          .where('equipo', isEqualTo: equipo)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      throw 'Error al verificar categoría-equipo: $e';
    }
  }
}