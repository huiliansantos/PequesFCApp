import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth.provider.dart';
import 'providers/user_role_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/login/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('es_ES', null);
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      home: authState.when(
        data: (user) {
          if (user == null) {
            // Aquí entra tanto el apoderado como cualquier usuario no autenticado
            // El LoginScreen se encarga de distinguir el flujo
            return const LoginScreen();
          }
          // Solo usuarios autenticados con Firebase Auth (ej: admin)
          return FutureBuilder<String?>(
            future: ref.read(userRoleProvider.future),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData) {
                if (snapshot.data == 'admin') {
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
