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
      //añadir un buscador por nombre y el titulo de apoderados mas o menos como en las otras ventanas en un column
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.family_restroom, color: Color(0xFFD32F2F), size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lista de Apoderados',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD32F2F),
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black12,
                          offset: Offset(1, 2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nombre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Color(0xFFD32F2F)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Color(0xFFD32F2F)),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD32F2F)),
              ),
              onChanged: (value) {
                // Lógica para filtrar la lista de apoderados por nombre
              },
            ),
          ),
          Expanded(
            child: guardiansAsync.when(
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
          ),
        ],
      ),
    );
  }
}