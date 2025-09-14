import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profesor_model.dart';

class ProfesorRepository {
  final FirebaseFirestore _firestore;
  ProfesorRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _profesores => _firestore.collection('profesores');

  Future<List<ProfesorModel>> getProfesores() async {
    final querySnapshot = await _profesores.get();
    return querySnapshot.docs
        .map((doc) => ProfesorModel.fromFirestore(doc))
        .toList();
  }

  Future<void> addProfesor(ProfesorModel profesor) async {
    await _profesores.doc(profesor.id).set(profesor.toMap());
  }

  Future<void> updateProfesor(ProfesorModel profesor) async {
    await _profesores.doc(profesor.id).set(profesor.toMap());
  }

  Future<void> deleteProfesor(String id) async {
    await _profesores.doc(id).delete();
  }
// autentica profesor similar al que se realizo en guardian
  Future<ProfesorModel?> autenticarProfesor(String usuario, String contrasena) async {
    final query = await _profesores
        .where('usuario', isEqualTo: usuario)
        .where('contrasena', isEqualTo: contrasena)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return ProfesorModel.fromMap(query.docs.first.data() as Map<String, dynamic>);
    }
    return null;
  }
  // Obtener un profesor por ID
  Future<ProfesorModel?> getProfesorById(String id) async {
    final doc = await _profesores.doc(id).get();
    if (!doc.exists) return null;
    return ProfesorModel.fromMap(doc.data()! as Map<String, dynamic>);
    }
  // Obtener un profesor por usuario (email)
  Future<ProfesorModel?> getProfesorByUsuario(String usuario) async { 
    final query = await _profesores
        .where('usuario', isEqualTo: usuario)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return ProfesorModel.fromMap(query.docs.first.data() as Map<String, dynamic>);  

  
 
  }
 }