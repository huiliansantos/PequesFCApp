import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/user_repository.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());

final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  return ref.read(userRepositoryProvider).getUserRole(user.uid);
});