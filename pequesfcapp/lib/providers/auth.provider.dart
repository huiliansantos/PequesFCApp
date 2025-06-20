import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

// Simulación de estado de autenticación
enum AuthStatus { authenticated, unauthenticated, loading }

final authStatusProvider = StateProvider<AuthStatus>((ref) => AuthStatus.unauthenticated);

// Ejemplo de provider para el usuario autenticado (puedes conectar con Firebase más adelante)
final userProvider = StateProvider<String?>((ref) => null);

// Puedes crear más providers para otros módulos:
// - playerProvider
// - paymentProvider
// - matchProvider
// etc.

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);