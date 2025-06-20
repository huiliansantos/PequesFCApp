import 'package:flutter/material.dart';
import '../core/constants.dart';

class CustomBottomNav extends StatelessWidget {
  final String role;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.role,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == AppConstants.adminRole;
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: const Color(AppConstants.rojo),
      unselectedItemColor: Colors.grey,
      items: isAdmin
          ? const [
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Jugadores',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payment),
                label: 'Pagos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Ajustes',
              ),
            ]
          : const [
              BottomNavigationBarItem(
                icon: Icon(Icons.child_care),
                label: 'Mis Hijos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'Pagos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Ajustes',
              ),
            ],
    );
  }
}