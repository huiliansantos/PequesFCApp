import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profesor_model.dart';
import '../screens/auth/change_password_manual_screen.dart';
import '../services/auth_service.dart';
import '../screens/login/login_screen.dart';

class ProfesorDrawer extends StatelessWidget {
  final ProfesorModel profesor;
  final VoidCallback? onLogout;
  final Function(int)? onMenuItemSelected; // ✅ AGREGADO: Callback para navegar

  const ProfesorDrawer({
    Key? key,
    required this.profesor,
    this.onLogout,
    this.onMenuItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('profesores')
          .doc(profesor.id)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        // Obtener datos actuales (del stream o del modelo local)
        final profesorActual = snapshot.hasData && snapshot.data!.exists
            ? ProfesorModel.fromMap(
                snapshot.data!.data()!..['id'] = profesor.id)
            : profesor;

        return Drawer(
          child: SafeArea(
            child: Column(
              children: [
                // ✅ HEADER CON INFORMACIÓN DEL PROFESOR - ANCHO COMPLETO
                Container(
                  width: double.infinity, // ✅ Ancho completo
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/peques.png',
                        width: 60,
                        height: 60,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profesorActual.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Profesor',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ✅ OPCIONES DEL MENÚ PRINCIPAL (COMO EN LA IMAGEN)
                _buildMenuOption(
                  context,
                  icon: Icons.home,
                  label: 'Inicio',
                  index: 0,
                  onTap: () {
                    Navigator.pop(context);
                    onMenuItemSelected?.call(0);
                  },
                ),
                _buildMenuOption(
                  context,
                  icon: Icons.people,
                  label: 'Jugadores',
                  index: 1,
                  onTap: () {
                    Navigator.pop(context);
                    onMenuItemSelected?.call(1);
                  },
                ),
                _buildMenuOption(
                  context,
                  icon: Icons.sports_soccer,
                  label: 'Partidos',
                  index: 2,
                  onTap: () {
                    Navigator.pop(context);
                    onMenuItemSelected?.call(2);
                  },
                ),
                _buildMenuOption(
                  context,
                  icon: Icons.emoji_events,
                  label: 'Resultados',
                  index: 3,
                  onTap: () {
                    Navigator.pop(context);
                    onMenuItemSelected?.call(3);
                  },
                ),
                _buildMenuOption(
                  context,
                  icon: Icons.checklist,
                  label: 'Asistencia',
                  index: 4,
                  onTap: () {
                    Navigator.pop(context);
                    onMenuItemSelected?.call(4);
                  },
                ),
                _buildMenuOption(
                  context,
                  icon: Icons.payments,
                  label: 'Pagos',
                  index: 5,
                  onTap: () {
                    Navigator.pop(context);
                    onMenuItemSelected?.call(5);
                  },
                ),

                const Divider(height: 16),

                // ✅ INFORMACIÓN DEL USUARIO
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Usuario'),
                  subtitle: Text(
                    profesorActual.usuario.isNotEmpty
                        ? profesorActual.usuario
                        : '---',
                  ),
                ),

                // ✅ VER CONTRASEÑA
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Ver contraseña'),
                  subtitle: Text(
                    profesorActual.contrasena.isNotEmpty
                        ? 'Mostrar / Ocultar'
                        : 'No disponible',
                  ),
                  onTap: () async {
                    // ✅ Obtener contraseña actual desde Firestore
                    final ref = FirebaseFirestore.instance
                        .collection('profesores')
                        .doc(profesorActual.id);
                    try {
                      final snap = await ref
                          .get(const GetOptions(source: Source.server));
                      final data = snap.data();
                      final latestPass =
                          (data != null && data!['contrasena'] != null)
                              ? data!['contrasena'].toString()
                              : '';

                      if (latestPass.isEmpty) {
                        if (!context.mounted) return;

                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Contraseña'),
                            content: const Text(
                              'La contraseña no está disponible. Puedes cambiarla de forma segura.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cerrar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ChangePasswordManualScreen(
                                        usuario: profesorActual,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Cambiar contraseña'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      bool obscure = true;
                      if (!context.mounted) return;

                      showDialog(
                        context: context,
                        builder: (ctx) {
                          return StatefulBuilder(
                            builder: (ctx2, setState) {
                              return AlertDialog(
                                title: const Text('Contraseña'),
                                content: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        obscure ? '●●●●●●●' : latestPass,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        obscure
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () => setState(
                                        () => obscure = !obscure,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cerrar'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ChangePasswordManualScreen(
                                            usuario: profesorActual,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Cambiar contraseña'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),

                const Spacer(),

                // ✅ CERRAR SESIÓN
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Cerrar sesión',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('¿Cerrar sesión?'),
                        content: const Text(
                          '¿Estás seguro de que deseas cerrar sesión?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Cerrar sesión'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      //cerrar sesion
                      debugPrint(
                          '🔐 Iniciando cierre de sesión del profesor...');

                      // ✅ 1. LIMPIAR SESIÓN LOCAL
                      await AuthService.cerrarSesion();
                      debugPrint('✅ Sesión local cerrada');

                      // ✅ 2. CERRAR SESIÓN EN FIREBASE SI EXISTE
                      try {
                        await FirebaseAuth.instance.signOut();
                        debugPrint('✅ Sesión Firebase cerrada');
                      } catch (e) {
                        debugPrint('⚠️ Error cerrando sesión Firebase: $e');
                      }

                      if (context.mounted) {
                        // ✅ 3. NAVEGAR A LOGIN
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                        debugPrint('✅ Navegado a LoginScreen');
                      }


                      if (!context.mounted) return;

                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );

                      // Ejecutar callback si existe
                      if (onLogout != null) onLogout!();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ WIDGET PARA CONSTRUIR LAS OPCIONES DEL MENÚ
  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFFD32F2F),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
