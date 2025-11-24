import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/user_role_provider.dart';
import 'repositories/user_repository.dart';
import 'services/auth_service.dart';
import 'models/guardian_model.dart';
import 'models/profesor_model.dart';
import 'models/player_model.dart';
import 'core/theme/app_theme.dart';
import 'screens/login/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/apoderado_home_screen.dart';
import 'screens/home/profesor_home_screen.dart';
import 'providers/player_provider.dart' as player_repo;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es_ES', null);
  runApp(const ProviderScope(child: PequesFCApp()));
}

class PequesFCApp extends ConsumerWidget {
  const PequesFCApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'PEQUES F.C.',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      home: const _RootScreen(),
    );
  }
}

/// ✅ WIDGET RAÍZ QUE MANEJA LA NAVEGACIÓN
class _RootScreen extends ConsumerWidget {
  const _RootScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (firebaseUser) {
        // ✅ 1. SI HAY USUARIO EN FIREBASE (ADMIN)
        if (firebaseUser != null) {
          debugPrint('👤 Usuario Firebase: ${firebaseUser.email}');
          debugPrint('🔐 UID: ${firebaseUser.uid}');

          return FutureBuilder<Map<String, dynamic>?>(
            future: _determinarRolYCargarDatos(firebaseUser.uid, ref),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingScreen();
              }

              if (snapshot.hasData && snapshot.data != null) {
                final data = snapshot.data!;
                final rol = data['rol'] as String;
                debugPrint('✅ Rol determinado: $rol');
                debugPrint('📋 Datos cargados: ${data.keys.join(', ')}');

                // ✅ ADMIN
                if (rol == 'admin') {
                  debugPrint('🎯 Navegando a HomeScreen (Admin)');
                  return const HomeScreen(role: 'admin');
                }

                // ✅ APODERADO
                if (rol == 'apoderado') {
                  debugPrint('🎯 Navegando a ApoderadoHomeScreen');
                  return ApoderadoHomeScreen(
                    guardian: data['guardian'] ?? {},
                    hijos: data['hijos'] ?? [],
                  );
                }

                // ✅ PROFESOR
                if (rol == 'profesor') {
                  debugPrint('🎯 Navegando a ProfesorHomeScreen');
                  return ProfesorHomeScreen(
                    profesor: data['profesor'] ?? {},
                  );
                }
              }

              debugPrint('❌ No se pudo determinar rol o cargar datos');
              return const LoginScreen();
            },
          );
        }

        // ✅ 2. SI NO HAY USUARIO EN FIREBASE, VERIFICAR SESIÓN LOCAL
        return FutureBuilder<String?>(
          future: AuthService.obtenerTipoUsuario(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (snapshot.hasData) {
              final tipoUsuario = snapshot.data;
              debugPrint('📱 Sesión local encontrada: $tipoUsuario');

              // ✅ APODERADO (SESIÓN LOCAL)
              if (tipoUsuario == 'apoderado') {
                return FutureBuilder(
                  future: AuthService.obtenerApoderado(),
                  builder: (context, apoderadoSnapshot) {
                    if (apoderadoSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const _LoadingScreen();
                    }
                    if (apoderadoSnapshot.hasData &&
                        apoderadoSnapshot.data != null) {
                      final guardian = apoderadoSnapshot.data!;
                      debugPrint(
                          '✅ Apoderado restaurado: ${guardian.nombreCompleto}');
                      return ApoderadoHomeScreen(
                        guardian: guardian.toMap(),
                        hijos: [],
                      );
                    }
                    debugPrint('❌ Error restaurando apoderado');
                    return const LoginScreen();
                  },
                );
              }

              // ✅ PROFESOR (SESIÓN LOCAL)
              if (tipoUsuario == 'profesor') {
                return FutureBuilder(
                  future: AuthService.obtenerProfesor(),
                  builder: (context, profesorSnapshot) {
                    if (profesorSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const _LoadingScreen();
                    }
                    if (profesorSnapshot.hasData &&
                        profesorSnapshot.data != null) {
                      final profesor = profesorSnapshot.data!;
                      debugPrint('✅ Profesor restaurado: ${profesor.nombre}');
                      return ProfesorHomeScreen(
                        profesor: profesor.toMap(),
                      );
                    }
                    debugPrint('❌ Error restaurando profesor');
                    return const LoginScreen();
                  },
                );
              }

              // ✅ ADMIN (SESIÓN LOCAL)
              if (tipoUsuario == 'admin') {
                debugPrint('✅ Admin restaurado de sesión local');
                return const HomeScreen(role: 'admin');
              }
            }

            // ✅ 3. SIN SESIÓN - IR A LOGIN
            debugPrint('📍 No hay sesión activa - ir a LoginScreen');
            return const LoginScreen();
          },
        );
      },
      loading: () => const _LoadingScreen(),
      error: (error, stack) {
        debugPrint('❌ Error en auth state: $error');
        return const LoginScreen();
      },
    );
  }

  /// ✅ DETERMINAR ROL Y CARGAR TODOS LOS DATOS DESDE FIRESTORE
  Future<Map<String, dynamic>?> _determinarRolYCargarDatos(
      String uid, WidgetRef ref) async {
    try {
      debugPrint('🔍 Determinando rol y cargando datos para UID: $uid');

      final userRepo = UserRepository();
      final rol = await userRepo.getUserRole(uid);

      if (rol == null) {
        debugPrint('❌ No se encontró rol para el UID');
        return null;
      }

      debugPrint('✅ Rol encontrado: $rol');

      // ✅ CARGAR DATOS SEGÚN EL ROL
      if (rol == 'admin') {
        debugPrint('👤 Cargando datos del admin...');
        final userData = await userRepo.getUserData(uid);

        if (userData != null) {
          await AuthService.guardarSesionAdmin(
            email: userData['correo'] ?? uid,
            uid: uid,
          );
          debugPrint('✅ Sesión admin guardada');
          return {
            'rol': 'admin',
            'data': userData,
          };
        }
        return null;
      }

      if (rol == 'apoderado') {
        debugPrint('👨‍👩‍👧 Cargando datos del apoderado...');
        final userData = await userRepo.getUserData(uid);
        debugPrint('📋 Datos crudos del apoderado: $userData');

        if (userData != null) {
          userData['id'] = uid;
          final guardian = GuardianModel.fromMap(userData);

          // ✅ GUARDAR SESIÓN APODERADO
          await AuthService.guardarSesionApoderado(guardian);
          debugPrint('✅ Sesión apoderado guardada');

          // ✅ CARGAR HIJOS
          List<PlayerModel> hijos = [];
          try {
            if (guardian.jugadoresIds.isNotEmpty) {
              debugPrint(
                  '👶 Cargando ${guardian.jugadoresIds.length} hijos...');
              final playerRepo =
                    ref.read(player_repo.playerRepositoryProvider);
                hijos = await (playerRepo as dynamic)
                    .getPlayersByIds(guardian.jugadoresIds)
                    .timeout(
                      const Duration(seconds: 15),
                      onTimeout: () {
                        debugPrint('⚠️ Timeout al obtener hijos');
                        return [];
                      },
                    );
              debugPrint('✅ Hijos cargados: ${hijos.length}');
            } else {
              debugPrint('⚠️ Apoderado sin hijos asignados');
            }
          } catch (e) {
            debugPrint('⚠️ Error cargando hijos: $e');
            hijos = [];
          }

          return {
            'rol': 'apoderado',
            'guardian': guardian.toMap(),
            'hijos': hijos,
          };
        }
        return null;
      }

      if (rol == 'profesor') {
        debugPrint('👨‍🏫 Cargando datos del profesor...');
        final userData = await userRepo.getUserData(uid);
        debugPrint('📋 Datos crudos del profesor: $userData');

        if (userData != null) {
          userData['id'] = uid;
          final profesor = ProfesorModel.fromMap(userData);

          // ✅ GUARDAR SESIÓN PROFESOR
          await AuthService.guardarSesionProfesor(profesor);
          debugPrint('✅ Sesión profesor guardada');

          return {
            'rol': 'profesor',
            'profesor': profesor.toMap(),
          };
        }
        return null;
      }

      debugPrint('❌ Rol desconocido: $rol');
      return null;
    } catch (e) {
      debugPrint('❌ Error determinando rol y cargando datos: $e');
      return null;
    }
  }
}

/// ✅ PANTALLA DE CARGA
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD32F2F),
              Color(0xFFF57C00),
              Color(0xFF7CB342),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/peques.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Peques FC',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cargando...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
