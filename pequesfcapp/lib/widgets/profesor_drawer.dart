import 'package:flutter/material.dart';
import '../models/profesor_model.dart';
import '../screens/auth/change_password_manual_screen.dart';

class ProfesorDrawer extends StatelessWidget {
  final ProfesorModel profesor;
  final VoidCallback? onLogout;

  const ProfesorDrawer({Key? key, required this.profesor, this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(radius: 32, backgroundColor: Colors.white, child: Icon(Icons.person, color: Color(0xFFD32F2F), size: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${profesor.nombre} ${profesor.apellido}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Profesor', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        Text('Equipo: ${profesor.categoriaEquipoId}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Usuario'),
              subtitle: Text(profesor.usuario.isNotEmpty ? profesor.usuario : '---'),
            ),

            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Ver contraseña'),
              subtitle: Text(profesor.contrasena.isNotEmpty ? 'Mostrar / Ocultar' : 'No disponible'),
              onTap: () {
                if (profesor.contrasena.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Contraseña'),
                      content: const Text('La contraseña no está disponible. Puedes cambiarla de forma segura.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordManualScreen(profesor: profesor)));
                          },
                          child: const Text('Cambiar contraseña'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                bool obscure = true;
                showDialog(
                  context: context,
                  builder: (ctx) {
                    return StatefulBuilder(builder: (ctx2, setState) {
                      return AlertDialog(
                        title: const Text('Contraseña'),
                        content: Row(
                          children: [
                            Expanded(child: Text(obscure ? '●●●●●●●' : profesor.contrasena)),
                            IconButton(icon: Icon(obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => obscure = !obscure)),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordManualScreen(profesor: profesor)));
                            },
                            child: const Text('Cambiar contraseña'),
                          ),
                        ],
                      );
                    });
                  },
                );
              },
            ),

            const Divider(),
            // Aquí puedes agregar las opciones del menú (navegación)
            ListTile(leading: const Icon(Icons.person), title: const Text('Perfil'), onTap: () {/* navegar */}),
            ListTile(leading: const Icon(Icons.group), title: const Text('Jugadores'), onTap: () {/* navegar */}),

            const Spacer(),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                if (onLogout != null) onLogout!();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}