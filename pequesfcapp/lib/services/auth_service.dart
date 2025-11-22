import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
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

  /// Verifica si hay sesión activa
  static Future<bool> tieneSesionActiva() async {
    final prefs = await SharedPreferences.getInstance();
    final usuario = prefs.getString(_keyUsuario);
    return usuario != null && usuario.isNotEmpty;
  }

  /// Obtiene datos de la sesión actual
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
          await _guardarSesion(
            usuario: usuario,
            contrasena: contrasena,
            docId: doc.id,
            rol: 'profesor',
            nombre: data['nombre'] ?? '',
            apellido: data['apellido'] ?? '',
            nombreCompleto: '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}',
            celular: data['celular'] ?? '',
            ci: data['ci'] ?? '',
            direccion: data['direccion'] ?? '',
            categoriaEquipoId: data['categoriaEquipoId'] ?? '',
          );
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
          
          final jugadoresIds =
              (data['jugadoresIds'] as List<dynamic>?)?.cast<String>() ?? [];

          await _guardarSesion(
            usuario: usuario,
            contrasena: contrasena,
            docId: doc.id,
            rol: 'apoderado',
            nombre: '',
            apellido: '',
            nombreCompleto: data['nombreCompleto'] ?? '',
            celular: data['celular'] ?? '',
            ci: data['ci'] ?? '',
            direccion: data['direccion'] ?? '',
            jugadoresIds: jugadoresIds,
          );
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

  /// Guarda la sesión en SharedPreferences
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
  /// Se llama después de cambiar contraseña en Firestore
  static Future<void> actualizarContrasenaLocal(
      String nuevaContrasena) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyContrasena, nuevaContrasena);
    debugPrint('✅ Contraseña actualizada localmente');
  }

  /// Cierra la sesión actual
  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
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
    debugPrint('✅ Sesión cerrada');
  }
}