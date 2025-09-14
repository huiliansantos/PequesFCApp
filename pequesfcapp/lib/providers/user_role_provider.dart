import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/user_repository.dart';
import 'profesor_provider.dart';
import 'guardian_provider.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());

final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  // Busca en la colección principal de usuarios
  final role = await ref.read(userRepositoryProvider).getUserRole(user.uid);
  if (role != null) return role;

  // Si no encuentra, busca en profesores
  final profesor = await ref.read(profesorRepositoryProvider).getProfesorByUsuario(user.email ?? '');
  if (profesor != null) return 'profesor';

  // Si no encuentra, busca en guardianes
  final guardian = await ref.read(guardianRepositoryProvider).getGuardianByEmail(user.email ?? '');
  if (guardian != null) return 'apoderado';

  return null;
});
//obtener rol del usuario autenticado
//verificar si es profesor
//verificar si es administrador
//verificar si es guardián
