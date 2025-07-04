import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth.provider.dart';
import 'providers/user_role_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/login/login_screen.dart';
import 'screens/guardians/guardian_dashboard_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: PequesFCApp()));
}

class PequesFCApp extends ConsumerWidget {
  const PequesFCApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'PEQUES F.C.',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }
          // Usuario autenticado, ahora obtenemos el rol
          return FutureBuilder<String?>(
            future: ref.read(userRoleProvider.future),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData) {
                if (snapshot.data == 'apoderado') {
                  return const GuardianDashboardScreen();
                } else if (snapshot.data == 'admin') {
                  return const HomeScreen(role: 'admin');
                } else {
                  return const Center(child: Text('Rol desconocido'));
                }
              }
              return const Center(child: Text('No se pudo obtener el rol'));
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

