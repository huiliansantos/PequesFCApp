import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/guardian_model.dart';
import '../screens/login/login_screen.dart';
import '../services/auth_service.dart';
import '../screens/auth/change_password_manual_screen.dart';

class ApoderadoDrawer extends StatelessWidget {
  final GuardianModel guardian;
  final Function(int)? onMenuItemSelected;

  const ApoderadoDrawer({
    Key? key,
    required this.guardian,
    this.onMenuItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final docStream = FirebaseFirestore.instance
        .collection('guardianes')
        .doc(guardian.id)
        .snapshots(includeMetadataChanges: true);

    return Drawer(
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: docStream,
          builder: (context, snapshot) {
            final data = (snapshot.hasData && snapshot.data!.exists)
                ? snapshot.data!.data()
                : null;

            final nombreCompleto =
                (data?['nombreCompleto'] ?? guardian.nombreCompleto)
                    .toString();
            final usuario = (data?['usuario'] ?? guardian.usuario).toString();
            final contrasena =
                (data?['contrasena'] ?? guardian.contrasena).toString();

            return Column(
              children: [
                // ✅ HEADER CON INFORMACIÓN DEL APODERADO
                Container(
                  width: double.infinity,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/peques.png',
                        width: 60,
                        height: 60,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nombreCompleto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Apoderado',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ✅ CONTENIDO SCROLLABLE
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // ✅ OPCIONES DEL MENÚ PRINCIPAL
                        _buildMenuOption(
                          context,
                          icon: Icons.home_outlined,
                          label: 'Inicio',
                          onTap: () {
                            Navigator.pop(context);
                            onMenuItemSelected?.call(0);
                          },
                        ),
                        _buildMenuOption(
                          context,
                          icon: Icons.checklist_rtl,
                          label: 'Asistencia',
                          onTap: () {
                            Navigator.pop(context);
                            onMenuItemSelected?.call(1);
                          },
                        ),
                        _buildMenuOption(
                          context,
                          icon: Icons.payment_outlined,
                          label: 'Pagos',
                          onTap: () {
                            Navigator.pop(context);
                            onMenuItemSelected?.call(2);
                          },
                        ),
                        _buildMenuOption(
                          context,
                          icon: Icons.sports_soccer_outlined,
                          label: 'Partidos',
                          onTap: () {
                            Navigator.pop(context);
                            onMenuItemSelected?.call(3);
                          },
                        ),
                        _buildMenuOption(
                          context,
                          icon: Icons.emoji_events_outlined,
                          label: 'Resultados',
                          onTap: () {
                            Navigator.pop(context);
                            onMenuItemSelected?.call(4);
                          },
                        ),

                        const Divider(height: 16),

                        // ✅ INFORMACIÓN DEL USUARIO
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: const Text('Usuario'),
                          subtitle:
                              Text(usuario.isNotEmpty ? usuario : '---'),
                        ),

                        // ✅ VER CONTRASEÑA
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: const Text('Ver contraseña'),
                          subtitle: Text(contrasena.isNotEmpty
                              ? 'Mostrar / Ocultar'
                              : 'No disponible'),
                          onTap: () async {
                            await _mostrarContrasena(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ✅ CERRAR SESIÓN - SIEMPRE AL FINAL
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Cerrar sesión',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    await _cerrarSesionConDialogo(context);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ✅ MOSTRAR CONTRASEÑA EN DIALOG
  Future<void> _mostrarContrasena(BuildContext context) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('guardianes')
          .doc(guardian.id);
      final snap =
          await ref.get(const GetOptions(source: Source.server));
      final data = snap.data();
      final latestPass = (data != null && data!['contrasena'] != null)
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
                      builder: (_) => ChangePasswordManualScreen(
                        usuario: guardian,
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
                        obscure ? Icons.visibility : Icons.visibility_off,
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
                          builder: (_) => ChangePasswordManualScreen(
                            usuario: guardian,
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
      debugPrint('❌ Error mostrando contraseña: $e');
    }
  }

  // ✅ CERRAR SESIÓN CON CONFIRMACIÓN
  Future<void> _cerrarSesionConDialogo(BuildContext context) async {
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        debugPrint('🔐 Iniciando cierre de sesión del apoderado...');

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

        if (!context.mounted) return;

        // ✅ 3. NAVEGAR A LOGIN (SIN RUTAS NOMBRADAS)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false,
        );
        debugPrint('✅ Navegado a LoginScreen');
      } catch (e) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
        debugPrint('❌ Error al cerrar sesión: $e');
      }
    }
  }

  // ✅ WIDGET PARA CONSTRUIR LAS OPCIONES DEL MENÚ
  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String label,
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
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
      splashColor: Colors.red.shade50,
      hoverColor: Colors.red.shade50,
    );
  }
}