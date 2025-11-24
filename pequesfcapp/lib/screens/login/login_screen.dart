import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:PequesFCApp/services/auth_registration_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_role_provider.dart';
import '../../providers/guardian_provider.dart';
import '../../providers/profesor_provider.dart';
import '../../repositories/player_repository.dart' as player_repo;
import '../../models/profesor_model.dart';
import '../../models/guardian_model.dart';
import '../../services/auth_service.dart';
import '../home/apoderado_home_screen.dart';
import '../home/home_screen.dart';
import '../home/profesor_home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String? error;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(AppConstants.rojo),
              Color(AppConstants.naranjaFuego),
              Color(AppConstants.verdeOliva),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Logo institucional
                    Image.asset(
                      'assets/peques.png',
                      height: 90,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(AppConstants.rojo),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Usuario o correo',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isLoading,
                      onChanged: (v) => email = v.trim(),
                      validator: (v) => v != null && v.isNotEmpty
                          ? null
                          : 'Ingrese su usuario o correo',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      enabled: !_isLoading,
                      onChanged: (v) => password = v.trim(),
                      validator: (v) => v != null && v.length >= 6
                          ? null
                          : 'Mínimo 6 caracteres',
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FractionallySizedBox(
                      widthFactor: 1,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(AppConstants.rojo),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Iniciar sesión'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      error = null;
      _isLoading = true;
    });

    try {
      debugPrint('🔐 Intentando login con usuario: $email');

      // ✅ 1. INTENTA LOGIN LOCAL DE PROFESOR
      debugPrint('👨‍🏫 Verificando profesor...');
      final profesorRepo = ref.read(profesorRepositoryProvider);
      final profesor =
          await profesorRepo.autenticarProfesor(email, password);

      if (profesor != null && mounted) {
        debugPrint('✅ Login profesor exitoso: ${profesor.nombre}');
        
        // ✅ GUARDAR SESIÓN
        await AuthService.guardarSesionProfesor(profesor);
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProfesorHomeScreen(
                profesor: profesor.toMap(),
              ),
            ),
          );
        }
        return;
      }

      // ✅ 2. INTENTA LOGIN CON FIREBASE AUTH DE PROFESOR
      debugPrint('🔓 Intentando Firebase Auth profesor...');
      final emailProfesor = '${email}@peques.local';
      try {
        final userCred = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: emailProfesor,
          password: password,
        );

        if (!mounted) return;

        debugPrint('✅ Profesor autenticado en Firebase Auth');

        final profesorSnapshot = await FirebaseFirestore.instance
            .collection('profesores')
            .where('firebaseUid', isEqualTo: userCred.user?.uid)
            .limit(1)
            .get();

        if (profesorSnapshot.docs.isNotEmpty && mounted) {
          final profesorData = profesorSnapshot.docs.first.data();
          final profesorLogeado = ProfesorModel.fromMap(profesorData
            ..['id'] = profesorSnapshot.docs.first.id);

          // ✅ GUARDAR SESIÓN
          await AuthService.guardarSesionProfesor(profesorLogeado);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ProfesorHomeScreen(
                  profesor: profesorLogeado.toMap(),
                ),
              ),
            );
          }
          return;
        }

        if (mounted) {
          await FirebaseAuth.instance.signOut();
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('⚠️ Error Firebase Auth profesor: ${e.code}');
      }

      if (!mounted) return;

      // ✅ 3. INTENTA LOGIN LOCAL DE APODERADO
      debugPrint('👨‍👩‍👧 Verificando apoderado...');
      final guardianRepo = ref.read(guardianRepositoryProvider);
      final guardian =
          await guardianRepo.autenticarGuardian(email, password);

      if (guardian != null && mounted) {
        debugPrint('✅ Login apoderado exitoso: ${guardian.nombreCompleto}');
        debugPrint('📋 Datos del apoderado: ${guardian.toMap()}');
        
        try {
          // ✅ OBTENER HIJOS CON MANEJO DE ERRORES
          debugPrint('📱 Obteniendo hijos del apoderado (ID: ${guardian.id})...');
          final playerRepo = ref.read(player_repo.playerRepositoryProvider);
          
          List<dynamic> hijos = [];
          try {
            hijos = await playerRepo
                .getPlayersByGuardianId(guardian.id)
                .timeout(
                  const Duration(seconds: 15),
                  onTimeout: () {
                    debugPrint('⚠️ Timeout al obtener hijos - continuando sin hijos');
                    return [];
                  },
                );
          } catch (e) {
            debugPrint('⚠️ Error al obtener hijos: $e - continuando sin hijos');
            hijos = [];
          }

          if (!mounted) return;

          debugPrint('✅ Hijos obtenidos: ${hijos.length}');

          // ✅ GUARDAR SESIÓN ANTES DE NAVEGAR
          try {
            await AuthService.guardarSesionApoderado(guardian);
            debugPrint('✅ Sesión guardada correctamente');
          } catch (e) {
            debugPrint('⚠️ Error guardando sesión: $e');
          }

          if (mounted) {
            debugPrint('🔄 Navegando a ApoderadoHomeScreen...');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ApoderadoHomeScreen(
                  guardian: guardian.toMap(),
                  hijos: hijos,
                ),
              ),
            );
          }
          return;
        } catch (e) {
          debugPrint('❌ Error en login local apoderado: $e');
          if (mounted) {
            setState(() =>
                error = 'Error: $e');
          }
          return;
        }
      }

      debugPrint('⚠️ No encontrado en login local apoderado, intentando Firebase...');

      if (!mounted) return;

      // ✅ 4. INTENTA LOGIN CON FIREBASE AUTH DE APODERADO
      debugPrint('🔓 Intentando Firebase Auth apoderado...');
      final emailGuardian = '${email}@peques.local';
      try {
        final userCred = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: emailGuardian,
          password: password,
        );

        if (!mounted) return;

        debugPrint('✅ Apoderado autenticado en Firebase Auth: ${userCred.user?.email}');
        debugPrint('🔍 Firebase UID: ${userCred.user?.uid}');

        // ✅ BUSCAR POR EMAIL PRIMERO (más rápido)
        var guardianSnapshot = await FirebaseFirestore.instance
            .collection('guardianes')
            .where('email', isEqualTo: emailGuardian)
            .limit(1)
            .get();

        debugPrint('🔍 Búsqueda por email: ${guardianSnapshot.docs.length} resultados');

        // ✅ SI NO ENCUENTRA POR EMAIL, BUSCAR POR USUARIO
        if (guardianSnapshot.docs.isEmpty) {
          debugPrint('⚠️ No encontrado por email, buscando por usuario: $email');
          guardianSnapshot = await FirebaseFirestore.instance
              .collection('guardianes')
              .where('usuario', isEqualTo: email)
              .limit(1)
              .get();

          debugPrint('🔍 Búsqueda por usuario: ${guardianSnapshot.docs.length} resultados');
        }

        // ✅ SI NO ENCUENTRA POR USUARIO, BUSCAR POR UID
        if (guardianSnapshot.docs.isEmpty) {
          debugPrint('⚠️ No encontrado por usuario, buscando por firebaseUid: ${userCred.user?.uid}');
          guardianSnapshot = await FirebaseFirestore.instance
              .collection('guardianes')
              .where('firebaseUid', isEqualTo: userCred.user?.uid)
              .limit(1)
              .get();

          debugPrint('🔍 Búsqueda por firebaseUid: ${guardianSnapshot.docs.length} resultados');
        }

        if (guardianSnapshot.docs.isNotEmpty && mounted) {
          final guardianData = guardianSnapshot.docs.first.data();
          final guardianId = guardianSnapshot.docs.first.id;
          
          debugPrint('✅ Apoderado encontrado: ${guardianData['nombreCompleto']}');

          // ✅ ACTUALIZAR FIREBASEUID SI NO EXISTE O ES DIFERENTE
          if (guardianData['firebaseUid'] != userCred.user?.uid) {
            try {
              debugPrint('📝 Actualizando firebaseUid del apoderado...');
              await FirebaseFirestore.instance
                  .collection('guardianes')
                  .doc(guardianId)
                  .update({'firebaseUid': userCred.user?.uid});
            } catch (e) {
              debugPrint('⚠️ Error actualizando firebaseUid: $e');
            }
          }

          final guardianLogeado = GuardianModel.fromMap(guardianData
            ..['id'] = guardianId);

          try {
            // ✅ OBTENER HIJOS CON MANEJO DE ERRORES
            debugPrint('📱 Obteniendo hijos del apoderado (Firebase Auth)...');
            final playerRepo = ref.read(player_repo.playerRepositoryProvider);
            
            List<dynamic> hijos = [];
            try {
              hijos = await playerRepo
                  .getPlayersByGuardianId(guardianLogeado.id)
                  .timeout(
                    const Duration(seconds: 15),
                    onTimeout: () {
                      debugPrint('⚠️ Timeout al obtener hijos');
                      return [];
                    },
                  );
            } catch (e) {
              debugPrint('⚠️ Error al obtener hijos: $e - continuando sin hijos');
              hijos = [];
            }

            if (!mounted) return;

            debugPrint('✅ Hijos obtenidos: ${hijos.length}');

            // ✅ GUARDAR SESIÓN
            try {
              await AuthService.guardarSesionApoderado(guardianLogeado);
              debugPrint('✅ Sesión guardada correctamente');
            } catch (e) {
              debugPrint('⚠️ Error guardando sesión: $e');
            }

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ApoderadoHomeScreen(
                    guardian: guardianLogeado.toMap(),
                    hijos: hijos,
                  ),
                ),
              );
            }
            return;
          } catch (e) {
            debugPrint('❌ Error obteniendo hijos (Firebase Auth): $e');
            if (mounted) {
              setState(() => error = 'Error al obtener información: $e');
            }
            return;
          }
        } else {
          debugPrint('❌ No encontrado apoderado en Firestore');
        }

        if (mounted) {
          try {
            await FirebaseAuth.instance.signOut();
          } catch (e) {
            debugPrint('⚠️ Error cerrando sesión Firebase: $e');
          }
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('❌ Error Firebase Auth apoderado: ${e.code} - ${e.message}');
      } catch (e) {
        debugPrint('❌ Error general en Firebase Auth apoderado: $e');
      }

      if (!mounted) return;

      // ✅ 5. INTENTA LOGIN CON FIREBASE AUTH (ADMIN)
      debugPrint('👤 Verificando admin (Firebase Auth)...');
      try {
        final userCred = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (!mounted) return;

        debugPrint('✅ Usuario autenticado en Firebase: ${userCred.user?.email}');

        // ✅ VERIFICAR SI ES ADMIN CHECANDO CUSTOM CLAIMS
        final idTokenResult = await userCred.user?.getIdTokenResult(true);
        final isAdmin = idTokenResult?.claims?['admin'] ?? false;

        if (isAdmin) {
          debugPrint('✅ Login Admin exitoso: ${userCred.user?.email}');
          
          // ✅ GUARDAR SESIÓN ADMIN
          await AuthService.guardarSesionAdmin(
            email: email,
            uid: userCred.user?.uid ?? '',
          );

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const HomeScreen(role: 'admin'),
              ),
            );
          }
          return;
        } else {
          debugPrint('❌ Usuario no es admin');
          if (mounted) {
            setState(() => error = 'Usuario o contraseña incorrectos');
          }
          return;
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('❌ Error Firebase Admin: ${e.code} - ${e.message}');
        if (mounted) {
          setState(() => error = 'Usuario o contraseña incorrectos');
        }
      } catch (e) {
        debugPrint('❌ Error en Firebase Auth: $e');
        if (mounted) {
          setState(() => error = 'Usuario o contraseña incorrectos');
        }
      }
    } catch (e) {
      debugPrint('❌ Error general en login: $e');
      if (mounted) {
        setState(() => error = 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
