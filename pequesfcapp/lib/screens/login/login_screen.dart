import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../providers/auth.provider.dart';
import '../../providers/user_role_provider.dart';
import '../../providers/guardian_provider.dart';
import '../../providers/profesor_provider.dart';
import '../../repositories/player_repository.dart' as player_repo;
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Usuario o correo',
                        border: OutlineInputBorder(),
                      ),
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
                      onChanged: (v) => password = v.trim(),
                      validator: (v) => v != null && v.length >= 6
                          ? null
                          : 'Mínimo 6 caracteres',
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    FractionallySizedBox(
                      widthFactor: 1,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => error = null);

                              // 1. Intenta login personalizado de profesor
                              final profesorRepo = ref.read(profesorRepositoryProvider);
                              final profesor = await profesorRepo.autenticarProfesor(email, password);
                              if (profesor != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfesorHomeScreen(profesor: profesor),
                                  ),
                                );
                                return;
                              }

                              // 2. Intenta login personalizado de apoderado
                              final guardianRepo = ref.read(guardianRepositoryProvider);
                              final guardian = await guardianRepo.autenticarGuardian(email, password);
                              if (guardian != null) {
                                final playerRepo = ref.read(player_repo.playerRepositoryProvider);
                                final hijos = await playerRepo.getPlayersByGuardianId(guardian.id);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ApoderadoHomeScreen(
                                      guardian: guardian,
                                      hijos: hijos,
                                    ),
                                  ),
                                );
                                return;
                              }

                              // 3. Intenta login con Firebase Auth (admin)
                              try {
                                await ref
                                    .read(authRepositoryProvider)
                                    .signInWithEmail(email, password);
                                final rol =
                                    await ref.read(userRoleProvider.future);
                                print('ROL DETECTADO: $rol');
                                if (mounted) {
                                  if (rol == 'admin') {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const HomeScreen(role: 'admin')),
                                    );
                                    return;
                                  }
                                  setState(() => error = 'Rol desconocido');
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() => error = 'Usuario o contraseña incorrectos');
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(AppConstants.rojo),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Iniciar sesión'),
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
}
