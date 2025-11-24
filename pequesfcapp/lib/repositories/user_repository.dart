import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserRepository {
  final _db = FirebaseFirestore.instance;

  /// ✅ OBTENER ROL DEL USUARIO
  Future<String?> getUserRole(String uid) async {
    try {
      debugPrint('🔍 Buscando usuario con UID: $uid');

      // ✅ 1. BUSCAR EN PROFESORES
      debugPrint('👨‍🏫 Buscando en profesores...');
      var doc = await _db.collection('profesores').doc(uid).get();
      if (doc.exists) {
        debugPrint('✅ Encontrado en profesores');
        return 'profesor';
      }

      // ✅ 2. BUSCAR EN GUARDIANES
      debugPrint('👨‍👩‍👧 Buscando en guardianes...');
      doc = await _db.collection('guardianes').doc(uid).get();
      if (doc.exists) {
        debugPrint('✅ Encontrado en guardianes');
        return 'apoderado';
      }

      // ✅ 3. BUSCAR EN ADMINS
      debugPrint('👤 Buscando en admins...');
      doc = await _db.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        debugPrint('✅ Encontrado en admins');
        return 'admin';
      }

      // ✅ 4. BUSCAR POR FIREBASEID EN GUARDIANES (compatibilidad)
      debugPrint('🔄 Buscando por firebaseUid en guardianes...');
      final guardianes = await _db
          .collection('guardianes')
          .where('firebaseUid', isEqualTo: uid)
          .limit(1)
          .get();

      if (guardianes.docs.isNotEmpty) {
        debugPrint('✅ Encontrado en guardianes por firebaseUid');
        return 'apoderado';
      }

      // ✅ 5. BUSCAR POR FIREBASEID EN PROFESORES (compatibilidad)
      debugPrint('🔄 Buscando por firebaseUid en profesores...');
      final profesores = await _db
          .collection('profesores')
          .where('firebaseUid', isEqualTo: uid)
          .limit(1)
          .get();

      if (profesores.docs.isNotEmpty) {
        debugPrint('✅ Encontrado en profesores por firebaseUid');
        return 'profesor';
      }

      debugPrint('❌ Usuario no encontrado');
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo rol: $e');
      return null;
    }
  }

  /// ✅ OBTENER DATOS DEL USUARIO
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      debugPrint('🔍 Obteniendo datos del usuario: $uid');

      // ✅ 1. BUSCAR EN PROFESORES
      var doc = await _db.collection('profesores').doc(uid).get();
      if (doc.exists) {
        debugPrint('✅ Datos encontrados en profesores');
        return doc.data();
      }

      // ✅ 2. BUSCAR EN GUARDIANES
      doc = await _db.collection('guardianes').doc(uid).get();
      if (doc.exists) {
        debugPrint('✅ Datos encontrados en guardianes');
        return doc.data();
      }

      // ✅ 3. BUSCAR EN ADMINS
      doc = await _db.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        debugPrint('✅ Datos encontrados en admins');
        return doc.data();
      }

      debugPrint('❌ Datos del usuario no encontrados');
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo datos del usuario: $e');
      return null;
    }
  }

  /// ✅ VERIFICAR SI EL USUARIO ES ADMIN
  Future<bool> isAdmin(String uid) async {
    try {
      debugPrint('🔐 Verificando si es admin: $uid');
      final doc = await _db.collection('usuarios').doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ Error verificando admin: $e');
      return false;
    }
  }

  /// ✅ OBTENER USUARIO POR EMAIL
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      debugPrint('🔍 Buscando usuario con email: $email');

      // ✅ 1. BUSCAR EN PROFESORES
      var query = await _db
          .collection('profesores')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        debugPrint('✅ Encontrado en profesores');
        return {
          'id': query.docs.first.id,
          'data': query.docs.first.data(),
          'rol': 'profesor',
        };
      }

      // ✅ 2. BUSCAR EN GUARDIANES
      query = await _db
          .collection('guardianes')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        debugPrint('✅ Encontrado en guardianes');
        return {
          'id': query.docs.first.id,
          'data': query.docs.first.data(),
          'rol': 'apoderado',
        };
      }

      // ✅ 3. BUSCAR EN ADMINS
      query = await _db
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        debugPrint('✅ Encontrado en admins');
        return {
          'id': query.docs.first.id,
          'data': query.docs.first.data(),
          'rol': 'admin',
        };
      }

      debugPrint('❌ Usuario no encontrado');
      return null;
    } catch (e) {
      debugPrint('❌ Error buscando usuario: $e');
      return null;
    }
  }
}