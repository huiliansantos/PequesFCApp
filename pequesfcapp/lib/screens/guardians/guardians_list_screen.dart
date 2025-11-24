import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/guardian_provider.dart';
import 'guardian_detail_screen.dart';
import 'guardian_form_screen.dart';

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
                          backgroundImage: 
                          const AssetImage('assets/apoderado.png'),
                          
                        ),
                        title: Text(
                          // a lado del nombre completo poner apellido
                          '${guardian.nombreCompleto} ${guardian.apellido}',
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
                        onLongPress: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (context) => Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit, color: Color(0xFFD32F2F)),
                                    title: const Text('Modificar apoderado'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => GuardianFormScreen(guardian: guardian),
                                        ),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete, color: Colors.red),
                                    title: const Text('Eliminar apoderado'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('¿Eliminar apoderado?'),
                                          content: const Text('¿Estás seguro de eliminar este apoderado?'),
                                          actions: [
                                            TextButton(
                                              child: const Text('Cancelar'),
                                              onPressed: () => Navigator.pop(context),
                                            ),
                                            TextButton(
                                              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                await ref.read(guardianRepositoryProvider).deleteGuardian(guardian.id);
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
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
    );
  }
}