import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GuardianDashboardScreen extends StatelessWidget {
  const GuardianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Panel del Tutor (${user?.email ?? ''})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Información del Alumno'),
            onTap: () {
              // Navegar a la pantalla de información del alumno
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Pagos'),
            onTap: () {
              // Navegar a la pantalla de pagos
            },
          ),
          ListTile(
            leading: const Icon(Icons.announcement),
            title: const Text('Avisos'),
            onTap: () {
              // Navegar a la pantalla de avisos
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historial de Asistencia'),
            onTap: () {
              // Navegar a la pantalla de asistencia
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Actualizar Datos de Contacto'),
            onTap: () {
              // Navegar a la pantalla de configuración
            },
          ),
        ],
      ),
    );
  }
}