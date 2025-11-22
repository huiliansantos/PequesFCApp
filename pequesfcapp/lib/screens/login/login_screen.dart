import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_role_provider.dart';
import '../../providers/guardian_provider.dart';
import '../../providers/profesor_provider.dart';
import '../../repositories/player_repository.dart' as player_repo;
import '../../models/profesor_model.dart';
import '../../models/guardian_model.dart';
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

      // 1. Intenta login personalizado de profesor
      debugPrint('👨‍🏫 Verificando profesor...');
      final profesorRepo = ref.read(profesorRepositoryProvider);
      final profesor =
          await profesorRepo.autenticarProfesor(email, password);

      if (profesor != null) {
        debugPrint('✅ Login profesor exitoso: ${profesor.nombre}');
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

      // 2. Intenta login personalizado de apoderado
      debugPrint('👨‍👩‍👧 Verificando apoderado...');
      final guardianRepo = ref.read(guardianRepositoryProvider);
      final guardian =
          await guardianRepo.autenticarGuardian(email, password);

      if (guardian != null) {
        debugPrint('✅ Login apoderado exitoso: ${guardian.nombreCompleto}');
        final playerRepo = ref.read(player_repo.playerRepositoryProvider);
        final hijos = await playerRepo.getPlayersByGuardianId(guardian.id);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ApoderadoHomeScreen(
                guardian: guardian.toMap(), // ✅ CORREGIDO: Cambiar de guardian a guardian.toMap()
                hijos: hijos,
              ),
            ),
          );
        }
        return;
      }

      // 3. Intenta login con Firebase Auth (admin)
      debugPrint('👤 Verificando admin (Firebase Auth)...');
      try {
        await ref
            .read(authRepositoryProvider)
            .signInWithEmail(email, password);

        final rol = await ref.read(userRoleProvider.future);
        debugPrint('✅ Login Firebase exitoso. Rol: $rol');

        if (!mounted) return;

        if (rol == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomeScreen(role: 'admin'),
            ),
          );
          return;
        } else {
          setState(() => error = 'Rol no reconocido: $rol');
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('❌ Error Firebase: ${e.code}');
        setState(() => error = 'Usuario o contraseña incorrectos (Admin)');
      } catch (e) {
        debugPrint('❌ Error en Firebase Auth: $e');
        setState(() => error = 'Usuario o contraseña incorrectos');
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
