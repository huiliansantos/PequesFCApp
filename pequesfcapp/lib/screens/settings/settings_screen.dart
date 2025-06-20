import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Editar perfil'),
            onTap: () {
              // Navegar a edición de perfil
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Cambiar contraseña'),
            onTap: () {
              // Navegar a cambio de contraseña
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () {
              // Lógica para cerrar sesión
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Acerca de la app'),
            onTap: () {
              // Mostrar información de la app
            },
          ),
        ],
      ),
    );
  }
}