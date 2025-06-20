import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../providers/auth.provider.dart';
import '../../providers/user_role_provider.dart';
import '../home/home_screen.dart';

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
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => email = v,
                      validator: (v) => v != null && v.contains('@') ? null : 'Correo inválido',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => password = v,
                      validator: (v) => v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres',
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              await ref.read(authRepositoryProvider).signInWithEmail(email, password);
                              final rol = await ref.read(userRoleProvider.future);
                              if (mounted) {
                                if (rol == 'admin') {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const HomeScreen(role: 'admin')),
                                  );
                                } else if (rol == 'apoderado') {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const HomeScreen(role: 'apoderado')),
                                  );
                                } else {
                                  // Maneja el caso de rol desconocido
                                }
                              }
                            } catch (e) {
                              setState(() => error = 'Usuario o contraseña incorrectos');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppConstants.rojo),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Iniciar sesión'),
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