import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/guardian_provider.dart';
import '../../models/guardian_model.dart';
import 'guardian_detail_screen.dart';

class GuardianListScreen extends ConsumerWidget {
  const GuardianListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardiansAsync = ref.watch(guardiansStreamProvider);

    return Scaffold(
      //appBar: AppBar(title: const Text('Lista de Apoderados')),
      body: guardiansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (guardians) => ListView.builder(
          itemCount: guardians.length,
          itemBuilder: (context, index) {
            final guardian = guardians[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFD32F2F),
                child: Icon(Icons.family_restroom, color: Colors.white),
              ),
              title: Text(guardian.nombreCompleto),
              subtitle: Text('CI: ${guardian.ci}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GuardianDetailScreen(guardian: guardian),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}