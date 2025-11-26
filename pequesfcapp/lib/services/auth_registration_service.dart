import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthRegistrationService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  /// ✅ Registra un usuario en Firebase Auth y guarda credenciales locales
  static Future<void> registrarEnAuth({
    required String email,
    required String usuario,
    required String contrasena,
    required String tipo, // 'profesor' o 'apoderado'
    required String docId,
    String? adminEmail,      // ✅ Nuevo parámetro
    String? adminPassword,   // ✅ Nuevo parámetro
  }) async {
    try {
      debugPrint('🔐 Iniciando registro en Auth: $email');

      // Guardar credenciales del admin antes de crear el usuario
      final prevUser = _auth.currentUser;

      // ✅ Crear usuario en Firebase Auth (esto cambia la sesión)
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: contrasena,
      );

      debugPrint('✅ Usuario creado en Auth: ${userCredential.user?.uid}');

      await _firestore
          .collection(tipo == 'profesor' ? 'profesores' : 'guardianes')
          .doc(docId)
          .update({
        'firebaseUid': userCredential.user?.uid,
        'email': email,
        'cuentaAuth': true,
      });

      debugPrint('✅ Credenciales guardadas en Firestore');

      // ✅ Volver a loguear al admin automáticamente
      if (adminEmail != null && adminPassword != null) {
        await _auth.signOut();
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        debugPrint('✅ Sesión de admin restaurada');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Error Firebase Auth: ${e.code} - ${e.message}');
      throw Exception('Error al registrar en Auth: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error general: $e');
      throw Exception('Error al registrar: $e');
    }
  }

  /// ✅ Actualiza la contraseña en Auth (cuando cambien desde el app)
  static Future<void> actualizarContrasenaEnAuth(
    String contrasenaActual,
    String contrasenanueva,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      // Reautenticar primero
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: contrasenaActual,
      );

      await user.reauthenticateWithCredential(credential);
      debugPrint('✅ Reautenticación exitosa');

      // Actualizar contraseña
      await user.updatePassword(contrasenanueva);
      debugPrint('✅ Contraseña actualizada en Auth');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Error Firebase Auth: ${e.code} - ${e.message}');
      throw Exception('Error: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error: $e');
      throw Exception('Error: $e');
    }
  }
}