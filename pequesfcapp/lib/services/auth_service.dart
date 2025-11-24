import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/guardian_model.dart';
import '../models/profesor_model.dart';

class AuthService {
  static const String _keyTipoUsuario = 'tipo_usuario';
  static const String _keyGuardianData = 'guardian_data';
  static const String _keyProfesorData = 'profesor_data';
  
  static const String _keyUsuario = 'usuario_key';
  static const String _keyContrasena = 'contrasena_key';
  static const String _keyDocId = 'doc_id_key';
  static const String _keyRol = 'rol_key';
  static const String _keyNombre = 'nombre_key';
  static const String _keyApellido = 'apellido_key';
  static const String _keyNombreCompleto = 'nombre_completo_key';
  static const String _keyCelular = 'celular_key';
  static const String _keyCI = 'ci_key';
  static const String _keyDireccion = 'direccion_key';
  static const String _keyJugadoresIds = 'jugadores_ids_key';
  static const String _keyEmail = 'email_key';  // ✅ AGREGADO

  /// ✅ GUARDAR SESIÓN DE APODERADO
  static Future<void> guardarSesionApoderado(GuardianModel guardian) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTipoUsuario, 'apoderado');
    await prefs.setString(_keyGuardianData, jsonEncode(guardian.toMap()));
    await prefs.setString(_keyUsuario, guardian.usuario);
    await prefs.setString(_keyContrasena, guardian.contrasena);
    await prefs.setString(_keyDocId, guardian.id);
    await prefs.setString(_keyRol, 'apoderado');
    await prefs.setString(_keyNombreCompleto, guardian.nombreCompleto);
    await prefs.setString(_keyCelular, guardian.celular);
    await prefs.setString(_keyCI, guardian.ci);
    await prefs.setString(_keyDireccion, guardian.direccion);
    await prefs.setStringList(_keyJugadoresIds, guardian.jugadoresIds);
    await prefs.setString(_keyEmail, guardian.usuario);  // ✅ AGREGADO
    debugPrint('✅ Sesión apoderado guardada: ${guardian.usuario}');
  }

  /// ✅ GUARDAR SESIÓN DE PROFESOR
  static Future<void> guardarSesionProfesor(ProfesorModel profesor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTipoUsuario, 'profesor');
    await prefs.setString(_keyProfesorData, jsonEncode(profesor.toMap()));
    await prefs.setString(_keyUsuario, profesor.usuario);
    await prefs.setString(_keyContrasena, profesor.contrasena);
    await prefs.setString(_keyDocId, profesor.id);
    await prefs.setString(_keyRol, 'profesor');
    await prefs.setString(_keyNombre, profesor.nombre);
    await prefs.setString(_keyApellido, profesor.apellido);
    await prefs.setString(
        _keyNombreCompleto, '${profesor.nombre} ${profesor.apellido}');
    await prefs.setString(_keyCelular, profesor.celular);
    await prefs.setString(_keyCI, profesor.ci);
    await prefs.setString(_keyEmail, profesor.usuario);  // ✅ AGREGADO
    debugPrint('✅ Sesión profesor guardada: ${profesor.usuario}');
  }

  /// ✅ GUARDAR SESIÓN DE ADMIN
  static Future<void> guardarSesionAdmin({
    required String email,
    required String uid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTipoUsuario, 'admin');
    await prefs.setString(_keyUsuario, email);
    await prefs.setString(_keyDocId, uid);
    await prefs.setString(_keyRol, 'admin');
    await prefs.setString(_keyEmail, email);  // ✅ AGREGADO
    debugPrint('✅ Sesión admin guardada: $email');
  }

  /// ✅ OBTENER TIPO DE USUARIO
  static Future<String?> obtenerTipoUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTipoUsuario);
  }

  /// ✅ OBTENER APODERADO GUARDADO
  static Future<GuardianModel?> obtenerApoderado() async {
    final prefs = await SharedPreferences.getInstance();
    final guardianJson = prefs.getString(_keyGuardianData);
    if (guardianJson != null) {
      try {
        final guardianMap = jsonDecode(guardianJson) as Map<String, dynamic>;
        return GuardianModel.fromMap(guardianMap);
      } catch (e) {
        debugPrint('❌ Error decodificando apoderado: $e');
      }
    }
    return null;
  }

  /// ✅ OBTENER PROFESOR GUARDADO
  static Future<ProfesorModel?> obtenerProfesor() async {
    final prefs = await SharedPreferences.getInstance();
    final profesorJson = prefs.getString(_keyProfesorData);
    if (profesorJson != null) {
      try {
        final profesorMap = jsonDecode(profesorJson) as Map<String, dynamic>;
        return ProfesorModel.fromMap(profesorMap);
      } catch (e) {
        debugPrint('❌ Error decodificando profesor: $e');
      }
    }
    return null;
  }

  /// ✅ VERIFICAR SI HAY SESIÓN ACTIVA
  static Future<bool> tieneSesionActiva() async {
    final prefs = await SharedPreferences.getInstance();
    final usuario = prefs.getString(_keyUsuario);
    return usuario != null && usuario.isNotEmpty;
  }

  /// ✅ OBTENER DATOS DE LA SESIÓN ACTUAL
  static Future<Map<String, dynamic>?> obtenerSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final usuario = prefs.getString(_keyUsuario);

    if (usuario == null) return null;

    return {
      'usuario': usuario,
      'contrasena': prefs.getString(_keyContrasena) ?? '',
      'id': prefs.getString(_keyDocId) ?? '',
      'docId': prefs.getString(_keyDocId) ?? '',
      'rol': prefs.getString(_keyRol) ?? '',
      'nombre': prefs.getString(_keyNombre) ?? '',
      'apellido': prefs.getString(_keyApellido) ?? '',
      'nombreCompleto': prefs.getString(_keyNombreCompleto) ?? '',
      'celular': prefs.getString(_keyCelular) ?? '',
      'ci': prefs.getString(_keyCI) ?? '',
      'direccion': prefs.getString(_keyDireccion) ?? '',
      'email': prefs.getString(_keyEmail) ?? '',
      'jugadoresIds': prefs.getStringList(_keyJugadoresIds) ?? [],
    };
  }

  /// Login manual: busca en Firestore y guarda sesión
  static Future<Map<String, dynamic>?> loginManual(
    String usuario,
    String contrasena,
  ) async {
    try {
      debugPrint('🔍 Buscando usuario: $usuario');

      // Buscar en profesores
      var snap = await FirebaseFirestore.instance
          .collection('profesores')
          .where('usuario', isEqualTo: usuario)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        final data = Map<String, dynamic>.from(doc.data());

        if (data['contrasena'] == contrasena) {
          debugPrint('✅ Login exitoso: Profesor ${data['nombre']}');
          
          // ✅ GUARDAR CON NUEVO MÉTODO
          final profesor = ProfesorModel.fromMap(data..['id'] = doc.id);
          await guardarSesionProfesor(profesor);
          
          data['id'] = doc.id;
          data['docId'] = doc.id;
          return data;
        }
      }

      // Buscar en guardianes (apoderados)
      snap = await FirebaseFirestore.instance
          .collection('guardianes')
          .where('usuario', isEqualTo: usuario)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        final data = Map<String, dynamic>.from(doc.data());

        if (data['contrasena'] == contrasena) {
          debugPrint('✅ Login exitoso: Apoderado ${data['nombreCompleto']}');
          
          // ✅ GUARDAR CON NUEVO MÉTODO
          final guardian = GuardianModel.fromMap(data..['id'] = doc.id);
          await guardarSesionApoderado(guardian);
          
          data['id'] = doc.id;
          data['docId'] = doc.id;
          return data;
        }
      }

      debugPrint('❌ Usuario o contraseña incorrectos');
      return null;
    } catch (e) {
      debugPrint('❌ Error en login manual: $e');
      return null;
    }
  }

  /// Guarda la sesión en SharedPreferences (legacy - usar guardarSesionApoderado/guardarSesionProfesor)
  static Future<void> _guardarSesion({
    required String usuario,
    required String contrasena,
    required String docId,
    required String rol,
    required String nombre,
    required String apellido,
    required String nombreCompleto,
    required String celular,
    required String ci,
    required String direccion,
    String categoriaEquipoId = '',
    List<String> jugadoresIds = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsuario, usuario);
    await prefs.setString(_keyContrasena, contrasena);
    await prefs.setString(_keyDocId, docId);
    await prefs.setString(_keyRol, rol);
    await prefs.setString(_keyNombre, nombre);
    await prefs.setString(_keyApellido, apellido);
    await prefs.setString(_keyNombreCompleto, nombreCompleto);
    await prefs.setString(_keyCelular, celular);
    await prefs.setString(_keyCI, ci);
    await prefs.setString(_keyDireccion, direccion);
    await prefs.setStringList(_keyJugadoresIds, jugadoresIds);
    debugPrint('✅ Sesión guardada: $usuario ($rol)');
  }

  /// Actualiza la contraseña en la sesión local
  static Future<void> actualizarContrasenaLocal(String nuevaContrasena) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyContrasena, nuevaContrasena);
    
    // ✅ ACTUALIZAR TAMBIÉN EN JSON GUARDADO
    final tipoUsuario = await obtenerTipoUsuario();
    if (tipoUsuario == 'apoderado') {
      final guardian = await obtenerApoderado();
      if (guardian != null) {
        await guardarSesionApoderado(
          GuardianModel(
            id: guardian.id,
            nombreCompleto: guardian.nombreCompleto,
            apellido: guardian.apellido,
            ci: guardian.ci,
            celular: guardian.celular,
            direccion: guardian.direccion,
            usuario: guardian.usuario,
            contrasena: nuevaContrasena,  // ✅ Nueva contraseña
            jugadoresIds: guardian.jugadoresIds,
            rol: guardian.rol,
          ),
        );
      }
    } else if (tipoUsuario == 'profesor') {
      final profesor = await obtenerProfesor();
      if (profesor != null) {
        await guardarSesionProfesor(
          ProfesorModel(
            id: profesor.id,
            nombre: profesor.nombre,
            apellido: profesor.apellido,
            ci: profesor.ci,
            fechaNacimiento: profesor.fechaNacimiento,
            celular: profesor.celular,
            usuario: profesor.usuario,
            contrasena: nuevaContrasena,  // ✅ Nueva contraseña
            categoriaEquipoId: profesor.categoriaEquipoId,
            rol: profesor.rol,
          ),
        );
      }
    }
    
    debugPrint('✅ Contraseña actualizada localmente');
  }

  /// ✅ VERIFICAR SI HAY SESIÓN ACTIVA
  static Future<bool> haySesionActiva() async {
    final tipo = await obtenerTipoUsuario();
    return tipo != null;
  }

  /// ✅ CERRAR SESIÓN
  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTipoUsuario);
    await prefs.remove(_keyGuardianData);
    await prefs.remove(_keyProfesorData);
    await prefs.remove(_keyUsuario);
    await prefs.remove(_keyContrasena);
    await prefs.remove(_keyDocId);
    await prefs.remove(_keyRol);
    await prefs.remove(_keyNombre);
    await prefs.remove(_keyApellido);
    await prefs.remove(_keyNombreCompleto);
    await prefs.remove(_keyCelular);
    await prefs.remove(_keyCI);
    await prefs.remove(_keyDireccion);
    await prefs.remove(_keyJugadoresIds);
    await prefs.remove(_keyEmail);  // ✅ AGREGADO
    debugPrint('✅ Sesión cerrada completamente');
  }
}
