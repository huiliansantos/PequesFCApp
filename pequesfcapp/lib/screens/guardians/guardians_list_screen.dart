import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/guardian_provider.dart';
import '../../models/guardian_model.dart';
import 'guardian_detail_screen.dart';

class GuardianListScreen extends ConsumerStatefulWidget {
  const GuardianListScreen({super.key});

  @override
  ConsumerState<GuardianListScreen> createState() => _GuardianListScreenState();
}

class _GuardianListScreenState extends ConsumerState<GuardianListScreen> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    final guardiansAsync = ref.watch(guardiansStreamProvider);

    return Scaffold(
        body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                setState(() {
                  searchText = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: guardiansAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (guardians) {
                final filtered = guardians.where((g) =>
                  g.nombreCompleto.toLowerCase().contains(searchText)
                ).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No se encontraron apoderados.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final guardian = filtered[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFD32F2F),
                          child: const Icon(Icons.family_restroom, color: Colors.white),
                        ),
                        title: Text(
                          guardian.nombreCompleto,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('CI: ${guardian.ci}'),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFFD32F2F)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GuardianDetailScreen(guardianId: guardian.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      /*floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD32F2F),
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar Apoderado'),
        onPressed: () {
          // Navega al formulario para crear un nuevo apoderado
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GuardianFormScreen()),
          );
        },
      ),*/
    );
  }
}